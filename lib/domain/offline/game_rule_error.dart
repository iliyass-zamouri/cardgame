class GameRuleError implements Exception {
  final String code;
  final String message;

  GameRuleError(this.code, this.message);

  @override
  String toString() => 'GameRuleError($code): $message';
}
