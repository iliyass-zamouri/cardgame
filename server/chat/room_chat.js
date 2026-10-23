const crypto = require('crypto');

/** Quick phrases are sent as ids; each client renders its own translation. */
const PHRASE_IDS = Object.freeze([
  'hello',
  'goodLuck',
  'wellPlayed',
  'niceSwap',
  'sharpMemory',
  'playFast',
  'stopPeeking',
  'giveCardBack',
  'blackKingPlease',
  'foundJoker',
  'knowMyCards',
  'lowTotal',
  'endingNextTurn',
  'unlucky',
  'oops',
  'thanks',
  'hehe',
  'gg',
]);

const EMOJI_IDS = Object.freeze([
  'laugh',
  'love',
  'cry',
  'angry',
  'cool',
  'shock',
  'fist',
  'clap',
]);

const MAX_TEXT_LENGTH = 120;

// Kept short on purpose: obvious slurs/insults in the app's languages.
const BLOCKED_WORDS = [
  // en
  'fuck', 'fucking', 'fucker', 'shit', 'bitch', 'asshole', 'bastard', 'cunt', 'dick',
  'pussy', 'whore', 'slut', 'motherfucker', 'nigger', 'nigga', 'faggot', 'retard',
  // fr
  'putain', 'merde', 'connard', 'connasse', 'salope', 'pute', 'encule', 'enculé',
  'batard', 'bâtard', 'nique', 'niquer', 'fdp', 'ntm',
  // es
  'puta', 'puto', 'mierda', 'cabron', 'cabrón', 'pendejo', 'gilipollas', 'coño',
  'joder', 'maricon', 'maricón', 'hijoputa',
  // pt
  'caralho', 'porra', 'merda', 'foda', 'fodase', 'viado', 'buceta', 'arrombado',
  // darija (latin)
  'zamel', 'zaml', 'qahba', '9ahba', 'qhba', 'tabon', 'zebi', 'zbi', 'nmok',
  '7mar', 'hmar', 'kelb', 'klb',
  // ar
  'قحبة', 'زامل', 'شرموطة', 'كلب', 'حمار', 'زبي', 'طبون', 'منيوك', 'خرا',
];

const blockedPattern = new RegExp(
  `(?<![\\p{L}\\p{N}])(?:${BLOCKED_WORDS.map(escapeRegExp).join('|')})(?![\\p{L}\\p{N}])`,
  'giu',
);

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

/**
 * Trims, strips control characters and collapses whitespace.
 * @param {unknown} raw
 * @returns {string}
 */
function sanitizeText(raw) {
  if (typeof raw !== 'string') return '';
  return Array.from(
    raw
      // eslint-disable-next-line no-control-regex
      .replace(/[\u0000-\u001f\u007f-\u009f​-‏‪-‮⁦-⁩]/g, ' ')
      .replace(/\s+/g, ' ')
      .trim(),
  )
    .slice(0, MAX_TEXT_LENGTH)
    .join('')
    .trim();
}

/** @param {string} text */
function filterProfanity(text) {
  return text.replace(blockedPattern, (match) => '*'.repeat(Array.from(match).length));
}

/**
 * Validates a `chatSend` command and returns the payload to relay,
 * or null when it is invalid.
 * @returns {{ kind: 'text', text: string } | { kind: 'phrase', phraseId: string } | { kind: 'emoji', emojiId: string } | null}
 */
function validateChatCommand(command) {
  switch (command?.kind) {
    case 'text': {
      const text = filterProfanity(sanitizeText(command.text));
      return text ? { kind: 'text', text } : null;
    }
    case 'phrase':
      return PHRASE_IDS.includes(command.phraseId)
        ? { kind: 'phrase', phraseId: command.phraseId }
        : null;
    case 'emoji':
      return EMOJI_IDS.includes(command.emojiId)
        ? { kind: 'emoji', emojiId: command.emojiId }
        : null;
    default:
      return null;
  }
}

/** Token bucket per connection: short bursts allowed, no flooding. */
class ChatLimiter {
  constructor({ burst = 3, refillMs = 1500, now = Date.now } = {}) {
    this.burst = burst;
    this.refillMs = refillMs;
    this.now = now;
    this.tokens = burst;
    this.updatedAt = now();
  }

  tryConsume() {
    const now = this.now();
    this.tokens = Math.min(this.burst, this.tokens + (now - this.updatedAt) / this.refillMs);
    this.updatedAt = now;
    if (this.tokens < 1) return false;
    this.tokens -= 1;
    return true;
  }
}

/** Builds the `chatMessage` event sent to every seat. */
function buildChatMessage(fromPlayerId, payload) {
  return {
    type: 'chatMessage',
    id: crypto.randomUUID(),
    fromPlayerId,
    ...payload,
    at: Date.now(),
  };
}

const VOICE_SIGNAL_KINDS = ['offer', 'answer', 'ice', 'hangup'];
const MAX_SDP_LENGTH = 12 * 1024;

/**
 * Validates a WebRTC signaling payload before relaying it to the peer.
 * @returns {object | null}
 */
function validateVoiceSignal(signal) {
  if (!signal || !VOICE_SIGNAL_KINDS.includes(signal.kind)) return null;
  if (signal.kind === 'offer' || signal.kind === 'answer') {
    if (typeof signal.sdp !== 'string' || !signal.sdp || signal.sdp.length > MAX_SDP_LENGTH) {
      return null;
    }
    return { kind: signal.kind, sdp: signal.sdp };
  }
  if (signal.kind === 'ice') {
    const candidate = signal.candidate;
    if (!candidate || typeof candidate.candidate !== 'string' || candidate.candidate.length > 1024) {
      return null;
    }
    return {
      kind: 'ice',
      candidate: {
        candidate: candidate.candidate,
        sdpMid: typeof candidate.sdpMid === 'string' ? candidate.sdpMid.slice(0, 64) : null,
        sdpMLineIndex: Number.isInteger(candidate.sdpMLineIndex) ? candidate.sdpMLineIndex : null,
      },
    };
  }
  return { kind: 'hangup' };
}

module.exports = {
  PHRASE_IDS,
  EMOJI_IDS,
  MAX_TEXT_LENGTH,
  sanitizeText,
  filterProfanity,
  validateChatCommand,
  ChatLimiter,
  buildChatMessage,
  validateVoiceSignal,
};
