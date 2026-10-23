const crypto = require('crypto');

/**
 * Each bot gets a stable personality from its player id, so the same bot
 * always "feels" the same across matches and friend chats.
 */
const PERSONALITIES = Object.freeze({
  chatty: {
    name: 'chatty',
    proactiveChance: 0.75,
    bluffChance: 0.3,
    emojiShare: 0.45,
    typingMs: [900, 2600],
  },
  cocky: {
    name: 'cocky',
    proactiveChance: 0.6,
    bluffChance: 0.6,
    emojiShare: 0.5,
    typingMs: [1000, 3000],
  },
  friendly: {
    name: 'friendly',
    proactiveChance: 0.55,
    bluffChance: 0.15,
    emojiShare: 0.4,
    typingMs: [1200, 3200],
  },
  quiet: {
    name: 'quiet',
    proactiveChance: 0.25,
    bluffChance: 0.2,
    emojiShare: 0.7,
    typingMs: [1800, 4000],
  },
});

const ORDER = ['chatty', 'cocky', 'friendly', 'quiet'];

/** Stable 32-bit hash of a string (first 4 bytes of sha1). */
function stableHash(value) {
  return crypto.createHash('sha1').update(String(value)).digest().readUInt32BE(0);
}

function personalityFor(botPlayerId) {
  return PERSONALITIES[ORDER[stableHash(botPlayerId) % ORDER.length]];
}

module.exports = { PERSONALITIES, personalityFor, stableHash };
