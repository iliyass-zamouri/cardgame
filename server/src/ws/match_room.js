import {
  cardValue,
  gameValue,
  topDiscardValue,
  valuesMatch,
  allRevealEnded,
} from '../domain/card_rules.js';

const SUITS = ['A', 'B', 'C', 'D'];
const REVEAL_MS = 5000;

export function generateDeck() {
  const deck = [];
  for (const suit of SUITS) {
    for (let v = 1; v <= 13; v += 1) {
      deck.push(`${suit}${v}`);
    }
  }
  for (let i = deck.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    [deck[i], deck[j]] = [deck[j], deck[i]];
  }
  return deck;
}

export class MatchRoom {
  constructor(opts) {
    this.matchId = opts.matchId;
    this.stake = opts.stake ?? 100;
    this.mode = opts.mode ?? 'quick';
    this.roomCode = opts.roomCode ?? null;
    this.rematchId = opts.rematchId ?? null;
    this.matchesPlayed = opts.matchesPlayed ?? 0;
    this._send = opts.send;
    this._onFinished = opts.onFinished;
    this._onClosed = opts.onClosed;
    this.phase = 'dealing';
    this.closed = false;
    this.revealSecondsLeft = 0;
    this._revealTimer = null;

    this.participants = opts.players.map((p, index) => ({
      playerId: p.playerId,
      connectionId: p.connectionId,
      displayName: p.displayName ?? `Player ${index + 1}`,
      cards: [],
      handCard: null,
      total: 0,
      turn: false,
      launchReveal: 'NOT_LAUNCHED',
    }));

    this.deck = generateDeck();
    this.throwedCards = [];
    this.currentPlayerIndex = 0;
    this._deal();
  }

  get connectionIds() {
    return this.participants.map((p) => p.connectionId);
  }

  _deal() {
    for (let round = 0; round < 4; round += 1) {
      for (const p of this.participants) {
        p.cards.push({
          tag: this.deck.pop(),
          isThrown: false,
          cardSeen: false,
          isCardShown: false,
        });
      }
    }
    for (const p of this.participants) {
      p.handCard = null;
      p.launchReveal = 'NOT_LAUNCHED';
      p.turn = false;
      p.total = 0;
    }
    const starter = this.deck.pop();
    if (starter) this.throwedCards.push(starter);

    this.phase = 'reveal';
    this.currentPlayerIndex = Math.floor(Math.random() * this.participants.length);
    this.revealSecondsLeft = Math.ceil(REVEAL_MS / 1000);
    this._startRevealTimer();
    this.broadcastSnapshot();
  }

  _startRevealTimer() {
    if (this._revealTimer) clearInterval(this._revealTimer);
    this._revealTimer = setInterval(() => {
      if (this.phase !== 'reveal') {
        clearInterval(this._revealTimer);
        this._revealTimer = null;
        return;
      }
      this.revealSecondsLeft -= 1;
      if (this.revealSecondsLeft <= 0) {
        this._forceRevealEnd();
        clearInterval(this._revealTimer);
        this._revealTimer = null;
        return;
      }
      this.broadcastSnapshot();
    }, 1000);
  }

  _forceRevealEnd() {
    for (const p of this.participants) {
      if (p.launchReveal !== 'ENDED') {
        if (p.cards[2]) {
          p.cards[2].isCardShown = false;
          p.cards[2].cardSeen = true;
        }
        if (p.cards[3]) {
          p.cards[3].isCardShown = false;
          p.cards[3].cardSeen = true;
        }
        p.launchReveal = 'ENDED';
      }
    }
    this._beginPlaying();
    this.broadcastSnapshot();
  }

  _beginPlaying() {
    this.phase = 'playing';
    for (const p of this.participants) p.turn = false;
    this.participants[this.currentPlayerIndex].turn = true;
    this.revealSecondsLeft = 0;
  }

  _actor(connectionId) {
    return this.participants.find((p) => p.connectionId === connectionId);
  }

  _topTag() {
    if (!this.throwedCards.length) return null;
    const top = this.throwedCards[this.throwedCards.length - 1];
    return typeof top === 'string' ? top : top.tag;
  }

  _drawPenalty(actor) {
    if (!this.deck.length) this._restock();
    const tag = this.deck.pop();
    if (tag) {
      actor.cards.push({
        tag,
        isThrown: false,
        cardSeen: false,
        isCardShown: false,
      });
    }
  }

  _nextTurn() {
    const actor = this.participants[this.currentPlayerIndex];
    actor.turn = false;
    actor.endTurn?.();
    this._cleanThrownPairs(actor);
    this.currentPlayerIndex =
      (this.currentPlayerIndex + 1) % this.participants.length;
    this.participants[this.currentPlayerIndex].turn = true;
  }

  _cleanThrownPairs(actor) {
    if (actor.cards.length >= 2 && actor.cards[0].isThrown && actor.cards[1].isThrown) {
      actor.cards.splice(0, 2);
    }
    if (actor.cards.length >= 4 && actor.cards[2].isThrown && actor.cards[3].isThrown) {
      actor.cards.splice(2, 2);
    }
  }

  broadcastSnapshot() {
    for (const p of this.participants) {
      const payload = this.toSnapshot(p.playerId);
      this._send(
        p.connectionId,
        JSON.stringify({ event: 'match.snapshot', payload }),
      );
    }
  }

  toSnapshot(localPlayerId) {
    const local = this.participants.find((p) => p.playerId === localPlayerId);
    const top = topDiscardValue(this.throwedCards);
    const canAct =
      this.phase === 'playing' &&
      local?.turn === true &&
      local?.launchReveal === 'ENDED';

    return {
      matchId: this.matchId,
      phase: this.phase,
      localPlayerId,
      players: this.participants.map((p) => ({
        id: p.playerId,
        displayName: p.displayName,
        cards: p.cards.map((c) => ({
          tag: c.tag,
          isThrown: c.isThrown,
          cardSeen: c.cardSeen,
          isCardShown:
            p.playerId === localPlayerId
              ? c.isCardShown
              : c.isCardShown || c.isThrown || c.cardSeen,
        })),
        handCard: p.handCard
          ? {
              tag:
                p.playerId === localPlayerId || this.phase === 'result'
                  ? p.handCard.tag
                  : 'XX',
              isThrown: false,
              cardSeen: true,
              isCardShown: p.playerId === localPlayerId,
            }
          : null,
        total: p.total,
        turn: p.turn,
        launchReveal: p.launchReveal,
      })),
      deck: this.deck.map(() => 'XX'),
      throwedCards: this.throwedCards.map((t) => (typeof t === 'string' ? t : t.tag)),
      currentPlayerId: this.participants[this.currentPlayerIndex]?.playerId ?? '',
      topDiscardValue: top,
      canAct,
      revealSecondsLeft: this.revealSecondsLeft,
      rematchId: this.rematchId,
      matchesPlayed: this.matchesPlayed,
      stake: this.stake,
      outcome: this.outcome ?? null,
      winnerId: this.winnerId ?? null,
    };
  }

  handleAction(connectionId, payload) {
    if (this.closed || this.phase === 'result') return;
    const actor = this._actor(connectionId);
    if (!actor) return;

    const type = payload.type;

    if (type === 'launch') {
      if (this.phase !== 'reveal') return;
      if (actor.launchReveal === 'NOT_LAUNCHED') {
        actor.launchReveal = 'LAUNCHED';
        if (actor.cards[2]) actor.cards[2].isCardShown = true;
        if (actor.cards[3]) actor.cards[3].isCardShown = true;
        setTimeout(() => {
          if (this.closed || actor.launchReveal !== 'LAUNCHED') return;
          if (actor.cards[2]) {
            actor.cards[2].isCardShown = false;
            actor.cards[2].cardSeen = true;
          }
          if (actor.cards[3]) {
            actor.cards[3].isCardShown = false;
            actor.cards[3].cardSeen = true;
          }
          actor.launchReveal = 'ENDED';
          if (allRevealEnded(this.participants)) {
            if (this._revealTimer) {
              clearInterval(this._revealTimer);
              this._revealTimer = null;
            }
            this._beginPlaying();
          }
          this.broadcastSnapshot();
        }, REVEAL_MS);
      }
      this.broadcastSnapshot();
      return;
    }

    if (this.phase !== 'playing') return;
    if (!actor.turn) return;

    switch (type) {
      case 'draw': {
        if (actor.handCard) return;
        if (!this.deck.length) this._restock();
        const tag = this.deck.pop();
        if (!tag) return;
        actor.handCard = {
          tag,
          isThrown: false,
          cardSeen: true,
          isCardShown: true,
        };
        this.broadcastSnapshot();
        return;
      }
      case 'throw': {
        const topTag = this._topTag();
        if (!topTag) return;

        if (payload.hand && actor.handCard) {
          const tableCard = actor.cards.find(
            (c) => c.tag === payload.card && !c.isThrown,
          );
          if (!tableCard) return;
          const handMatches = valuesMatch(actor.handCard.tag, topTag);
          const tableMatches = valuesMatch(tableCard.tag, topTag);
          if (handMatches && tableMatches) {
            tableCard.isThrown = true;
            this.throwedCards.push(tableCard.tag);
            this.throwedCards.push(actor.handCard.tag);
            actor.handCard = null;
            this._nextTurn();
          } else if (tableMatches) {
            tableCard.isThrown = true;
            this.throwedCards.push(tableCard.tag);
            this._nextTurn();
          } else {
            this._drawPenalty(actor);
            this._nextTurn();
          }
        } else if (payload.card) {
          const card = actor.cards.find((c) => c.tag === payload.card && !c.isThrown);
          if (!card) return;
          if (actor.handCard) {
            if (valuesMatch(card.tag, actor.handCard.tag)) {
              card.isThrown = true;
              this.throwedCards.push(card.tag);
              this.throwedCards.push(actor.handCard.tag);
              actor.handCard = null;
              this._nextTurn();
            } else {
              this.throwedCards.push(card.tag);
              actor.cards[actor.cards.indexOf(card)] = {
                tag: actor.handCard.tag,
                isThrown: false,
                cardSeen: true,
                isCardShown: false,
              };
              actor.handCard = null;
              this._nextTurn();
            }
          } else if (valuesMatch(card.tag, topTag)) {
            card.isThrown = true;
            this.throwedCards.push(card.tag);
            this._nextTurn();
          } else {
            this._drawPenalty(actor);
            this._nextTurn();
          }
        }
        break;
      }
      case 'end': {
        this._endGame();
        return;
      }
      default:
        return;
    }
    this.broadcastSnapshot();
  }

  _restock() {
    if (!this.throwedCards.length) return;
    const last = this.throwedCards.pop();
    this.deck = this.throwedCards.map((t) => (typeof t === 'string' ? t : t.tag));
    this.throwedCards = [last];
    for (let i = this.deck.length - 1; i > 0; i -= 1) {
      const j = Math.floor(Math.random() * (i + 1));
      [this.deck[i], this.deck[j]] = [this.deck[j], this.deck[i]];
    }
  }

  _endGame() {
    for (const p of this.participants) {
      p.total = p.cards
        .filter((c) => !c.isThrown)
        .reduce((sum, c) => sum + gameValue(c.tag), 0);
      if (p.handCard) p.total += gameValue(p.handCard.tag);
    }
    const sorted = [...this.participants].sort((a, b) => a.total - b.total);
    if (sorted[0].total === sorted[1].total) {
      this.outcome = 'draw';
      this.winnerId = null;
    } else {
      this.outcome = 'win';
      this.winnerId = sorted[0].playerId;
    }
    this.phase = 'result';
    if (this._revealTimer) clearInterval(this._revealTimer);
    this.broadcastSnapshot();
    this._onFinished({
      matchId: this.matchId,
      outcome: this.outcome,
      winnerId: this.winnerId,
      participants: this.participants.map((p) => ({
        playerId: p.playerId,
        score: p.total,
      })),
      stake: this.stake,
    });
  }

  rebind(playerId, connectionId) {
    const p = this.participants.find((x) => x.playerId === playerId);
    if (!p) return false;
    p.connectionId = connectionId;
    this._send(
      connectionId,
      JSON.stringify({
        event: 'match.found',
        payload: {
          matchId: this.matchId,
          localPlayerId: playerId,
          players: this.participants.map((x) => ({
            id: x.playerId,
            displayName: x.displayName,
          })),
          rematchId: this.rematchId,
          matchesPlayed: this.matchesPlayed,
          mode: this.mode,
          roomCode: this.roomCode,
          stake: this.stake,
        },
      }),
    );
    this.broadcastSnapshot();
    return true;
  }

  close() {
    if (this.closed) return;
    this.closed = true;
    if (this._revealTimer) clearInterval(this._revealTimer);
    this._onClosed(this.matchId);
  }
}
