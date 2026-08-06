import crypto from 'node:crypto';

export class RematchSession {
  constructor({
    mode,
    roomCode = null,
    stake = 100,
    expectedPlayers,
    eligiblePlayerIds,
    matchesPlayed = 0,
  }) {
    this.id = `rm_${crypto.randomBytes(6).toString('hex')}`;
    this.mode = mode;
    this.roomCode = roomCode;
    this.stake = stake;
    this.expectedPlayers = expectedPlayers;
    this.eligiblePlayerIds = new Set(eligiblePlayerIds);
    this.matchesPlayed = matchesPlayed;
    /** @type {Map<string, {playerId:string, connectionId:string, name:string, ready:boolean}>} */
    this.members = new Map();
    this.closed = false;
    this._idleTimer = null;
  }

  bumpMatchesPlayed() {
    this.matchesPlayed += 1;
  }

  refreshEligible(ids, expected) {
    this.eligiblePlayerIds = new Set(ids);
    this.expectedPlayers = expected;
  }

  join({ playerId, connectionId, displayName }) {
    if (!this.eligiblePlayerIds.has(playerId)) throw new Error('ineligible');
    this.members.set(playerId, {
      playerId,
      connectionId,
      name: displayName ?? 'Player',
      ready: false,
    });
  }

  setReady(playerId, ready) {
    const m = this.members.get(playerId);
    if (!m) throw new Error('not_joined');
    m.ready = ready;
  }

  leave(playerId) {
    this.members.delete(playerId);
  }

  allReady() {
    if (this.members.size < this.expectedPlayers) return false;
    return [...this.members.values()].every((m) => m.ready);
  }

  toWireState() {
    return {
      rematchId: this.id,
      mode: this.mode,
      roomCode: this.roomCode,
      matchesPlayed: this.matchesPlayed,
      expectedPlayers: this.expectedPlayers,
      members: [...this.members.values()].map((m) => ({
        playerId: m.playerId,
        name: m.name,
        ready: m.ready,
      })),
      stake: this.stake,
      closed: this.closed,
    };
  }

  scheduleIdle(onIdle, ms = 120000) {
    if (this._idleTimer) clearTimeout(this._idleTimer);
    this._idleTimer = setTimeout(() => onIdle(this), ms);
  }

  dissolve() {
    this.closed = true;
    if (this._idleTimer) clearTimeout(this._idleTimer);
  }
}
