/** Wire event names — keep in sync with packages/game_protocol. */
export const ProtocolEvents = {
  matchQueue: 'match.queue',
  matchCancel: 'match.cancel',
  matchJoin: 'match.join',
  matchLeave: 'match.leave',
  cardAction: 'card.action',
  roomCreate: 'room.create',
  roomJoin: 'room.join',
  roomLeave: 'room.leave',
  roomStart: 'room.start',
  roomKick: 'room.kick',
  roomInvite: 'room.invite',
  roomPresence: 'room.presence',
  rematchJoin: 'rematch.join',
  rematchReady: 'rematch.ready',
  rematchLeave: 'rematch.leave',
  matchFound: 'match.found',
  matchSnapshot: 'match.snapshot',
  matchError: 'match.error',
  roomState: 'room.state',
  rematchState: 'rematch.state',
};

export const ALL_EVENTS = Object.values(ProtocolEvents);

export function encodeEnvelope(event, payload) {
  return JSON.stringify({ event, payload });
}

export function decodeEnvelope(raw) {
  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return null;
  }
  if (!parsed || typeof parsed !== 'object') return null;
  if (typeof parsed.event !== 'string' || !parsed.event) return null;
  if (!parsed.payload || typeof parsed.payload !== 'object') return null;
  return { event: parsed.event, payload: parsed.payload };
}
