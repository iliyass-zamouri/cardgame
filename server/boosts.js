// Coin Boost presets, inventory and activation rules. A claimed boost waits
// in the player's inventory until they activate it. Only one boost value
// (percent) runs at a time: the same value adds its time to the running
// boost, a different value waits until the running one ends. These functions
// are pure. server/db/boosts.js applies them.

const TIERS = ['bronze', 'silver', 'gold', 'diamond'];
const MAX_PRESETS = 8;
const FALLBACK_NAME = Object.freeze({ en: 'Coin Boost' });

function ceilSeconds(untilMs, nowMs) {
  return Math.max(0, Math.ceil((untilMs - nowMs) / 1000));
}

/** The preset with `presetId`, otherwise null. */
function findPreset(presets, presetId) {
  return presets.find((preset) => preset.id === presetId) ?? null;
}

/**
 * The running boost from a `player_boosters` coin_boost row, or null when none
 * runs. A row written before presets existed has no percent: it runs at the
 * first preset, which the legacy config upgrade made from the old global value.
 */
function activeBoostFromRow(row, presets, nowMs) {
  const untilMs = Number(row?.active_until_ms) || 0;
  if (untilMs <= nowMs) return null;
  const legacy = row.percent == null;
  const preset = legacy ? presets[0] : findPreset(presets, row.preset_id);
  return {
    presetId: legacy ? presets[0].id : row.preset_id,
    percent: legacy ? presets[0].percent : Number(row.percent),
    maxBonus: legacy ? presets[0].maxBonus : Number(row.max_bonus),
    tier: preset?.tier ?? 'silver',
    // When this run started, so the app can show how much is left of it.
    fromMs: Number(row.active_from_ms) || null,
    untilMs,
  };
}

/**
 * What activating `item` does while `active` runs (null when nothing runs).
 * Returns { action: 'start' | 'extend', untilMs } or { action: 'conflict', active }.
 */
function activationDecision(active, item, nowMs) {
  const running = active && active.untilMs > nowMs ? active : null;
  if (running && running.percent !== item.percent) return { action: 'conflict', active: running };
  const from = running ? running.untilMs : nowMs;
  return { action: running ? 'extend' : 'start', untilMs: from + item.minutes * 60_000 };
}

/** The display fields of a preset, for the app and the admin. */
function presetView(preset) {
  return {
    id: preset.id,
    name: preset.name,
    percent: preset.percent,
    maxBonus: preset.maxBonus,
    tier: preset.tier,
  };
}

function activeView(active, presets, nowMs) {
  if (!active) return null;
  const preset = findPreset(presets, active.presetId);
  return {
    presetId: active.presetId,
    name: preset?.name ?? FALLBACK_NAME,
    percent: active.percent,
    maxBonus: active.maxBonus,
    tier: active.tier,
    remainingSeconds: ceilSeconds(active.untilMs, nowMs),
    totalSeconds: active.fromMs ? ceilSeconds(active.untilMs, active.fromMs) : null,
  };
}

/**
 * The payload for GET /boosts. `items` are `player_boost_items` rows, oldest
 * first. Items are grouped by value. Each group lists its items so the app can
 * activate one at a time, and says whether the running boost blocks it.
 */
function boostView({ active, items, presets, nowMs }) {
  const groups = new Map();
  for (const row of items) {
    const percent = Number(row.percent);
    let group = groups.get(percent);
    if (!group) {
      const preset = findPreset(presets, row.preset_id);
      group = {
        presetId: row.preset_id,
        name: preset?.name ?? FALLBACK_NAME,
        percent,
        maxBonus: Number(row.max_bonus),
        tier: preset?.tier ?? 'silver',
        blocked: Boolean(active) && active.percent !== percent,
        items: [],
      };
      groups.set(percent, group);
    }
    group.items.push({ id: row.id, minutes: Number(row.minutes) });
  }
  return {
    active: activeView(active, presets, nowMs),
    inventory: [...groups.values()].sort((a, b) => b.percent - a.percent),
    presets: presets.map(presetView),
  };
}

/** The boost a seat carries into a money match, or null. */
function seatBoost(active) {
  if (!active) return null;
  return {
    presetId: active.presetId,
    percent: active.percent,
    maxBonus: active.maxBonus,
    tier: active.tier,
  };
}

module.exports = {
  TIERS,
  MAX_PRESETS,
  findPreset,
  activeBoostFromRow,
  activationDecision,
  presetView,
  boostView,
  seatBoost,
};
