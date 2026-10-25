// Runs the daily-reward SQL against a real MySQL. Skipped unless
// DAILY_REWARDS_DB_TEST=1 and the MYSQL_* variables point at a scratch database.
// Example:
//   DAILY_REWARDS_DB_TEST=1 MYSQL_HOST=127.0.0.1 MYSQL_PORT=3306 \
//     MYSQL_USER=cardgame MYSQL_PASSWORD=cardgame MYSQL_DATABASE=cardgame \
//     node --test server/test/daily_rewards_db.test.js

const test = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('crypto');
const { DEFAULTS, validateConfig } = require('../daily_rewards');

const skip =
  process.env.DAILY_REWARDS_DB_TEST === '1'
    ? false
    : 'set DAILY_REWARDS_DB_TEST=1 and MYSQL_* to run against MySQL';

const DAY_MS = 86_400_000;
const NOW = Date.parse('2026-10-23T10:00:00Z');

let ready = null;
function connect() {
  ready ??= (async () => {
    const pool = require('../db/pool');
    await pool.initDb();
    return pool;
  })();
  return ready;
}

async function db() {
  return (await connect()).getPool();
}

async function createPlayer({ money = 500, chips = 1, createdAt = null } = {}) {
  const id = `t-${crypto.randomUUID()}`;
  const pool = await db();
  await pool.execute(`INSERT INTO players (id, money, chips) VALUES (:id, :money, :chips)`, {
    id,
    money,
    chips,
  });
  if (createdAt !== null) {
    await pool.execute(`UPDATE players SET created_at = :createdAt WHERE id = :id`, {
      id,
      createdAt: new Date(createdAt),
    });
  }
  return id;
}

/** A streak that was last claimed on `lastDate`, as if the player had been playing. */
async function seedStreak(playerId, { position, count, lastDate, lastAtMs, freezes = 0 }) {
  const pool = await db();
  await pool.execute(
    `INSERT INTO daily_reward_state
       (player_id, streak_position, streak_count, best_streak, last_claim_local_date, last_claim_at_ms)
     VALUES (:playerId, :position, :count, :count, :lastDate, :lastAtMs)`,
    { playerId, position, count, lastDate, lastAtMs },
  );
  if (freezes > 0) {
    await pool.execute(
      `INSERT INTO player_boosters (player_id, booster_id, quantity, active_until_ms)
       VALUES (:playerId, 'streak_freeze', :freezes, 0)`,
      { playerId, freezes },
    );
  }
}

async function balances(playerId) {
  const [rows] = await (await db()).execute(`SELECT money, chips FROM players WHERE id = :playerId`, {
    playerId,
  });
  return { money: Number(rows[0].money), chips: Number(rows[0].chips) };
}

async function freezeCount(playerId) {
  const [rows] = await (await db()).execute(
    `SELECT quantity FROM player_boosters WHERE player_id = :playerId AND booster_id = 'streak_freeze'`,
    { playerId },
  );
  return Number(rows[0]?.quantity) || 0;
}

async function streakRow(playerId) {
  const [rows] = await (await db()).execute(
    `SELECT * FROM daily_reward_state WHERE player_id = :playerId`,
    { playerId },
  );
  return rows[0] ?? null;
}

function withDayOne(reward) {
  const days = structuredClone(DEFAULTS.calendar.days);
  days[0] = { day: 1, rewards: [reward] };
  const { config, message } = validateConfig(
    { ...structuredClone(DEFAULTS), calendar: { id: 'default', days } },
    { catalog: require('../db/daily_rewards').rewardCatalog() },
  );
  if (!config) throw new Error(message);
  return config;
}

async function claim(playerId, overrides = {}) {
  const daily = require('../db/daily_rewards');
  return daily.claimDailyReward({
    playerId,
    nowMs: NOW,
    tzOffsetMinutes: 0,
    config: DEFAULTS,
    ...overrides,
  });
}

test('the first claim pays day 1, saves the offset, and a repeat the same day pays nothing', { skip }, async () => {
  const playerId = await createPlayer({ money: 500, chips: 1 });
  const first = await claim(playerId, { tzOffsetMinutes: 60 });
  assert.equal(first.alreadyClaimed, false);
  assert.equal(first.day, 1);
  assert.equal(first.money, 700);
  assert.deepEqual(await balances(playerId), { money: 700, chips: 1 });
  assert.equal((await streakRow(playerId)).tz_offset_minutes, 60);

  const again = await claim(playerId, { tzOffsetMinutes: 60, nowMs: NOW + 60_000 });
  assert.equal(again.alreadyClaimed, true);
  assert.equal(again.granted.length, 1, 'the stored grant is returned');
  assert.deepEqual(await balances(playerId), { money: 700, chips: 1 });
});

test('two claims that arrive together grant exactly once', { skip }, async () => {
  const playerId = await createPlayer({ money: 500 });
  const results = await Promise.all([claim(playerId), claim(playerId)]);
  assert.equal(results.filter((result) => !result.alreadyClaimed).length, 1);
  assert.deepEqual(await balances(playerId), { money: 700, chips: 1 });
});

test('an app build without the boost inventory still starts a Coin Boost on claim', { skip }, async () => {
  const playerId = await createPlayer();
  await claim(playerId);
  const nextDayMs = NOW + 25 * 3600_000;
  const second = await claim(playerId, { nowMs: nextDayMs });
  assert.equal(second.day, 2);
  const [boost] = second.granted;
  assert.equal(boost.boosterId, 'coin_boost');
  assert.equal(boost.activated, true);
  assert.equal(boost.activeUntilMs, nextDayMs + 60 * 60_000);
  assert.equal(second.status.coinBoost.remainingSeconds, 3600);
  assert.equal(second.streak.count, 2);
});

test('with the boost inventory a claimed Coin Boost waits until the player activates it', { skip }, async () => {
  const boosts = require('../db/boosts');
  const playerId = await createPlayer();
  await claim(playerId, { boostInventory: true });
  const nextDayMs = NOW + 25 * 3600_000;
  const second = await claim(playerId, { nowMs: nextDayMs, boostInventory: true });
  const [boost] = second.granted;
  assert.equal(boost.activated, false);
  assert.equal(boost.percent, 25);
  assert.ok(boost.itemId);
  assert.equal(second.status.coinBoost.remainingSeconds, 0);

  const view = await boosts.getBoosts({ playerId, nowMs: nextDayMs, config: DEFAULTS });
  assert.equal(view.active, null);
  assert.deepEqual(view.inventory.map((group) => group.items.map((item) => item.id)), [[boost.itemId]]);

  const activated = await boosts.activateBoost({ playerId, itemId: boost.itemId, nowMs: nextDayMs, config: DEFAULTS });
  assert.equal(activated.action, 'start');
  assert.equal(activated.boosts.active.remainingSeconds, 3600);
  assert.deepEqual(activated.boosts.inventory, []);

  await assert.rejects(
    boosts.activateBoost({ playerId, itemId: boost.itemId, nowMs: nextDayMs, config: DEFAULTS }),
    { code: 'boost_not_found' },
  );
});

test('an ad boost doubles currency and leaves booster durations alone', { skip }, async () => {
  const playerId = await createPlayer({ money: 500 });
  const boosted = await claim(playerId, { boosted: true });
  assert.equal(boosted.boosted, true);
  assert.deepEqual(await balances(playerId), { money: 900, chips: 1 });
});

test('a rescue charges chips in the same transaction, and fails cleanly without them', { skip }, async () => {
  const lastAtMs = Date.parse('2026-10-20T09:00:00Z');
  const poor = await createPlayer({ money: 500, chips: 2 });
  await seedStreak(poor, { position: 3, count: 3, lastDate: '2026-10-20', lastAtMs });

  await assert.rejects(claim(poor, { choice: null }), (error) => error.code === 'streak_broken');
  await assert.rejects(claim(poor, { choice: 'rescue' }), (error) => error.code === 'insufficient_funds');
  assert.deepEqual(await balances(poor), { money: 500, chips: 2 });
  assert.equal((await streakRow(poor)).streak_position, 3, 'a refused rescue changes nothing');

  const rich = await createPlayer({ money: 500, chips: 5 });
  await seedStreak(rich, { position: 3, count: 3, lastDate: '2026-10-20', lastAtMs });
  const rescued = await claim(rich, { choice: 'rescue' });
  assert.equal(rescued.rescued, true);
  assert.equal(rescued.chipsSpent, 3);
  assert.equal(rescued.day, 4);
  assert.equal(rescued.streak.count, 4, 'the rescue keeps the streak going');
  // Day 4 pays 400 coins and a Streak Freeze.
  assert.deepEqual(await balances(rich), { money: 900, chips: 2 });
  assert.equal(await freezeCount(rich), 1);
});

test('restarting after a broken streak pays day 1 and keeps the best streak', { skip }, async () => {
  const playerId = await createPlayer({ money: 500 });
  await seedStreak(playerId, {
    position: 3,
    count: 3,
    lastDate: '2026-10-20',
    lastAtMs: Date.parse('2026-10-20T09:00:00Z'),
  });
  const restarted = await claim(playerId, { choice: 'restart' });
  assert.equal(restarted.day, 1);
  assert.equal(restarted.streakReset, true);
  assert.deepEqual(restarted.streak, { count: 1, best: 3, position: 1, cycle: 0 });
  assert.deepEqual(await balances(playerId), { money: 700, chips: 1 });
});

test('a streak freeze covers a gap beyond grace and is spent on the claim', { skip }, async () => {
  const playerId = await createPlayer({ money: 500 });
  await seedStreak(playerId, {
    position: 3,
    count: 3,
    lastDate: '2026-10-20',
    lastAtMs: Date.parse('2026-10-20T09:00:00Z'),
    freezes: 1,
  });
  const result = await claim(playerId);
  assert.equal(result.freezesUsed, 1);
  assert.equal(result.streak.count, 4);
  // One freeze is spent, then day 4 grants a new one: 1 - 1 + 1.
  assert.equal(await freezeCount(playerId), 1);
});

test('a duplicate avatar converts to its coin fallback, and a new one is owned', { skip }, async () => {
  const config = withDayOne({
    type: 'avatar',
    itemId: 'blue',
    fallback: { type: 'money', amount: 150 },
  });

  const owner = await createPlayer({ money: 500 });
  await (await db()).execute(
    `INSERT INTO player_items (id, player_id, item_type, item_id) VALUES (:id, :playerId, 'avatar', 'blue')`,
    { id: `seed-${crypto.randomUUID()}`, playerId: owner },
  );
  const duplicate = await claim(owner, { config });
  assert.equal(duplicate.granted[0].duplicate, true);
  assert.deepEqual(await balances(owner), { money: 650, chips: 1 });

  const fresh = await createPlayer({ money: 500 });
  const granted = await claim(fresh, { config });
  assert.equal(granted.granted[0].granted, true);
  assert.ok(granted.ownedAvatars.includes('blue'));
  assert.deepEqual(await balances(fresh), { money: 500, chips: 1 });
});

test('a chest rolls on the server and grants the loot it picked', { skip }, async () => {
  const days = structuredClone(DEFAULTS.calendar.days);
  days[0] = { day: 1, rewards: [{ type: 'chest', chestId: 'royal' }] };
  const chests = {
    royal: { title: { en: 'Royal' }, pool: [{ weight: 1, reward: { type: 'money', amount: 777 } }] },
  };
  const { config, message } = validateConfig(
    { ...structuredClone(DEFAULTS), calendar: { id: 'default', days }, chests },
    { catalog: require('../db/daily_rewards').rewardCatalog() },
  );
  if (!config) throw new Error(message);

  const playerId = await createPlayer({ money: 500 });
  const result = await claim(playerId, { config });
  assert.equal(result.granted[0].type, 'chest');
  assert.equal(result.granted[0].loot.amount, 777);
  assert.deepEqual(await balances(playerId), { money: 1277, chips: 1 });
});

test('the welcome-back bonus pays once and then waits out its cooldown', { skip }, async () => {
  const daily = require('../db/daily_rewards');
  const playerId = await createPlayer({ money: 500, createdAt: NOW - 10 * DAY_MS });

  const first = await daily.claimComeback({ playerId, nowMs: NOW, tzOffsetMinutes: 0, config: DEFAULTS });
  assert.equal(first.money, 1000);
  assert.equal(first.chips, 2);

  await assert.rejects(
    daily.claimComeback({ playerId, nowMs: NOW + DAY_MS, tzOffsetMinutes: 0, config: DEFAULTS }),
    (error) => error.code === 'comeback_unavailable',
  );
});

test('a status read for a new player is claimable and writes nothing', { skip }, async () => {
  const daily = require('../db/daily_rewards');
  const playerId = await createPlayer();
  const status = await daily.getDailyRewardStatus({
    playerId,
    nowMs: NOW,
    tzOffsetMinutes: 0,
    config: DEFAULTS,
  });
  assert.equal(status.state, 'claimable');
  assert.equal(status.days[0].status, 'today');
  assert.equal(await streakRow(playerId), null);
});

test('the player routes need a token, map refusals to status codes, and pay once', { skip }, async (t) => {
  const { GameServer } = require('../game_server');
  const { testToken } = require('./session_helpers');

  const previousSecret = process.env.ADMIN_PUSH_SECRET;
  process.env.ADMIN_PUSH_SECRET = 'test-admin-secret';
  t.after(() => {
    if (previousSecret === undefined) delete process.env.ADMIN_PUSH_SECRET;
    else process.env.ADMIN_PUSH_SECRET = previousSecret;
  });

  // The server reads the admin's saved table; start from the code defaults.
  await (await db()).execute(
    `DELETE FROM app_settings WHERE setting_key IN ('daily_rewards', 'daily_rewards_prev')`,
  );
  const playerId = await createPlayer({ money: 500 });
  const token = await testToken(playerId, 0);
  const server = new GameServer({ port: 0 });
  const address = await server.start();
  t.after(() => server.stop());
  const base = `http://127.0.0.1:${address.port}`;
  const auth = { authorization: `Bearer ${token}`, 'content-type': 'application/json' };
  const post = (path, body) =>
    fetch(`${base}${path}`, { method: 'POST', headers: auth, body: JSON.stringify(body) });

  assert.equal((await fetch(`${base}/daily-reward`)).status, 401);

  const badChoice = await post('/daily-reward/claim', { streakChoice: 'maybe' });
  assert.equal(badChoice.status, 400);
  assert.equal((await badChoice.json()).error, 'invalid_choice');

  const status = await (await fetch(`${base}/daily-reward?tzOffset=0`, { headers: auth })).json();
  assert.equal(status.state, 'claimable');

  const paid = await post('/daily-reward/claim', { tzOffsetMinutes: 0 });
  assert.equal(paid.status, 200);
  const paidBody = await paid.json();
  assert.equal(paidBody.alreadyClaimed, false);
  assert.equal(paidBody.money, 700);

  const repeat = await post('/daily-reward/claim', { tzOffsetMinutes: 0 });
  assert.equal((await repeat.json()).alreadyClaimed, true);
  assert.deepEqual(await balances(playerId), { money: 700, chips: 1 });

  // A brand-new account has not been away long enough for the welcome-back bonus.
  const comeback = await post('/daily-reward/comeback/claim', {});
  assert.equal(comeback.status, 409);
  assert.equal((await comeback.json()).error, 'comeback_unavailable');

  const boosts = await fetch(`${base}/boosts`, { headers: auth });
  assert.equal(boosts.status, 200);
  const view = await boosts.json();
  assert.equal(view.active, null);
  assert.deepEqual(view.presets.map((preset) => preset.id), ['standard', 'gold']);

  assert.equal((await post('/boosts/activate', {})).status, 400);
  const missing = await post('/boosts/activate', { itemId: 'boost-nope' });
  assert.equal(missing.status, 404);
  assert.equal((await missing.json()).error, 'boost_not_found');
});

// ---------------------------------------------------------------- boost inventory

/** Gifts one boost through the QA action and returns the new item's id. */
async function giftBoost(playerId, presetId, minutes, nowMs = NOW) {
  const admin = require('../db/daily_rewards_admin');
  const { getBoosts } = require('../db/boosts');
  const ids = async () =>
    (await getBoosts({ playerId, nowMs, config: DEFAULTS })).inventory.flatMap((group) => group.items.map((item) => item.id));
  const before = new Set(await ids());
  await admin.applySupportAction({ playerId, action: 'gift_boost', presetId, minutes, nowMs, config: DEFAULTS });
  return (await ids()).find((id) => !before.has(id));
}

test('the same value adds its time, a different value waits for the running boost to end', { skip }, async () => {
  const boosts = require('../db/boosts');
  const playerId = await createPlayer();
  const first = await giftBoost(playerId, 'standard', 60);
  const same = await giftBoost(playerId, 'standard', 30);
  const gold = await giftBoost(playerId, 'gold', 15);

  await boosts.activateBoost({ playerId, itemId: first, nowMs: NOW, config: DEFAULTS });
  const later = NOW + 10 * 60_000;
  const extended = await boosts.activateBoost({ playerId, itemId: same, nowMs: later, config: DEFAULTS });
  assert.equal(extended.action, 'extend');
  // 60 minutes from NOW, plus 30 more, read as one 90-minute run.
  assert.equal(extended.boosts.active.remainingSeconds, 80 * 60);
  assert.equal(extended.boosts.active.totalSeconds, 90 * 60);
  assert.equal(extended.boosts.inventory[0].blocked, true, 'gold is blocked while +25% runs');

  await assert.rejects(boosts.activateBoost({ playerId, itemId: gold, nowMs: later, config: DEFAULTS }), (error) => {
    assert.equal(error.code, 'boost_conflict');
    assert.equal(error.details.boosts.active.percent, 25);
    return true;
  });

  const afterEnd = NOW + 91 * 60_000;
  const started = await boosts.activateBoost({ playerId, itemId: gold, nowMs: afterEnd, config: DEFAULTS });
  assert.equal(started.action, 'start');
  assert.equal(started.boosts.active.percent, 50);
  assert.equal(started.boosts.active.tier, 'gold');
});

test('a boost running from before presets reads as the first preset', { skip }, async () => {
  const boosts = require('../db/boosts');
  const playerId = await createPlayer();
  await giveCoinBoost(playerId, NOW + 3600_000);
  const view = await boosts.getBoosts({ playerId, nowMs: NOW, config: DEFAULTS });
  assert.equal(view.active.presetId, 'standard');
  assert.equal(view.active.percent, 25);
  const seats = await boosts.seatBoostsFor([playerId], { nowMs: NOW, config: DEFAULTS });
  assert.deepEqual(seats[playerId], { presetId: 'standard', percent: 25, maxBonus: 2000, tier: 'silver' });
});

test('activations that arrive together for one item run it once', { skip }, async () => {
  const boosts = require('../db/boosts');
  const playerId = await createPlayer();
  const itemId = await giftBoost(playerId, 'standard', 60);
  const results = await Promise.allSettled([
    boosts.activateBoost({ playerId, itemId, nowMs: NOW, config: DEFAULTS }),
    boosts.activateBoost({ playerId, itemId, nowMs: NOW, config: DEFAULTS }),
  ]);
  assert.equal(results.filter((result) => result.status === 'fulfilled').length, 1);
  const view = await boosts.getBoosts({ playerId, nowMs: NOW, config: DEFAULTS });
  assert.equal(view.active.remainingSeconds, 3600);
});

// ---------------------------------------------------------------- Coin Boost in matches

async function giveCoinBoost(playerId, activeUntilMs) {
  await (await db()).execute(
    `INSERT INTO player_boosters (player_id, booster_id, quantity, active_until_ms)
     VALUES (:playerId, 'coin_boost', 0, :activeUntilMs)`,
    { playerId, activeUntilMs },
  );
}

/** A staked match whose seats carry the boosts that were running at `kickoffMs`. */
async function stakedMatch({ winner, loser, stake, currency = 'money', kickoffMs = NOW }) {
  const ranking = require('../db/ranking');
  const boosts = require('../db/boosts');
  await ranking.escrowStake({ playerIds: [winner, loser], stake, currency });
  const seats = await boosts.seatBoostsFor([winner, loser], { nowMs: kickoffMs, config: DEFAULTS });
  return ranking.recordRankedMatch({
    roomId: `boost-${crypto.randomUUID()}`,
    players: [
      { playerId: winner, cardTotal: 10, boost: currency === 'money' ? seats[winner] ?? null : null },
      { playerId: loser, cardTotal: 30, boost: currency === 'money' ? seats[loser] ?? null : null },
    ],
    winnerIndex: 0,
    stakePerPlayer: stake,
    potAmount: stake * 2,
    stakeCurrency: currency,
    escrowed: true,
  });
}

test('a running Coin Boost tops up the winner\'s money winnings', { skip }, async () => {
  const winner = await createPlayer({ money: 1000 });
  const loser = await createPlayer({ money: 1000 });
  await giveCoinBoost(winner, NOW + 3600_000);
  await giveCoinBoost(loser, NOW + 3600_000);

  const result = await stakedMatch({ winner, loser, stake: 200 });
  // 1000 - 200 stake + 400 pot + 25% of the 200 won.
  assert.deepEqual(await balances(winner), { money: 1250, chips: 1 });
  assert.deepEqual(await balances(loser), { money: 800, chips: 1 }, 'a losing boost pays nothing');
  assert.equal(result.players[0].boostBonus, 50);
  assert.equal(result.players[0].boostPercent, 25);
  assert.equal(result.players[0].moneyAfter, 1250);
  assert.equal(result.players[1].boostBonus, 0);
});

test('Coin Boost respects its cap, its end time and money-only matches', { skip }, async () => {
  const capped = await createPlayer({ money: 1000 });
  const expired = await createPlayer({ money: 1000 });
  const lateEnd = await createPlayer({ money: 1000 });
  const chipsWinner = await createPlayer({ money: 1000, chips: 10 });
  const opponent = await createPlayer({ money: 50_000, chips: 10 });
  await giveCoinBoost(expired, NOW - 1);
  await giveCoinBoost(lateEnd, NOW + 60_000);
  await giveCoinBoost(chipsWinner, NOW + 3600_000);

  // +25% of 10,000 won would be 2,500. The standard preset caps it at 2,000.
  await (await db()).execute(`UPDATE players SET money = 20000 WHERE id = :id`, { id: capped });
  await giveCoinBoost(capped, NOW + 3600_000);
  await stakedMatch({ winner: capped, loser: opponent, stake: 10_000 });
  assert.equal((await balances(capped)).money, 32_000, 'the bonus stops at the cap');

  await stakedMatch({ winner: expired, loser: opponent, stake: 200 });
  assert.equal((await balances(expired)).money, 1200, 'an expired boost pays nothing');

  // Running at kickoff, so it pays even though it ended before the result.
  await stakedMatch({ winner: lateEnd, loser: opponent, stake: 200, kickoffMs: NOW });
  assert.equal((await balances(lateEnd)).money, 1250, 'the boost locked at kickoff pays');

  await stakedMatch({
    winner: chipsWinner,
    loser: opponent,
    stake: 2,
    currency: 'chips',
  });
  assert.deepEqual(await balances(chipsWinner), { money: 1000, chips: 12 }, 'chips matches are unchanged');
});

// ---------------------------------------------------------------- admin tab

const utcDate = (ms) => new Date(ms).toISOString().slice(0, 10);

test('stats count claims, boosts, rescues and comebacks over the window', { skip }, async () => {
  const admin = require('../db/daily_rewards_admin');
  const daily = require('../db/daily_rewards');
  // The day series is anchored on the real date, so these claims use the real clock.
  const nowMs = Date.now();
  const before = await admin.getDailyRewardStats({ nowMs, days: 30 });

  await claim(await createPlayer(), { nowMs });
  await claim(await createPlayer(), { nowMs, boosted: true });
  const rescued = await createPlayer({ chips: 5 });
  await seedStreak(rescued, {
    position: 3,
    count: 3,
    lastDate: utcDate(nowMs - 3 * DAY_MS),
    lastAtMs: nowMs - 3 * DAY_MS,
  });
  await claim(rescued, { nowMs, choice: 'rescue' });
  const returning = await createPlayer({ createdAt: nowMs - 10 * DAY_MS });
  await daily.claimComeback({ playerId: returning, nowMs, tzOffsetMinutes: 0, config: DEFAULTS });

  const after = await admin.getDailyRewardStats({ nowMs, days: 30 });
  const delta = (key) => after.totals[key] - before.totals[key];
  assert.equal(delta('claims'), 3);
  assert.equal(delta('claimers'), 3);
  assert.equal(delta('boosted'), 1);
  assert.equal(delta('rescues'), 1);
  assert.equal(delta('rescueChips'), 3);
  assert.equal(delta('comebacks'), 1);

  assert.equal(after.byDay.length, 30);
  const today = (stats) => stats.byDay.find((entry) => entry.day === utcDate(nowMs));
  assert.equal(today(after).claims - today(before).claims, 3);
  assert.equal(today(after).boosted - today(before).boosted, 1);
  assert.equal(today(after).rescued - today(before).rescued, 1);

  const cycleDay = (stats, day) => stats.byCycleDay[day - 1].claims;
  assert.equal(cycleDay(after, 1) - cycleDay(before, 1), 2);
  assert.equal(cycleDay(after, 4) - cycleDay(before, 4), 1);
  assert.equal(after.reach.claimers24h - before.reach.claimers24h, 3);
});

test('the support lookup shows a broken streak, and restore lets it continue', { skip }, async () => {
  const admin = require('../db/daily_rewards_admin');
  const playerId = await createPlayer({ money: 500 });
  await seedStreak(playerId, {
    position: 3,
    count: 3,
    lastDate: '2026-10-20',
    lastAtMs: Date.parse('2026-10-20T09:00:00Z'),
  });

  const before = await admin.getDailyRewardPlayer({ playerId, nowMs: NOW, config: DEFAULTS });
  assert.equal(before.status.state, 'broken');
  assert.equal(before.streak.count, 3);
  assert.deepEqual(before.support, []);

  const done = await admin.applySupportAction({ playerId, action: 'restore', nowMs: NOW, config: DEFAULTS });
  assert.equal(done.to, '2026-10-22');

  const after = await admin.getDailyRewardPlayer({ playerId, nowMs: NOW, config: DEFAULTS });
  assert.equal(after.status.state, 'claimable');
  assert.equal(after.status.streak.nextDay, 4);
  assert.equal(after.support[0].action, 'restore');

  const claimed = await claim(playerId);
  assert.equal(claimed.day, 4);
  assert.equal(claimed.streak.count, 4);
  assert.equal(claimed.chipsSpent, 0, 'a support restore costs the player nothing');

  await assert.rejects(
    admin.applySupportAction({ playerId, action: 'restore', nowMs: NOW, config: DEFAULTS }),
    (error) => error.code === 'streak_not_broken',
  );
});

test('gifted Streak Freezes add to what the player already has', { skip }, async () => {
  const admin = require('../db/daily_rewards_admin');
  const playerId = await createPlayer();
  await admin.applySupportAction({ playerId, action: 'gift_freeze', quantity: 2, nowMs: NOW, config: DEFAULTS });
  // A second later, so the history order (newest first) is deterministic.
  await admin.applySupportAction({
    playerId,
    action: 'gift_freeze',
    quantity: 1,
    nowMs: NOW + 1000,
    config: DEFAULTS,
  });
  assert.equal(await freezeCount(playerId), 3);

  const lookup = await admin.getDailyRewardPlayer({ playerId, nowMs: NOW, config: DEFAULTS });
  assert.equal(lookup.streak.freezes, 3);
  assert.deepEqual(
    lookup.support.map((entry) => entry.detail.quantity),
    [1, 2],
  );
});

test('moving a streak back lets QA claim again, across several claim rows', { skip }, async () => {
  const admin = require('../db/daily_rewards_admin');
  const shift = (playerId) =>
    admin.applySupportAction({ playerId, action: 'shift_days', days: 1, nowMs: NOW, config: DEFAULTS });

  const playerId = await createPlayer();
  assert.equal((await claim(playerId)).day, 1);
  await shift(playerId);
  assert.equal((await claim(playerId)).day, 2);
  // Two claim rows move now: 22 -> 21 must happen before 23 -> 22.
  await shift(playerId);
  assert.equal((await claim(playerId)).day, 3);

  const lookup = await admin.getDailyRewardPlayer({ playerId, nowMs: NOW, config: DEFAULTS });
  assert.deepEqual(
    lookup.claims.map((entry) => entry.localDate),
    ['2026-10-23', '2026-10-22', '2026-10-21'],
  );
});

test('reset wipes a player streak for QA and keeps the support history', { skip }, async () => {
  const admin = require('../db/daily_rewards_admin');
  const playerId = await createPlayer();
  await claim(playerId);
  await admin.applySupportAction({ playerId, action: 'reset', nowMs: NOW, config: DEFAULTS });

  assert.equal(await streakRow(playerId), null);
  const lookup = await admin.getDailyRewardPlayer({ playerId, nowMs: NOW, config: DEFAULTS });
  assert.deepEqual(lookup.claims, []);
  assert.equal(lookup.status.state, 'claimable');
  assert.equal(lookup.support[0].action, 'reset');
});

test('closes the pool', { skip }, async () => {
  if (ready) {
    await require('../db/pool').closeDb();
    ready = null;
  }
});
