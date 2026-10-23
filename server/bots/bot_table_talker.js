const { replyTo, reactTo, isAllowed } = require('./bot_brain');
const { personalityFor } = require('./bot_personality');

function gameValue(tag) {
  const value = Number(String(tag).slice(1));
  if (value === 14) return -1;
  if (value === 13 && (tag[0] === 'A' || tag[0] === 'D')) return 0;
  return value;
}

function handTotal(cards) {
  return (cards || []).reduce((sum, tag) => sum + gameValue(tag), 0);
}

// A discarded own card this heavy means the bot just improved its hand.
const GOOD_SWAP_DISCARD_VALUE = 8;

/**
 * Chat behaviour of one bot seat: always answers the human (after a
 * human-like typing delay) and comments on table events now and then.
 */
class BotTableTalker {
  constructor({
    room,
    botClientId,
    botPlayerId,
    send,
    random = Math.random,
    now = Date.now,
    proactiveGapMs = 15_000,
    maxProactivePerGame = 6,
  }) {
    this.room = room;
    this.botClientId = botClientId;
    this.personality = personalityFor(botPlayerId);
    this.send = send;
    this.random = random;
    this.now = now;
    this.proactiveGapMs = proactiveGapMs;
    this.maxProactivePerGame = maxProactivePerGame;

    this.timers = new Set();
    this.disposed = false;
    this.pendingMessage = null;
    this.replyTimer = null;
    this.lastStatus = room.status;
    this.lastAction = room.lastAction;
    this.lastProactiveAt = 0;
    this.proactiveThisGame = 0;
  }

  dispose() {
    this.disposed = true;
    for (const timer of this.timers) clearTimeout(timer);
    this.timers.clear();
    this.replyTimer = null;
  }

  /** A human said something at the table. Several quick messages get one answer. */
  onHumanMessage(message) {
    if (this.disposed) return;
    this.pendingMessage = message;
    if (this.replyTimer) return;
    this.replyTimer = this.#schedule(this.#typingDelay(), () => {
      this.replyTimer = null;
      const latest = this.pendingMessage;
      this.pendingMessage = null;
      this.#emit(replyTo(latest, this.#context()));
    });
  }

  onRoomChanged() {
    if (this.disposed) return;
    const room = this.room;
    const events = [];

    if (room.status !== this.lastStatus) {
      if (room.status === 'playing') {
        this.proactiveThisGame = 0;
        events.push('start');
      } else if (room.status === 'ended') {
        const outcome = this.#outcomeEvent();
        if (outcome) events.push(outcome);
      }
      this.lastStatus = room.status;
    }

    if (room.lastAction && room.lastAction !== this.lastAction) {
      const event = this.#actionEvent(room.lastAction);
      if (event) events.push(event);
    }
    this.lastAction = room.lastAction;

    // Result reactions always get a chance; mid-game chatter is rate limited.
    const event = events.find((e) => ['won', 'lost', 'tie'].includes(e)) || events[0];
    if (!event) return;
    const isOutcome = ['won', 'lost', 'tie'].includes(event);
    if (!isOutcome) {
      if (this.proactiveThisGame >= this.maxProactivePerGame) return;
      if (this.now() - this.lastProactiveAt < this.proactiveGapMs) return;
    }
    if (this.replyTimer) return;
    const reply = reactTo(event, this.#context());
    if (!reply) return;
    this.lastProactiveAt = this.now();
    this.proactiveThisGame += 1;
    this.#schedule(800 + Math.floor(this.random() * 1700), () => this.#emit(reply));
  }

  #outcomeEvent() {
    const result = this.room.result;
    if (!result) return null;
    // Opponent quit or dropped: nobody left to talk to.
    if (result.quitterIndex != null && result.quitterIndex !== this.#botIndex) return null;
    if (result.winnerIndex == null) return 'tie';
    return result.winnerIndex === this.#botIndex ? 'won' : 'lost';
  }

  #actionEvent(action) {
    const byBot = action.playerId === this.botClientId;
    switch (action.type) {
      case 'jackPeek':
        if (byBot) return 'myPeek';
        return action.side === 'opponent' ? 'peekedMe' : null;
      case 'queenReplace':
        return byBot ? null : 'swappedMe';
      case 'queenShuffle':
        return !byBot && action.side === 'opponent' ? 'shuffledMe' : null;
      case 'penaltyDraw':
        return byBot ? null : 'opponentPenalty';
      case 'discardMatch':
        return byBot ? null : 'opponentMatch';
      case 'doubleDiscard':
        return byBot ? null : 'opponentDouble';
      case 'swap':
        return byBot && action.cardTag && gameValue(action.cardTag) >= GOOD_SWAP_DISCARD_VALUE
          ? 'myGoodSwap'
          : null;
      default:
        return null;
    }
  }

  get #botIndex() {
    return this.room.players.findIndex((p) => p.id === this.botClientId);
  }

  #context() {
    const room = this.room;
    const botIndex = this.#botIndex;
    let mood = null;
    if (room.status === 'playing' && botIndex >= 0 && room.players.length === 2) {
      const mine = handTotal(room.players[botIndex].cards);
      const theirs = handTotal(room.players[1 - botIndex].cards);
      mood = mine < theirs - 3 ? 'ahead' : mine > theirs + 3 ? 'behind' : 'even';
    }
    const winnerIndex = room.result?.winnerIndex;
    return {
      personality: this.personality,
      random: this.random,
      phase: room.status,
      mood,
      botWon:
        room.status === 'ended' && winnerIndex != null ? winnerIndex === botIndex : null,
    };
  }

  #typingDelay() {
    const [min, max] = this.personality.typingMs;
    return min + Math.floor(this.random() * (max - min));
  }

  #emit(reply) {
    if (this.disposed || !isAllowed(reply)) return;
    this.send(reply);
  }

  #schedule(delayMs, callback) {
    const timer = setTimeout(() => {
      this.timers.delete(timer);
      if (!this.disposed) callback();
    }, delayMs);
    timer.unref?.();
    this.timers.add(timer);
    return timer;
  }
}

module.exports = { BotTableTalker, handTotal };
