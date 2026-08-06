import 'dart:async';
import 'dart:math';

import 'package:game_protocol/game_protocol.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/server_config.dart';

abstract class SocketClient {
  Stream<WireEnvelope> get messages;
  Stream<bool> get connectionState;
  bool get isConnected;
  Future<void> connect({
    String? token,
    String? activeMatchId,
    String? playerId,
  });
  void send(String event, Map<String, dynamic> payload);
  Future<void> close();
}

class NoopSocketClient implements SocketClient {
  final _controller = StreamController<WireEnvelope>.broadcast();
  final _state = StreamController<bool>.broadcast();

  @override
  Stream<WireEnvelope> get messages => _controller.stream;

  @override
  Stream<bool> get connectionState => _state.stream;

  @override
  bool get isConnected => false;

  @override
  Future<void> connect({
    String? token,
    String? activeMatchId,
    String? playerId,
  }) async {}

  @override
  void send(String event, Map<String, dynamic> payload) {}

  @override
  Future<void> close() async {
    await _controller.close();
    await _state.close();
  }
}

class WsSocketClient implements SocketClient {
  WsSocketClient(this.config);

  final ServerConfig config;
  WebSocketChannel? _channel;
  final _controller = StreamController<WireEnvelope>.broadcast();
  final _state = StreamController<bool>.broadcast();
  StreamSubscription? _sub;
  String? _token;
  String? _activeMatchId;
  String? _playerId;
  bool _closed = false;
  int _attempt = 0;

  @override
  Stream<WireEnvelope> get messages => _controller.stream;

  @override
  Stream<bool> get connectionState => _state.stream;

  @override
  bool get isConnected => _channel != null;

  @override
  Future<void> connect({
    String? token,
    String? activeMatchId,
    String? playerId,
  }) async {
    _token = token;
    _activeMatchId = activeMatchId;
    _playerId = playerId;
    _closed = false;
    _attempt = 0;
    await _open();
  }

  Future<void> _open() async {
    await _sub?.cancel();
    await _channel?.sink.close();
    final uri = Uri.parse(config.wsUrl).replace(
      queryParameters: _token == null ? null : {'token': _token!},
    );
    _channel = WebSocketChannel.connect(uri);
    _state.add(true);
    _attempt = 0;
    _sub = _channel!.stream.listen(
      (raw) {
        final envelope = WireEnvelope.tryDecode(raw.toString());
        if (envelope != null) _controller.add(envelope);
      },
      onDone: _scheduleReconnect,
      onError: (_) => _scheduleReconnect,
    );
    if (_activeMatchId != null && _playerId != null) {
      send(
        ProtocolEvents.matchJoin,
        MatchJoinMessage(matchId: _activeMatchId!, playerId: _playerId).toJson(),
      );
    }
  }

  void _scheduleReconnect() {
    if (_closed) return;
    _state.add(false);
    _attempt += 1;
    final delayMs = min(30000, 500 * pow(2, _attempt - 1).toInt());
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (!_closed) _open();
    });
  }

  @override
  void send(String event, Map<String, dynamic> payload) {
    _channel?.sink.add(WireEnvelope(event: event, payload: payload).encode());
  }

  @override
  Future<void> close() async {
    _closed = true;
    await _sub?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _state.add(false);
  }
}
