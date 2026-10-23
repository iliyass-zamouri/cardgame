import 'dart:convert';

import 'package:cardgame/data/offline/offline_game_socket.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('offline robot always answers a chat message', () async {
    final socket = OfflineGameSocket(
      humanDisplayName: 'Ace',
      humanPlayerId: 'local-player',
    );
    addTearDown(socket.close);
    final robotReply = socket.stream
        .map((raw) => jsonDecode(raw) as Map<String, dynamic>)
        .firstWhere(
          (m) => m['type'] == 'chatMessage' && m['fromPlayerId'] == 'robot',
        )
        .timeout(const Duration(seconds: 5));

    await Future<void>.delayed(Duration.zero);
    socket.send(
      jsonEncode({'type': 'chatSend', 'kind': 'phrase', 'phraseId': 'gg'}),
    );

    final reply = await robotReply;
    expect(
      ['gg', 'wellPlayed', 'clap'],
      contains(reply['phraseId'] ?? reply['emojiId']),
    );
  });
}
