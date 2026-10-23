import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/app/table_social_prefs.dart';
import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TableChatKind { text, phrase, emoji }

class TableChatMessage {
  const TableChatMessage({
    required this.id,
    required this.fromPlayerId,
    required this.kind,
    required this.value,
    required this.at,
    required this.mine,
  });

  final String id;
  final String fromPlayerId;
  final TableChatKind kind;

  /// Free text, phrase id or emoji id depending on [kind].
  final String value;
  final DateTime at;
  final bool mine;

  /// Parses a server `chatMessage`; null when malformed.
  static TableChatMessage? fromJson(
    Map<String, dynamic> json, {
    required String? opponentPlayerId,
  }) {
    final kind = switch (json['kind']) {
      'text' => TableChatKind.text,
      'phrase' => TableChatKind.phrase,
      'emoji' => TableChatKind.emoji,
      _ => null,
    };
    if (kind == null) return null;
    final value = switch (kind) {
      TableChatKind.text => json['text'],
      TableChatKind.phrase => json['phraseId'],
      TableChatKind.emoji => json['emojiId'],
    };
    if (value is! String || value.isEmpty) return null;
    final fromPlayerId = json['fromPlayerId'] as String? ?? '';
    final at = (json['at'] as num?)?.toInt();
    return TableChatMessage(
      id: json['id'] as String? ?? '${DateTime.now().microsecondsSinceEpoch}',
      fromPlayerId: fromPlayerId,
      kind: kind,
      value: value,
      at: at == null ? DateTime.now() : DateTime.fromMillisecondsSinceEpoch(at),
      mine: opponentPlayerId == null || fromPlayerId != opponentPlayerId,
    );
  }
}

class TableChatState {
  const TableChatState({
    this.roomId,
    this.messages = const [],
    this.unread = 0,
    this.opponentMuted = false,
    this.panelOpen = false,
  });

  final String? roomId;

  /// Oldest first.
  final List<TableChatMessage> messages;
  final int unread;

  /// Hides opponent chat and silences their voice for this table.
  final bool opponentMuted;
  final bool panelOpen;

  TableChatState copyWith({
    List<TableChatMessage>? messages,
    int? unread,
    bool? opponentMuted,
    bool? panelOpen,
  }) {
    return TableChatState(
      roomId: roomId,
      messages: messages ?? this.messages,
      unread: unread ?? this.unread,
      opponentMuted: opponentMuted ?? this.opponentMuted,
      panelOpen: panelOpen ?? this.panelOpen,
    );
  }
}

final tableChatProvider = NotifierProvider<TableChatController, TableChatState>(
  TableChatController.new,
);

/// Chat log of the current table. Resets whenever the room changes.
class TableChatController extends Notifier<TableChatState> {
  static const maxMessages = 50;
  static const maxTextLength = 120;

  @override
  TableChatState build() {
    final roomId = ref.watch(
      gameSessionProvider.select((state) => state.game?.roomId),
    );
    final subscription = ref
        .watch(gameSessionProvider.notifier)
        .tableEvents
        .where((event) => event['type'] == 'chatMessage')
        .listen(receive);
    ref.onDispose(subscription.cancel);
    return TableChatState(roomId: roomId);
  }

  void receive(Map<String, dynamic> json) {
    final opponentId = ref.read(gameSessionProvider).game?.opponent?.playerId;
    final message = TableChatMessage.fromJson(
      json,
      opponentPlayerId: opponentId,
    );
    if (message == null) return;
    if (!message.mine &&
        (state.opponentMuted || !ref.read(tableSocialPrefsProvider).showChat)) {
      return;
    }
    if (state.messages.any((m) => m.id == message.id)) return;
    final messages = [...state.messages, message];
    state = state.copyWith(
      messages:
          messages.length > maxMessages
              ? messages.sublist(messages.length - maxMessages)
              : messages,
      unread:
          !message.mine && !state.panelOpen ? state.unread + 1 : state.unread,
    );
  }

  void sendPhrase(String phraseId) =>
      _send({'kind': 'phrase', 'phraseId': phraseId});

  void sendEmoji(String emojiId) =>
      _send({'kind': 'emoji', 'emojiId': emojiId});

  /// Returns false when there is nothing to send.
  bool sendText(String raw) {
    final text = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) return false;
    final chars = text.characters;
    _send({
      'kind': 'text',
      'text':
          chars.length > maxTextLength
              ? chars.take(maxTextLength).toString()
              : text,
    });
    return true;
  }

  void setPanelOpen(bool open) {
    state = state.copyWith(panelOpen: open, unread: open ? 0 : state.unread);
  }

  void setOpponentMuted(bool muted) {
    state = state.copyWith(
      opponentMuted: muted,
      // Muting also clears what they already said from the table.
      messages: muted ? state.messages.where((m) => m.mine).toList() : null,
      unread: muted ? 0 : null,
    );
  }

  void _send(Map<String, dynamic> payload) {
    ref.read(gameSessionProvider.notifier).sendChat(payload);
  }
}
