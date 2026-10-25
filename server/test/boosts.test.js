const test = require('node:test');
const assert = require('node:assert/strict');
const { activeBoostFromRow, activationDecision, boostView, seatBoost } = require('../boosts');
const { DEFAULTS } = require('../daily_rewards');

const PRESETS = DEFAULTS.boosters.coin_boost.presets;
const NOW = Date.parse('2026-10-24T12:00:00Z');
const MIN = 60_000;

const silver = {
  presetId: 'standard',
  percent: 25,
  maxBonus: 2000,
  tier: 'silver',
  fromMs: NOW - 30 * MIN,
  untilMs: NOW + 30 * MIN,
};

test('a boost starts when nothing runs or the running one has ended', () => {
  assert.deepEqual(activationDecision(null, { percent: 50, minutes: 60 }, NOW), {
    action: 'start',
    untilMs: NOW + 60 * MIN,
  });
  const ended = { ...silver, untilMs: NOW - 1 };
  assert.deepEqual(activationDecision(ended, { percent: 50, minutes: 60 }, NOW), {
    action: 'start',
    untilMs: NOW + 60 * MIN,
  });
});

test('the same value adds its time to the running boost', () => {
  assert.deepEqual(activationDecision(silver, { percent: 25, minutes: 60 }, NOW), {
    action: 'extend',
    untilMs: NOW + 90 * MIN,
  });
});

test('a different value is refused while another boost runs', () => {
  const decision = activationDecision(silver, { percent: 50, minutes: 60 }, NOW);
  assert.equal(decision.action, 'conflict');
  assert.equal(decision.active.percent, 25);
});

test('a running row without a percent is a legacy boost at the first preset', () => {
  const legacy = activeBoostFromRow({ active_until_ms: NOW + MIN, percent: null }, PRESETS, NOW);
  assert.deepEqual(legacy, {
    presetId: 'standard',
    percent: 25,
    maxBonus: 2000,
    tier: 'silver',
    fromMs: null,
    untilMs: NOW + MIN,
  });
  assert.equal(activeBoostFromRow({ active_until_ms: NOW - 1, percent: 25 }, PRESETS, NOW), null);
  assert.equal(activeBoostFromRow(undefined, PRESETS, NOW), null);
});

test('a running row keeps the value it was activated with, not the preset as edited since', () => {
  const row = { active_until_ms: NOW + MIN, preset_id: 'gold', percent: 40, max_bonus: 3000 };
  const active = activeBoostFromRow(row, PRESETS, NOW);
  assert.equal(active.percent, 40);
  assert.equal(active.maxBonus, 3000);
  assert.equal(active.tier, 'gold');
  assert.deepEqual(seatBoost(active), { presetId: 'gold', percent: 40, maxBonus: 3000, tier: 'gold' });
  assert.equal(seatBoost(null), null);
});

test('boostView groups items by value, strongest first, and marks the blocked ones', () => {
  const items = [
    { id: 'a', preset_id: 'standard', percent: 25, max_bonus: 2000, minutes: 60 },
    { id: 'b', preset_id: 'gold', percent: 50, max_bonus: 5000, minutes: 30 },
    { id: 'c', preset_id: 'standard', percent: 25, max_bonus: 2000, minutes: 240 },
    { id: 'd', preset_id: 'removed', percent: 10, max_bonus: 100, minutes: 15 },
  ];
  const view = boostView({ active: silver, items, presets: PRESETS, nowMs: NOW });
  assert.equal(view.active.remainingSeconds, 30 * 60);
  assert.equal(view.active.totalSeconds, 60 * 60);
  assert.equal(view.active.name.en, 'Coin Boost');
  assert.deepEqual(
    view.inventory.map((group) => [group.percent, group.blocked, group.items.map((item) => item.id)]),
    [
      [50, true, ['b']],
      [25, false, ['a', 'c']],
      [10, true, ['d']],
    ],
  );
  // A preset the admin removed still shows, under a generic name.
  assert.equal(view.inventory[2].name.en, 'Coin Boost');
  assert.equal(view.presets.length, PRESETS.length);

  const idle = boostView({ active: null, items, presets: PRESETS, nowMs: NOW });
  assert.equal(idle.active, null);
  assert.ok(idle.inventory.every((group) => !group.blocked));
});
