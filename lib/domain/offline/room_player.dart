class RoomPlayer {
  final String id;
  String? playerId;
  String displayName;
  String avatarId;
  String deckId;
  bool connected;
  List<String> cards;
  String? handCard;
  String launch;
  int total;
  bool jackPeekAvailable;
  bool queenAbilityAvailable;

  RoomPlayer({
    required this.id,
    this.playerId,
    this.displayName = 'Player',
    this.avatarId = 'default',
    this.deckId = 'default',
    this.connected = true,
    List<String>? cards,
    this.handCard,
    this.launch = 'notLaunched',
    this.total = 0,
    this.jackPeekAvailable = false,
    this.queenAbilityAvailable = false,
  }) : cards = cards ?? <String>[];
}
