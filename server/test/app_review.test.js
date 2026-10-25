const test = require('node:test');
const assert = require('node:assert/strict');
const { DEFAULTS } = require('../app_review_config');
const {
  DAY_MS,
  evaluateEligibility,
  decideAction,
  countsAsPrompt,
  parseClientInfo,
  parseRateInput,
  parseFeedbackInput,
  inSendWindow,
  pushCopyFor,
  runPushTick,
} = require('../app_review');

const NOW = Date.UTC(2026, 9, 25, 17);

function draft() {
  return JSON.parse(JSON.stringify(DEFAULTS));
}

/** A player who passes every default rule. */
const veteran = { matchesPlayed: 40, wins: 20, createdAtMs: NOW - 30 * DAY_MS };

function freshState(overrides = {}) {
  return { promptsShown: 0, lastPromptAtMs: null, lastStars: null, lastRatedAtMs: null, ...overrides };
}

function check(overrides) {
  return evaluateEligibility({
    config: draft(),
    trigger: 'win',
    player: veteran,
    state: freshState(),
    nowMs: NOW,
    ...overrides,
  });
}

test('an eligible player sees the prompt', () => {
  assert.deepEqual(check({}), { show: true, reason: 'eligible' });
  assert.deepEqual(check({ state: null }), { show: true, reason: 'eligible' });
});

test('each rule can hold the prompt back', () => {
  const disabled = draft();
  disabled.enabled = false;
  const launchOff = draft();
  launchOff.triggers.launch = false;

  const cases = [
    [{ config: disabled }, 'disabled'],
    [{ trigger: 'nope' }, 'unknown_trigger'],
    [{ config: launchOff, trigger: 'launch' }, 'trigger_off'],
    [{ player: { ...veteran, matchesPlayed: 4 } }, 'too_few_matches'],
    [{ player: { ...veteran, wins: 1 } }, 'too_few_wins'],
    [{ player: { ...veteran, createdAtMs: NOW - DAY_MS } }, 'account_too_new'],
    [{ state: freshState({ promptsShown: 3 }) }, 'max_prompts'],
    [{ state: freshState({ lastPromptAtMs: NOW - 13 * DAY_MS }) }, 'cooldown'],
    // A happy rating with highRatingRepromptDays = 0 never asks again.
    [{ state: freshState({ lastStars: 5, lastRatedAtMs: NOW - 400 * DAY_MS }) }, 'already_rated'],
    // A low rating waits lowRatingRepromptDays (90).
    [{ state: freshState({ lastStars: 2, lastRatedAtMs: NOW - 89 * DAY_MS }) }, 'already_rated'],
  ];
  for (const [overrides, reason] of cases) {
    assert.deepEqual(check(overrides), { show: false, reason }, reason);
  }
});

test('the cooldown and re-prompt windows open again once they pass', () => {
  assert.equal(check({ state: freshState({ lastPromptAtMs: NOW - 14 * DAY_MS }) }).show, true);
  assert.equal(check({ state: freshState({ lastStars: 2, lastRatedAtMs: NOW - 90 * DAY_MS }) }).show, true);

  const config = draft();
  config.rules.highRatingRepromptDays = 180;
  const happy = freshState({ lastStars: 4, lastRatedAtMs: NOW - 181 * DAY_MS });
  assert.equal(check({ config, state: happy }).show, true);
});

test('settings and push prompts skip the rules but not the master switch', () => {
  const newcomer = { matchesPlayed: 0, wins: 0, createdAtMs: NOW };
  const maxed = freshState({ promptsShown: 99, lastPromptAtMs: NOW });
  assert.deepEqual(check({ trigger: 'settings', player: newcomer, state: maxed }), {
    show: true,
    reason: 'settings',
  });
  assert.deepEqual(check({ trigger: 'push', player: newcomer, state: maxed }), {
    show: true,
    reason: 'push',
  });

  const settingsOff = draft();
  settingsOff.triggers.settings = false;
  assert.equal(check({ config: settingsOff, trigger: 'settings' }).reason, 'trigger_off');
  const disabled = draft();
  disabled.enabled = false;
  assert.equal(check({ config: disabled, trigger: 'push' }).reason, 'disabled');
});

test('only automatic prompts count towards maxPrompts', () => {
  assert.equal(countsAsPrompt('win'), true);
  assert.equal(countsAsPrompt('daily'), true);
  assert.equal(countsAsPrompt('launch'), true);
  assert.equal(countsAsPrompt('settings'), false);
  assert.equal(countsAsPrompt('push'), false);
});

test('decideAction sends happy players to the store and asks the rest why', () => {
  const config = draft();
  assert.equal(decideAction(config, 'android', 4), 'store');
  assert.equal(decideAction(config, 'ios', 5), 'store');
  assert.equal(decideAction(config, 'ios', 3), 'feedback');
  config.storeMinStars = 3;
  assert.equal(decideAction(config, 'android', 3), 'store');
  // No store to send to.
  assert.equal(decideAction(config, 'other', 5), 'feedback');
  // native_only never gates on stars.
  config.flow.android = 'native_only';
  assert.equal(decideAction(config, 'android', 1), 'store');
});

test('parseClientInfo coerces unknown device facts instead of failing', () => {
  assert.deepEqual(parseClientInfo({ platform: 'iOS', appVersion: ' 1.2.0+14 ', locale: 'fr_FR' }), {
    platform: 'ios',
    appVersion: '1.2.0+14',
    locale: 'fr',
  });
  assert.deepEqual(parseClientInfo({ platform: 'windows', locale: 'de' }), {
    platform: 'other',
    appVersion: null,
    locale: 'en',
  });
  assert.equal(parseClientInfo({ appVersion: 'x'.repeat(50) }).appVersion.length, 32);
});

test('parseRateInput checks stars and trigger', () => {
  assert.equal(parseRateInput({ stars: 0, trigger: 'win' }).error, 'invalid_value');
  assert.equal(parseRateInput({ stars: 6, trigger: 'win' }).error, 'invalid_value');
  assert.equal(parseRateInput({ stars: '5', trigger: 'win' }).error, 'invalid_value');
  assert.equal(parseRateInput({ stars: 5, trigger: 'boom' }).error, 'invalid_value');
  assert.equal(parseRateInput(null).error, 'invalid_value');
  assert.deepEqual(parseRateInput({ stars: 2, trigger: 'daily', platform: 'android', locale: 'ar' }), {
    stars: 2,
    trigger: 'daily',
    platform: 'android',
    appVersion: null,
    locale: 'ar',
  });
});

test('parseFeedbackInput keeps known tags and a clean, capped comment', () => {
  assert.deepEqual(parseFeedbackInput({ tags: ['ads', 'nope', 'bugs'], comment: '  Too many ads\u0007 ' }), {
    tags: ['bugs', 'ads'],
    comment: 'Too many ads',
  });
  assert.deepEqual(parseFeedbackInput({ tags: ['bots'] }), { tags: ['bots'], comment: null });
  assert.equal(parseFeedbackInput({ comment: 'x'.repeat(2000) }).comment.length, 1000);
  assert.equal(parseFeedbackInput({ tags: [], comment: '   ' }).error, 'invalid_value');
});

test('inSendWindow handles plain and midnight-wrapping windows', () => {
  const at = (hour) => Date.UTC(2026, 9, 25, hour, 30);
  assert.equal(inSendWindow([16, 20], at(16)), true);
  assert.equal(inSendWindow([16, 20], at(19)), true);
  assert.equal(inSendWindow([16, 20], at(20)), false);
  assert.equal(inSendWindow([22, 2], at(23)), true);
  assert.equal(inSendWindow([22, 2], at(1)), true);
  assert.equal(inSendWindow([22, 2], at(12)), false);
  assert.equal(inSendWindow([5, 5], at(12)), true);
});

test('pushCopyFor falls back to English for a missing language', () => {
  const push = { title: { en: 'Hi', fr: 'Salut' }, body: { en: 'Body' } };
  assert.deepEqual(pushCopyFor(push, 'fr'), { title: 'Salut', body: 'Body' });
  assert.deepEqual(pushCopyFor(push, 'ar'), { title: 'Hi', body: 'Body' });
});

function pushDeps(candidates) {
  const calls = { selected: 0, marked: [], sent: [] };
  return {
    calls,
    selectCandidates: async (_config, _now, limit) => {
      calls.selected += 1;
      calls.limit = limit;
      return candidates;
    },
    markPushSent: async (ids) => {
      calls.marked.push(...ids);
    },
    sendToPlayers: async (ids, opts) => {
      calls.sent.push({ ids, opts });
      return { successCount: ids.length };
    },
  };
}

test('runPushTick does nothing while the push is off or outside the window', async () => {
  const deps = pushDeps([{ playerId: 'a', locale: 'en' }]);
  assert.deepEqual(await runPushTick({ config: draft(), nowMs: NOW, ...deps }), {
    sent: 0,
    skipped: 'disabled',
  });
  const config = draft();
  config.push.enabled = true;
  const noon = Date.UTC(2026, 9, 25, 12);
  assert.deepEqual(await runPushTick({ config, nowMs: noon, ...deps }), {
    sent: 0,
    skipped: 'outside_window',
  });
  assert.equal(deps.calls.selected, 0);
});

test('runPushTick marks players first and sends once per language', async () => {
  const config = draft();
  config.push.enabled = true;
  config.push.perTickLimit = 50;
  const deps = pushDeps([
    { playerId: 'a', locale: 'fr' },
    { playerId: 'b', locale: 'en' },
    { playerId: 'c', locale: 'fr' },
    { playerId: 'd', locale: null },
  ]);
  const result = await runPushTick({ config, nowMs: NOW, ...deps });
  assert.deepEqual(result, { sent: 4 });
  assert.equal(deps.calls.limit, 50);
  assert.deepEqual(deps.calls.marked, ['a', 'b', 'c', 'd']);
  const byTitle = Object.fromEntries(deps.calls.sent.map(({ ids, opts }) => [opts.title, ids]));
  assert.deepEqual(byTitle[DEFAULTS.push.title.fr], ['a', 'c']);
  assert.deepEqual(byTitle[DEFAULTS.push.title.en], ['b', 'd']);
  for (const { opts } of deps.calls.sent) {
    assert.equal(opts.category, 'marketing');
    assert.equal(opts.data.route, '/rate');
    assert.equal(opts.data.campaignId, 'app_review_auto');
  }
});
