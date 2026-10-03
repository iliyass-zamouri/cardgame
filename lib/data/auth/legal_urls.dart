// ignore_for_file: constant_identifier_names

/// Legal document URLs (override via `--dart-define` / flavor JSON).
const PRIVACY_URL = String.fromEnvironment(
  'PRIVACY_URL',
  defaultValue: 'https://hailsom.com/privacy',
);

const TOS_URL = String.fromEnvironment(
  'TOS_URL',
  defaultValue: 'https://hailsom.com/terms',
);
