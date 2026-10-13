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

/// iOS OAuth client. Same value as `GOOGLE_IOS_CLIENT_ID` in
/// `ios/Flutter/Debug.xcconfig` and `Release.xcconfig`.
///
/// `google_sign_in_ios` only applies [googleServerClientId] when an iOS
/// client id is present (Dart `clientId` or `CLIENT_ID` in
/// `GoogleService-Info.plist`). The flavor `GOOGLE_SERVER_CLIENT_ID` is the
/// Web client and must stay the server audience on every platform.
String get googleIosClientId {
  const fromDefine = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
  if (fromDefine.isNotEmpty) return fromDefine;
  return '1078123174745-vqtuf28vb3aurkmkslg657rel2gfv7cg.apps.googleusercontent.com';
}
