const ADJECTIVES = [
  'Lucky',
  'Sharp',
  'Royal',
  'Bold',
  'Swift',
  'Sly',
  'Wild',
  'Quiet',
  'Bright',
  'Golden',
  'Silver',
  'Cosmic',
  'Shadow',
  'Chrome',
  'Neon',
];

const NOUNS = [
  'Ace',
  'King',
  'Queen',
  'Joker',
  'Dealer',
  'Suit',
  'Deck',
  'Chip',
  'Flush',
  'Stack',
  'Hand',
  'Trick',
  'Bluff',
  'River',
  'Ante',
];

function pick(list) {
  return list[Math.floor(Math.random() * list.length)];
}

/**
 * Generate a display name + username pair.
 * @returns {{ name: string, username: string }}
 */
function generateGuestIdentity() {
  const adjective = pick(ADJECTIVES);
  const noun = pick(NOUNS);
  const number = Math.floor(1000 + Math.random() * 9000);
  const name = `${adjective} ${noun}`;
  const raw = `${adjective}_${noun}_${number}`
    .toLowerCase()
    .replace(/[^a-z0-9_]/g, '_');
  const username = raw.length <= 16
    ? raw
    : `${adjective.slice(0, 4)}_${noun.slice(0, 4)}_${number}`
      .toLowerCase()
      .replace(/[^a-z0-9_]/g, '_')
      .slice(0, 16);
  return { name, username };
}

module.exports = { generateGuestIdentity };
