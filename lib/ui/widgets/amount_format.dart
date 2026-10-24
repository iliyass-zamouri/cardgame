/// 1234 -> 1234, 12500 -> 12.5K, 1020000 -> 1.02M.
String compactAmount(int value) {
  String trim(String s) =>
      s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;
  if (value >= 1000000) {
    return '${trim((value / 1000000).toStringAsFixed(2))}M';
  }
  if (value >= 10000) return '${trim((value / 1000).toStringAsFixed(1))}K';
  return '$value';
}

/// 1234567 -> 1,234,567, for amounts shown in full.
String groupedAmount(int value) {
  final digits = value.abs().toString();
  final out = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}
