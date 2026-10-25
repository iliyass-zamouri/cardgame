// Runs the push history and pot stats SQL against a real MySQL. Skipped unless
// ADMIN_DB_TEST=1 and the MYSQL_* variables point at a scratch database.
// Example:
//   ADMIN_DB_TEST=1 MYSQL_HOST=127.0.0.1 MYSQL_PORT=3306 \
//     MYSQL_USER=cardgame MYSQL_PASSWORD=cardgame MYSQL_DATABASE=cardgame \
//     node --test server/test/push_admin_db.test.js

const test = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('crypto');

const skip =
  process.env.ADMIN_DB_TEST === '1'
    ? false
    : 'set ADMIN_DB_TEST=1 and MYSQL_* to run against MySQL';

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

async function createPlayer({ bot = false, marketing = true } = {}) {
  const id = `t-${crypto.randomUUID()}`;
  await (await db()).execute(
    `INSERT INTO players (id, is_bot, notify_marketing) VALUES (:id, :bot, :marketing)`,
    { id, bot: bot ? 1 : 0, marketing: marketing ? 1 : 0 },
  );
  return id;
}

test('push history groups marketing rows by campaign', { skip }, async () => {
  const { insertPlayerNotifications, listMarketingCampaigns } = require('../db/push');
  await connect();
  const tag = crypto.randomUUID().slice(0, 8);
  const [a, b, c] = [await createPlayer(), await createPlayer(), await createPlayer()];
  const optedOut = await createPlayer({ marketing: false });

  const send = (playerIds, title, data) =>
    insertPlayerNotifications({
      playerIds,
      type: 'marketing',
      category: 'marketing',
      title,
      body: 'Come play',
      data: { type: 'marketing', ...data },
    });
  await send([a, b, c, optedOut], `Cairo ${tag}`, { campaignId: `c-${tag}`, route: '/play?pot=cairo' });
  await send([a], `Test ${tag}`, { campaignId: `t-${tag}`, test: '1' });
  // Sent before campaigns were stamped: grouped by title and minute.
  await send([b, c], `Legacy ${tag}`, { route: '/friends' });
  await (await db()).execute(
    `UPDATE player_notifications SET read_at = CURRENT_TIMESTAMP
     WHERE player_id = :a AND title = :title`,
    { a, title: `Cairo ${tag}` },
  );

  const mine = (await listMarketingCampaigns({ limit: 100 })).filter((row) => row.title.endsWith(tag));
  const byTitle = Object.fromEntries(mine.map((row) => [row.title.split(' ')[0], row]));
  assert.equal(mine.length, 3);
  assert.deepEqual(
    { recipients: byTitle.Cairo.recipients, readCount: byTitle.Cairo.readCount, route: byTitle.Cairo.route, test: byTitle.Cairo.test },
    { recipients: 3, readCount: 1, route: '/play?pot=cairo', test: false },
  );
  assert.equal(byTitle.Cairo.campaignId, `c-${tag}`);
  assert.equal(byTitle.Test.test, true);
  assert.equal(byTitle.Test.recipients, 1);
  assert.equal(byTitle.Legacy.recipients, 2);
  assert.match(byTitle.Legacy.campaignId, /^legacy:/);
  assert.ok(!Number.isNaN(Date.parse(byTitle.Cairo.sentAt)));
});

test('the push schema adds its history index once', { skip }, async () => {
  const { ensurePushSchema } = require('../db/push');
  await connect();
  await ensurePushSchema();
  const [rows] = await (await db()).query(
    `SELECT COUNT(DISTINCT INDEX_NAME) AS n FROM information_schema.STATISTICS
     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'player_notifications'
       AND INDEX_NAME = 'idx_player_notifications_category_created'`,
  );
  assert.equal(Number(rows[0].n), 1);
});

test('dashboard stats count matches per pot', { skip }, async () => {
  const { getAdminDashboardStats } = require('../admin/stats');
  const pool = await db();
  const potOf = (stats, id) => stats.pots.find((pot) => pot.id === id);
  const before = await getAdminDashboardStats();

  const human = await createPlayer();
  const bot = await createPlayer({ bot: true });
  const addMatch = async (currency, pot, players) => {
    const id = `m-${crypto.randomUUID()}`;
    await pool.execute(
      `INSERT INTO matches (id, room_id, match_type, stake_per_player, pot_amount, stake_currency)
       VALUES (:id, 'R1', 'random', :stake, :pot, :currency)`,
      { id, stake: pot / 2, pot, currency },
    );
    for (const [seat, playerId] of players.entries()) {
      await pool.execute(
        `INSERT INTO match_players
           (match_id, player_id, seat, card_total, result, points_earned, elo_before, elo_after, elo_delta)
         VALUES (:id, :playerId, :seat, 10, 'win', 0, 1000, 1000, 0)`,
        { id, playerId, seat },
      );
    }
  };
  await addMatch('money', 200, [human, bot]);
  await addMatch('money', 200, [human]);
  await addMatch('chips', 50, [human]);
  await addMatch('money', 7, [human]);

  const after = await getAdminDashboardStats();
  const cairo = potOf(after, 'cairo');
  assert.equal(cairo.matches - potOf(before, 'cairo').matches, 2);
  assert.equal(cairo.withBot - potOf(before, 'cairo').withBot, 1);
  assert.equal(cairo.volume, cairo.matches * 200);
  assert.equal(potOf(after, 'tokyo').matches - potOf(before, 'tokyo').matches, 1);
  assert.equal(after.potsOther - before.potsOther, 1);
  const today = after.potsByDay.at(-1);
  assert.equal(today.cairo - before.potsByDay.at(-1).cairo, 2);
  assert.equal(after.recentMatches.find((row) => row.potAmount === 50 && row.stakeCurrency === 'chips').potId, 'tokyo');
});

test('closes the pool', { skip }, async () => {
  if (ready) {
    await require('../db/pool').closeDb();
    ready = null;
  }
});
