/**
 * Bot "IQ" (0-100) and the behaviour profile derived from it.
 * IQ rises with the pot so higher stakes face tougher robots.
 */

/** Pot ladders per currency. Keep in sync with ALLOWED_STAKE_POOLS in game_server.js. */
const POT_LADDERS = {
  money: [20, 50, 100, 200, 500],
  chips: [2, 10, 50],
};

const MIN_POT_IQ = 25;
const MAX_POT_IQ = 90;
const IQ_JITTER = 6;

function clamp(value, min, max) {
  return Math.min(max, Math.max(min, value));
}

function lerp(from, to, t) {
  return from + (to - from) * t;
}

/** 0..1 position of the pot within its currency ladder (unknown pots snap to the nearest). */
function potTier(stakePool, currency = 'money') {
  const ladder = POT_LADDERS[currency] || POT_LADDERS.money;
  if (ladder.length < 2) return 0;
  let nearest = 0;
  for (let i = 1; i < ladder.length; i += 1) {
    if (Math.abs(ladder[i] - stakePool) < Math.abs(ladder[nearest] - stakePool)) {
      nearest = i;
    }
  }
  return nearest / (ladder.length - 1);
}

function iqForPot(stakePool, currency = 'money', random = Math.random) {
  const base = lerp(MIN_POT_IQ, MAX_POT_IQ, potTier(stakePool, currency));
  const jitter = (random() * 2 - 1) * IQ_JITTER;
  return Math.round(clamp(base + jitter, 0, 100));
}

function profileForIq(iq) {
  const s = clamp(Number(iq) || 0, 0, 100) / 100;
  return {
    iq: Math.round(s * 100),
    // Chance each remembered card is still remembered at the start of a turn.
    memoryRetention: lerp(0.9, 1, s),
    // Chance of a deliberately suboptimal move.
    mistakeRate: lerp(0.25, 0.02, s),
    // Throw the drawn card away outright when its score is at or below this.
    throwThreshold: Math.round(lerp(2, 4, s)),
    // Own turns before the bot may call the match.
    callMinTurns: Math.round(lerp(4, 2, s)),
    // Required estimated lead (points) before calling.
    callMargin: lerp(8, 1, s),
    // Chance of using a Jack/Queen ability when available.
    abilityUse: lerp(0.5, 1, s),
    thinkMinMs: Math.round(lerp(1100, 500, s)),
    thinkMaxMs: Math.round(lerp(2200, 1000, s)),
  };
}

module.exports = {
  POT_LADDERS,
  potTier,
  iqForPot,
  profileForIq,
};
