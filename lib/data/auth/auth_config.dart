String get httpBaseUrl {
  const fromDefine = String.fromEnvironment('HTTP_URL');
  if (fromDefine.isNotEmpty) {
    return fromDefine.replaceAll(RegExp(r'/+$'), '');
  }
  const host = String.fromEnvironment('WS_HOST', defaultValue: '127.0.0.1');
  const port = String.fromEnvironment('WS_PORT', defaultValue: '8080');
  return 'http://$host:$port';
}

String? get googleServerClientId {
  const fromDefine = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
  if (fromDefine.isEmpty) return null;
  return fromDefine;
}
