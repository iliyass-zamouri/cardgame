import 'dart:async';

import 'dart:convert';

import 'package:cardgame/data/game_socket.dart';

class FakeGameSocket implements GameSocket {
  final StreamController<String> _controller =
      StreamController<String>.broadcast();
  final List<String> sent = [];

  @override
  Stream<String> get stream => _controller.stream;

  @override
  void send(String message) {
    sent.add(message);
  }

  void emit(Map<String, dynamic> message) {
    _controller.add(jsonEncode(message));
  }

  @override
  void close() {
    _controller.close();
  }
}
