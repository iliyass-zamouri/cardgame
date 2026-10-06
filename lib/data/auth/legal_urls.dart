// ignore_for_file: constant_identifier_names

const _legalBase = 'https://iliyass-zamouri.github.io/apps-privacy/shadowhand';

/// Legal document URLs (override via `--dart-define` / flavor JSON).
const PRIVACY_URL = String.fromEnvironment(
  'PRIVACY_URL',
  defaultValue: '$_legalBase/privacy/',
);

const TOS_URL = String.fromEnvironment(
  'TOS_URL',
  defaultValue: '$_legalBase/terms/',
);

const DELETE_ACCOUNT_URL = String.fromEnvironment(
  'DELETE_ACCOUNT_URL',
  defaultValue: '$_legalBase/delete-account/',
);
