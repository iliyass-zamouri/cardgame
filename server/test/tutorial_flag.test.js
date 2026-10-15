const test = require('node:test');
const assert = require('node:assert/strict');

// Swap in a fake pool before the db modules capture `getPool`.
const poolModule = require('../db/pool');
const executed = [];
let tutorialDoneRow = 0;
poolModule.getPool = () => ({
  async execute(sql, params) {
    executed.push({ sql, params });
    if (sql.startsWith('UPDATE players') && sql.includes('tutorial_done = 1')) {
      tutorialDoneRow = 1;
      return [{ affectedRows: 1 }];
    }
    if (sql.startsWith('SELECT')) {
      return [[{ id: params.playerId, display_name: 'Ana', tutorial_done: tutorialDoneRow }]];
    }
    return [[]];
  },
});

const { updatePlayerProfile } = require('../db/friends');
const { mapPlayerRow } = require('../db/store');

test('mapPlayerRow exposes tutorialDone', () => {
  assert.equal(mapPlayerRow({ id: 'p1', tutorial_done: 1 }).tutorialDone, true);
  assert.equal(mapPlayerRow({ id: 'p1', tutorial_done: 0 }).tutorialDone, false);
  assert.equal(mapPlayerRow({ id: 'p1' }).tutorialDone, false);
});

test('updatePlayerProfile marks the tutorial done', async () => {
  executed.length = 0;
  tutorialDoneRow = 0;
  const row = await updatePlayerProfile({ playerId: 'p1', tutorialDone: true });
  assert.ok(executed.some((q) => q.sql.includes('tutorial_done = 1')));
  assert.equal(row.tutorial_done, 1);
});

test('updatePlayerProfile never resets the tutorial flag', async () => {
  executed.length = 0;
  await updatePlayerProfile({ playerId: 'p1', tutorialDone: false });
  assert.ok(!executed.some((q) => q.sql.startsWith('UPDATE')));
});
