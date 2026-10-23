const test = require('node:test');
const assert = require('node:assert/strict');
const { BotSocialDirector } = require('../bots/bot_social');

const HOUR = 60 * 60 * 1000;
// 12:00 UTC: daytime for most of the offset table.
const NOON = Date.UTC(2026, 9, 23, 12, 0, 0);

function fakeWorld(overrides = {}) {
  const calls = [];
  const world = {
    now: NOON,
    calls,
    relations: new Map(),
    summary: {
      friendRequestsToday: 0,
      invitesToday: 0,
      lastAt: null,
      askedByBots: new Set(),
    },
    pending: 0,
    profiles: new Map([
      ['human-1', { playerId: 'human-1', countryCode: 'MA', elo: 1100, isBot: false, eligible: true }],
    ]),
    busyBots: new Set(),
    busyHumans: new Set(),
    idle: [],
    offline: [],
    botFriends: [],
    pendingToBots: [],
  };
  const deps = {
    now: () => world.now,
    random: () => 0,
    busyBotIds: () => world.busyBots,
    listBotUsers: async () => [{ playerId: 'bot-a' }, { playerId: 'bot-b' }],
    listBotFriendIds: async () => world.botFriends,
    relationStatus: async (botId, humanId) => world.relations.get(`${botId}:${humanId}`) || 'none',
    listPendingRequestsToBots: async () => world.pendingToBots,
    outreachSummary: async () => world.summary,
    pendingBotRequestCount: async () => world.pending,
    recordOutreach: async (entry) => calls.push(['record', entry]),
    listOfflineTargets: async () => world.offline,
    loadHumanProfiles: async (ids) => new Map(ids.map((id) => [id, world.profiles.get(id)]).filter(([, p]) => p)),
    onlineHumanIds: () => new Set(world.idle.map((h) => h.playerId)),
    idleHumans: () => world.idle,
    isHumanBusy: (id) => world.busyHumans.has(id),
    hostInvite: async (args) => {
      calls.push(['invite', args]);
      return true;
    },
    joinHumanRoom: async (args) => calls.push(['join', args]),
    sendBotFriendRequest: async (args) => calls.push(['request', args]),
    acceptBotFriendRequest: async (args) => calls.push(['accept', args]),
    ...overrides,
  };
  return { world, deps };
}

function director(deps, options = {}) {
  // onlineShare 1: every bot looks online, so tests don't depend on the hour hash.
  return new BotSocialDirector(deps, { onlineShare: 1, idleReachChance: 1, offlineReachChance: 1, ...options });
}

test('overdue friend requests to bots get accepted on tick', async () => {
  const { world, deps } = fakeWorld();
  world.pendingToBots = [{ requestId: 'f1', requesterId: 'human-1', botId: 'bot-a' }];
  const social = director(deps, { enabled: false });
  await social.tick();
  assert.deepEqual(world.calls, [['accept', { botId: 'bot-a', requesterId: 'human-1' }]]);
});

test('idle human with a bot friend gets a private-match invite', async () => {
  const { world, deps } = fakeWorld();
  world.idle = [{ playerId: 'human-1', idleForMs: 5 * 60 * 1000 }];
  world.botFriends = ['bot-a'];
  world.relations.set('bot-a:human-1', 'friends');
  const social = director(deps);
  await social.tick();
  const invite = world.calls.find(([kind]) => kind === 'invite');
  assert.deepEqual(invite[1], { botId: 'bot-a', humanId: 'human-1', ttlMs: 10 * 60 * 1000 });
  assert.ok(world.calls.some(([kind, e]) => kind === 'record' && e.kind === 'invite'));
});

test('idle human without bot friends gets a friend request from a stranger bot', async () => {
  const { world, deps } = fakeWorld({ random: () => 0.5 });
  world.idle = [{ playerId: 'human-1', idleForMs: 5 * 60 * 1000 }];
  const social = director(deps);
  await social.tick();
  const request = world.calls.find(([kind]) => kind === 'request');
  assert.equal(request[1].humanId, 'human-1');
});

test('caps: spacing, daily limits, pending limit, busy and new players', async () => {
  const cases = [
    (w) => { w.summary.lastAt = NOON - HOUR; },
    (w) => { w.summary.invitesToday = 2; w.summary.friendRequestsToday = 1; },
    (w) => { w.summary.invitesToday = 2; w.pending = 3; },
    (w) => { w.busyHumans.add('human-1'); },
    (w) => { w.profiles.get('human-1').eligible = false; },
  ];
  for (const apply of cases) {
    const { world, deps } = fakeWorld({ random: () => 0.5 });
    world.idle = [{ playerId: 'human-1', idleForMs: 5 * 60 * 1000 }];
    apply(world);
    await director(deps).tick();
    assert.equal(
      world.calls.filter(([kind]) => kind === 'invite' || kind === 'request').length,
      0,
      apply.toString(),
    );
  }
});

test('never re-asks the same player and skips blocks', async () => {
  const { world, deps } = fakeWorld({ random: () => 0.5 });
  world.idle = [{ playerId: 'human-1', idleForMs: 5 * 60 * 1000 }];
  world.summary.askedByBots = new Set(['bot-a', 'bot-b']);
  await director(deps).tick();
  assert.equal(world.calls.filter(([k]) => k === 'request').length, 0);

  const blocked = fakeWorld();
  blocked.world.idle = [{ playerId: 'human-1', idleForMs: 5 * 60 * 1000 }];
  blocked.world.botFriends = ['bot-a'];
  blocked.world.relations.set('bot-a:human-1', 'blocked');
  await director(blocked.deps).tick();
  assert.equal(blocked.world.calls.filter(([k]) => k === 'invite').length, 0);
});

test('offline players get pushes only outside quiet hours', async () => {
  const day = fakeWorld();
  day.world.offline = [{ playerId: 'human-1' }];
  day.world.botFriends = ['bot-a'];
  await director(day.deps).tick();
  const invite = day.world.calls.find(([k]) => k === 'invite');
  assert.equal(invite[1].ttlMs, 30 * 60 * 1000);

  const night = fakeWorld();
  night.world.now = Date.UTC(2026, 9, 23, 2, 0, 0); // 03:00 in Morocco
  night.world.offline = [{ playerId: 'human-1' }];
  night.world.botFriends = ['bot-a'];
  await director(night.deps).tick();
  assert.equal(night.world.calls.length, 0);
});

test('kill switch stops outreach but bots still accept requests', async () => {
  const { world, deps } = fakeWorld();
  world.idle = [{ playerId: 'human-1', idleForMs: 5 * 60 * 1000 }];
  world.offline = [{ playerId: 'human-1' }];
  world.pendingToBots = [{ requestId: 'f1', requesterId: 'human-1', botId: 'bot-a' }];
  const social = director(deps, { enabled: false });
  await social.tick();
  assert.deepEqual(world.calls.map(([k]) => k), ['accept']);
  social.onBotMatchEnded({ botId: 'bot-a', humanId: 'human-1', scoreGap: 1, gamesPlayed: 3 });
  assert.equal(social.timers.size, 0);
  social.dispose();
});

test('human invites an online bot friend: the bot joins', async (t) => {
  t.mock.timers.enable({ apis: ['setTimeout'] });
  const { world, deps } = fakeWorld();
  const social = director(deps);
  social.onHumanInvitedBot({ botId: 'bot-a', humanId: 'human-1', roomId: 'ABC123' });
  t.mock.timers.tick(11_000);
  await new Promise((resolve) => setImmediate(resolve));
  assert.deepEqual(world.calls, [['join', { botId: 'bot-a', humanId: 'human-1', roomId: 'ABC123' }]]);

  // Busy bots ignore invites.
  world.calls.length = 0;
  world.busyBots.add('bot-b');
  social.onHumanInvitedBot({ botId: 'bot-b', humanId: 'human-1', roomId: 'ABC123' });
  t.mock.timers.tick(11_000);
  assert.equal(world.calls.length, 0);
  social.dispose();
});
