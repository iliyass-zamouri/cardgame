abstract interface class GameSocket {
  Stream<String> get stream;
  void send(String message);
  void close();
}
