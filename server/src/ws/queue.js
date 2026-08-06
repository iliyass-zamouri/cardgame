export class MatchQueue {
  constructor(onMatch) {
    this._onMatch = onMatch;
    /** @type {Map<number, Array<object>>} stake → waiters */
    this._byStake = new Map();
  }

  enqueue(entry) {
    const stake = entry.stake ?? 100;
    const list = this._byStake.get(stake) ?? [];
    // replace existing same player
    const filtered = list.filter((e) => e.playerId !== entry.playerId);
    filtered.push(entry);
    this._byStake.set(stake, filtered);
    this._tryMatch(stake);
  }

  cancel(connectionId) {
    for (const [stake, list] of this._byStake.entries()) {
      this._byStake.set(
        stake,
        list.filter((e) => e.connectionId !== connectionId),
      );
    }
  }

  _tryMatch(stake) {
    const list = this._byStake.get(stake) ?? [];
    while (list.length >= 2) {
      const a = list.shift();
      const b = list.shift();
      this._onMatch({ stake, players: [a, b] });
    }
    this._byStake.set(stake, list);
  }
}
