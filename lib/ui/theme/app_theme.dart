import 'package:cardgame/data/app/app_theme_config.dart';
import 'package:cardgame/ui/theme/casino_palette.dart';
import 'package:flutter/foundation.dart';

/// A colour theme: the palette every [CasinoColors] token reads, and whether
/// its motion layer may run.
@immutable
class AppTheme {
  const AppTheme({
    required this.id,
    required this.palette,
    this.animated = true,
  });

  static const casino = AppTheme(
    id: AppThemeId.casino,
    palette: CasinoPalette.casino,
  );
  static const halloween = AppTheme(
    id: AppThemeId.halloween,
    palette: CasinoPalette.halloween,
  );

  final AppThemeId id;
  final CasinoPalette palette;

  /// Motion layers (bats, embers) run only when true.
  final bool animated;

  static AppTheme _active = casino;

  /// The theme [CasinoColors] reads right now. Change it with [activate], then
  /// rebuild painted UI with `refreshEntireUi` so the change shows on screen.
  static AppTheme get active => _active;

  static void activate(AppTheme theme) => _active = theme;

  static AppTheme of(AppThemeId id, {bool animated = true}) {
    final theme = switch (id) {
      AppThemeId.casino => casino,
      AppThemeId.halloween => halloween,
    };
    return theme.copyWith(animated: animated);
  }

  AppTheme copyWith({bool? animated}) =>
      AppTheme(id: id, palette: palette, animated: animated ?? this.animated);

  @override
  bool operator ==(Object other) =>
      other is AppTheme && other.id == id && other.animated == animated;

  @override
  int get hashCode => Object.hash(id, animated);
}
