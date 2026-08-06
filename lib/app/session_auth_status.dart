enum SessionAuthStatus {
  signedOut,
  guest,
  google;

  static SessionAuthStatus fromStorage(String? raw) {
    return switch (raw) {
      'guest' => SessionAuthStatus.guest,
      'google' => SessionAuthStatus.google,
      _ => SessionAuthStatus.signedOut,
    };
  }

  String get storageValue => name;

  bool get isInApp => this != SessionAuthStatus.signedOut;

  String get linkedAccountLabel => switch (this) {
    SessionAuthStatus.guest => 'Guest',
    SessionAuthStatus.google => 'Google',
    SessionAuthStatus.signedOut => 'None',
  };
}
