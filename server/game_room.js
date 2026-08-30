const crypto = require('crypto');

class GameRuleError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

class GameRoom {
  constructor(id, {
    random = Math.random,
    onChange = () => {},
    onRankedEnd = null,
    peekDurationMs = 3500,
    queenShuffleDurationMs = 1200,
    queenReplaceDurationMs = 1400,
  } = {}) {
    this.id = id;
    this.random = random;
    this.onChange = onChange;
    this.onRankedEnd = onRankedEnd;
    this.peekDurationMs = peekDurationMs;
    this.queenShuffleDurationMs = queenShuffleDurationMs;
    this.queenReplaceDurationMs = queenReplaceDurationMs;
    this.version = 0;
    this.status = 'waiting';
    this.matchType = 'private';
    this.stakePool = 0;
    this.stakePerPlayer = 0;
    this.potAmount = 0;
    this.seriesWins = [0, 0];
    this.lobbyReady = [false, false];
    this.rematchReady = [false, false];
    this.rankedSaved = false;
    this.players = [];
    this.deck = [];
    this.discard = [];
    this.turnIndex = null;
    this.result = null;
    this.lastAction = null;
    this.discardSource = null;
    this.launchTimers = new Map();
    this.activePeek = null;
    this.activeQueenAbility = null;
  }

  addPlayer(clientId, { playerId = null, displayName = null, avatarId = 'default' } = {}) {
    const existing = this.players.find((player) => player.id === clientId);
    if (existing) {
      existing.connected = true;
      if (playerId) existing.playerId = playerId;
      if (displayName) existing.displayName = displayName;
      if (avatarId) existing.avatarId = avatarId;
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
      connected: true,
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
    clearTimeout(this.launchTimers.get(clientId));
    this.launchTimers.delete(clientId);
    this.#clearActivePeek();
    this.#clearActiveQueenAbility();
    this.players.splice(index, 1);
    this.status = 'waiting';
    this.matchType = 'private';
    this.stakePool = 0;
    this.stakePerPlayer = 0;
    this.potAmount = 0;
    this.seriesWins = [0, 0];
    this.lobbyReady = [false, false];
    this.rematchReady = [false, false];
    this.rankedSaved = false;
    this.deck = [];
    this.discard = [];
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
    this.deck = shuffle(createDeck(), this.random);
    this.discard = [];
    this.result = null;
    this.lastAction = null;
    this.discardSource = null;
    this.status = 'playing';
    this.lobbyReady = [false, false];
    this.rematchReady = [false, false];
    this.rankedSaved = false;
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
    const index = this.players.findIndex((player) => player.id === clientId);
    this.rematchReady[index] = true;
    if (this.rematchReady[0] && this.rematchReady[1]) {
      this.start(clientId);
      return;
    }
    this.#changed();
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
      player.launch = 'ended';
      this.launchTimers.delete(clientId);
      this.#changed();
    }, 5000);
    this.launchTimers.set(clientId, timer);
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
      if (cardValue(selected) === cardValue(this.discard.at(-1))) {
        player.cards.splice(index, 1);
        this.discard.push(selected);
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
      }
      this.#finishIfNeeded();
      this.#changed();
      return;
    }

    if (cardValue(player.handCard) === cardValue(selected)) {
      const drawnTag = player.handCard;
      player.cards.splice(index, 1);
      this.discard.push(selected, drawnTag);
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
    this.lastAction = null;
    this.discardSource = null;
    this.#endGame();
    this.#changed();
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
      deckCount: this.deck.length,
      discardTop: this.discard.at(-1) ?? null,
      discardRecent: this.discard.slice(-2),
      turn: this.turnIndex === null
        ? null
        : this.turnIndex === viewerIndex ? 'you' : 'opponent',
      you: viewer
        ? this.#playerView(viewer, true, showAll, clientId, viewerIndex)
        : null,
      opponent: opponent
        ? this.#playerView(opponent, false, showAll, clientId, 1 - viewerIndex)
        : null,
      result: this.result,
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
      playerId: player.playerId || null,
      seriesWins: this.seriesWins[seatIndex] ?? 0,
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
    this.turnIndex = 1 - this.turnIndex;
    this.#restock();
    this.#changed();
  }

  #finishIfNeeded() {
    if (this.players.some((player) => player.cards.length === 0)) {
      this.#endGame();
      return true;
    }
    return false;
  }

  #endGame() {
    this.status = 'ended';
    this.turnIndex = null;
    this.rematchReady = [false, false];
    this.players.forEach((player) => {
      player.total = player.cards.reduce((sum, tag) => sum + gameValue(tag), 0);
    });
    const winnerIndex = this.players[0].total === this.players[1].total
      ? null
      : this.players[0].total < this.players[1].total ? 0 : 1;
    this.result = {
      scores: this.players.map((player) => player.total),
      winnerIndex,
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
      players: this.players.map((player) => ({
        playerId: player.playerId,
        cardTotal: player.total,
      })),
      winnerIndex,
    };
    Promise.resolve()
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
