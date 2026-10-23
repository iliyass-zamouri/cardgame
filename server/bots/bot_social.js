const { stableHash } = require('./bot_personality');

const MINUTE = 60 * 1000;
const HOUR = 60 * MINUTE;

// Rough UTC offsets (hours) for quiet hours; unknown countries use UTC.
const COUNTRY_UTC_OFFSET = {
  MA: 1, DZ: 1, TN: 1, EG: 2, SA: 3, AE: 4, TR: 3, FR: 1, ES: 1, PT: 0, GB: 0,
  DE: 1, IT: 1, NL: 1, BE: 1, CH: 1, SE: 1, PL: 1, UA: 2, RU: 3, IN: 5.5,
  PK: 5, ID: 7, CN: 8, JP: 9, KR: 9, AU: 10, NZ: 12, ZA: 2, NG: 1, KE: 3,
  US: -5, CA: -5, MX: -6, BR: -3, AR: -3, CL: -4, CO: -5, PE: -5,
};

const DEFAULTS = {
  enabled: true,
  tickMs: MINUTE,
  // Online, idle humans: chance per tick that a bot reaches out.
  idleReachChance: 0.03,
  idleMinMs: 2 * MINUTE,
  // Offline humans (push): candidates looked at per tick, and act chance each.
  offlinePerTick: 2,
  offlineReachChance: 0.15,
  // Caps per human.
  minGapMs: 3 * HOUR,
  friendRequestsPerDay: 1,
  maxPendingBotRequests: 3,
  invitesPerDayOnline: 2,
  invitesPerDayOffline: 1,
  // Bot presence: share of hour slots a bot looks online.
  onlineShare: 0.35,
  inviteTtlOnlineMs: 10 * MINUTE,
  inviteTtlOfflineMs: 30 * MINUTE,
};

/**
 * Decides when bots befriend, accept and invite real players. Everything it
 * touches (DB, sockets, push, rooms) comes in through [deps], so it can run
 * with fakes in tests.
 */
class BotSocialDirector {
  constructor(deps, options = {}) {
    this.deps = deps;
    this.options = { ...DEFAULTS, ...options };
    this.random = deps.random || Math.random;
    this.now = deps.now || Date.now;
    this.timers = new Set();
    this.disposed = false;
    this.botCache = null;
    this.botCacheAt = 0;
    this.ticking = false;
  }

  dispose() {
    this.disposed = true;
    for (const timer of this.timers) clearTimeout(timer);
    this.timers.clear();
  }

  // ---------------------------------------------------------------- presence

  /** Bots in a match or hosting a room, plus a stable "online hours" schedule. */
  isBotOnline(botId) {
    if (this.deps.busyBotIds().has(botId)) return true;
    const slot = Math.floor(this.now() / HOUR);
    return stableHash(`${botId}:${slot}`) % 100 < this.options.onlineShare * 100;
  }

  async onlineBotIds() {
    const bots = await this.#bots();
    return new Set(bots.filter((bot) => this.isBotOnline(bot.playerId)).map((b) => b.playerId));
  }

  // ------------------------------------------------------------ event hooks

  /** A human sent a friend request to a bot: accept like a person would. */
  onFriendRequestToBot({ botId, requesterId }) {
    // Mostly within a minute; the rest is picked up by the tick a bit later.
    if (this.random() >= 0.9) return;
    this.#schedule(5_000 + this.random() * 55_000, () =>
      this.deps.acceptBotFriendRequest({ botId, requesterId }),
    );
  }

  /** A bot match finished: maybe ask the opponent to be friends. */
  onBotMatchEnded({ botId, humanId, scoreGap, gamesPlayed }) {
    if (!this.options.enabled) return;
    let chance = 0.15;
    if (scoreGap != null && Math.abs(scoreGap) <= 3) chance += 0.15;
    if (gamesPlayed > 1) chance += 0.1;
    if (this.random() >= chance) return;
    this.#schedule(10_000 + this.random() * 80_000, () =>
      this.#tryFriendRequest({ botId, humanId, offline: false }),
    );
  }

  /** A human invited a bot friend to their table: join if "around". */
  onHumanInvitedBot({ botId, humanId, roomId }) {
    if (!this.isBotOnline(botId) || this.deps.busyBotIds().has(botId)) return;
    this.#schedule(3_000 + this.random() * 7_000, () =>
      this.deps.joinHumanRoom({ botId, humanId, roomId }),
    );
  }

  // ------------------------------------------------------------------ tick

  async tick() {
    if (this.disposed || this.ticking) return;
    this.ticking = true;
    try {
      await this.#acceptOverdueRequests();
      if (!this.options.enabled) return;
      await this.#reachIdleHumans();
      await this.#reachOfflineHumans();
    } catch (error) {
      console.error('[bot social] tick', error);
    } finally {
      this.ticking = false;
    }
  }

  async #acceptOverdueRequests() {
    const overdue = await this.deps.listPendingRequestsToBots(3 * MINUTE);
    for (const request of overdue) {
      await this.deps.acceptBotFriendRequest({
        botId: request.botId,
        requesterId: request.requesterId,
      });
    }
  }

  async #reachIdleHumans() {
    const idle = this.deps
      .idleHumans()
      .filter((human) => human.idleForMs >= this.options.idleMinMs);
    for (const human of idle) {
      if (this.random() >= this.options.idleReachChance) continue;
      await this.#reachOut(human.playerId, { offline: false });
    }
  }

  async #reachOfflineHumans() {
    const online = this.deps.onlineHumanIds();
    const targets = await this.deps.listOfflineTargets({
      limit: this.options.offlinePerTick,
      excludeIds: [...online],
    });
    for (const target of targets) {
      if (this.random() >= this.options.offlineReachChance) continue;
      await this.#reachOut(target.playerId, { offline: true });
    }
  }

  /** Pick between a private-match invite and a friend request for one human. */
  async #reachOut(humanId, { offline }) {
    const friendBots = await this.deps.listBotFriendIds(humanId);
    const available = friendBots.filter(
      (id) => !this.deps.busyBotIds().has(id) && (offline || this.isBotOnline(id)),
    );
    const preferInvite = available.length > 0 ? 0.7 : 0.4;
    if (this.random() < preferInvite) {
      const botId = available.length > 0
        ? available[Math.floor(this.random() * available.length)]
        : await this.#strangerBot(humanId, { forInvite: true });
      if (botId) await this.#tryInvite({ botId, humanId, offline });
      return;
    }
    const botId = await this.#strangerBot(humanId, { forInvite: false });
    if (botId) await this.#tryFriendRequest({ botId, humanId, offline });
  }

  async #strangerBot(humanId, { forInvite }) {
    const bots = (await this.#bots()).filter(
      (bot) => !this.deps.busyBotIds().has(bot.playerId) && this.isBotOnline(bot.playerId),
    );
    // A few random tries is plenty; each costs one query.
    for (let i = 0; i < 4 && bots.length > 0; i += 1) {
      const bot = bots.splice(Math.floor(this.random() * bots.length), 1)[0];
      const relation = await this.deps.relationStatus(bot.playerId, humanId);
      if (relation === 'none' || (forInvite && relation === 'friends')) return bot.playerId;
    }
    return null;
  }

  // ------------------------------------------------------------- actions

  async #tryFriendRequest({ botId, humanId, offline }) {
    if (!(await this.#allowed(humanId, 'friendRequest', { offline }))) return false;
    const relation = await this.deps.relationStatus(botId, humanId);
    if (relation !== 'none') return false;
    const summary = await this.deps.outreachSummary(humanId);
    // Never ask the same person twice within 30 days.
    if (summary.askedByBots.has(botId)) return false;
    await this.deps.sendBotFriendRequest({ botId, humanId });
    await this.deps.recordOutreach({ playerId: humanId, botId, kind: 'friendRequest' });
    return true;
  }

  async #tryInvite({ botId, humanId, offline }) {
    if (!(await this.#allowed(humanId, 'invite', { offline }))) return false;
    if ((await this.deps.relationStatus(botId, humanId)) === 'blocked') return false;
    const hosted = await this.deps.hostInvite({
      botId,
      humanId,
      ttlMs: offline ? this.options.inviteTtlOfflineMs : this.options.inviteTtlOnlineMs,
    });
    if (!hosted) return false;
    await this.deps.recordOutreach({ playerId: humanId, botId, kind: 'invite' });
    return true;
  }

  /** Caps, spacing, eligibility, busy state and quiet hours. */
  async #allowed(humanId, kind, { offline }) {
    if (!offline && this.deps.isHumanBusy(humanId)) return false;
    const profile = (await this.deps.loadHumanProfiles([humanId])).get(humanId);
    if (!profile || profile.isBot || !profile.eligible) return false;
    if (offline && this.#quietHours(profile.countryCode)) return false;

    const summary = await this.deps.outreachSummary(humanId);
    if (summary.lastAt != null && this.now() - summary.lastAt < this.options.minGapMs) {
      return false;
    }
    if (kind === 'friendRequest') {
      if (summary.friendRequestsToday >= this.options.friendRequestsPerDay) return false;
      const pending = await this.deps.pendingBotRequestCount(humanId);
      if (pending >= this.options.maxPendingBotRequests) return false;
    } else {
      const cap = offline ? this.options.invitesPerDayOffline : this.options.invitesPerDayOnline;
      if (summary.invitesToday >= cap) return false;
    }
    return true;
  }

  #quietHours(countryCode) {
    const offset = COUNTRY_UTC_OFFSET[countryCode] ?? 0;
    const utcHours = new Date(this.now()).getUTCHours() + new Date(this.now()).getUTCMinutes() / 60;
    const local = (utcHours + offset + 24) % 24;
    return local >= 23 || local < 9;
  }

  async #bots() {
    if (!this.botCache || this.now() - this.botCacheAt > 10 * MINUTE) {
      this.botCache = await this.deps.listBotUsers();
      this.botCacheAt = this.now();
    }
    return [...this.botCache];
  }

  #schedule(delayMs, callback) {
    if (this.disposed) return;
    const timer = setTimeout(() => {
      this.timers.delete(timer);
      if (this.disposed) return;
      Promise.resolve()
        .then(callback)
        .catch((error) => console.error('[bot social]', error));
    }, delayMs);
    timer.unref?.();
    this.timers.add(timer);
  }
}

module.exports = { BotSocialDirector, COUNTRY_UTC_OFFSET };
