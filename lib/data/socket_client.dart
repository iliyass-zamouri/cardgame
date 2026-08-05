import 'dart:convert';

import 'package:cardgame/data/game_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

String get socketUrl {
  const host = String.fromEnvironment('WS_HOST', defaultValue: '127.0.0.1');
  const port = String.fromEnvironment('WS_PORT', defaultValue: '8080');
  return 'ws://$host:$port';
}

class SocketClient implements GameSocket {
  final WebSocketChannel _channel;

  SocketClient() : _channel = WebSocketChannel.connect(Uri.parse(socketUrl));

  @override
  Stream<String> get stream => _channel.stream.map((event) {
        if (event is String) {
          return event;
        }
        if (event is List<int>) {
          return utf8.decode(event);
        }
        throw UnsupportedError(
          'Unexpected message type: ${event.runtimeType}',
        );
      });

  @override
  void send(String message) {
    _channel.sink.add(message);
  }

  @override
  void close() {
    _channel.sink.close(status.goingAway);
  }
}
