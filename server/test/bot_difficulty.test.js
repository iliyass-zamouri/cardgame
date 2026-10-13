const test = require('node:test');
const assert = require('node:assert/strict');
const { iqForPot, profileForIq, POT_LADDERS } = require('../bot_difficulty');
const { ServerRobotPlayer } = require('../bot_player');

const noJitter = () => 0.5;

test('iq rises with the pot in every currency', () => {
  for (const [currency, ladder] of Object.entries(POT_LADDERS)) {
    const iqs = ladder.map((pot) => iqForPot(pot, currency, noJitter));
    for (let i = 1; i < iqs.length; i += 1) assert.ok(iqs[i] > iqs[i - 1], `${currency} ${iqs}`);
    iqs.forEach((iq) => assert.ok(iq >= 0 && iq <= 100));
  }
});

test('profile gets stricter as iq rises', () => {
  const low = profileForIq(20);
  const high = profileForIq(90);
  assert.ok(high.mistakeRate < low.mistakeRate);
  assert.ok(high.memoryRetention > low.memoryRetention);
  assert.ok(high.thinkMaxMs < low.thinkMaxMs);
  assert.ok(high.callMinTurns <= low.callMinTurns);
});

test('ServerRobotPlayer derives its profile from iq; explicit args win', () => {
  const room = { players: [] };
  const bot = new ServerRobotPlayer({ room, clientId: 'b', iq: 90 });
  assert.equal(bot.thinkMaxMs, profileForIq(90).thinkMaxMs);
  const custom = new ServerRobotPlayer({ room, clientId: 'b', iq: 90, thinkMaxMs: 5 });
  assert.equal(custom.thinkMaxMs, 5);
});
