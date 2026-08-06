/// Wire event names shared by client and server.
abstract final class ProtocolEvents {
  // Client → server
  static const matchQueue = 'match.queue';
  static const matchCancel = 'match.cancel';
  static const matchJoin = 'match.join';
  static const matchLeave = 'match.leave';
  static const cardAction = 'card.action';
  static const roomCreate = 'room.create';
  static const roomJoin = 'room.join';
  static const roomLeave = 'room.leave';
  static const roomStart = 'room.start';
  static const roomKick = 'room.kick';
  static const roomInvite = 'room.invite';
  static const roomPresence = 'room.presence';
  static const rematchJoin = 'rematch.join';
  static const rematchReady = 'rematch.ready';
  static const rematchLeave = 'rematch.leave';

  // Server → client
  static const matchFound = 'match.found';
  static const matchSnapshot = 'match.snapshot';
  static const matchError = 'match.error';
  static const roomState = 'room.state';
  static const rematchState = 'rematch.state';

  /// All known event names (parity tests).
  static const all = <String>{
    matchQueue,
    matchCancel,
    matchJoin,
    matchLeave,
    cardAction,
    roomCreate,
    roomJoin,
    roomLeave,
    roomStart,
    roomKick,
    roomInvite,
    roomPresence,
    rematchJoin,
    rematchReady,
    rematchLeave,
    matchFound,
    matchSnapshot,
    matchError,
    roomState,
    rematchState,
  };
}
