const crypto = require('crypto');

class GameRuleError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

class GameRoom {
  constructor(id, { random = Math.random, onChange = () => {} } = {}) {
    this.id = id;
    this.random = random;
    this.onChange = onChange;
    this.version = 0;
    this.status = 'waiting';
    this.players = [];
    this.deck = [];
    this.discard = [];
    this.turnIndex = null;
    this.result = null;
    this.lastAction = null;
    this.discardSource = null;
    this.launchTimers = new Map();
  }

  addPlayer(clientId) {
    const existing = this.players.find((player) => player.id === clientId);
    if (existing) {
      existing.connected = true;
      this.#changed();
      return existing;
    }
    if (this.players.length >= 2) {
      throw new GameRuleError('room_full', 'Room already has two players');
    }
    const player = {
      id: clientId,
      connected: true,
      cards: [],
      handCard: null,
      launch: 'notLaunched',
      total: 0,
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
    this.players.splice(index, 1);
    this.status = 'waiting';
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
    });
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
    this.players.forEach((player) => {
      player.cards = [];
      player.handCard = null;
      player.launch = 'notLaunched';
      player.total = 0;
    });
    for (let round = 0; round < 4; round += 1) {
      this.players.forEach((player) => player.cards.push(this.deck.pop()));
    }
    this.turnIndex = Math.floor(this.random() * 2);
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
    this.lastAction = {
      playerId: clientId,
      type: 'draw',
      cardIndex: null,
    };
    this.discardSource = null;
    this.#changed();
  }

  tapCard(clientId, cardIndex) {
    this.#requireAction(clientId);
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
    this.#advanceTurn();
  }

  throwHand(clientId) {
    this.#requireAction(clientId);
    const player = this.#requirePlayer(clientId);
    if (!player.handCard) {
      throw new GameRuleError('no_hand_card', 'Draw a card first');
    }
    const cardTag = player.handCard;
    this.lastAction = {
      playerId: clientId,
      type: 'throw',
      cardIndex: null,
      cardTag,
    };
    this.discardSource = 'drawn';
    this.discard.push(cardTag);
    player.handCard = null;
    this.#advanceTurn();
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
      deckCount: this.deck.length,
      discardTop: this.discard.at(-1) ?? null,
      discardRecent: this.discard.slice(-2),
      turn: this.turnIndex === null
        ? null
        : this.turnIndex === viewerIndex ? 'you' : 'opponent',
      you: viewer ? this.#playerView(viewer, true, showAll) : null,
      opponent: opponent ? this.#playerView(opponent, false, showAll) : null,
      result: this.result,
      discardSource: this.discardSource,
      lastAction: this.lastAction
        ? {
          actor: this.lastAction.playerId === clientId ? 'you' : 'opponent',
          type: this.lastAction.type,
          cardIndex: this.lastAction.cardIndex,
          cardTag: this.lastAction.cardTag ?? null,
          drawnTag: this.lastAction.drawnTag ?? null,
        }
        : null,
    };
  }

  dispose() {
    this.#clearTimers();
  }

  #playerView(player, isSelf, showAll) {
    return {
      connected: player.connected,
      launch: player.launch,
      total: player.total,
      cards: player.cards.map((tag, index) => {
        const initialReveal = isSelf && player.launch === 'launched' && index < 2;
        const visible = showAll || initialReveal;
        return { index, tag: visible ? tag : null, visible };
      }),
      handCard: isSelf && player.handCard ? player.handCard : null,
      hasHandCard: Boolean(player.handCard),
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
    this.players.forEach((player) => {
      player.total = player.cards.reduce((sum, tag) => sum + gameValue(tag), 0);
    });
    this.result = {
      scores: this.players.map((player) => player.total),
      winnerIndex: this.players[0].total === this.players[1].total
        ? null
        : this.players[0].total < this.players[1].total ? 0 : 1,
    };
    this.#clearTimers();
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

  #clearTimers() {
    this.launchTimers.forEach(clearTimeout);
    this.launchTimers.clear();
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
