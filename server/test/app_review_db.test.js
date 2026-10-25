// Runs the rate-the-app SQL against a real MySQL. Skipped unless
// APP_REVIEW_DB_TEST=1 and the MYSQL_* variables point at a scratch
// database. Example:
//   APP_REVIEW_DB_TEST=1 MYSQL_HOST=127.0.0.1 MYSQL_PORT=3306 \
//     MYSQL_USER=cardgame MYSQL_PASSWORD=cardgame MYSQL_DATABASE=cardgame \
//     node --test server/test/app_review_db.test.js

const test = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('crypto');
const { DEFAULTS } = require('../app_review_config');
const { DAY_MS } = require('../app_review');

const skip =
  process.env.APP_REVIEW_DB_TEST === '1'
    ? false
    : 'set APP_REVIEW_DB_TEST=1 and MYSQL_* to run against MySQL';

// Far enough ahead that stats windows only see the rows these tests write.
const FUTURE = Date.UTC(2100, 0, 15, 12);

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

function reviews() {
  return require('../db/app_reviews');
}

async function createPlayer({ wins = 0, losses = 0, marketing = true, ageDays = 30, idleHours = 24 } = {}) {
  const id = `t-${crypto.randomUUID()}`;
  await (await db()).execute(
    `INSERT INTO players (id, wins, losses, notify_marketing, created_at, last_seen_at)
     VALUES (:id, :wins, :losses, :marketing,
       UTC_TIMESTAMP() - INTERVAL :ageDays DAY, UTC_TIMESTAMP() - INTERVAL :idleHours HOUR)`,
    { id, wins, losses, marketing: marketing ? 1 : 0, ageDays, idleHours },
  );
  return id;
}

async function addToken(playerId) {
  await (await db()).execute(
    `INSERT INTO device_tokens (player_id, token, platform) VALUES (:playerId, :token, 'android')`,
    { playerId, token: `tok-${crypto.randomUUID()}` },
  );
}

const device = { platform: 'android', appVersion: '1.1.0+13', locale: 'fr' };

test('status creates the state row and reports the player stats', { skip }, async () => {
  const { touchReviewState } = reviews();
  const id = await createPlayer({ wins: 4, losses: 3, ageDays: 10 });
  const context = await touchReviewState(id, device, FUTURE);
  assert.equal(context.player.matchesPlayed, 7);
  assert.equal(context.player.wins, 4);
  assert.ok(Math.abs(Date.now() - 10 * DAY_MS - context.player.createdAtMs) < 60_000);
  assert.equal(context.state.promptsShown, 0);
  assert.equal(context.state.locale, 'fr');
  assert.equal(await touchReviewState('t-missing', device, FUTURE), null);
});

test('prompts, ratings and feedback update the state and stay with their owner', { skip }, async () => {
  const { touchReviewState, recordPromptShown, recordDismiss, insertReview, addReviewFeedback, lastRatedAtMs } =
    reviews();
  const id = await createPlayer({ wins: 5 });
  const other = await createPlayer();
  await touchReviewState(id, device, FUTURE);

  await recordPromptShown(id, 'win', true, FUTURE);
  await recordPromptShown(id, 'settings', false, FUTURE + 1);
  await recordDismiss(id, 'settings', FUTURE + 2);
  let { state } = await touchReviewState(id, device, FUTURE + 3);
  assert.equal(state.promptsShown, 1);
  assert.equal(state.lastPromptAtMs, FUTURE + 1);
  assert.equal(state.lastDismissedAtMs, FUTURE + 2);

  const reviewId = await insertReview({
    playerId: id, stars: 2, trigger: 'win', ...device, storeRedirected: false, nowMs: FUTURE + 4,
  });
  assert.ok(reviewId > 0);
  ({ state } = await touchReviewState(id, device, FUTURE + 5));
  assert.equal(state.lastStars, 2);
  assert.equal(state.lastRatedAtMs, FUTURE + 4);
  assert.equal(state.lastRedirectedAtMs, null);
  assert.equal(await lastRatedAtMs(id), FUTURE + 4);

  const feedback = { reviewId, tags: ['ads', 'bugs'], comment: 'Too many ads', nowMs: FUTURE + 6 };
  assert.equal(await addReviewFeedback({ ...feedback, playerId: other }), false);
  assert.equal(await addReviewFeedback({ ...feedback, playerId: id }), true);

  const [rows] = await (await db()).execute('SELECT * FROM app_reviews WHERE id = :reviewId', { reviewId });
  assert.equal(rows[0].tags, 'ads,bugs');
  assert.equal(rows[0].comment, 'Too many ads');
  assert.equal(Number(rows[0].feedback_at_ms), FUTURE + 6);
});

test('a rating also works for a player whose app never asked for status', { skip }, async () => {
  const { insertReview, touchReviewState } = reviews();
  const id = await createPlayer();
  await insertReview({ playerId: id, stars: 5, trigger: 'settings', ...device, storeRedirected: true, nowMs: FUTURE });
  const { state } = await touchReviewState(id, device, FUTURE + 1);
  assert.equal(state.lastStars, 5);
  assert.equal(state.lastRedirectedAtMs, FUTURE);
});

test('the admin list filters, pages and marks ratings handled', { skip }, async () => {
  const { insertReview, addReviewFeedback, listReviews, setReviewHandled, exportReviewsCsv } = reviews();
  const id = await createPlayer();
  const platform = `qa${crypto.randomUUID().slice(0, 6)}`;
  const ids = [];
  for (const stars of [1, 2, 5]) {
    ids.push(
      await insertReview({
        playerId: id, stars, trigger: 'win', platform, appVersion: null, locale: 'en',
        storeRedirected: stars === 5, nowMs: FUTURE + stars,
      }),
    );
  }
  await addReviewFeedback({ reviewId: ids[0], playerId: id, tags: [], comment: '=HYPERLINK("x")', nowMs: FUTURE });

  const all = await listReviews({ platform });
  assert.equal(all.total, 3);
  assert.deepEqual(all.items.map((item) => item.stars), [5, 2, 1]);

  const low = await listReviews({ platform, stars: '1,2' });
  assert.equal(low.total, 2);
  const withComment = await listReviews({ platform, hasComment: '1' });
  assert.deepEqual(withComment.items.map((item) => item.id), [ids[0]]);

  const page = await listReviews({ platform, limit: '2', offset: '2' });
  assert.equal(page.items.length, 1);
  assert.equal(page.items[0].stars, 1);

  assert.equal(await setReviewHandled(ids[0], true), true);
  assert.equal(await setReviewHandled(999_999_999_999, true), false);
  assert.equal((await listReviews({ platform, handled: '0' })).total, 2);

  const { csv, count } = await exportReviewsCsv({ platform });
  assert.equal(count, 3);
  // A comment that looks like a formula is quoted so spreadsheets show it as text.
  assert.match(csv, /'=HYPERLINK\(""x""\)/);
});

test('stats summarize the window', { skip }, async () => {
  const { touchReviewState, recordPromptShown, recordDismiss, insertReview, getReviewStats } = reviews();
  const nowMs = FUTURE + 300 * DAY_MS;
  const a = await createPlayer();
  const b = await createPlayer();
  for (const id of [a, b]) await touchReviewState(id, device, nowMs);
  await recordPromptShown(a, 'win', true, nowMs);
  await recordPromptShown(b, 'daily', true, nowMs);
  await recordDismiss(b, 'daily', nowMs);
  await insertReview({ playerId: a, stars: 5, trigger: 'win', ...device, storeRedirected: true, nowMs });
  await insertReview({ playerId: b, stars: 2, trigger: 'win', ...device, platform: 'ios', storeRedirected: false, nowMs });

  const stats = await getReviewStats({ days: 1, nowMs: nowMs + 1000, storeMinStars: 4 });
  assert.equal(stats.ratings, 2);
  assert.equal(stats.average, 3.5);
  assert.equal(stats.happy, 1);
  assert.equal(stats.redirected, 1);
  assert.deepEqual(stats.distribution.map((row) => row.count), [0, 1, 0, 0, 1]);
  assert.equal(stats.daily.length, 1);
  assert.deepEqual(
    stats.byPlatform.map((row) => row.platform).sort(),
    ['android', 'ios'],
  );
  const win = stats.byTrigger.find((row) => row.trigger === 'win');
  assert.deepEqual({ shown: win.shown, rated: win.rated }, { shown: 1, rated: 2 });
  assert.equal(stats.funnel.shown, 2);
  assert.equal(stats.funnel.dismissed, 1);
});

test('the auto push picks eligible players once and the admin filter finds unrated ones', { skip }, async () => {
  const { touchReviewState, selectPushCandidates, markPushSent, insertReview, recordPushOpened } = reviews();
  const { countMarketingBlastAudience, listMarketingBlastAudience } = require('../db/push');
  const config = JSON.parse(JSON.stringify(DEFAULTS));
  config.push.minMatchesPlayed = 3;
  const nowMs = Date.now();

  const eligible = await createPlayer({ wins: 3 });
  const rated = await createPlayer({ wins: 3 });
  const tooFew = await createPlayer({ wins: 1 });
  const active = await createPlayer({ wins: 3, idleHours: 0 });
  const optedOut = await createPlayer({ wins: 3, marketing: false });
  const oldBuild = await createPlayer({ wins: 3 });
  const noToken = await createPlayer({ wins: 3 });
  for (const id of [eligible, rated, tooFew, active, optedOut, oldBuild]) await addToken(id);
  for (const id of [eligible, rated, tooFew, active, optedOut, noToken]) {
    await touchReviewState(id, device, nowMs);
  }
  await insertReview({ playerId: rated, stars: 4, trigger: 'win', ...device, storeRedirected: true, nowMs });

  const mine = new Set([eligible, rated, tooFew, active, optedOut, oldBuild, noToken]);
  const picked = (await selectPushCandidates(config, nowMs, 5000)).filter((row) => mine.has(row.playerId));
  assert.deepEqual(picked, [{ playerId: eligible, locale: 'fr' }]);

  const audience = await listMarketingBlastAudience({ notRated: true, maxLastSeenDays: 90 });
  assert.ok(audience.includes(eligible));
  assert.ok(!audience.includes(rated));
  assert.ok(!audience.includes(oldBuild), 'builds without the prompt are left out');
  assert.ok((await countMarketingBlastAudience({ notRated: true })) >= 1);

  await markPushSent([eligible], nowMs);
  const again = (await selectPushCandidates(config, nowMs, 5000)).filter((row) => mine.has(row.playerId));
  assert.deepEqual(again, []);

  await recordPushOpened(eligible, nowMs + 1);
  await recordPushOpened(eligible, nowMs + 2);
  const [events] = await (await db()).execute(
    `SELECT kind FROM app_review_events WHERE player_id = :id ORDER BY id`,
    { id: eligible },
  );
  assert.deepEqual(events.map((row) => row.kind), ['push_sent', 'push_opened']);
});

test.after(async () => {
  if (!ready) return;
  await (await connect()).closeDb();
});
