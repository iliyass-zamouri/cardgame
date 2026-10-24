const test = require('node:test');
const assert = require('node:assert/strict');
const {
  DEFAULTS,
  LIMITS,
  localDateOf,
  resolveOffset,
  computeStreakState,
  planClaim,
  applyClaim,
  pickCalendar,
  rollChest,
  computeBoostBonus,
  comebackStatus,
  buildDailyStatus,
  selectReminderRecipients,
  planRestore,
  parseSupportAction,
  validateConfig,
  normalizeConfig,
  createDailyRewardsStore,
} = require('../daily_rewards');
const { shapeDailyStats } = require('../db/daily_rewards_admin');

const DAY_MS = 86_400_000;
const at = (iso) => Date.parse(iso);

const catalog = {
  avatarIds: new Set(['default', 'blue', 'queen-of-heart']),
  deckIds: new Set(['default', 'neon_nights', 'gilded_gold']),
};

/** A deep copy of the defaults with one section replaced. */
function withConfig(overrides) {
  return { ...structuredClone(DEFAULTS), ...overrides };
}

function validOrThrow(input) {
  const { config, message } = validateConfig(input, { catalog });
  if (!config) throw new Error(message);
  return config;
}

// ---------------------------------------------------------------- time and offsets

test('localDateOf applies the player offset to the server clock', () => {
  assert.equal(localDateOf(at('2026-10-23T23:30:00Z'), 0), '2026-10-23');
  // Morocco in winter is UTC+1, so 23:30 UTC is already the 24th.
  assert.equal(localDateOf(at('2026-10-23T23:30:00Z'), 60), '2026-10-24');
  // Los Angeles is UTC-7 in October, so the same instant is still the 23rd.
  assert.equal(localDateOf(at('2026-10-23T23:30:00Z'), -420), '2026-10-23');
});

test('resolveOffset takes the first value and small DST-sized moves at once', () => {
  const nowMs = at('2026-10-23T10:00:00Z');
  assert.deepEqual(resolveOffset({ requested: 60, stored: null, changedAtMs: null, nowMs }), {
    value: 60,
    changedAtMs: nowMs,
  });
  assert.equal(resolveOffset({ requested: 0, stored: 60, changedAtMs: null, nowMs }).value, 0);
  assert.equal(resolveOffset({ requested: null, stored: 60, changedAtMs: null, nowMs }).value, 60);
});

test('resolveOffset locks a travel-sized jump to once per week', () => {
  const nowMs = at('2026-10-23T10:00:00Z');
  const jumped = resolveOffset({ requested: -300, stored: 60, changedAtMs: null, nowMs });
  assert.deepEqual(jumped, { value: -300, changedAtMs: nowMs });

  const locked = resolveOffset({
    requested: 120,
    stored: -300,
    changedAtMs: nowMs - DAY_MS,
    nowMs,
  });
  assert.equal(locked.value, -300, 'a second jump within a week is refused');

  const later = resolveOffset({
    requested: 120,
    stored: -300,
    changedAtMs: nowMs - 8 * DAY_MS,
    nowMs,
  });
  assert.equal(later.value, 120, 'after a week the jump is accepted again');
});

test('resolveOffset clamps out-of-range offsets', () => {
  const nowMs = at('2026-10-23T10:00:00Z');
  assert.equal(resolveOffset({ requested: 5000, stored: null, changedAtMs: null, nowMs }).value, 840);
  assert.equal(resolveOffset({ requested: -5000, stored: null, changedAtMs: null, nowMs }).value, -720);
});

// ---------------------------------------------------------------- streak state machine

const lastAt = (iso) => at(iso);

test('a new player can claim day 1', () => {
  const streak = computeStreakState({}, at('2026-10-23T10:00:00Z'), 0, DEFAULTS);
  assert.equal(streak.state, 'claimable');
  assert.equal(streak.nextDay, 1);
  assert.equal(streak.resets, false);
  assert.equal(planClaim(streak).plan.nextDay, 1);
});

test('a second claim on the same local day waits for the next local midnight', () => {
  const streak = computeStreakState(
    { position: 1, count: 1, best: 1, lastDate: '2026-10-23', lastAtMs: lastAt('2026-10-23T08:00:00Z') },
    at('2026-10-23T12:00:00Z'),
    0,
    DEFAULTS,
  );
  assert.equal(streak.state, 'claimed');
  assert.equal(streak.nextClaimAtMs, at('2026-10-24T00:00:00Z'));
  assert.equal(planClaim(streak).error, 'already_claimed');
});

test('the minimum gap holds a claim even after local midnight', () => {
  // Claimed at 23:00 local, checked at 02:00 the next day. Six hours has not passed.
  const streak = computeStreakState(
    { position: 1, count: 1, best: 1, lastDate: '2026-10-23', lastAtMs: lastAt('2026-10-23T23:00:00Z') },
    at('2026-10-24T02:00:00Z'),
    0,
    DEFAULTS,
  );
  assert.equal(streak.state, 'claimed');
  assert.equal(streak.nextClaimAtMs, at('2026-10-24T05:00:00Z'));
});

test('a consecutive day continues the cycle with no grace used', () => {
  const streak = computeStreakState(
    { position: 3, count: 3, best: 3, lastDate: '2026-10-22', lastAtMs: lastAt('2026-10-22T09:00:00Z') },
    at('2026-10-23T09:30:00Z'),
    0,
    DEFAULTS,
  );
  assert.equal(streak.state, 'claimable');
  assert.equal(streak.nextDay, 4);
  assert.equal(streak.missedDays, 0);
  assert.equal(planClaim(streak).plan.continues, true);
});

test('one missed day is forgiven by grace and the streak continues', () => {
  const streak = computeStreakState(
    { position: 3, count: 3, best: 3, lastDate: '2026-10-22', lastAtMs: lastAt('2026-10-22T09:00:00Z') },
    at('2026-10-24T10:00:00Z'),
    0,
    DEFAULTS,
  );
  assert.equal(streak.state, 'claimable');
  assert.equal(streak.missedDays, 1);
  assert.equal(streak.graceUsed, 1);
  assert.equal(streak.nextDay, 4);
  assert.equal(planClaim(streak).plan.continues, true);
});

test('a freeze covers a missed day beyond grace and is spent on claim', () => {
  const streak = computeStreakState(
    {
      position: 3,
      count: 3,
      best: 3,
      lastDate: '2026-10-21',
      lastAtMs: lastAt('2026-10-21T09:00:00Z'),
      freezes: 1,
    },
    at('2026-10-24T10:00:00Z'),
    0,
    DEFAULTS,
  );
  assert.equal(streak.state, 'claimable');
  assert.equal(streak.freezesUsed, 1);
  assert.equal(planClaim(streak).plan.continues, true);
});

test('missing beyond grace without freezes breaks the streak and offers a rescue', () => {
  const streak = computeStreakState(
    { position: 3, count: 3, best: 3, lastDate: '2026-10-21', lastAtMs: lastAt('2026-10-21T09:00:00Z') },
    at('2026-10-24T10:00:00Z'),
    0,
    DEFAULTS,
  );
  assert.equal(streak.state, 'broken');
  assert.equal(streak.rescue.available, true);
  assert.equal(streak.rescue.lastDate, '2026-10-26');

  assert.equal(planClaim(streak).error, 'streak_broken');
  assert.equal(planClaim(streak).details.rescue.chipCost, DEFAULTS.rescue.chipCost);

  const rescued = planClaim(streak, 'rescue').plan;
  assert.equal(rescued.continues, true);
  assert.equal(rescued.nextDay, 4);
  assert.equal(rescued.chipCost, DEFAULTS.rescue.chipCost);
  assert.equal(rescued.rescued, true);

  const restarted = planClaim(streak, 'restart').plan;
  assert.equal(restarted.continues, false);
  assert.equal(restarted.nextDay, 1);
  assert.equal(restarted.chipCost, 0);

  assert.equal(planClaim(streak, 'maybe').error, 'invalid_choice');
});

test('a long absence resets the streak to day 1 automatically', () => {
  const streak = computeStreakState(
    { position: 5, count: 9, best: 9, lastDate: '2026-10-10', lastAtMs: lastAt('2026-10-10T09:00:00Z') },
    at('2026-10-23T10:00:00Z'),
    0,
    DEFAULTS,
  );
  assert.equal(streak.state, 'claimable');
  assert.equal(streak.resets, true);
  assert.equal(streak.nextDay, 1);
  const plan = planClaim(streak).plan;
  assert.equal(plan.continues, false);
  assert.equal(applyClaim(streak, plan).count, 1);
});

test('with rescue disabled a missed streak resets instead of breaking', () => {
  const config = withConfig({ rescue: { ...DEFAULTS.rescue, enabled: false } });
  const streak = computeStreakState(
    { position: 3, count: 3, best: 3, lastDate: '2026-10-21', lastAtMs: lastAt('2026-10-21T09:00:00Z') },
    at('2026-10-24T10:00:00Z'),
    0,
    config,
  );
  assert.equal(streak.state, 'claimable');
  assert.equal(streak.resets, true);
});

test('applyClaim counts cycles on the wrap from day 7 to day 1', () => {
  const streak = computeStreakState(
    { position: 7, count: 7, best: 7, cycles: 2, lastDate: '2026-10-22', lastAtMs: lastAt('2026-10-22T09:00:00Z') },
    at('2026-10-23T09:00:00Z'),
    0,
    DEFAULTS,
  );
  assert.equal(streak.nextDay, 1);
  assert.deepEqual(applyClaim(streak, planClaim(streak).plan), {
    position: 1,
    count: 8,
    best: 8,
    cycles: 3,
  });
});

test('a restart after a broken streak does not count as a completed cycle', () => {
  const streak = computeStreakState(
    { position: 7, count: 7, best: 7, cycles: 2, lastDate: '2026-10-19', lastAtMs: lastAt('2026-10-19T09:00:00Z') },
    at('2026-10-23T09:00:00Z'),
    0,
    DEFAULTS,
  );
  const result = applyClaim(streak, planClaim(streak, 'restart').plan);
  assert.deepEqual(result, { position: 1, count: 1, best: 7, cycles: 2 });
});

// ---------------------------------------------------------------- calendars, chests, boosts

test('an event calendar takes over while its dates are current, inclusive at both ends', () => {
  const config = validOrThrow(
    withConfig({
      events: [
        {
          id: 'ramadan',
          title: { en: 'Ramadan' },
          startsAt: '2027-02-18',
          endsAt: '2027-03-19',
          days: DEFAULTS.calendar.days,
        },
      ],
    }),
  );
  assert.equal(pickCalendar(config, '2027-02-18').id, 'ramadan');
  assert.equal(pickCalendar(config, '2027-03-19').id, 'ramadan');
  assert.equal(pickCalendar(config, '2027-03-20').id, 'default');
  assert.equal(pickCalendar(config, '2027-02-17').id, 'default');
});

test('rollChest picks by weight using the injected random source', () => {
  const chest = DEFAULTS.chests.royal;
  const pick = (roll) => rollChest(chest, () => roll);
  assert.equal(pick(0).index, 0);
  assert.equal(pick(59).index, 0);
  assert.equal(pick(60).index, 1);
  assert.equal(pick(84).index, 1);
  assert.equal(pick(85).index, 2);
  assert.equal(pick(99).index, 4);
});

test('computeBoostBonus takes a share of the profit and respects the cap', () => {
  assert.equal(computeBoostBonus({ pot: 2000, ownStake: 1000, percent: 25, maxBonus: 2000 }), 250);
  assert.equal(computeBoostBonus({ pot: 2000, ownStake: 1000, percent: 25, maxBonus: 100 }), 100);
  assert.equal(computeBoostBonus({ pot: 1000, ownStake: 1000, percent: 25, maxBonus: 100 }), 0);
});

test('comeback is offered after the absence and then respects its cooldown', () => {
  const nowMs = at('2026-10-23T10:00:00Z');
  const fresh = { createdAtMs: nowMs - 10 * DAY_MS };
  assert.equal(comebackStatus(fresh, nowMs, DEFAULTS).available, true);

  const recent = { lastAtMs: nowMs - 3 * DAY_MS };
  assert.equal(comebackStatus(recent, nowMs, DEFAULTS).available, false);

  const cooling = { lastAtMs: nowMs - 10 * DAY_MS, lastComebackAtMs: nowMs - 10 * DAY_MS };
  assert.equal(comebackStatus(cooling, nowMs, DEFAULTS).available, false);

  const off = withConfig({ comeback: { ...DEFAULTS.comeback, enabled: false } });
  assert.equal(comebackStatus(fresh, nowMs, off).available, false);
});

// ---------------------------------------------------------------- payload

test('buildDailyStatus marks the days of a claimed streak as claimed and next', () => {
  const nowMs = at('2026-10-23T12:00:00Z');
  const streak = computeStreakState(
    { position: 3, count: 3, best: 3, lastDate: '2026-10-23', lastAtMs: lastAt('2026-10-23T08:00:00Z') },
    nowMs,
    0,
    DEFAULTS,
  );
  const body = buildDailyStatus({
    streak,
    calendar: { id: 'default', title: null, endsAt: null, days: DEFAULTS.calendar.days },
    config: DEFAULTS,
    nowMs,
    offsetMinutes: 0,
    coinBoostUntilMs: nowMs + 90_000,
    comeback: comebackStatus({ lastAtMs: nowMs }, nowMs, DEFAULTS),
  });
  assert.equal(body.state, 'claimed');
  assert.deepEqual(
    body.days.map((day) => day.status),
    ['claimed', 'claimed', 'claimed', 'next', 'upcoming', 'upcoming', 'upcoming'],
  );
  assert.equal(body.secondsUntilNextClaim, 12 * 3600);
  assert.equal(body.coinBoost.remainingSeconds, 90);
  // Day 7 holds the Royal Chest, so the app gets its title and odds.
  assert.deepEqual(Object.keys(body.chests), ['royal']);
  assert.equal(body.chests.royal.title.fr, 'Coffre royal');
  assert.equal(body.chests.royal.pool.length, DEFAULTS.chests.royal.pool.length);
});

test('buildDailyStatus marks today on a claimable streak', () => {
  const nowMs = at('2026-10-23T12:00:00Z');
  const streak = computeStreakState(
    { position: 3, count: 3, best: 3, lastDate: '2026-10-22', lastAtMs: lastAt('2026-10-22T09:00:00Z') },
    nowMs,
    0,
    DEFAULTS,
  );
  const body = buildDailyStatus({
    streak,
    calendar: { id: 'default', title: null, endsAt: null, days: DEFAULTS.calendar.days },
    config: DEFAULTS,
    nowMs,
    offsetMinutes: 0,
    coinBoostUntilMs: 0,
    comeback: comebackStatus({}, nowMs, DEFAULTS),
  });
  assert.deepEqual(
    body.days.map((day) => day.status),
    ['claimed', 'claimed', 'claimed', 'today', 'upcoming', 'upcoming', 'upcoming'],
  );
  assert.equal(body.secondsUntilNextClaim, 0);
});

// ---------------------------------------------------------------- reminders

test('reminders go out once a day at the right local hour and skip players who already claimed', () => {
  const rows = [
    { playerId: 'eager', tzOffsetMinutes: 0, lastClaimLocalDate: null, lastReminderDate: null, streakCount: 0 },
    { playerId: 'streaky', tzOffsetMinutes: 0, lastClaimLocalDate: null, lastReminderDate: null, streakCount: 5 },
    { playerId: 'claimed', tzOffsetMinutes: 0, lastClaimLocalDate: '2026-10-23', lastReminderDate: null, streakCount: 0 },
    { playerId: 'reminded', tzOffsetMinutes: 0, lastClaimLocalDate: null, lastReminderDate: '2026-10-23', streakCount: 0 },
    { playerId: 'morocco', tzOffsetMinutes: 60, lastClaimLocalDate: null, lastReminderDate: null, streakCount: 0 },
  ];
  const kinds = (nowIso) =>
    selectReminderRecipients(rows, at(nowIso), DEFAULTS).map((entry) => [entry.playerId, entry.kind]);

  // 19:00 UTC is 19:00 local for the UTC players, and 20:00 in Morocco.
  assert.deepEqual(kinds('2026-10-23T19:00:00Z'), [['eager', 'reminder']]);
  // 18:00 UTC is 19:00 in Morocco.
  assert.deepEqual(kinds('2026-10-23T18:00:00Z'), [['morocco', 'reminder']]);
  // A player on a streak of 3 or more hears from us at the at-risk hour instead.
  assert.deepEqual(kinds('2026-10-23T21:00:00Z'), [['streaky', 'at_risk']]);
});

// ---------------------------------------------------------------- validation

test('the defaults are a valid config under the real catalog', () => {
  assert.equal(validateConfig(DEFAULTS, { catalog }).error, undefined);
  assert.deepEqual(normalizeConfig(null), DEFAULTS);
});

test('validation rejects unknown fields at every level', () => {
  assert.match(validateConfig({ ...structuredClone(DEFAULTS), extra: 1 }).message, /unknown field: extra/);
  const nested = structuredClone(DEFAULTS);
  nested.rescue.bogus = true;
  assert.match(validateConfig(nested).message, /rescue has unknown field: bogus/);
});

test('validation rejects avatars and decks the catalog does not know', () => {
  const config = structuredClone(DEFAULTS);
  config.calendar.days[0].rewards = [
    { type: 'avatar', itemId: 'ghost', fallback: { type: 'money', amount: 100 } },
  ];
  assert.match(validateConfig(config, { catalog }).message, /"ghost" is not a known avatar/);
  // Without a catalog (reads from storage) the same config is structurally fine.
  assert.equal(validateConfig(config).error, undefined);
});

test('validation requires exactly seven days numbered in order', () => {
  const short = structuredClone(DEFAULTS);
  short.calendar.days = short.calendar.days.slice(0, 6);
  assert.match(validateConfig(short).message, /exactly 7 days/);

  const misnumbered = structuredClone(DEFAULTS);
  misnumbered.calendar.days[2].day = 9;
  assert.match(validateConfig(misnumbered).message, /must be numbered 3/);
});

test('validation caps rewards per day and enforces currency bounds', () => {
  const crowded = structuredClone(DEFAULTS);
  crowded.calendar.days[0].rewards = [1, 2, 3, 4].map(() => ({ type: 'chips', amount: 1 }));
  assert.match(validateConfig(crowded).message, /needs 1 to 3 rewards/);

  const rich = structuredClone(DEFAULTS);
  rich.calendar.days[0].rewards = [{ type: 'money', amount: LIMITS.maxMoney + 1 }];
  assert.match(validateConfig(rich).message, /amount must be a whole number/);
});

test('validation rejects a fallback that is not currency, including prototype names', () => {
  const avatarFallback = structuredClone(DEFAULTS);
  avatarFallback.calendar.days[0].rewards = [
    { type: 'avatar', itemId: 'blue', fallback: { type: 'avatar', amount: 1 } },
  ];
  assert.match(validateConfig(avatarFallback, { catalog }).message, /fallback\.type must be money or chips/);

  const protoFallback = structuredClone(DEFAULTS);
  protoFallback.calendar.days[0].rewards = [
    { type: 'deck', itemId: 'neon_nights', fallback: { type: 'toString', amount: 1 } },
  ];
  assert.match(validateConfig(protoFallback, { catalog }).message, /fallback\.type must be money or chips/);
});

test('validation rejects overlapping events and chests that reference missing chests', () => {
  const event = (id, startsAt, endsAt) => ({
    id,
    title: { en: id },
    startsAt,
    endsAt,
    days: DEFAULTS.calendar.days,
  });
  const overlapping = withConfig({
    events: [event('spring', '2027-03-01', '2027-03-10'), event('echo', '2027-03-10', '2027-03-20')],
  });
  assert.match(validateConfig(overlapping).message, /overlap/);

  const missingChest = structuredClone(DEFAULTS);
  missingChest.calendar.days[6].rewards = [{ type: 'chest', chestId: 'nope' }];
  assert.match(validateConfig(missingChest).message, /"nope" is not defined/);
});

test('validation forbids a chest inside a chest pool', () => {
  const nested = structuredClone(DEFAULTS);
  nested.chests.royal.pool[0].reward = { type: 'chest', chestId: 'royal' };
  assert.match(validateConfig(nested).message, /cannot hold another chest/);
});

test('normalizeConfig falls back to the defaults for garbage and logs it', (t) => {
  const logged = t.mock.method(console, 'error', () => {});
  assert.deepEqual(normalizeConfig({ enabled: 'yes' }), DEFAULTS);
  assert.equal(logged.mock.callCount(), 1);
});

// ---------------------------------------------------------------- support tools

test('planRestore refuses a streak that is not broken', () => {
  const nowMs = at('2026-10-23T12:00:00Z');
  const healthy = computeStreakState(
    { position: 3, count: 3, best: 3, lastDate: '2026-10-22', lastAtMs: lastAt('2026-10-22T09:00:00Z') },
    nowMs,
    0,
    DEFAULTS,
  );
  assert.deepEqual(planRestore(healthy, nowMs, 0, DEFAULTS), { error: 'streak_not_broken' });
  const fresh = computeStreakState({}, nowMs, 0, DEFAULTS);
  assert.deepEqual(planRestore(fresh, nowMs, 0, DEFAULTS), { error: 'streak_not_broken' });
});

test('a restored streak continues on the next claim, whatever the gap, timezone or hour', () => {
  const broken = { position: 3, count: 9, best: 12, lastDate: '2026-10-19', lastAtMs: lastAt('2026-10-19T09:00:00Z') };
  const longGone = { position: 3, count: 9, best: 12, lastDate: '2026-10-01', lastAtMs: lastAt('2026-10-01T09:00:00Z') };
  const moments = [
    ['2026-10-23T12:00:00Z', 0],
    ['2026-10-23T23:30:00Z', 0],
    // 00:30 the next day in Morocco.
    ['2026-10-23T23:30:00Z', 60],
    // Late afternoon the day before in Los Angeles.
    ['2026-10-23T00:30:00Z', -420],
  ];
  for (const minClaimGapHours of [0, 6, 24]) {
    const config = withConfig({ minClaimGapHours });
    for (const [nowIso, offset] of moments) {
      for (const input of [broken, longGone]) {
        const label = `gap ${minClaimGapHours}h at ${nowIso} offset ${offset} from ${input.lastDate}`;
        const nowMs = at(nowIso);
        const streak = computeStreakState(input, nowMs, offset, config);
        const restored = planRestore(streak, nowMs, offset, config);
        assert.equal(restored.error, undefined, label);

        const after = computeStreakState({ ...input, ...restored }, nowMs, offset, config);
        assert.equal(after.state, 'claimable', label);
        assert.equal(after.resets, false, label);
        assert.equal(after.nextDay, 4, label);
        assert.equal(applyClaim(after, planClaim(after).plan).count, 10, label);
      }
    }
  }
});

test('parseSupportAction checks the action, its bounds and the QA-only switch', () => {
  assert.deepEqual(parseSupportAction({ playerId: ' p1 ', action: 'restore' }), {
    action: 'restore',
    playerId: 'p1',
  });
  assert.deepEqual(parseSupportAction({ playerId: 'p1', action: 'gift_freeze' }), {
    action: 'gift_freeze',
    playerId: 'p1',
    quantity: 1,
  });
  assert.equal(parseSupportAction({ playerId: 'p1', action: 'gift_freeze', quantity: 9 }).error, 'invalid_value');
  assert.equal(parseSupportAction({ playerId: 'p1', action: 'nuke' }).error, 'invalid_action');
  assert.equal(parseSupportAction({ action: 'restore' }).error, 'invalid_value');
  assert.equal(parseSupportAction(null).error, 'invalid_action');

  assert.equal(parseSupportAction({ playerId: 'p1', action: 'reset' }).error, 'debug_only');
  assert.equal(parseSupportAction({ playerId: 'p1', action: 'shift_days', days: 2 }).error, 'debug_only');
  assert.deepEqual(parseSupportAction({ playerId: 'p1', action: 'shift_days', days: 2 }, { debug: true }), {
    action: 'shift_days',
    playerId: 'p1',
    days: 2,
  });
  assert.equal(
    parseSupportAction({ playerId: 'p1', action: 'shift_days', days: 0 }, { debug: true }).error,
    'invalid_value',
  );
});

test('shapeDailyStats zero-fills the day series, cycle days and streak buckets', () => {
  const today = new Date().toISOString().slice(0, 10);
  const shaped = shapeDailyStats(
    {
      // DECIMAL sums arrive from MySQL as strings.
      totals: { claims: 3, claimers: 2, boosted: '1', rescues: '1', rescueChips: '3', freezesUsed: '0' },
      comebacks: 1,
      byDay: [{ day: today, claims: 3, boosted: '1', rescued: '1' }],
      byCycleDay: [{ day: 2, claims: 3 }],
      streaks: [{ bucket: '3-6', players: 2 }],
      reach: { claimers24h: 2, active24h: 4, claimers7d: 2, active7d: 9 },
    },
    7,
  );
  assert.equal(shaped.byDay.length, 7);
  assert.deepEqual(shaped.byDay.at(-1), { day: today, claims: 3, boosted: 1, rescued: 1 });
  assert.equal(shaped.byDay[0].claims, 0);
  assert.deepEqual(shaped.byCycleDay.map((entry) => entry.claims), [0, 3, 0, 0, 0, 0, 0]);
  assert.deepEqual(shaped.streaks.map((entry) => entry.players), [0, 2, 0, 0, 0]);
  assert.deepEqual(shaped.totals, {
    claims: 3,
    claimers: 2,
    boosted: 1,
    rescues: 1,
    rescueChips: 3,
    freezesUsed: 0,
    comebacks: 1,
  });
});

// ---------------------------------------------------------------- store

test('the store serves defaults until a record is stored, then the stored config', async () => {
  let stored = null;
  const store = createDailyRewardsStore({
    read: async () => stored,
    write: async (config) => {
      stored = config;
    },
    readPrevious: async () => null,
    writePrevious: async () => {},
  });
  assert.equal(store.current().source, 'default');
  await store.refresh();
  assert.equal(store.current().source, 'default');

  const next = withConfig({ graceDays: 2 });
  await store.set(next);
  assert.equal(store.current().graceDays, 2);
  assert.equal(store.current().source, 'admin');
});

test('revert swaps the saved config with the previous one', async () => {
  let current = null;
  let previous = null;
  const store = createDailyRewardsStore({
    read: async () => current,
    write: async (config) => {
      current = config;
    },
    readPrevious: async () => previous,
    writePrevious: async (config) => {
      previous = config;
    },
  });
  const first = withConfig({ graceDays: 1 });
  const second = withConfig({ graceDays: 3 });
  await store.set(first);
  await store.set(second);
  assert.equal(store.current().graceDays, 3);

  await store.revert();
  assert.equal(store.current().graceDays, 1);

  await store.revert();
  assert.equal(store.current().graceDays, 3, 'a second revert undoes the first');
});

test('revert with nothing to restore is refused', async () => {
  const store = createDailyRewardsStore({
    read: async () => null,
    write: async () => {},
    readPrevious: async () => null,
    writePrevious: async () => {},
  });
  await assert.rejects(store.revert(), (error) => error.code === 'no_previous');
});

test('a failing read keeps the last known settings', async (t) => {
  let stored = withConfig({ graceDays: 2 });
  let failing = false;
  const store = createDailyRewardsStore({
    read: async () => {
      if (failing) throw new Error('db down');
      return stored;
    },
    write: async () => {},
    readPrevious: async () => null,
    writePrevious: async () => {},
    onReadError: () => {},
  });
  await store.refresh();
  assert.equal(store.current().graceDays, 2);
  failing = true;
  await store.refresh();
  assert.equal(store.current().graceDays, 2);
});

test('a read that started before a save cannot overwrite the saved config', async () => {
  let stored = withConfig({ graceDays: 1 });
  let calls = 0;
  let releaseFirst;
  const store = createDailyRewardsStore({
    read: () => {
      calls += 1;
      if (calls === 1) {
        // The slow read sees the value from before the save.
        const snapshot = stored;
        return new Promise((resolve) => {
          releaseFirst = () => resolve(snapshot);
        });
      }
      return Promise.resolve(stored);
    },
    write: async (config) => {
      stored = config;
    },
    readPrevious: async () => null,
    writePrevious: async () => {},
  });

  const refreshing = store.refresh();
  await store.set(withConfig({ graceDays: 3 }));
  releaseFirst();
  await refreshing;
  assert.equal(store.current().graceDays, 3);
});
