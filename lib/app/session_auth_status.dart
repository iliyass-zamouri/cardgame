enum SessionAuthStatus {
  signedOut,
  guest,
  google,
  apple;

  static SessionAuthStatus fromStorage(String? raw) {
    return switch (raw) {
      'guest' => SessionAuthStatus.guest,
      'google' => SessionAuthStatus.google,
      'apple' => SessionAuthStatus.apple,
      _ => SessionAuthStatus.signedOut,
    };
  }

  String get storageValue => name;

  bool get isInApp => this != SessionAuthStatus.signedOut;

  String get linkedAccountLabel => switch (this) {
    SessionAuthStatus.guest => 'Guest',
    SessionAuthStatus.google => 'Google',
    SessionAuthStatus.apple => 'Apple',
    SessionAuthStatus.signedOut => 'None',
  };
}
