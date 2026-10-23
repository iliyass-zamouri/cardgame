import 'dart:convert';

import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/app/session_auth_repository.dart';
import 'package:cardgame/app/session_auth_status.dart';
import 'package:cardgame/app/table_chat_controller.dart';
import 'package:cardgame/app/table_social_prefs.dart';
import 'package:cardgame/app/voice_chat_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_game_socket.dart';

Future<(ProviderContainer, FakeGameSocket)> _seatedAtTable() async {
  final socket = FakeGameSocket();
  final container = ProviderContainer(
    overrides: [
      gameSocketFactoryProvider.overrideWithValue(() => socket),
      sessionAuthRepositoryProvider.overrideWithValue(
        SessionAuthRepository.memory(SessionAuthStatus.guest),
      ),
      playerProfileRepositoryProvider.overrideWithValue(
        PlayerProfileRepository.memory(
          const PlayerProfile(
            playerId: 'guest-1',
            name: 'Lucky Ace',
            username: 'lucky_ace',
          ),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  container.read(gameSessionProvider);
  await Future<void>.delayed(Duration.zero);
  socket.emit({'type': 'connected', 'protocolVersion': 1, 'clientId': 'c1'});
  socket.emit(_snapshot('ABC123'));
  await Future<void>.delayed(Duration.zero);
  // Keep the chat notifier alive like the HUD does.
  container.listen(tableChatProvider, (_, __) {});
  return (container, socket);
}

Map<String, dynamic> _chat(
  String from,
  String kind,
  String value, {
  String? id,
}) {
  final field = switch (kind) {
    'text' => 'text',
    'phrase' => 'phraseId',
    _ => 'emojiId',
  };
  return {
    'type': 'chatMessage',
    'id': id ?? '$from-$kind-$value',
    'fromPlayerId': from,
    'kind': kind,
    field: value,
    'at': 1700000000000,
  };
}

void main() {
  test('opponent messages count as unread until the panel opens', () async {
    final (container, socket) = await _seatedAtTable();

    socket.emit(_chat('guest-2', 'phrase', 'goodLuck'));
    socket.emit(_chat('guest-1', 'emoji', 'clap'));
    await Future<void>.delayed(Duration.zero);

    final state = container.read(tableChatProvider);
    expect(state.messages, hasLength(2));
    expect(state.messages.first.mine, isFalse);
    expect(state.messages.first.kind, TableChatKind.phrase);
    expect(state.messages.first.value, 'goodLuck');
    expect(state.messages.last.mine, isTrue);
    expect(state.unread, 1);

    container.read(tableChatProvider.notifier).setPanelOpen(true);
    expect(container.read(tableChatProvider).unread, 0);
  });

  test('duplicate and malformed messages are ignored', () async {
    final (container, socket) = await _seatedAtTable();

    socket.emit(_chat('guest-2', 'emoji', 'laugh', id: 'm1'));
    socket.emit(_chat('guest-2', 'emoji', 'laugh', id: 'm1'));
    socket.emit({'type': 'chatMessage', 'id': 'm2', 'kind': 'bogus'});
    await Future<void>.delayed(Duration.zero);

    expect(container.read(tableChatProvider).messages, hasLength(1));
  });

  test('muting the opponent hides their messages', () async {
    final (container, socket) = await _seatedAtTable();
    socket.emit(_chat('guest-2', 'text', 'hello'));
    await Future<void>.delayed(Duration.zero);

    container.read(tableChatProvider.notifier).setOpponentMuted(true);
    expect(container.read(tableChatProvider).messages, isEmpty);

    socket.emit(_chat('guest-2', 'text', 'still here?'));
    socket.emit(_chat('guest-1', 'text', 'mine'));
    await Future<void>.delayed(Duration.zero);
    final messages = container.read(tableChatProvider).messages;
    expect(messages.map((m) => m.value), ['mine']);
  });

  test('hiding opponent chat in settings drops their messages', () async {
    final (container, socket) = await _seatedAtTable();
    await container.read(tableSocialPrefsProvider.notifier).setShowChat(false);

    socket.emit(_chat('guest-2', 'emoji', 'angry'));
    await Future<void>.delayed(Duration.zero);
    expect(container.read(tableChatProvider).messages, isEmpty);
  });

  test('chat resets when the room changes', () async {
    final (container, socket) = await _seatedAtTable();
    socket.emit(_chat('guest-2', 'emoji', 'cool'));
    await Future<void>.delayed(Duration.zero);
    container.read(tableChatProvider.notifier).setOpponentMuted(true);

    socket.emit(_snapshot('XYZ789'));
    await Future<void>.delayed(Duration.zero);

    final state = container.read(tableChatProvider);
    expect(state.roomId, 'XYZ789');
    expect(state.messages, isEmpty);
    expect(state.opponentMuted, isFalse);
  });

  test('sending phrases, emojis and text goes through chatSend', () async {
    final (container, socket) = await _seatedAtTable();
    final chat = container.read(tableChatProvider.notifier);

    chat.sendPhrase('wellPlayed');
    expect(jsonDecode(socket.sent.last), {
      'type': 'chatSend',
      'kind': 'phrase',
      'phraseId': 'wellPlayed',
    });

    chat.sendEmoji('love');
    expect(jsonDecode(socket.sent.last), {
      'type': 'chatSend',
      'kind': 'emoji',
      'emojiId': 'love',
    });

    expect(chat.sendText('   '), isFalse);
    expect(chat.sendText('  nice   one  '), isTrue);
    expect(jsonDecode(socket.sent.last), {
      'type': 'chatSend',
      'kind': 'text',
      'text': 'nice one',
    });
  });

  test('voiceState from the opponent updates their mic indicator', () async {
    final (container, socket) = await _seatedAtTable();
    container.listen(voiceChatProvider, (_, __) {});

    socket.emit({
      'type': 'voiceState',
      'fromPlayerId': 'guest-2',
      'micOn': true,
    });
    await Future<void>.delayed(Duration.zero);
    expect(container.read(voiceChatProvider).peerMicOn, isTrue);
  });
}

Map<String, dynamic> _snapshot(String roomId) {
  return {
    'type': 'snapshot',
    'roomId': roomId,
    'version': 2,
    'status': 'playing',
    'ready': true,
    'deckCount': 45,
    'discardTop': 'A2',
    'turn': 'you',
    'you': {
      'connected': true,
      'displayName': 'Lucky Ace',
      'playerId': 'guest-1',
      'launch': 'ended',
      'total': 5,
      'cards': [
        {'index': 0, 'tag': 'A1', 'visible': true},
      ],
      'handCard': null,
      'hasHandCard': false,
    },
    'opponent': {
      'connected': true,
      'displayName': 'Sharp King',
      'playerId': 'guest-2',
      'avatarId': 'golden-king',
      'launch': 'ended',
      'total': 8,
      'cards': [
        {'index': 0, 'tag': null, 'visible': false},
      ],
      'handCard': null,
      'hasHandCard': false,
    },
    'result': null,
    'lastAction': null,
  };
}
