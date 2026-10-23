const crypto = require('crypto');

const DEFAULT_STUN_URLS = ['stun:stun.l.google.com:19302'];
const DEFAULT_TTL_SECONDS = 6 * 60 * 60;

function splitList(value) {
  return String(value || '')
    .split(',')
    .map((entry) => entry.trim())
    .filter(Boolean);
}

/**
 * Time-limited TURN credentials for coturn's `use-auth-secret` mode
 * (the "TURN REST API" scheme): username = "<expiry>:<playerId>",
 * credential = base64(HMAC-SHA1(secret, username)).
 */
function turnCredential({ secret, playerId, ttlSeconds = DEFAULT_TTL_SECONDS, nowMs = Date.now() }) {
  const expiry = Math.floor(nowMs / 1000) + ttlSeconds;
  const username = `${expiry}:${playerId || 'anon'}`;
  const credential = crypto.createHmac('sha1', secret).update(username).digest('base64');
  return { username, credential, ttl: ttlSeconds };
}

/**
 * ICE server list for the client's RTCPeerConnection. Falls back to STUN
 * only when TURN is not configured.
 */
function buildIceServers({ playerId, env = process.env, nowMs = Date.now() } = {}) {
  const turnUrls = splitList(env.TURN_URLS);
  const secret = String(env.TURN_SHARED_SECRET || '').trim();
  const stunUrls = splitList(env.STUN_URLS);
  const iceServers = [];

  if (turnUrls.length > 0 && secret) {
    const ttlSeconds = Number(env.TURN_TTL_SECONDS) > 0 ? Number(env.TURN_TTL_SECONDS) : DEFAULT_TTL_SECONDS;
    const { username, credential, ttl } = turnCredential({ secret, playerId, ttlSeconds, nowMs });
    // Our own coturn also answers STUN on the same port; keep a public STUN
    // too so direct connections still work if the relay port is unreachable.
    const ownStun = turnUrls
      .map((url) => url.replace(/^turns?:/, 'stun:').replace(/\?.*$/, ''))
      .filter((url, index, all) => all.indexOf(url) === index);
    iceServers.push({
      urls: stunUrls.length > 0 ? stunUrls : [...ownStun, ...DEFAULT_STUN_URLS],
    });
    iceServers.push({ urls: turnUrls, username, credential });
    return { iceServers, ttl };
  }

  iceServers.push({ urls: stunUrls.length > 0 ? stunUrls : DEFAULT_STUN_URLS });
  return { iceServers, ttl: DEFAULT_TTL_SECONDS };
}

module.exports = { turnCredential, buildIceServers };
