import 'package:country_flags/country_flags.dart' as cf;
import 'package:flutter/widgets.dart';

/// Used to validate a code (empty means invalid). Flag emoji for an ISO 3166-1 alpha-2 code, or '' when the code is invalid.
String flagEmoji(String? code) {
  final c = code?.trim().toUpperCase();
  if (c == null || !RegExp(r'^[A-Z]{2}$').hasMatch(c)) return '';
  return String.fromCharCodes(c.codeUnits.map((u) => 0x1F1E6 + u - 65));
}

class CountryFlag extends StatelessWidget {
  const CountryFlag({super.key, required this.code, this.size = 16});

  final String? code;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (flagEmoji(code).isEmpty) return const SizedBox.shrink();
    return cf.CountryFlag.fromCountryCode(
      code!.trim().toUpperCase(),
      theme: cf.ImageTheme(
        width: size * 1.4,
        height: size,
        shape: const cf.RoundedRectangle(3),
      ),
    );
  }
}
