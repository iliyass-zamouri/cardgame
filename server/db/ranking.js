const { randomUUID } = require('crypto');
const { getPool } = require('./pool');

const ELO_START = 1000;
const ELO_K = 32;
const ELO_FLOOR = 100;

const POINTS_WIN_BASE = 20;
const POINTS_DRAW_BASE = 8;
const POINTS_LOSS_BASE = 2;
const POINTS_MARGIN_CAP = 15;

/**
 * Classic Elo expected score for player A vs B.
 * @param {number} eloA
 * @param {number} eloB
 */
function expectedScore(eloA, eloB) {
  return 1 / (1 + 10 ** ((eloB - eloA) / 400));
}

/**
 * @param {number} eloBefore
 * @param {number} opponentElo
 * @param {'win'|'loss'|'draw'} result
 * @returns {{ eloAfter: number, eloDelta: number }}
 */
function applyElo(eloBefore, opponentElo, result) {
  const s = result === 'win' ? 1 : result === 'draw' ? 0.5 : 0;
  const expected = expectedScore(eloBefore, opponentElo);
  const rawDelta = Math.round(ELO_K * (s - expected));
  const eloAfter = Math.max(ELO_FLOOR, eloBefore + rawDelta);
  return { eloAfter, eloDelta: eloAfter - eloBefore };
}

/**
 * Margin points from card totals (lower total wins).
 * @param {'win'|'loss'|'draw'} result
 * @param {number} myTotal
 * @param {number} oppTotal
 */
function marginPoints(result, myTotal, oppTotal) {
  if (result === 'draw') return POINTS_DRAW_BASE;
  if (result === 'loss') return POINTS_LOSS_BASE;
  const bonus = Math.min(
    POINTS_MARGIN_CAP,
    Math.floor(Math.abs(oppTotal - myTotal) / 2),
  );
  return POINTS_WIN_BASE + bonus;
}

/**
 * @param {{ cardTotal: number, elo: number }} a
 * @param {{ cardTotal: number, elo: number }} b
 * @param {0|1|null} winnerIndex
 */
function computeMatchRatings(a, b, winnerIndex) {
  const resultA =
    winnerIndex === null ? 'draw' : winnerIndex === 0 ? 'win' : 'loss';
  const resultB =
    winnerIndex === null ? 'draw' : winnerIndex === 1 ? 'win' : 'loss';

  const eloA = applyElo(a.elo, b.elo, resultA);
  const eloB = applyElo(b.elo, a.elo, resultB);

  return {
    a: {
      result: resultA,
      pointsEarned: marginPoints(resultA, a.cardTotal, b.cardTotal),
      eloBefore: a.elo,
      eloAfter: eloA.eloAfter,
      eloDelta: eloA.eloDelta,
    },
    b: {
      result: resultB,
      pointsEarned: marginPoints(resultB, b.cardTotal, a.cardTotal),
      eloBefore: b.elo,
      eloAfter: eloB.eloAfter,
      eloDelta: eloB.eloDelta,
    },
  };
}

async function addColumnIfMissing(conn, table, column, definition) {
  const [rows] = await conn.query(
    `SELECT 1 AS ok
     FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME = :table
       AND COLUMN_NAME = :column
     LIMIT 1`,
    { table, column },
  );
  if (rows.length > 0) return;
  await conn.query(`ALTER TABLE \`${table}\` ADD COLUMN ${definition}`);
}

async function addIndexIfMissing(conn, table, indexName, indexSql) {
  const [rows] = await conn.query(
    `SELECT 1 AS ok
     FROM information_schema.STATISTICS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME = :table
       AND INDEX_NAME = :indexName
     LIMIT 1`,
    { table, indexName },
  );
  if (rows.length > 0) return;
  await conn.query(`ALTER TABLE \`${table}\` ADD ${indexSql}`);
}

/** Idempotent upgrades for DBs created before ranking columns. */
async function ensureRankingSchema() {
  const pool = getPool();
  const conn = await pool.getConnection();
  try {
    await addColumnIfMissing(
      conn,
      'players',
      'elo',
      `elo INT NOT NULL DEFAULT ${ELO_START}`,
    );
    await addColumnIfMissing(
      conn,
      'players',
      'total_points',
      'total_points INT NOT NULL DEFAULT 0',
    );
    await addColumnIfMissing(
      conn,
      'players',
      'wins',
      'wins INT NOT NULL DEFAULT 0',
    );
    await addColumnIfMissing(
      conn,
      'players',
      'losses',
      'losses INT NOT NULL DEFAULT 0',
    );
    await addColumnIfMissing(
      conn,
      'players',
      'draws',
      'draws INT NOT NULL DEFAULT 0',
    );
    await addIndexIfMissing(
      conn,
      'players',
      'idx_players_elo',
      'KEY idx_players_elo (elo, total_points)',
    );
  } finally {
    conn.release();
  }
}

/**
 * Persist a completed random match. Returns null if skipped (missing players).
 * @param {{
 *   roomId: string,
 *   players: Array<{ playerId: string, cardTotal: number }>,
 *   winnerIndex: 0|1|null,
 * }} input
 */
async function recordRankedMatch({
  roomId,
  players,
  winnerIndex,
  stakePerPlayer = 0,
  potAmount = 0,
}) {
  if (!Array.isArray(players) || players.length !== 2) return null;
  const [p0, p1] = players;
  if (!p0?.playerId || !p1?.playerId) return null;

  const safeStake = Math.max(0, Number(stakePerPlayer) || 0);
  const safePot = Math.max(0, Number(potAmount) || 0);

  const pool = getPool();
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    const [rows] = await conn.execute(
      `SELECT id, elo, total_points, wins, losses, draws, money, chips
       FROM players
       WHERE id IN (:id0, :id1)
       FOR UPDATE`,
      { id0: p0.playerId, id1: p1.playerId },
    );

    if (rows.length !== 2) {
      await conn.rollback();
      return null;
    }

    const byId = new Map(rows.map((row) => [row.id, row]));
    const row0 = byId.get(p0.playerId);
    const row1 = byId.get(p1.playerId);
    if (!row0 || !row1) {
      await conn.rollback();
      return null;
    }

    const rated = computeMatchRatings(
      { cardTotal: p0.cardTotal, elo: row0.elo },
      { cardTotal: p1.cardTotal, elo: row1.elo },
      winnerIndex,
    );

    const matchId = `match-${randomUUID()}`;
    const winnerPlayerId =
      winnerIndex === 0
        ? p0.playerId
        : winnerIndex === 1
          ? p1.playerId
          : null;

    await conn.execute(
      `INSERT INTO matches (id, room_id, match_type, stake_per_player, pot_amount, winner_player_id)
       VALUES (:id, :roomId, 'random', :stakePerPlayer, :potAmount, :winnerPlayerId)`,
      {
        id: matchId,
        roomId,
        stakePerPlayer: safeStake,
        potAmount: safePot,
        winnerPlayerId,
      },
    );

    const seats = [
      { playerId: p0.playerId, seat: 0, cardTotal: p0.cardTotal, ...rated.a },
      { playerId: p1.playerId, seat: 1, cardTotal: p1.cardTotal, ...rated.b },
    ];

    for (const seat of seats) {
      await conn.execute(
        `INSERT INTO match_players (
           match_id, player_id, seat, card_total, result,
           points_earned, elo_before, elo_after, elo_delta
         ) VALUES (
           :matchId, :playerId, :seat, :cardTotal, :result,
           :pointsEarned, :eloBefore, :eloAfter, :eloDelta
         )`,
        {
          matchId,
          playerId: seat.playerId,
          seat: seat.seat,
          cardTotal: seat.cardTotal,
          result: seat.result,
          pointsEarned: seat.pointsEarned,
          eloBefore: seat.eloBefore,
          eloAfter: seat.eloAfter,
          eloDelta: seat.eloDelta,
        },
      );

      const winInc = seat.result === 'win' ? 1 : 0;
      const lossInc = seat.result === 'loss' ? 1 : 0;
      const drawInc = seat.result === 'draw' ? 1 : 0;

      let moneyUpdate = '';
      const updateParams = {
        elo: seat.eloAfter,
        points: seat.pointsEarned,
        wins: winInc,
        losses: lossInc,
        draws: drawInc,
        playerId: seat.playerId,
      };

      const playerRow = byId.get(seat.playerId);
      const currentMoney = Number(playerRow?.money) || 0;
      const currentChips = Number(playerRow?.chips) || 0;
      let moneyAfter = currentMoney;

      if (safeStake > 0) {
        if (seat.result === 'win') {
          moneyUpdate = ', money = money + :stake';
          updateParams.stake = safeStake;
          moneyAfter = currentMoney + safeStake;
        } else if (seat.result === 'loss') {
          moneyUpdate = ', money = GREATEST(0, money - :stake)';
          updateParams.stake = safeStake;
          moneyAfter = Math.max(0, currentMoney - safeStake);
        }
      }

      seat.moneyAfter = moneyAfter;
      seat.chipsAfter = currentChips;

      await conn.execute(
        `UPDATE players
         SET elo = :elo,
             total_points = total_points + :points,
             wins = wins + :wins,
             losses = losses + :losses,
             draws = draws + :draws
             ${moneyUpdate}
         WHERE id = :playerId`,
        updateParams,
      );
    }

    await conn.commit();
    return {
      matchId,
      players: seats.map((seat) => ({
        playerId: seat.playerId,
        result: seat.result,
        pointsEarned: seat.pointsEarned,
        eloBefore: seat.eloBefore,
        eloAfter: seat.eloAfter,
        eloDelta: seat.eloDelta,
        moneyAfter: seat.moneyAfter,
        chipsAfter: seat.chipsAfter,
      })),
    };
  } catch (error) {
    await conn.rollback();
    throw error;
  } finally {
    conn.release();
  }
}

function clampPaging(limit, offset, { maxLimit = 100, defaultLimit = 50 } = {}) {
  const lim = Number.parseInt(String(limit ?? defaultLimit), 10);
  const off = Number.parseInt(String(offset ?? 0), 10);
  return {
    limit: Number.isFinite(lim) ? Math.min(Math.max(lim, 1), maxLimit) : defaultLimit,
    offset: Number.isFinite(off) ? Math.max(off, 0) : 0,
  };
}

async function getLeaderboard({ limit = 50, offset = 0 } = {}) {
  const paging = clampPaging(limit, offset);
  const pool = getPool();
  const [rows] = await pool.execute(
    `SELECT id, display_name, username, elo, total_points, wins, losses, draws, deck_id
     FROM players
     ORDER BY elo DESC, total_points DESC, id ASC
     LIMIT ${paging.limit} OFFSET ${paging.offset}`,
  );

  return {
    entries: rows.map((row, index) => ({
      rank: paging.offset + index + 1,
      playerId: row.id,
      name: row.display_name,
      username: row.username,
      elo: row.elo,
      totalPoints: row.total_points,
      wins: row.wins,
      losses: row.losses,
      draws: row.draws,
      deckId: row.deck_id || 'default',
    })),
  };
}

async function getPlayerRank(playerId) {
  if (!playerId) return null;
  const pool = getPool();
  const [rows] = await pool.execute(
    `SELECT id, display_name, username, elo, total_points, wins, losses, draws, deck_id
     FROM players
     WHERE id = :playerId
     LIMIT 1`,
    { playerId },
  );
  const row = rows[0];
  if (!row) return null;

  const [rankRows] = await pool.execute(
    `SELECT COUNT(*) AS better
     FROM players
     WHERE elo > :elo
        OR (elo = :elo AND total_points > :points)
        OR (elo = :elo AND total_points = :points AND id < :playerId)`,
    {
      elo: row.elo,
      points: row.total_points,
      playerId: row.id,
    },
  );

  return {
    rank: Number(rankRows[0].better) + 1,
    playerId: row.id,
    name: row.display_name,
    username: row.username,
    elo: row.elo,
    totalPoints: row.total_points,
    wins: row.wins,
    losses: row.losses,
    draws: row.draws,
    deckId: row.deck_id || 'default',
  };
}

async function getMatchHistory({ playerId, limit = 20, offset = 0 } = {}) {
  if (!playerId) return { matches: [] };
  const paging = clampPaging(limit, offset, {
    maxLimit: 50,
    defaultLimit: 20,
  });
  const pool = getPool();
  const [rows] = await pool.execute(
    `SELECT
       m.id AS match_id,
       m.created_at,
       mp.result,
       mp.card_total,
       mp.points_earned,
       mp.elo_delta,
       mp.elo_after,
       opp.display_name AS opponent_name,
       opp.username AS opponent_username,
       opp_mp.card_total AS opponent_card_total
     FROM match_players mp
     INNER JOIN matches m ON m.id = mp.match_id
     INNER JOIN match_players opp_mp
       ON opp_mp.match_id = mp.match_id AND opp_mp.player_id <> mp.player_id
     INNER JOIN players opp ON opp.id = opp_mp.player_id
     WHERE mp.player_id = :playerId
     ORDER BY m.created_at DESC, m.id DESC
     LIMIT ${paging.limit} OFFSET ${paging.offset}`,
    { playerId },
  );

  return {
    matches: rows.map((row) => ({
      matchId: row.match_id,
      createdAt:
        row.created_at instanceof Date
          ? row.created_at.toISOString()
          : row.created_at,
      result: row.result,
      cardTotal: row.card_total,
      opponentName: row.opponent_name || row.opponent_username || 'Opponent',
      opponentCardTotal: row.opponent_card_total,
      pointsEarned: row.points_earned,
      eloDelta: row.elo_delta,
      eloAfter: row.elo_after,
    })),
  };
}

module.exports = {
  ELO_START,
  ELO_K,
  ELO_FLOOR,
  POINTS_WIN_BASE,
  POINTS_DRAW_BASE,
  POINTS_LOSS_BASE,
  POINTS_MARGIN_CAP,
  expectedScore,
  applyElo,
  marginPoints,
  computeMatchRatings,
  ensureRankingSchema,
  recordRankedMatch,
  getLeaderboard,
  getPlayerRank,
  getMatchHistory,
};
