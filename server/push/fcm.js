const { readFileSync } = require('node:fs');
const admin = require('firebase-admin');

const {
  insertPlayerNotifications,
  listMarketingTokens,
  listPlayerIdsWithNotifyPref,
  listMarketingBlastAudience,
  listTokensForPlayers,
  removeDeviceTokens,
} = require('../db/push');

let _ready = false;
let _initAttempted = false;

function loadServiceAccount() {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!raw || !raw.trim()) return null;

  const trimmed = raw.trim();
  try {
    if (trimmed.startsWith('{')) {
      return JSON.parse(trimmed);
    }
    const fileContents = readFileSync(trimmed, 'utf8');
    return JSON.parse(fileContents);
  } catch (error) {
    console.error('[fcm] Failed to load FIREBASE_SERVICE_ACCOUNT_JSON', error);
    return null;
  }
}

function initFcm() {
  if (_initAttempted) return _ready;
  _initAttempted = true;

  const serviceAccount = loadServiceAccount();
  if (!serviceAccount) {
    console.warn(
      '[fcm] Disabled — set FIREBASE_SERVICE_ACCOUNT_JSON to a service account JSON path or inline JSON',
    );
    return false;
  }

  try {
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    }
    _ready = true;
    console.log('[fcm] Firebase Admin initialized');
  } catch (error) {
    console.error('[fcm] Init failed', error);
    _ready = false;
  }
  return _ready;
}

function isFcmReady() {
  return _ready;
}

function stringifyData(value) {
  if (value == null) return '';
  return typeof value === 'string' ? value : String(value);
}

function toStringData(data) {
  const out = {};
  if (!data || typeof data !== 'object') return out;
  for (const [key, value] of Object.entries(data)) {
    if (value == null) continue;
    out[key] = stringifyData(value);
  }
  return out;
}

function chunk(items, size) {
  const out = [];
  for (let i = 0; i < items.length; i += size) {
    out.push(items.slice(i, i + size));
  }
  return out;
}

const INVALID_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
]);

async function sendToTokenRows(tokenRows, { title, body, data }) {
  if (!_ready || !tokenRows.length) {
    return { successCount: 0, failureCount: 0, skipped: true };
  }

  const stringData = toStringData(data);
  const tokens = [...new Set(tokenRows.map((row) => row.token))];
  let successCount = 0;
  let failureCount = 0;
  const staleTokens = [];

  for (const batch of chunk(tokens, 500)) {
    try {
      const response = await admin.messaging().sendEachForMulticast({
        tokens: batch,
        notification: { title, body },
        data: stringData,
        android: {
          priority: 'high',
          notification: {
            channelId: 'shadowhand_default',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
            },
          },
        },
      });
      successCount += response.successCount;
      failureCount += response.failureCount;
      response.responses.forEach((res, index) => {
        if (res.success) return;
        const code = res.error?.code;
        if (code && INVALID_TOKEN_CODES.has(code)) {
          staleTokens.push(batch[index]);
        }
      });
    } catch (error) {
      console.error('[fcm] sendEachForMulticast failed', error);
      failureCount += batch.length;
    }
  }

  if (staleTokens.length) {
    try {
      await removeDeviceTokens(staleTokens);
    } catch (error) {
      console.error('[fcm] failed to prune stale tokens', error);
    }
  }

  return { successCount, failureCount, skipped: false };
}

async function sendToPlayers(playerIds, opts) {
  const exclude = new Set(
    (opts.excludePlayerIds || [])
      .filter((id) => typeof id === 'string' && id.trim())
      .map((id) => id.trim()),
  );
  const targets = [
    ...new Set(
      (playerIds || [])
        .filter((id) => typeof id === 'string' && id.trim())
        .map((id) => id.trim())
        .filter((id) => !exclude.has(id)),
    ),
  ];
  if (!targets.length) {
    return { successCount: 0, failureCount: 0, skipped: false, inboxCount: 0 };
  }

  let inboxCount = 0;
  if (!opts.skipInbox) {
    const type =
      typeof opts.data?.type === 'string' && opts.data.type.trim()
        ? opts.data.type.trim()
        : opts.category;
    try {
      inboxCount = await insertPlayerNotifications({
        playerIds: targets,
        type,
        category: opts.category,
        title: opts.title,
        body: opts.body,
        data: opts.data,
      });
    } catch (error) {
      console.error('[fcm] inbox insert failed', error);
    }
  }

  if (!_ready) {
    return {
      successCount: 0,
      failureCount: 0,
      skipped: true,
      inboxCount,
    };
  }

  const tokenRows = await listTokensForPlayers(targets, opts.category);
  const pushResult = await sendToTokenRows(tokenRows, {
    title: opts.title,
    body: opts.body,
    data: opts.data,
  });
  return { ...pushResult, inboxCount };
}

async function sendMarketingBlast(opts) {
  const data = { type: 'marketing', ...(opts.data || {}) };
  const hasExplicitIds = Array.isArray(opts.playerIds);
  const hasAudienceFilters = Boolean(opts.audienceFilters);

  let targeted;
  if (hasExplicitIds) {
    targeted = [
      ...new Set(
        opts.playerIds
          .filter((id) => typeof id === 'string' && id.trim())
          .map((id) => id.trim()),
      ),
    ];
  } else if (hasAudienceFilters) {
    targeted = await listMarketingBlastAudience(opts.audienceFilters);
  } else {
    targeted = await listPlayerIdsWithNotifyPref('marketing');
  }

  let inboxCount = 0;
  if (targeted.length) {
    try {
      inboxCount = await insertPlayerNotifications({
        playerIds: targeted,
        type: 'marketing',
        category: 'marketing',
        title: opts.title,
        body: opts.body,
        data,
      });
    } catch (error) {
      console.error('[fcm] marketing inbox insert failed', error);
    }
  }

  if (!_ready) {
    return {
      successCount: 0,
      failureCount: 0,
      skipped: true,
      inboxCount,
      audienceCount: targeted.length,
    };
  }

  if (!targeted.length) {
    return {
      successCount: 0,
      failureCount: 0,
      inboxCount: 0,
      skipped: true,
      audienceCount: 0,
      reason: 'empty_audience',
    };
  }

  const tokenRows =
    hasExplicitIds || hasAudienceFilters
      ? await listTokensForPlayers(targeted, 'marketing')
      : await listMarketingTokens();

  const pushResult = await sendToTokenRows(tokenRows, {
    title: opts.title,
    body: opts.body,
    data,
  });
  return { ...pushResult, inboxCount, audienceCount: targeted.length };
}

module.exports = {
  initFcm,
  isFcmReady,
  sendToPlayers,
  sendMarketingBlast,
};
