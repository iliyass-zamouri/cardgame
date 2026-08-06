import 'package:flutter/services.dart';

/// Ensures Cinzel is registered for canvas text. Pubspec registration alone
/// can fall back to .notdef tofu boxes under flutter_test; an explicit
/// [FontLoader] always paints real glyphs.
Future<void> ensureCardFontsLoaded() async {
  if (_loaded) return;
  final loader = FontLoader('Cinzel');
  loader.addFont(rootBundle.load('assets/fonts/Cinzel-Regular.ttf'));
  loader.addFont(rootBundle.load('assets/fonts/Cinzel-Bold.ttf'));
  await loader.load();
  _loaded = true;
}

bool _loaded = false;
