// The pot tables players pick from, in the app's order. Each player pays half
// the pool to enter. Must match `StakeSelectorScreen.potOptions` in the app
// and POT_LADDERS in bot_difficulty.js. Matchmaking reads its allowed pots
// from here.
const POTS = [
  { id: 'london', city: 'London', currency: 'money', pool: 20 },
  { id: 'paris', city: 'Paris', currency: 'money', pool: 50 },
  { id: 'moscow', city: 'Moscow', currency: 'money', pool: 100 },
  { id: 'cairo', city: 'Cairo', currency: 'money', pool: 200 },
  { id: 'marrakech', city: 'Marrakech', currency: 'money', pool: 500 },
  { id: 'toronto', city: 'Toronto', currency: 'chips', pool: 2 },
  { id: 'new_york', city: 'New York', currency: 'chips', pool: 10 },
  { id: 'tokyo', city: 'Tokyo', currency: 'chips', pool: 50 },
];

function potById(id) {
  return POTS.find((pot) => pot.id === id) || null;
}

/** The pot a stored match was played at, from its currency and pot amount. */
function potFor(currency, pool) {
  return POTS.find((pot) => pot.currency === currency && pot.pool === Number(pool)) || null;
}

module.exports = { POTS, potById, potFor };
