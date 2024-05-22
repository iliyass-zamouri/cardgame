import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

const String url = 'ws://localhost:8080';

class SocketService {
  final WebSocketChannel _channel;

  SocketService() : _channel = WebSocketChannel.connect(Uri.parse(url));

  Stream<String> get stream => _channel.stream.map((event) {
        if (event is String) {
          return event;
        } else if (event is List<int>) {
          return utf8.decode(event);
        } else {
          throw UnsupportedError(
              'Unexpected message type: ${event.runtimeType}');
        }
      });

  void send(String message) {
    _channel.sink.add(message);
  }

  void close() {
    _channel.sink.close(status.goingAway);
  }
}
