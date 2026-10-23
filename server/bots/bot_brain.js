const { PHRASE_IDS, EMOJI_IDS, filterProfanity } = require('../chat/room_chat');

/**
 * Rule-based table talk for bots. Replies are always phrase ids or emoji ids,
 * so every player reads them in their own language on the client.
 *
 * ctx = {
 *   personality,               // from bot_personality
 *   random,                    // () => [0, 1)
 *   phase: 'waiting' | 'playing' | 'ended',
 *   mood: 'ahead' | 'behind' | 'even' | null,   // bot's standing (tone only)
 *   botWon: true | false | null,                // set once the game ended
 * }
 */

const phrase = (phraseId) => ({ kind: 'phrase', phraseId });
const emoji = (emojiId) => ({ kind: 'emoji', emojiId });

const PHRASE_INTENTS = {
  hello: 'greet',
  goodLuck: 'goodLuck',
  wellPlayed: 'compliment',
  niceSwap: 'compliment',
  sharpMemory: 'compliment',
  playFast: 'hurry',
  stopPeeking: 'complain',
  giveCardBack: 'complain',
  blackKingPlease: 'wish',
  foundJoker: 'bluff',
  knowMyCards: 'bluff',
  lowTotal: 'bluff',
  endingNextTurn: 'bluff',
  unlucky: 'sympathy',
  oops: 'oops',
  thanks: 'thanks',
  hehe: 'laugh',
  gg: 'gg',
};

const EMOJI_INTENTS = {
  laugh: 'laugh',
  love: 'thanks',
  cry: 'sad',
  angry: 'angry',
  cool: 'brag',
  shock: 'laugh',
  fist: 'hype',
  clap: 'compliment',
};

// Free-text intents; first match wins. Covers en/fr/es/pt/ar/darija.
const TEXT_INTENTS = [
  ['botQuestion', /\b(bot|robot|ai|ia|machine|computer|ordi|cpu)\b|بوت|روبوت|آلي/iu],
  ['greet', /\b(hi|hey|hello|yo|salut|bonjour|bonsoir|cc|coucou|hola|buenas|ol[aá]|oi|salam|slm|ahlan|labas)\b|مرحب|سلام|اهلا|أهلا/iu],
  ['gg', /\b(gg|good game|bien jou[eé]|bem jogado|bien jugado|wp)\b/iu],
  ['thanks', /\b(thx|thanks|thank you|ty|merci|gracias|obrigad[oa]|shukran|choukran|baraka)\b|شكر/iu],
  ['laugh', /\b(lol|lmao|haha+|hehe+|mdr|ptdr|jaja+|kkk+|hhh+|xd)\b|ههه/iu],
  ['bluff', /\b(joker|jocker|coringa|comod[ií]n|king|roi|rey|rei|queen|reine|reina|rainha|jack|valet|zero|0 points?)\b|جوكر|ملك|ملكة/iu],
  ['hurry', /\b(fast|hurry|vite|d[eé]p[eê]che|r[aá]pido|apura|yalla|zreb)\b|بسرعة|يلا/iu],
  ['goodLuck', /\b(good luck|gl|bonne chance|suerte|boa sorte|bsa7a)\b|بالتوفيق|حظ/iu],
  ['sad', /\b(sad|unlucky|noo+|dommage|triste|mala suerte|azar|7chouma)\b|حظ سيء|للأسف/iu],
];

/** Weighted pick from [[weight, value], ...]. */
function pick(options, random) {
  const valid = options.filter(([weight, value]) => weight > 0 && value);
  const total = valid.reduce((sum, [weight]) => sum + weight, 0);
  if (total <= 0) return null;
  let roll = random() * total;
  for (const [weight, value] of valid) {
    roll -= weight;
    if (roll < 0) return value;
  }
  return valid[valid.length - 1][1];
}

function intentOf(message) {
  switch (message?.kind) {
    case 'phrase':
      return PHRASE_INTENTS[message.phraseId] || 'unknown';
    case 'emoji':
      return EMOJI_INTENTS[message.emojiId] || 'unknown';
    case 'text': {
      const text = String(message.text || '');
      if (filterProfanity(text) !== text) return 'insult';
      for (const [intent, pattern] of TEXT_INTENTS) {
        if (pattern.test(text)) return intent;
      }
      return 'unknown';
    }
    default:
      return 'unknown';
  }
}

function bluffs(ctx) {
  const p = ctx.personality;
  const weight = p.bluffChance * (ctx.mood === 'ahead' ? 2 : 1);
  return [
    [weight, phrase('foundJoker')],
    [weight, phrase('lowTotal')],
    [weight * 0.7, phrase('knowMyCards')],
    [ctx.phase === 'playing' ? weight * 0.5 : 0, phrase('endingNextTurn')],
  ];
}

/** Reply options for an intent, before personality and mood tweaks. */
function optionsFor(intent, ctx) {
  const p = ctx.personality;
  const cocky = p.name === 'cocky' ? 1 : 0;
  const friendly = p.name === 'friendly' ? 1 : 0;
  const ended = ctx.phase === 'ended';
  switch (intent) {
    case 'greet':
      return [
        [3, phrase('hello')],
        [ended ? 0 : 2, phrase('goodLuck')],
        [1 + cocky, emoji('cool')],
        [1, emoji('fist')],
      ];
    case 'goodLuck':
      return [
        [3, phrase('goodLuck')],
        [2, phrase('thanks')],
        [cocky * 2, phrase('hehe')],
        [cocky, phrase('foundJoker')],
      ];
    case 'compliment':
      return [
        [3, phrase('thanks')],
        [2, emoji('love')],
        [1 + cocky * 2, emoji('cool')],
        [1, phrase('hehe')],
        [friendly * 2, phrase('wellPlayed')],
      ];
    case 'bluff':
      // Call the bluff, or bluff back.
      return [
        [3, phrase('hehe')],
        [2, emoji('laugh')],
        [1 + cocky, emoji('cool')],
        [1, phrase('blackKingPlease')],
        ...bluffs(ctx).map(([w, v]) => [w * 2, v]),
      ];
    case 'complain':
      return [
        [3, phrase('hehe')],
        [2, emoji('laugh')],
        [1 + friendly, phrase('oops')],
        [cocky, emoji('cool')],
      ];
    case 'hurry':
      return [
        [3, phrase('oops')],
        [2, phrase('hehe')],
        [1, emoji('shock')],
        [cocky, emoji('cool')],
      ];
    case 'wish':
      return [
        [3, phrase('hehe')],
        [2, phrase('goodLuck')],
        [2, emoji('laugh')],
        [cocky * 2, phrase('foundJoker')],
      ];
    case 'sympathy':
      return [
        [3, phrase('thanks')],
        [2, emoji('cry')],
        [1, phrase('oops')],
        [cocky, phrase('hehe')],
      ];
    case 'oops':
      return [
        [3, phrase('hehe')],
        [2, emoji('laugh')],
        [1 + friendly * 2, phrase('unlucky')],
      ];
    case 'thanks':
      return [
        [3, emoji('love')],
        [2, emoji('clap')],
        [1, phrase('hehe')],
      ];
    case 'laugh':
      return [
        [3, phrase('hehe')],
        [3, emoji('laugh')],
        [cocky, emoji('cool')],
      ];
    case 'gg':
      return [
        [4, phrase('gg')],
        [2, phrase('wellPlayed')],
        [1, emoji('clap')],
      ];
    case 'sad':
      return friendly || !cocky
        ? [
          [3, phrase('unlucky')],
          [2, emoji('cry')],
          [1, phrase('goodLuck')],
        ]
        : [
          [3, phrase('hehe')],
          [2, emoji('laugh')],
          [1, phrase('unlucky')],
        ];
    case 'angry':
      return [
        [3, emoji('cool')],
        [2, phrase('hehe')],
        [1 + friendly, phrase('oops')],
      ];
    case 'brag':
      return [
        [3, emoji('cool')],
        [2, phrase('hehe')],
        ...bluffs(ctx),
      ];
    case 'hype':
      return [
        [3, emoji('fist')],
        [2, emoji('cool')],
        [1, phrase('goodLuck')],
      ];
    case 'botQuestion':
      // Never confirm; deflect like a real player would.
      return [
        [3, phrase('hehe')],
        [2, emoji('laugh')],
        [2, emoji('cool')],
        [1, phrase('knowMyCards')],
      ];
    case 'insult':
      return [
        [4, emoji('cool')],
        [2, phrase('hehe')],
      ];
    default:
      return [
        [3, emoji('laugh')],
        [2, phrase('hehe')],
        [1 + friendly, emoji('love')],
        [cocky, emoji('cool')],
      ];
  }
}

/** Mood colour on top of the intent-based options. */
function moodOptions(ctx) {
  if (ctx.phase === 'ended') {
    if (ctx.botWon === true) return [[2, phrase('gg')], [1, phrase('hehe')]];
    if (ctx.botWon === false) return [[2, phrase('wellPlayed')], [1, emoji('cry')]];
    return [[1, phrase('gg')]];
  }
  if (ctx.mood === 'behind') return [[1, phrase('unlucky')], [1, emoji('cry')]];
  if (ctx.mood === 'ahead') return bluffs(ctx).map(([w, v]) => [w * 0.5, v]);
  return [];
}

/**
 * Reply to a human chat message. Always returns a reply: an ignored
 * message is what gives a bot away.
 */
function replyTo(message, ctx) {
  const intent = intentOf(message);
  const options = [...optionsFor(intent, ctx), ...moodOptions(ctx)];
  return withEmojiShare(pick(options, ctx.random), ctx) || emoji('laugh');
}

/** Lean towards emojis for emoji-heavy personalities. */
function withEmojiShare(reply, ctx) {
  if (!reply || reply.kind !== 'phrase') return reply;
  if (ctx.random() >= ctx.personality.emojiShare * 0.35) return reply;
  const swap = {
    hehe: 'laugh',
    thanks: 'love',
    gg: 'clap',
    wellPlayed: 'clap',
    oops: 'shock',
    unlucky: 'cry',
  }[reply.phraseId];
  return swap ? emoji(swap) : reply;
}

/**
 * Proactive reaction to a table event, or null to stay quiet. Callers rate
 * limit; this only decides what fits.
 */
function reactTo(event, ctx) {
  const p = ctx.personality;
  if (ctx.random() >= p.proactiveChance) return null;
  const cocky = p.name === 'cocky' ? 1 : 0;
  const friendly = p.name === 'friendly' ? 1 : 0;
  switch (event) {
    case 'start':
      return pick([
        [3, phrase('goodLuck')],
        [3, phrase('hello')],
        [cocky * 2, emoji('fist')],
      ], ctx.random);
    case 'peekedMe':
      return pick([
        [4, phrase('stopPeeking')],
        [1, emoji('shock')],
      ], ctx.random);
    case 'swappedMe':
      return pick([
        [4, phrase('giveCardBack')],
        [1, emoji('angry')],
        [1, emoji('shock')],
      ], ctx.random);
    case 'shuffledMe':
      return pick([
        [2, emoji('angry')],
        [2, phrase('oops')],
        [1, emoji('shock')],
      ], ctx.random);
    case 'myPeek':
      return pick([
        [3, phrase('knowMyCards')],
        [2, emoji('cool')],
        [1, phrase('hehe')],
      ], ctx.random);
    case 'myGoodSwap':
      if (ctx.random() >= p.bluffChance) return null;
      return pick(bluffs(ctx).filter(([, v]) => v.phraseId !== 'endingNextTurn'), ctx.random);
    case 'opponentPenalty':
      return pick([
        [3, emoji('laugh')],
        [2, phrase('hehe')],
        [1 + friendly, phrase('oops')],
      ], ctx.random);
    case 'opponentMatch':
      return pick([
        [3, phrase('sharpMemory')],
        [2, emoji('clap')],
        [cocky, phrase('hehe')],
      ], ctx.random);
    case 'opponentDouble':
      return pick([
        [3, phrase('niceSwap')],
        [2, emoji('shock')],
        [1, emoji('clap')],
      ], ctx.random);
    case 'won':
      return pick([
        [3, phrase('gg')],
        [2 + cocky * 2, emoji('cool')],
        [1 + cocky, phrase('hehe')],
        [friendly * 2, phrase('wellPlayed')],
      ], ctx.random);
    case 'lost':
      return pick([
        [3, phrase('wellPlayed')],
        [2, phrase('gg')],
        [2, emoji('cry')],
        [1, phrase('unlucky')],
      ], ctx.random);
    case 'tie':
      return pick([
        [2, phrase('hehe')],
        [2, phrase('gg')],
        [1, emoji('shock')],
      ], ctx.random);
    default:
      return null;
  }
}

// Every reply must pass the server allowlist.
function isAllowed(reply) {
  if (!reply) return false;
  return reply.kind === 'phrase'
    ? PHRASE_IDS.includes(reply.phraseId)
    : EMOJI_IDS.includes(reply.emojiId);
}

module.exports = { replyTo, reactTo, intentOf, isAllowed };
