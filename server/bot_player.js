const { GameRuleError } = require('./game_room');

function cardValue(tag) {
  return Number(tag.slice(1));
}

function gameValue(tag) {
  const value = cardValue(tag);
  if (value === 14) return -1;
  if (value === 13 && (tag[0] === 'A' || tag[0] === 'D')) return 0;
  return value;
}

class ServerRobotPlayer {
  constructor({
    room,
    clientId,
    thinkMinMs = 600,
    thinkMaxMs = 1200,
    launchDelayMs = 400,
    actionDelayMs = 800,
    rematchDelayMs = 1000,
    random = Math.random,
  }) {
    this.room = room;
    this.clientId = clientId;
    this.thinkMinMs = thinkMinMs;
    this.thinkMaxMs = thinkMaxMs;
    this.launchDelayMs = launchDelayMs;
    this.actionDelayMs = actionDelayMs;
    this.rematchDelayMs = rematchDelayMs;
    this.random = random;

    this.memory = new Map();
    this.disposed = false;
    this.turnScheduled = false;
    this.launchScheduled = false;
    this.rematchScheduled = false;
    this.timers = new Set();
  }

  dispose() {
    this.disposed = true;
    for (const timer of this.timers) {
      clearTimeout(timer);
    }
    this.timers.clear();
    this.memory.clear();
  }

  schedule(delayMs, callback) {
    if (this.disposed) return;
    const timer = setTimeout(() => {
      this.timers.delete(timer);
      if (this.disposed) return;
      callback();
    }, delayMs);
    this.timers.add(timer);
    return timer;
  }

  onRoomChanged() {
    if (this.disposed) return;
    const player = this.self;
    if (!player) return;

    if (this.room.status === 'playing' && player.launch === 'notLaunched') {
      if (!this.launchScheduled) {
        this.launchScheduled = true;
        this.schedule(this.launchDelayMs, () => {
          this.launchScheduled = false;
          if (this.disposed) return;
          try {
            this.room.launch(this.clientId);
          } catch (error) {
            if (!(error instanceof GameRuleError)) throw error;
          }
        });
      }
      return;
    }

    if (this.room.status === 'ended') {
      const isRematchReady = this.room.rematchReady[
        this.room.players.findIndex((p) => p.id === this.clientId)
      ];
      if (!isRematchReady && !this.rematchScheduled) {
        this.rematchScheduled = true;
        this.schedule(this.rematchDelayMs, () => {
          this.rematchScheduled = false;
          if (this.disposed) return;
          try {
            this.room.rematch(this.clientId);
          } catch (error) {
            if (!(error instanceof GameRuleError)) throw error;
          }
        });
      }
      return;
    }

    if (this.room.status !== 'playing') return;
    if (!this.bothLaunched) return;
    if (!this.isMyTurn) return;
    if (this.abilityLocked) return;
    if (player.handCard != null) return;
    if (this.turnScheduled) return;

    this.turnScheduled = true;
    this.schedule(this.thinkDelay(), () => {
      this.turnScheduled = false;
      if (this.disposed) return;
      this.takeTurn();
    });
  }

  thinkDelay() {
    const span = this.thinkMaxMs - this.thinkMinMs;
    const ms = this.thinkMinMs + (span <= 0 ? 0 : Math.floor(this.random() * (span + 1)));
    return ms;
  }

  takeTurn() {
    const player = this.self;
    if (!player) return;
    if (this.room.status !== 'playing' || !this.isMyTurn || !this.bothLaunched) return;
    if (this.abilityLocked) return;

    this.syncMemoryFromLaunch(player);

    try {
      if (player.handCard == null) {
        const matchIndex = this.findDiscardMatch(player);
        if (matchIndex != null) {
          this.room.tapCard(this.clientId, matchIndex);
          this.forgetIndex(matchIndex);
          return;
        }

        this.room.draw(this.clientId);
        this.schedule(this.actionDelayMs, () => {
          if (this.disposed) return;
          const afterDraw = this.self;
          if (!afterDraw || afterDraw.handCard == null) return;
          if (!this.isMyTurn || this.abilityLocked) return;
          try {
            this.playWithHand(afterDraw);
          } catch (error) {
            if (error instanceof GameRuleError) {
              this.fallback();
            } else {
              throw error;
            }
          }
        });
        return;
      }

      this.playWithHand(player);
    } catch (error) {
      if (error instanceof GameRuleError) {
        this.fallback();
      } else {
        throw error;
      }
    }
  }

  playWithHand(player) {
    const hand = player.handCard;
    if (!hand) return;
    const handVal = cardValue(hand);

    for (let i = 0; i < player.cards.length; i += 1) {
      if (cardValue(player.cards[i]) === handVal) {
        this.room.tapCard(this.clientId, i);
        this.forgetIndex(i);
        return;
      }
    }

    if (player.jackPeekAvailable && handVal === 11) {
      const peekIndex = this.bestPeekIndex(player);
      if (peekIndex != null) {
        this.room.jackPeek(this.clientId, { side: 'you', cardIndex: peekIndex });
        this.memory.set(peekIndex, player.cards[peekIndex]);
        return;
      }
    }

    if (player.queenAbilityAvailable && handVal === 12) {
      const ownWorst = this.worstKnownIndex(player);
      const opponent = this.opponent;
      if (
        ownWorst != null &&
        opponent &&
        opponent.cards.length > 0 &&
        gameValue(player.cards[ownWorst]) >= 8
      ) {
        const incoming = opponent.cards[0];
        this.room.queenReplace(this.clientId, { youIndex: ownWorst, opponentIndex: 0 });
        this.memory.set(ownWorst, incoming);
        return;
      }
      if (player.cards.length >= 2) {
        this.room.queenShuffle(this.clientId, { side: 'opponent' });
        return;
      }
    }

    const drawnScore = gameValue(hand);
    if (drawnScore <= 3) {
      this.room.throwHand(this.clientId);
      return;
    }

    const swapIndex = this.bestSwapTarget(player, drawnScore);
    if (swapIndex != null) {
      this.room.tapCard(this.clientId, swapIndex);
      this.memory.set(swapIndex, hand);
      return;
    }

    this.room.throwHand(this.clientId);
  }

  fallback() {
    const player = this.self;
    if (!player) return;
    try {
      if (player.handCard != null) {
        this.room.throwHand(this.clientId);
      } else {
        this.room.draw(this.clientId);
        if (this.self?.handCard != null) {
          this.room.throwHand(this.clientId);
        }
      }
    } catch {
      // Ignore fallback failure for this tick
    }
  }

  findDiscardMatch(player) {
    if (this.room.discard.length === 0) return null;
    const top = cardValue(this.room.discard[this.room.discard.length - 1]);
    for (let i = 0; i < player.cards.length; i += 1) {
      if (cardValue(player.cards[i]) === top) return i;
    }
    return null;
  }

  bestPeekIndex(player) {
    for (let i = player.cards.length - 1; i >= 0; i -= 1) {
      if (!this.memory.has(i)) return i;
    }
    return player.cards.length === 0 ? null : 0;
  }

  worstKnownIndex(player) {
    let bestIndex = null;
    let bestScore = -999;
    for (let i = 0; i < player.cards.length; i += 1) {
      const known = this.memory.get(i) ?? (i < 2 ? player.cards[i] : null);
      if (!known) continue;
      const score = gameValue(known);
      if (score > bestScore) {
        bestScore = score;
        bestIndex = i;
      }
    }
    return bestIndex ?? (player.cards.length === 0 ? null : player.cards.length - 1);
  }

  bestSwapTarget(player, drawnScore) {
    let bestIndex = null;
    let bestOutgoing = -999;
    for (let i = 0; i < player.cards.length; i += 1) {
      const known = this.memory.get(i) ?? player.cards[i];
      const outgoing = gameValue(known);
      if (outgoing > drawnScore && outgoing > bestOutgoing) {
        bestOutgoing = outgoing;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  syncMemoryFromLaunch(player) {
    if (player.cards.length >= 2) {
      if (!this.memory.has(0)) this.memory.set(0, player.cards[0]);
      if (!this.memory.has(1)) this.memory.set(1, player.cards[1]);
    }
  }

  forgetIndex(removedIndex) {
    const next = new Map();
    for (const [key, value] of this.memory.entries()) {
      if (key < removedIndex) {
        next.set(key, value);
      } else if (key > removedIndex) {
        next.set(key - 1, value);
      }
    }
    this.memory = next;
  }

  get self() {
    return this.room.players.find((player) => player.id === this.clientId) || null;
  }

  get opponent() {
    return this.room.players.find((player) => player.id !== this.clientId) || null;
  }

  get bothLaunched() {
    return this.room.players.every((player) => player.launch === 'ended');
  }

  get isMyTurn() {
    const index = this.room.players.findIndex((p) => p.id === this.clientId);
    return this.room.turnIndex != null && index === this.room.turnIndex;
  }

  get abilityLocked() {
    const player = this.self;
    if (!player || player.handCard == null) return false;
    const last = this.room.lastAction;
    if (!last) return false;
    const type = last.type;
    if (type === 'jackPeek' || type === 'queenShuffle' || type === 'queenReplace') {
      return !player.jackPeekAvailable && !player.queenAbilityAvailable;
    }
    return false;
  }
}

module.exports = {
  ServerRobotPlayer,
  cardValue,
  gameValue,
};
