'use strict';

const geoip = require('geoip-lite');

function trustProxy() {
  return process.env.TRUST_PROXY === '1' || process.env.TRUST_PROXY === 'true';
}

function normalizeCountry(raw) {
  if (typeof raw !== 'string') return null;
  const code = raw.trim().toUpperCase();
  if (!/^[A-Z]{2}$/.test(code) || code === 'XX' || code === 'T1') return null;
  return code;
}

/** ISO 3166-1 alpha-2 country for a request, or null when unknown. */
function getClientCountry(req, ip) {
  if (trustProxy()) {
    const fromHeader = normalizeCountry(req?.headers?.['cf-ipcountry']);
    if (fromHeader) return fromHeader;
  }
  if (typeof ip !== 'string' || !ip) return null;
  try {
    return normalizeCountry(geoip.lookup(ip)?.country);
  } catch {
    return null;
  }
}

module.exports = { getClientCountry, normalizeCountry };
