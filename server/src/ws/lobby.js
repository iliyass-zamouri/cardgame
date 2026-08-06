import crypto from 'node:crypto';

export function generateRoomCode() {
  return crypto.randomBytes(3).toString('hex').toUpperCase();
}

export function normalizeRoomCode(code) {
  return String(code ?? '').trim().toUpperCase();
}

export class PrivateLobby {
  constructor({ host, stake = 100 }) {
    this.code = generateRoomCode();
    this.hostPlayerId = host.playerId;
    this.stake = stake;
    this.members = [
      {
        playerId: host.playerId,
        connectionId: host.connectionId,
        name: host.displayName ?? 'Host',
        isHost: true,
      },
    ];
    this.closed = false;
  }

  add(member) {
    if (this.members.find((m) => m.playerId === member.playerId)) return;
    if (this.members.length >= 2) throw new Error('full');
    this.members.push({
      playerId: member.playerId,
      connectionId: member.connectionId,
      name: member.displayName ?? 'Guest',
      isHost: false,
    });
  }

  remove(playerId) {
    this.members = this.members.filter((m) => m.playerId !== playerId);
    if (!this.members.length) this.closed = true;
    else if (playerId === this.hostPlayerId) {
      this.hostPlayerId = this.members[0].playerId;
      this.members[0].isHost = true;
    }
  }

  kick(hostPlayerId, targetPlayerId) {
    if (hostPlayerId !== this.hostPlayerId) throw new Error('forbidden');
    this.remove(targetPlayerId);
  }

  toWireState(reason) {
    return {
      code: this.code,
      hostPlayerId: this.hostPlayerId,
      members: this.members.map((m) => ({
        playerId: m.playerId,
        name: m.name,
        isHost: m.isHost,
      })),
      stake: this.stake,
      closed: this.closed,
      reason,
    };
  }
}
