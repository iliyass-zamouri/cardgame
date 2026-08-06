class ServerConfig {
  const ServerConfig({
    required this.httpUrl,
    required this.wsUrl,
    required this.onlineMp,
  });

  final String httpUrl;
  final String wsUrl;
  final bool onlineMp;

  static ServerConfig fromEnvironment() {
    const httpOverride = String.fromEnvironment('HTTP_URL');
    const wsOverride = String.fromEnvironment('WS_URL');
    const online = bool.fromEnvironment('ONLINE_MP', defaultValue: true);
    const base = String.fromEnvironment(
      'BASE_URL',
      defaultValue: 'http://127.0.0.1:8080',
    );

    final httpUrl = httpOverride.isNotEmpty ? httpOverride : base;
    final wsUrl = wsOverride.isNotEmpty
        ? wsOverride
        : _deriveWs(httpUrl);

    return ServerConfig(httpUrl: httpUrl, wsUrl: wsUrl, onlineMp: online);
  }

  static String _deriveWs(String http) {
    final uri = Uri.parse(http);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return Uri(
      scheme: scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: '/ws',
    ).toString();
  }
}
