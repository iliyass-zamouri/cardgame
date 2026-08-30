/// Shared identity payload from `/auth/guest` and `/auth/google`.
class ServerIdentity {
  const ServerIdentity({
    required this.playerId,
    required this.name,
    required this.username,
    required this.isNew,
    this.authType = 'guest',
    this.linkedFromGuest = false,
    this.money = 500,
    this.chips = 1,
  });

  final String playerId;
  final String name;
  final String username;
  final bool isNew;
  final String authType;
  final bool linkedFromGuest;
  final int money;
  final int chips;

  factory ServerIdentity.fromJson(Map<String, dynamic> json) {
    return ServerIdentity(
      playerId: json['playerId'] as String? ?? '',
      name: json['name'] as String? ?? 'Player',
      username: json['username'] as String? ?? 'player',
      isNew: json['isNew'] == true,
      authType: json['authType'] as String? ?? 'guest',
      linkedFromGuest: json['linkedFromGuest'] == true,
      money: (json['money'] as num?)?.toInt() ?? 500,
      chips: (json['chips'] as num?)?.toInt() ?? 1,
    );
  }
}

typedef GuestIdentity = ServerIdentity;
