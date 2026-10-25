const crypto = require('crypto');

/** Retry gap when a turn's clock runs out during a Jack/Queen lock. */
const LOCK_RETRY_MS = 1500;

class GameRuleError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

class GameRoom {
  /** Last penalty draw: lets a repeated tap on the same card be ignored. */
  #lastPenalty = null;
  /** True while a timed-out turn is played for its seat (keeps the miss streak). */
  #autoPlaying = false;

  constructor(id, {
    random = Math.random,
    onChange = () => {},
    onRankedEnd = null,
    beforeRematch = null,
    peekDurationMs = 3500,
    queenShuffleDurationMs = 1200,
    queenReplaceDurationMs = 1400,
    turnTimerConfig = null,
    launchRevealMs = 5000,
    turnGraceMs = 1000,
    now = () => performance.now(),
  } = {}) {
    this.id = id;
    this.random = random;
    this.onChange = onChange;
    this.onRankedEnd = onRankedEnd;
    /** Async hook that takes the stakes for a staked rematch; throws if a seat can't pay. */
    this.beforeRematch = beforeRematch;
    this.rankedPromise = null;
    this.rematchPending = false;
    this.rematchError = null;
    this.stakeBalances = null;
    this.peekDurationMs = peekDurationMs;
    this.queenShuffleDurationMs = queenShuffleDurationMs;
    this.queenReplaceDurationMs = queenReplaceDurationMs;
    /** Returns the live turn-limit settings, or null when timers are off. */
    this.turnTimerConfig = turnTimerConfig;
    this.launchRevealMs = launchRevealMs;
    this.turnGraceMs = turnGraceMs;
    this.now = now;
    this.version = 0;
    this.status = 'waiting';
    this.matchType = 'private';
    this.stakePool = 0;
    this.stakePerPlayer = 0;
    this.potAmount = 0;
    this.stakeCurrency = 'money';
    this.seriesWins = [0, 0];
    this.lobbyReady = [false, false];
    this.rematchReady = [false, false];
    this.rankedSaved = false;
    this.escrowed = false;
    // Running Coin Boosts by player id, read when the match was staked.
    this.seatBoosts = {};
    this.players = [];
    this.deck = [];
    this.discard = [];
    this.discardDeckId = null;
    this.turnIndex = null;
    this.result = null;
    this.lastAction = null;
    this.discardSource = null;
    this.launchTimers = new Map();
    this.activePeek = null;
    this.activeQueenAbility = null;
    /** Consecutive turns each seat has timed out. A real move resets its count. */
    this.missedTurns = [0, 0];
    /** @type {{ seat: number, limitMs: number, maxMissedTurns: number, deadline: number, timer: NodeJS.Timeout | null } | null} */
    this.turnClock = null;
    this.revealTimer = null;
  }

  addPlayer(clientId, { playerId = null, displayName = null, avatarId = 'default', deckId = 'default', isBot = false } = {}) {
    const existing = this.players.find((player) => player.id === clientId);
    if (existing) {
      existing.connected = true;
      if (playerId) existing.playerId = playerId;
      if (displayName) existing.displayName = displayName;
      if (avatarId) existing.avatarId = avatarId;
      if (deckId) existing.deckId = deckId;
      this.#changed();
      return existing;
    }
    if (this.players.length >= 2) {
      throw new GameRuleError('room_full', 'Room already has two players');
    }
    const player = {
      id: clientId,
      playerId: playerId || null,
      displayName: displayName || 'Player',
      avatarId: avatarId || 'default',
      deckId: deckId || 'default',
      connected: true,
      isBot: Boolean(isBot),
      cards: [],
      handCard: null,
      launch: 'notLaunched',
      total: 0,
      jackPeekAvailable: false,
      queenAbilityAvailable: false,
    };
    this.players.push(player);
    this.#changed();
    return player;
  }

  removePlayer(clientId) {
    const index = this.players.findIndex((player) => player.id === clientId);
    if (index < 0) return;
    this.#clearTimers();
    this.players.splice(index, 1);
    this.status = 'waiting';
    this.matchType = 'private';
    this.stakePool = 0;
    this.stakePerPlayer = 0;
    this.potAmount = 0;
    this.stakeCurrency = 'money';
    this.escrowed = false;
    this.seatBoosts = {};
    this.seriesWins = [0, 0];
    this.missedTurns = [0, 0];
    this.lobbyReady = [false, false];
    this.rematchReady = [false, false];
    this.rankedSaved = false;
    this.rematchPending = false;
    this.rematchError = null;
    this.stakeBalances = null;
    this.deck = [];
    this.discard = [];
    this.discardDeckId = null;
    this.turnIndex = null;
    this.result = null;
    this.lastAction = null;
    this.discardSource = null;
    this.players.forEach((player) => {
      player.cards = [];
      player.handCard = null;
      player.launch = 'notLaunched';
      player.total = 0;
      player.jackPeekAvailable = false;
      player.queenAbilityAvailable = false;
    });
    this.#changed();
  }

  /** Mark lobby ready; when both players ready, auto-start. */
  ready(clientId) {
    this.#requirePlayer(clientId);
    if (this.players.length !== 2) {
      throw new GameRuleError('waiting_for_player', 'Two players required');
    }
    if (this.status !== 'waiting') {
      throw new GameRuleError('already_started', 'Game already started');
    }
    const index = this.players.findIndex((player) => player.id === clientId);
    this.lobbyReady[index] = true;
    if (this.lobbyReady[0] && this.lobbyReady[1]) {
      this.start(clientId);
      return;
    }
    this.#changed();
  }

  start(clientId) {
    this.#requirePlayer(clientId);
    if (this.players.length !== 2) {
      throw new GameRuleError('waiting_for_player', 'Two players required');
    }
    if (this.status === 'playing') {
      throw new GameRuleError('already_started', 'Game already started');
    }

    this.#clearTimers();
    this.missedTurns = [0, 0];
    this.deck = shuffle(createDeck(), this.random);
    this.discard = [];
    this.discardDeckId = null;
    this.result = null;
    this.lastAction = null;
    this.discardSource = null;
    this.status = 'playing';
    this.lobbyReady = [false, false];
    this.rematchReady = [false, false];
    this.rankedSaved = false;
    this.rematchPending = false;
    this.rematchError = null;
    this.players.forEach((player) => {
      player.cards = [];
      player.handCard = null;
      player.launch = 'notLaunched';
      player.total = 0;
      player.jackPeekAvailable = false;
      player.queenAbilityAvailable = false;
    });
    for (let round = 0; round < 4; round += 1) {
      this.players.forEach((player) => player.cards.push(this.deck.pop()));
    }
    this.turnIndex = Math.floor(this.random() * 2);
    this.#armRevealTimer();
    this.#changed();
  }

  rematch(clientId) {
    this.#requirePlayer(clientId);
    if (this.players.length !== 2) {
      throw new GameRuleError('waiting_for_player', 'Two players required');
    }
    if (this.status !== 'ended') {
      throw new GameRuleError('not_ended', 'Game is not over');
    }
    if (this.rematchPending) return;
    const index = this.players.findIndex((player) => player.id === clientId);
    this.rematchReady[index] = true;
    this.rematchError = null;
    if (this.rematchReady[0] && this.rematchReady[1]) {
      if (this.#rematchNeedsStake()) {
        this.#startStakedRematch(clientId);
        return;
      }
      this.start(clientId);
      return;
    }
    this.#changed();
  }

  #rematchNeedsStake() {
    return this.matchType === 'random'
      && this.stakePerPlayer > 0
      && typeof this.beforeRematch === 'function';
  }

  /**
   * Take both stakes again before a random rematch; the previous match's
   * settlement (pot payout) must commit first.
   */
  #startStakedRematch(clientId) {
    this.rematchPending = true;
    this.#changed();
    const playerIds = this.players.map((player) => player.playerId);
    Promise.resolve(this.rankedPromise)
      .catch(() => {})
      .then(() => this.beforeRematch({
        roomId: this.id,
        playerIds,
        stake: this.stakePerPlayer,
        currency: this.stakeCurrency,
      }))
      .then((result) => {
        if (!this.#rematchStillValid(playerIds)) return;
        this.escrowed = Boolean(result?.escrowed);
        this.stakeBalances = result?.balances ?? null;
        this.seatBoosts = result?.boosts ?? {};
        const starter = this.players.find((p) => p.id === clientId) ?? this.players[0];
        this.start(starter.id);
      })
      .catch((error) => {
        if (!this.#rematchStillValid(playerIds)) return;
        this.rematchPending = false;
        if (error?.code === 'insufficient_funds') {
          const shortIndex = this.players.findIndex((p) => p.playerId === error.playerId);
          if (shortIndex >= 0) {
            this.rematchReady[shortIndex] = false;
          } else {
            this.rematchReady = [false, false];
          }
          this.rematchError = {
            code: 'insufficient_funds',
            playerId: error.playerId ?? null,
            required: Number(error.required) || this.stakePerPlayer,
            currency: this.stakeCurrency,
          };
        } else {
          console.error('[rematch] stake failed', error);
          this.rematchReady = [false, false];
          this.rematchError = {
            code: 'rematch_failed',
            playerId: null,
            required: this.stakePerPlayer,
            currency: this.stakeCurrency,
          };
        }
        this.#changed();
      });
  }

  #rematchStillValid(playerIds) {
    return this.rematchPending
      && this.status === 'ended'
      && this.players.length === 2
      && this.players.every((player, i) => player.playerId === playerIds[i]);
  }

  launch(clientId) {
    this.#requirePlaying();
    const player = this.#requirePlayer(clientId);
    if (player.launch !== 'notLaunched') {
      throw new GameRuleError('already_launched', 'Cards already revealed');
    }
    player.launch = 'launched';
    this.#changed();

    const timer = setTimeout(() => {
      this.launchTimers.delete(player.id);
      if (this.status !== 'playing') return;
      player.launch = 'ended';
      this.#armTurnClock();
      this.#changed();
    }, this.launchRevealMs);
    this.launchTimers.set(player.id, timer);
  }

  draw(clientId) {
    this.#requireAction(clientId);
    const player = this.#requirePlayer(clientId);
    if (player.handCard) {
      throw new GameRuleError('already_drew', 'Throw or swap drawn card first');
    }
    this.#restock();
    if (this.deck.length === 0) {
      throw new GameRuleError('deck_empty', 'No cards available');
    }
    player.handCard = this.deck.pop();
    const value = cardValue(player.handCard);
    player.jackPeekAvailable = value === 11;
    player.queenAbilityAvailable = value === 12;
    this.lastAction = {
      playerId: clientId,
      type: 'draw',
      cardIndex: null,
    };
    this.discardSource = null;
    this.#changed();
  }

  jackPeek(clientId, { side, cardIndex } = {}) {
    this.#requireAction(clientId);
    this.#requireNoAbilityLock(clientId);
    const player = this.#requirePlayer(clientId);
    if (!player.handCard || cardValue(player.handCard) !== 11) {
      throw new GameRuleError('no_jack', 'Jack peek requires a drawn Jack');
    }
    if (!player.jackPeekAvailable) {
      throw new GameRuleError('peek_used', 'Jack peek already used');
    }
    if (side !== 'you' && side !== 'opponent') {
      throw new GameRuleError('invalid_side', 'Peek side must be you or opponent');
    }
    const viewerIndex = this.players.findIndex((entry) => entry.id === clientId);
    const targetPlayer = side === 'you'
      ? player
      : this.players[1 - viewerIndex];
    const index = Number(cardIndex);
    if (
      !Number.isInteger(index) ||
      index < 0 ||
      index >= targetPlayer.cards.length
    ) {
      throw new GameRuleError('invalid_card', 'Card index is invalid');
    }

    player.jackPeekAvailable = false;
    this.#clearActivePeek();
    this.activePeek = {
      viewerId: clientId,
      side,
      cardIndex: index,
      tag: targetPlayer.cards[index],
      timer: null,
    };
    this.activePeek.timer = setTimeout(() => {
      this.#resolveJackPeek();
    }, this.peekDurationMs);
    this.lastAction = {
      playerId: clientId,
      type: 'jackPeek',
      cardIndex: index,
      side,
    };
    this.discardSource = null;
    this.#changed();
  }

  queenShuffle(clientId, { side } = {}) {
    this.#requireAction(clientId);
    this.#requireNoAbilityLock(clientId);
    const player = this.#requireQueenAbility(clientId);
    if (side !== 'you' && side !== 'opponent') {
      throw new GameRuleError('invalid_side', 'Shuffle side must be you or opponent');
    }
    const viewerIndex = this.players.findIndex((entry) => entry.id === clientId);
    const targetPlayer = side === 'you'
      ? player
      : this.players[1 - viewerIndex];
    if (targetPlayer.cards.length < 2) {
      throw new GameRuleError('cannot_shuffle', 'Not enough cards to shuffle');
    }

    player.queenAbilityAvailable = false;
    player.jackPeekAvailable = false;
    targetPlayer.cards = shuffle(targetPlayer.cards, this.random);
    this.lastAction = {
      playerId: clientId,
      type: 'queenShuffle',
      cardIndex: null,
      side,
    };
    this.discardSource = null;
    this.#startQueenAbilityLock(clientId, this.queenShuffleDurationMs);
    this.#changed();
  }

  queenReplace(clientId, { youIndex, opponentIndex } = {}) {
    this.#requireAction(clientId);
    this.#requireNoAbilityLock(clientId);
    const player = this.#requireQueenAbility(clientId);
    const viewerIndex = this.players.findIndex((entry) => entry.id === clientId);
    const opponent = this.players[1 - viewerIndex];
    const ownIndex = Number(youIndex);
    const oppIndex = Number(opponentIndex);
    if (
      !Number.isInteger(ownIndex) ||
      ownIndex < 0 ||
      ownIndex >= player.cards.length
    ) {
      throw new GameRuleError('invalid_card', 'Your card index is invalid');
    }
    if (
      !Number.isInteger(oppIndex) ||
      oppIndex < 0 ||
      oppIndex >= opponent.cards.length
    ) {
      throw new GameRuleError('invalid_card', 'Opponent card index is invalid');
    }

    player.queenAbilityAvailable = false;
    player.jackPeekAvailable = false;
    const ownTag = player.cards[ownIndex];
    player.cards[ownIndex] = opponent.cards[oppIndex];
    opponent.cards[oppIndex] = ownTag;
    this.lastAction = {
      playerId: clientId,
      type: 'queenReplace',
      cardIndex: ownIndex,
      youIndex: ownIndex,
      opponentIndex: oppIndex,
    };
    this.discardSource = null;
    this.#startQueenAbilityLock(clientId, this.queenReplaceDurationMs);
    this.#changed();
  }

  tapCard(clientId, cardIndex) {
    this.#requireAction(clientId);
    this.#requireNoAbilityLock(clientId);
    const player = this.#requirePlayer(clientId);
    const index = Number(cardIndex);
    if (!Number.isInteger(index) || index < 0 || index >= player.cards.length) {
      throw new GameRuleError('invalid_card', 'Card index is invalid');
    }
    const selected = player.cards[index];

    if (!player.handCard) {
      if (this.discard.length === 0) {
        throw new GameRuleError('draw_first', 'Draw a card first');
      }
      if (this.#isRepeatPenalty(clientId, selected)) return;
      if (cardValue(selected) === cardValue(this.discard.at(-1))) {
        player.cards.splice(index, 1);
        this.discard.push(selected);
        this.discardDeckId = player.deckId || 'default';
        this.discardSource = 'hand';
        this.lastAction = {
          playerId: clientId,
          type: 'discardMatch',
          cardIndex: index,
          cardTag: selected,
        };
      } else {
        this.#restock();
        if (this.deck.length > 0) player.cards.push(this.deck.pop());
        this.discardSource = null;
        this.lastAction = {
          playerId: clientId,
          type: 'penaltyDraw',
          cardIndex: index,
        };
        this.#lastPenalty = {
          clientId,
          tag: selected,
          discardSize: this.discard.length,
          discardTop: this.discard.at(-1),
        };
      }
      this.#finishIfNeeded();
      this.#changed();
      return;
    }

    if (cardValue(player.handCard) === cardValue(selected)) {
      const drawnTag = player.handCard;
      player.cards.splice(index, 1);
      this.discard.push(selected, drawnTag);
      this.discardDeckId = player.deckId || 'default';
      this.discardSource = 'hand';
      this.lastAction = {
        playerId: clientId,
        type: 'doubleDiscard',
        cardIndex: index,
        cardTag: selected,
        drawnTag,
      };
    } else {
      const drawnTag = player.handCard;
      player.cards[index] = drawnTag;
      this.discard.push(selected);
      this.discardDeckId = player.deckId || 'default';
      this.discardSource = 'hand';
      this.lastAction = {
        playerId: clientId,
        type: 'swap',
        cardIndex: index,
        cardTag: selected,
      };
    }
    player.handCard = null;
    player.jackPeekAvailable = false;
    player.queenAbilityAvailable = false;
    this.#advanceTurn();
  }

  throwHand(clientId) {
    this.#requireAction(clientId);
    this.#requireNoAbilityLock(clientId);
    const player = this.#requirePlayer(clientId);
    if (!player.handCard) {
      throw new GameRuleError('no_hand_card', 'Draw a card first');
    }
    this.#throwDrawnCard(player);
  }

  end(clientId) {
    this.#requirePlayer(clientId);
    this.#requirePlaying();
    this.lastAction = null;
    this.discardSource = null;
    this.#endGame();
    this.#changed();
  }

  /**
   * Caller ends the match on their turn (before drawing); hands are scored
   * normally. Unlike [end], this never counts as a forfeit in random matches.
   */
  call(clientId) {
    this.#requireAction(clientId);
    this.#requireNoAbilityLock(clientId);
    const player = this.#requirePlayer(clientId);
    if (player.handCard) {
      throw new GameRuleError('already_drew', 'Call before drawing');
    }
    this.lastAction = {
      playerId: clientId,
      type: 'call',
      cardIndex: null,
    };
    this.discardSource = null;
    this.#endGame({ reason: 'call' });
    this.#changed();
  }

  /**
   * Caller loses; opponent wins. Settles ranked if applicable.
   */
  forfeit(clientId, { reason = 'forfeit' } = {}) {
    const index = this.players.findIndex((player) => player.id === clientId);
    if (index < 0) {
      throw new GameRuleError('not_in_room', 'Player not in room');
    }
    if (this.players.length !== 2) {
      throw new GameRuleError('waiting_for_player', 'Two players required');
    }
    this.lastAction = {
      playerId: clientId,
      type: reason,
    };
    this.discardSource = null;
    this.status = 'ended';
    this.turnIndex = null;
    this.rematchReady = [false, false];
    // Post-settlement balances arrive via result.ratings[].moneyAfter.
    this.stakeBalances = null;
    this.players.forEach((player) => {
      player.total = player.cards.reduce((sum, tag) => sum + gameValue(tag), 0);
    });
    const winnerIndex = 1 - index;
    this.result = {
      scores: this.players.map((player) => player.total),
      winnerIndex,
      reason,
      quitterIndex: index,
    };
    this.seriesWins[winnerIndex] += 1;
    this.#clearTimers();
    this.#maybeRecordRanked(winnerIndex);
    this.#changed();
  }

  markDisconnected(clientId) {
    const player = this.players.find((p) => p.id === clientId);
    if (!player) return null;
    player.connected = false;
    this.#changed();
    return player;
  }

  /**
   * Rebind a disconnected seat to a new socket client id.
   */
  reconnectPlayer(oldClientId, newClientId, meta = {}) {
    const player = this.players.find((p) => p.id === oldClientId);
    if (!player) {
      throw new GameRuleError('not_in_room', 'Seat not found');
    }
    // Migrate launch timers keyed by client id
    if (this.launchTimers.has(oldClientId)) {
      const timer = this.launchTimers.get(oldClientId);
      this.launchTimers.delete(oldClientId);
      this.launchTimers.set(newClientId, timer);
    }
    // Ability locks name the seat by client id, so keep them on this seat.
    if (this.activePeek?.viewerId === oldClientId) this.activePeek.viewerId = newClientId;
    if (this.activeQueenAbility?.viewerId === oldClientId) {
      this.activeQueenAbility.viewerId = newClientId;
    }
    player.id = newClientId;
    player.connected = true;
    if (meta.displayName) player.displayName = meta.displayName;
    if (meta.avatarId) player.avatarId = meta.avatarId;
    if (meta.deckId) player.deckId = meta.deckId;
    this.#changed();
    return player;
  }

  findPlayerByPlayerId(playerId) {
    if (!playerId) return null;
    return this.players.find((p) => p.playerId === playerId) || null;
  }

  /** The Coin Boost a seat carries into this match. Only ranked money matches pay one. */
  #boostOf(player) {
    if (!player?.playerId || this.matchType !== 'random' || this.stakeCurrency !== 'money') return null;
    return this.seatBoosts?.[player.playerId] ?? null;
  }

  snapshotFor(clientId) {
    const viewerIndex = this.players.findIndex((player) => player.id === clientId);
    const viewer = viewerIndex >= 0 ? this.players[viewerIndex] : null;
    const opponent = viewerIndex >= 0 ? this.players[1 - viewerIndex] : null;
    const showAll = this.status === 'ended';

    return {
      type: 'snapshot',
      roomId: this.id,
      version: this.version,
      status: this.status,
      ready: this.players.length === 2,
      matchType: this.matchType,
      stakePool: this.stakePool,
      stakePerPlayer: this.stakePerPlayer,
      potAmount: this.potAmount,
      stakeCurrency: this.stakeCurrency,
      yourBoost: this.#boostOf(viewer),
      deckCount: this.deck.length,
      discardTop: this.discard.at(-1) ?? null,
      discardRecent: this.discard.slice(-2),
      discardDeckId: this.discardDeckId ?? null,
      turn: this.turnIndex === null
        ? null
        : this.turnIndex === viewerIndex ? 'you' : 'opponent',
      turnTimer: this.#turnTimerView(),
      you: viewer
        ? this.#playerView(viewer, true, showAll, clientId, viewerIndex)
        : null,
      opponent: opponent
        ? this.#playerView(opponent, false, showAll, clientId, 1 - viewerIndex)
        : null,
      rematchPending: this.rematchPending,
      rematchBlocked: this.rematchError
        ? {
          reason: this.rematchError.code,
          required: this.rematchError.required,
          who: this.rematchError.playerId == null
            ? null
            : viewer && viewer.playerId === this.rematchError.playerId ? 'you' : 'opponent',
        }
        : null,
      result: this.result
        ? {
          ...this.result,
          ...(this.result.quitterIndex != null
            ? { quitter: this.result.quitterIndex === viewerIndex ? 'you' : 'opponent' }
            : {}),
        }
        : null,
      discardSource: this.discardSource,
      lastAction: this.lastAction
        ? {
          actor: this.lastAction.playerId === clientId ? 'you' : 'opponent',
          type: this.lastAction.type,
          cardIndex: this.lastAction.cardIndex,
          cardTag: this.lastAction.cardTag ?? null,
          drawnTag: this.lastAction.drawnTag ?? null,
          ...(this.lastAction.side != null ? { side: this.lastAction.side } : {}),
          ...(this.lastAction.youIndex != null
            ? { youIndex: this.lastAction.youIndex }
            : {}),
          ...(this.lastAction.opponentIndex != null
            ? { opponentIndex: this.lastAction.opponentIndex }
            : {}),
        }
        : null,
    };
  }

  dispose() {
    this.#clearTimers();
  }

  #playerView(player, isSelf, showAll, viewerId = null, seatIndex = 0) {
    const peek = this.activePeek;
    const peekForViewer = Boolean(peek && peek.viewerId === viewerId);
    return {
      connected: player.connected,
      displayName: player.displayName || 'Player',
      avatarId: player.avatarId || 'default',
      deckId: player.deckId || 'default',
      playerId: player.playerId || null,
      ...(isSelf && this.stakeBalances && player.playerId in this.stakeBalances
        ? { [this.stakeCurrency]: this.stakeBalances[player.playerId] }
        : {}),
      seriesWins: this.seriesWins[seatIndex] ?? 0,
      missedTurns: this.missedTurns[seatIndex] ?? 0,
      lobbyReady: Boolean(this.lobbyReady[seatIndex]),
      rematchReady: Boolean(this.rematchReady[seatIndex]),
      launch: player.launch,
      total: player.total,
      cards: player.cards.map((tag, index) => {
        const initialReveal = isSelf && player.launch === 'launched' && index < 2;
        const jackPeekReveal = peekForViewer
          && peek.cardIndex === index
          && ((peek.side === 'you' && isSelf) || (peek.side === 'opponent' && !isSelf));
        const visible = Boolean(showAll || initialReveal || jackPeekReveal);
        return { index, tag: visible ? tag : null, visible };
      }),
      handCard: isSelf && player.handCard ? player.handCard : null,
      hasHandCard: Boolean(player.handCard),
      jackPeekAvailable: isSelf ? Boolean(player.jackPeekAvailable) : false,
      queenAbilityAvailable: isSelf ? Boolean(player.queenAbilityAvailable) : false,
    };
  }

  #advanceTurn() {
    if (this.#finishIfNeeded()) {
      this.#changed();
      return;
    }
    // A real move clears the mover's miss streak. A timed-out turn does not.
    if (!this.#autoPlaying) this.missedTurns[this.turnIndex] = 0;
    this.turnIndex = 1 - this.turnIndex;
    this.#restock();
    this.#armTurnClock();
    this.#changed();
  }

  #finishIfNeeded() {
    if (this.players.some((player) => player.cards.length === 0)) {
      this.#endGame();
      return true;
    }
    return false;
  }

  #endGame({ reason = null } = {}) {
    this.status = 'ended';
    this.turnIndex = null;
    this.rematchReady = [false, false];
    // Post-settlement balances arrive via result.ratings[].moneyAfter.
    this.stakeBalances = null;
    this.players.forEach((player) => {
      player.total = player.cards.reduce((sum, tag) => sum + gameValue(tag), 0);
    });
    const winnerIndex = this.players[0].total === this.players[1].total
      ? null
      : this.players[0].total < this.players[1].total ? 0 : 1;
    this.result = {
      scores: this.players.map((player) => player.total),
      winnerIndex,
      ...(reason ? { reason } : {}),
    };
    if (winnerIndex === 0 || winnerIndex === 1) {
      this.seriesWins[winnerIndex] += 1;
    }
    this.#clearTimers();
    this.#maybeRecordRanked(winnerIndex);
  }

  #maybeRecordRanked(winnerIndex) {
    if (this.rankedSaved) return;
    if (this.matchType !== 'random') return;
    if (this.players.length !== 2) return;
    if (!this.players[0].playerId || !this.players[1].playerId) return;
    if (typeof this.onRankedEnd !== 'function') return;

    this.rankedSaved = true;
    const payload = {
      roomId: this.id,
      stakePerPlayer: this.stakePerPlayer,
      potAmount: this.potAmount,
      stakeCurrency: this.stakeCurrency,
      escrowed: Boolean(this.escrowed),
      players: this.players.map((player) => ({
        playerId: player.playerId,
        cardTotal: player.total,
        boost: this.#boostOf(player),
      })),
      winnerIndex,
      quitterIndex: this.result?.quitterIndex ?? null,
    };
    this.rankedPromise = Promise.resolve()
      .then(() => this.onRankedEnd(payload))
      .then((rankedResult) => {
        if (rankedResult && Array.isArray(rankedResult.players) && this.result) {
          this.result = {
            ...this.result,
            ratings: rankedResult.players,
          };
          this.#changed();
        }
      })
      .catch((error) => {
        console.error('[ranking] record failed', error);
      });
  }

  /**
   * True when [selected] was just penalised against the same discard top
   * (e.g. a double tap): it can only miss again, so it must not cost a
   * second penalty card.
   */
  #isRepeatPenalty(clientId, selected) {
    const last = this.#lastPenalty;
    return (
      last !== null &&
      last.clientId === clientId &&
      last.tag === selected &&
      last.discardSize === this.discard.length &&
      last.discardTop === this.discard.at(-1)
    );
  }

  #restock() {
    if (this.deck.length > 0 || this.discard.length <= 1) return;
    const top = this.discard.pop();
    this.deck = shuffle(this.discard, this.random);
    this.discard = [top];
  }

  #requireAction(clientId) {
    this.#requirePlaying();
    const index = this.players.findIndex((player) => player.id === clientId);
    if (index < 0) throw new GameRuleError('not_in_room', 'Join room first');
    if (index !== this.turnIndex) {
      throw new GameRuleError('not_your_turn', 'It is not your turn');
    }
    if (!this.players.every((player) => player.launch === 'ended')) {
      throw new GameRuleError('reveal_first', 'Both players must reveal first');
    }
  }

  #requirePlaying() {
    if (this.status !== 'playing') {
      throw new GameRuleError('not_playing', 'Game is not running');
    }
  }

  #requirePlayer(clientId) {
    const player = this.#player(clientId);
    if (!player) throw new GameRuleError('not_in_room', 'Join room first');
    return player;
  }

  #player(clientId) {
    return this.players.find((player) => player.id === clientId);
  }

  #changed() {
    this.version += 1;
    this.onChange(this);
  }

  #requireNoAbilityLock(clientId) {
    if (this.activePeek?.viewerId === clientId) {
      throw new GameRuleError('peek_in_progress', 'Wait for peek to finish');
    }
    if (this.activeQueenAbility?.viewerId === clientId) {
      throw new GameRuleError('queen_in_progress', 'Wait for Queen ability to finish');
    }
  }

  #requireQueenAbility(clientId) {
    const player = this.#requirePlayer(clientId);
    if (!player.handCard || cardValue(player.handCard) !== 12) {
      throw new GameRuleError('no_queen', 'Queen ability requires a drawn Queen');
    }
    if (!player.queenAbilityAvailable) {
      throw new GameRuleError('queen_used', 'Queen ability already used');
    }
    return player;
  }

  #startQueenAbilityLock(clientId, durationMs) {
    this.#clearActiveQueenAbility();
    this.activeQueenAbility = {
      viewerId: clientId,
      timer: setTimeout(() => {
        this.#resolveQueenAbility();
      }, durationMs),
    };
  }

  #throwDrawnCard(player) {
    const cardTag = player.handCard;
    this.lastAction = {
      playerId: player.id,
      type: 'throw',
      cardIndex: null,
      cardTag,
    };
    this.discardSource = 'drawn';
    this.discardDeckId = player.deckId || 'default';
    this.discard.push(cardTag);
    player.handCard = null;
    player.jackPeekAvailable = false;
    player.queenAbilityAvailable = false;
    this.#advanceTurn();
  }

  #resolveJackPeek() {
    const peek = this.activePeek;
    this.#clearActivePeek();
    if (!peek) return;
    const player = this.#player(peek.viewerId);
    if (!player?.handCard) {
      this.#changed();
      return;
    }
    this.#throwDrawnCard(player);
  }

  #resolveQueenAbility() {
    const ability = this.activeQueenAbility;
    this.#clearActiveQueenAbility();
    if (!ability) return;
    const player = this.#player(ability.viewerId);
    if (!player?.handCard) {
      this.#changed();
      return;
    }
    this.#throwDrawnCard(player);
  }

  #clearActivePeek() {
    if (this.activePeek?.timer) clearTimeout(this.activePeek.timer);
    this.activePeek = null;
  }

  #clearActiveQueenAbility() {
    if (this.activeQueenAbility?.timer) clearTimeout(this.activeQueenAbility.timer);
    this.activeQueenAbility = null;
  }

  #clearTimers() {
    this.launchTimers.forEach(clearTimeout);
    this.launchTimers.clear();
    this.#clearActivePeek();
    this.#clearActiveQueenAbility();
    this.#clearTurnClock();
    this.#clearRevealTimer();
  }

  /** Live turn-limit settings for this room, or null when timers are off. */
  #timerConfig() {
    return this.turnTimerConfig?.() ?? null;
  }

  /**
   * Starts the clock for the seat on turn. Bot seats get one too, for display
   * only, so a bot's seat looks like any other. It is never enforced.
   */
  #armTurnClock() {
    this.#clearTurnClock();
    const config = this.#timerConfig();
    if (!config || this.status !== 'playing' || this.players.length !== 2) return;
    if (!this.players.every((player) => player.launch === 'ended')) return;
    const clock = {
      seat: this.turnIndex,
      limitMs: config.turnMs,
      maxMissedTurns: config.maxMissedTurns,
      deadline: this.now() + config.turnMs,
      timer: null,
    };
    // The grace keeps a tap sent at 0:00 from landing after the timeout.
    clock.timer = setTimeout(
      () => this.#guardTimer(() => this.#onTurnClockExpired(clock)),
      config.turnMs + this.turnGraceMs,
    );
    clock.timer.unref?.();
    this.turnClock = clock;
  }

  #clearTurnClock() {
    if (this.turnClock?.timer) clearTimeout(this.turnClock.timer);
    this.turnClock = null;
  }

  #armRevealTimer() {
    this.#clearRevealTimer();
    const config = this.#timerConfig();
    if (!config) return;
    this.revealTimer = setTimeout(
      () => this.#guardTimer(() => this.#onRevealExpired()),
      config.revealMs,
    );
    this.revealTimer.unref?.();
  }

  #clearRevealTimer() {
    if (this.revealTimer) clearTimeout(this.revealTimer);
    this.revealTimer = null;
  }

  /** A seat that never reveals is revealed for it, so the room cannot stall. */
  #onRevealExpired() {
    this.revealTimer = null;
    if (this.status !== 'playing' || !this.#timerConfig()) return;
    for (const player of this.players) {
      if (player.launch === 'notLaunched') this.launch(player.id);
    }
  }

  /** The turn clock ran out. Each step re-checks the room, so a stale clock does nothing. */
  #onTurnClockExpired(clock) {
    if (this.turnClock !== clock || this.status !== 'playing') return;
    if (clock.seat !== this.turnIndex) return;
    if (!this.#timerConfig()) {
      // Turned off since the turn began: show no clock and enforce nothing.
      this.#clearTurnClock();
      this.#changed();
      return;
    }
    const player = this.players[clock.seat];
    if (player.isBot) return;
    if (
      this.activePeek?.viewerId === player.id ||
      this.activeQueenAbility?.viewerId === player.id
    ) {
      // The ability lock ends the turn itself. Check again if it did not.
      clock.timer = setTimeout(
        () => this.#guardTimer(() => this.#onTurnClockExpired(clock)),
        LOCK_RETRY_MS,
      );
      clock.timer.unref?.();
      return;
    }
    if (player.connected) {
      this.missedTurns[clock.seat] += 1;
      if (clock.maxMissedTurns > 0 && this.missedTurns[clock.seat] >= clock.maxMissedTurns) {
        this.forfeit(player.id, { reason: 'timeout' });
        return;
      }
    }
    // A disconnected seat is played for but not counted: the 60 s grace owns its exit.
    this.#autoPlay(player.id);
  }

  /** Plays a timed-out turn with the normal moves: draw if needed, then throw the card. */
  #autoPlay(clientId) {
    this.#autoPlaying = true;
    try {
      if (!this.#player(clientId).handCard) this.draw(clientId);
      this.throwHand(clientId);
    } catch (error) {
      if (!(error instanceof GameRuleError)) throw error;
      // Nothing can be drawn (deck empty), so the turn simply passes.
      this.#advanceTurn();
    } finally {
      this.#autoPlaying = false;
    }
  }

  /** Runs a timer callback. A rule error is expected here. Anything else is logged. */
  #guardTimer(callback) {
    try {
      callback();
    } catch (error) {
      if (!(error instanceof GameRuleError)) console.error('[game-room timer]', error);
    }
  }

  /** Remaining time for clients. It is relative, so no clock sync is needed. */
  #turnTimerView() {
    const clock = this.turnClock;
    if (!clock || this.status !== 'playing') return null;
    return {
      limitMs: clock.limitMs,
      remainingMs: Math.min(clock.limitMs, Math.max(0, Math.ceil(clock.deadline - this.now()))),
      maxMissedTurns: clock.maxMissedTurns,
    };
  }
}

function createDeck() {
  const deck = [];
  for (const suit of ['A', 'B', 'C', 'D']) {
    for (let value = 1; value <= 13; value += 1) deck.push(`${suit}${value}`);
  }
  deck.push('A14', 'B14');
  return deck;
}

function shuffle(cards, random = Math.random) {
  const result = [...cards];
  for (let index = result.length - 1; index > 0; index -= 1) {
    const other = Math.floor(random() * (index + 1));
    [result[index], result[other]] = [result[other], result[index]];
  }
  return result;
}

function cardValue(tag) {
  return Number(tag.slice(1));
}

function gameValue(tag) {
  const value = cardValue(tag);
  if (value === 14) return -1;
  if (value === 13 && (tag[0] === 'A' || tag[0] === 'D')) return 0;
  return value;
}

function createRoomCode() {
  return crypto.randomBytes(3).toString('hex').toUpperCase();
}

module.exports = {
  GameRoom,
  GameRuleError,
  createDeck,
  createRoomCode,
  gameValue,
  shuffle,
};
