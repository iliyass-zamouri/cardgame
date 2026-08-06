import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:flutter/services.dart';

/// Ensures Cinzel is registered for canvas text. Pubspec registration alone
/// can fall back to .notdef tofu boxes under flutter_test; an explicit
/// [FontLoader] always paints real glyphs.
Future<void> ensureCardFontsLoaded() async {
  if (_cardLoaded) return;
  final loader = FontLoader(CasinoFonts.display);
  loader.addFont(rootBundle.load('assets/fonts/Cinzel-Regular.ttf'));
  loader.addFont(rootBundle.load('assets/fonts/Cinzel-Bold.ttf'));
  await loader.load();
  _cardLoaded = true;
}

/// Cairo for Arabic UI — FontLoader so Impeller actually attaches the face.
Future<void> ensureArabicUiFontLoaded() async {
  if (_arabicLoaded) return;
  final loader = FontLoader(CasinoFonts.arabicUi);
  loader.addFont(rootBundle.load('assets/fonts/Cairo-Regular.ttf'));
  loader.addFont(rootBundle.load('assets/fonts/Cairo-Medium.ttf'));
  loader.addFont(rootBundle.load('assets/fonts/Cairo-SemiBold.ttf'));
  loader.addFont(rootBundle.load('assets/fonts/Cairo-Bold.ttf'));
  await loader.load();
  _arabicLoaded = true;
}

bool _cardLoaded = false;
bool _arabicLoaded = false;
