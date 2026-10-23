const test = require('node:test');
const assert = require('node:assert/strict');
const { replyTo, reactTo, intentOf, isAllowed } = require('../bots/bot_brain');
const { PERSONALITIES, personalityFor } = require('../bots/bot_personality');
const { PHRASE_IDS, EMOJI_IDS } = require('../chat/room_chat');

function ctx(overrides = {}) {
  let seed = 1;
  return {
    personality: PERSONALITIES.friendly,
    random: () => {
      seed = (seed * 16807) % 2147483647;
      return (seed - 1) / 2147483646;
    },
    phase: 'playing',
    mood: 'even',
    botWon: null,
    ...overrides,
  };
}

test('intentOf reads phrases, emojis and multilingual text', () => {
  assert.equal(intentOf({ kind: 'phrase', phraseId: 'foundJoker' }), 'bluff');
  assert.equal(intentOf({ kind: 'phrase', phraseId: 'stopPeeking' }), 'complain');
  assert.equal(intentOf({ kind: 'emoji', emojiId: 'angry' }), 'angry');
  assert.equal(intentOf({ kind: 'text', text: 'salut ça va' }), 'greet');
  assert.equal(intentOf({ kind: 'text', text: 'مرحبا' }), 'greet');
  assert.equal(intentOf({ kind: 'text', text: 'merci bcp' }), 'thanks');
  assert.equal(intentOf({ kind: 'text', text: 'hhhhh' }), 'laugh');
  assert.equal(intentOf({ kind: 'text', text: 'are you a bot?' }), 'botQuestion');
  assert.equal(intentOf({ kind: 'text', text: 'wach nta robot' }), 'botQuestion');
  assert.equal(intentOf({ kind: 'text', text: 'I have the joker' }), 'bluff');
  assert.equal(intentOf({ kind: 'text', text: 'fuck you' }), 'insult');
  assert.equal(intentOf({ kind: 'text', text: 'blue sky' }), 'unknown');
});

test('replyTo always answers with an allowed phrase or emoji', () => {
  const messages = [
    ...PHRASE_IDS.map((phraseId) => ({ kind: 'phrase', phraseId })),
    ...EMOJI_IDS.map((emojiId) => ({ kind: 'emoji', emojiId })),
    { kind: 'text', text: 'hola' },
    { kind: 'text', text: 'are you a robot' },
    { kind: 'text', text: 'zzz' },
  ];
  for (const personality of Object.values(PERSONALITIES)) {
    for (const phase of ['waiting', 'playing', 'ended']) {
      for (const message of messages) {
        const reply = replyTo(message, ctx({ personality, phase }));
        assert.ok(isAllowed(reply), `${personality.name}/${phase}/${JSON.stringify(message)}`);
      }
    }
  }
});

test('bot questions are never answered with a giveaway', () => {
  for (let i = 0; i < 50; i += 1) {
    const reply = replyTo({ kind: 'text', text: 'you are a bot' }, ctx({ random: Math.random }));
    assert.ok(
      (reply.kind === 'phrase' && ['hehe', 'knowMyCards'].includes(reply.phraseId)) ||
        (reply.kind === 'emoji' && ['laugh', 'cool'].includes(reply.emojiId)),
      JSON.stringify(reply),
    );
  }
});

test('greeting gets a greeting-like answer and gg gets gg-like', () => {
  const greet = replyTo({ kind: 'phrase', phraseId: 'hello' }, ctx({ random: () => 0 }));
  assert.deepEqual(greet, { kind: 'phrase', phraseId: 'hello' });
  for (let i = 0; i < 30; i += 1) {
    const gg = replyTo({ kind: 'phrase', phraseId: 'gg' }, ctx({ random: Math.random, phase: 'ended' }));
    assert.ok(
      ['gg', 'wellPlayed', 'hehe', 'clap', 'cry', 'laugh'].includes(gg.phraseId || gg.emojiId),
      JSON.stringify(gg),
    );
  }
});

test('reactTo fits the event and respects the proactive chance', () => {
  const always = { ...PERSONALITIES.chatty, proactiveChance: 1 };
  assert.deepEqual(
    reactTo('swappedMe', ctx({ personality: always, random: () => 0.05 })),
    { kind: 'phrase', phraseId: 'giveCardBack' },
  );
  assert.deepEqual(
    reactTo('peekedMe', ctx({ personality: always, random: () => 0.05 })),
    { kind: 'phrase', phraseId: 'stopPeeking' },
  );
  const never = { ...PERSONALITIES.quiet, proactiveChance: 0 };
  assert.equal(reactTo('start', ctx({ personality: never })), null);
  assert.equal(reactTo('unknownEvent', ctx({ personality: always })), null);
});

test('personality is stable per bot id', () => {
  assert.equal(personalityFor('bot-abc'), personalityFor('bot-abc'));
  const names = new Set(
    Array.from({ length: 40 }, (_, i) => personalityFor(`bot-${i}`).name),
  );
  assert.ok(names.size >= 3);
});
