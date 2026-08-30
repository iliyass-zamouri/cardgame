const { randomUUID } = require('crypto');
const { getPool } = require('./pool');
const { generateGuestIdentity } = require('../auth/guest_name');
const {
  assertValidGuestDeviceId,
  assertClientIp,
  normalizeClientIp,
  guestIpRebindEnabled,
  GuestIpMismatchError,
} = require('../auth/guest_device');

class InvalidOAuthProviderError extends Error {
  constructor(provider) {
    super(`Unsupported OAuth provider: ${provider}`);
    this.name = 'InvalidOAuthProviderError';
    this.code = 'invalid_oauth_provider';
  }
}

const PLAYER_SELECT = `
  p.id, p.display_name, p.username, p.device_id,
  p.created_ip, p.last_ip, p.auth_type, p.google_sub,
  p.money, p.chips
`;

function mapPlayerRow(row) {
  if (!row) return null;
  return {
    playerId: row.id,
    name: row.display_name,
    username: row.username,
    authType: row.auth_type || 'guest',
    money: row.money != null ? Number(row.money) : 500,
    chips: row.chips != null ? Number(row.chips) : 1,
  };
}

async function usernameExists(username) {
  const pool = getPool();
  const [rows] = await pool.execute(
    `SELECT 1 AS ok FROM players WHERE username = :username LIMIT 1`,
    { username },
  );
  return rows.length > 0;
}

async function findGuestByDevice(deviceId) {
  try {
    assertValidGuestDeviceId(deviceId);
  } catch {
    return null;
  }
  const pool = getPool();
  const [rows] = await pool.execute(
    `SELECT ${PLAYER_SELECT}
     FROM players p
     WHERE p.device_id = :deviceId
     LIMIT 1`,
    { deviceId },
  );
  return rows[0] ?? null;
}

async function findGuestByDeviceAndIp(deviceId, clientIp) {
  try {
    assertValidGuestDeviceId(deviceId);
  } catch {
    return null;
  }
  const ip = normalizeClientIp(clientIp);
  if (!ip) {
    return null;
  }
  const pool = getPool();
  const [rows] = await pool.execute(
    `SELECT ${PLAYER_SELECT}
     FROM players p
     WHERE p.device_id = :deviceId AND p.last_ip = :clientIp
     LIMIT 1`,
    { deviceId, clientIp: ip },
  );
  return rows[0] ?? null;
}

async function touchGuest(playerId, clientIp) {
  const pool = getPool();
  await pool.execute(
    `UPDATE players
     SET last_seen_at = CURRENT_TIMESTAMP,
         last_ip = :clientIp
     WHERE id = :id`,
    { id: playerId, clientIp },
  );
}

async function bindGuestIp(playerId, clientIp) {
  const pool = getPool();
  await pool.execute(
    `UPDATE players
     SET last_seen_at = CURRENT_TIMESTAMP,
         last_ip = :clientIp,
         created_ip = COALESCE(created_ip, :clientIp)
     WHERE id = :id`,
    { id: playerId, clientIp },
  );
}

async function createGuest({ deviceId, clientIp }) {
  const safeDeviceId = assertValidGuestDeviceId(deviceId);
  const ip = assertClientIp(clientIp);
  const pool = getPool();
  const playerId = `guest-${randomUUID()}`;

  for (let attempt = 0; attempt < 12; attempt += 1) {
    const { name, username } = generateGuestIdentity();
    if (await usernameExists(username)) {
      continue;
    }
    try {
      await pool.execute(
        `INSERT INTO players
           (id, display_name, username, device_id, created_ip, last_ip, auth_type)
         VALUES
           (:playerId, :displayName, :username, :deviceId, :clientIp, :clientIp, 'guest')`,
        {
          playerId,
          displayName: name,
          username,
          deviceId: safeDeviceId,
          clientIp: ip,
        },
      );
      return {
        id: playerId,
        display_name: name,
        username,
        auth_type: 'guest',
        isNew: true,
      };
    } catch (error) {
      if (error?.code === 'ER_DUP_ENTRY') {
        const existing =
          (await findGuestByDeviceAndIp(safeDeviceId, ip)) ||
          (await findGuestByDevice(safeDeviceId));
        if (existing) {
          return { ...existing, isNew: false };
        }
        continue;
      }
      throw error;
    }
  }

  throw new Error('Could not allocate unique guest username');
}

async function findOrCreateGuest({ deviceId, clientIp }) {
  const safeDeviceId = assertValidGuestDeviceId(deviceId);
  const ip = assertClientIp(clientIp);

  const exact = await findGuestByDeviceAndIp(safeDeviceId, ip);
  if (exact) {
    await touchGuest(exact.id, ip);
    return {
      ...mapPlayerRow(exact),
      isNew: false,
    };
  }

  const existing = await findGuestByDevice(safeDeviceId);
  if (existing) {
    const boundIp = existing.last_ip || existing.created_ip || null;
    if (!boundIp) {
      await bindGuestIp(existing.id, ip);
      return {
        ...mapPlayerRow(existing),
        isNew: false,
      };
    }
    if (boundIp === ip) {
      await touchGuest(existing.id, ip);
      return {
        ...mapPlayerRow(existing),
        isNew: false,
      };
    }
    if (!guestIpRebindEnabled()) {
      throw new GuestIpMismatchError();
    }
    await bindGuestIp(existing.id, ip);
    return {
      ...mapPlayerRow(existing),
      isNew: false,
    };
  }

  const created = await createGuest({ deviceId: safeDeviceId, clientIp: ip });
  return {
    ...mapPlayerRow({
      id: created.id,
      display_name: created.display_name,
      username: created.username,
      auth_type: 'guest',
    }),
    isNew: true,
  };
}

async function findPlayerByGoogleSub(googleSub) {
  if (typeof googleSub !== 'string' || !googleSub.trim()) {
    return null;
  }
  const pool = getPool();
  const [rows] = await pool.execute(
    `SELECT ${PLAYER_SELECT}
     FROM players p
     WHERE p.google_sub = :googleSub
     LIMIT 1`,
    { googleSub: googleSub.trim() },
  );
  return rows[0] ?? null;
}

async function linkGuestToProvider({
  playerId,
  provider,
  sub,
  displayNameHint = null,
  clientIp = null,
}) {
  if (provider !== 'google') {
    throw new InvalidOAuthProviderError(provider);
  }
  const pool = getPool();
  const name =
    typeof displayNameHint === 'string' && displayNameHint.trim()
      ? displayNameHint.trim().slice(0, 64)
      : null;
  const ip = clientIp ? normalizeClientIp(clientIp) : null;

  await pool.execute(
    `UPDATE players
     SET auth_type = :authType,
         google_sub = :sub,
         display_name = COALESCE(:displayName, display_name),
         last_seen_at = CURRENT_TIMESTAMP,
         last_ip = COALESCE(:clientIp, last_ip)
     WHERE id = :playerId
       AND auth_type = 'guest'
       AND google_sub IS NULL`,
    {
      authType: provider,
      sub,
      displayName: name,
      clientIp: ip,
      playerId,
    },
  );

  const [rows] = await pool.execute(
    `SELECT ${PLAYER_SELECT}
     FROM players p
     WHERE p.id = :playerId
     LIMIT 1`,
    { playerId },
  );
  return rows[0] ?? null;
}

async function createOAuthPlayer({
  provider,
  sub,
  deviceId = null,
  displayNameHint = null,
  clientIp = null,
}) {
  if (provider !== 'google') {
    throw new InvalidOAuthProviderError(provider);
  }

  const pool = getPool();
  const playerId = `${provider}-${randomUUID()}`;
  const ip = clientIp ? normalizeClientIp(clientIp) : null;

  let safeDeviceId = null;
  if (typeof deviceId === 'string' && deviceId.trim()) {
    try {
      safeDeviceId = assertValidGuestDeviceId(deviceId);
      const taken = await findGuestByDevice(safeDeviceId);
      if (taken) {
        safeDeviceId = null;
      }
    } catch {
      safeDeviceId = null;
    }
  }

  const hintName =
    typeof displayNameHint === 'string' && displayNameHint.trim()
      ? displayNameHint.trim().slice(0, 64)
      : null;

  for (let attempt = 0; attempt < 12; attempt += 1) {
    const generated = generateGuestIdentity();
    const name = hintName || generated.name;
    const username = generated.username;
    if (await usernameExists(username)) {
      continue;
    }
    try {
      await pool.execute(
        `INSERT INTO players
           (id, display_name, username, device_id, created_ip, last_ip, auth_type, google_sub)
         VALUES
           (:playerId, :displayName, :username, :deviceId, :clientIp, :clientIp, :authType, :sub)`,
        {
          playerId,
          displayName: name,
          username,
          deviceId: safeDeviceId,
          clientIp: ip,
          authType: provider,
          sub,
        },
      );
      return {
        id: playerId,
        display_name: name,
        username,
        auth_type: provider,
        google_sub: sub,
        _created: true,
      };
    } catch (error) {
      if (error?.code === 'ER_DUP_ENTRY') {
        const existing = await findPlayerByGoogleSub(sub);
        if (existing) {
          return { ...existing, _created: false };
        }
        if (safeDeviceId) {
          safeDeviceId = null;
          continue;
        }
        continue;
      }
      throw error;
    }
  }

  throw new Error('Could not allocate unique OAuth username');
}

async function findOrLinkOAuth({
  provider,
  sub,
  deviceId = null,
  displayNameHint = null,
  clientIp = null,
}) {
  if (provider !== 'google') {
    throw new InvalidOAuthProviderError(provider);
  }
  if (typeof sub !== 'string' || !sub.trim()) {
    throw new Error('OAuth sub is required');
  }
  const safeSub = sub.trim();
  const ip = clientIp ? normalizeClientIp(clientIp) : null;

  const existing = await findPlayerByGoogleSub(safeSub);
  if (existing) {
    if (ip) {
      await touchGuest(existing.id, ip);
    }
    return {
      ...mapPlayerRow(existing),
      isNew: false,
      linkedFromGuest: false,
    };
  }

  let linkableGuest = null;
  if (typeof deviceId === 'string' && deviceId.trim()) {
    try {
      const safeDeviceId = assertValidGuestDeviceId(deviceId);
      const byDevice = await findGuestByDevice(safeDeviceId);
      if (
        byDevice &&
        byDevice.auth_type === 'guest' &&
        !byDevice.google_sub
      ) {
        linkableGuest = byDevice;
      }
    } catch {
      // Invalid deviceId — skip link path.
    }
  }

  if (linkableGuest) {
    const linked = await linkGuestToProvider({
      playerId: linkableGuest.id,
      provider,
      sub: safeSub,
      displayNameHint,
      clientIp: ip,
    });
    if (linked && linked.auth_type === provider && linked.google_sub === safeSub) {
      return {
        ...mapPlayerRow(linked),
        isNew: false,
        linkedFromGuest: true,
      };
    }
    const raced = await findPlayerByGoogleSub(safeSub);
    if (raced) {
      return {
        ...mapPlayerRow(raced),
        isNew: false,
        linkedFromGuest: false,
      };
    }
  }

  const created = await createOAuthPlayer({
    provider,
    sub: safeSub,
    deviceId,
    displayNameHint,
    clientIp: ip,
  });

  return {
    ...mapPlayerRow(created),
    isNew: Boolean(created._created),
    linkedFromGuest: false,
  };
}

module.exports = {
  InvalidOAuthProviderError,
  mapPlayerRow,
  findOrCreateGuest,
  findOrLinkOAuth,
  findGuestByDevice,
  findPlayerByGoogleSub,
  GuestIpMismatchError,
};
