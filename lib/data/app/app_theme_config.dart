import 'package:flutter/foundation.dart';

/// Colour themes the server can switch between. Keep in sync with `THEMES`
/// in server/app_theme.js.
enum AppThemeId { casino, halloween }

/// The theme the server picked, served through GET /app/config. `animated` is
/// the server's kill switch for a theme's motion layer.
@immutable
class AppThemeConfig {
  const AppThemeConfig({required this.id, this.animated = true});

  final AppThemeId id;
  final bool animated;

  /// Null for an id this build doesn't know, so the current theme is kept.
  static AppThemeConfig? tryFromJson(Map<dynamic, dynamic> json) {
    final id = AppThemeId.values.asNameMap()[json['id']];
    if (id == null) return null;
    return AppThemeConfig(id: id, animated: json['animated'] != false);
  }

  Map<String, Object> toJson() => {'id': id.name, 'animated': animated};

  @override
  bool operator ==(Object other) =>
      other is AppThemeConfig && other.id == id && other.animated == animated;

  @override
  int get hashCode => Object.hash(id, animated);
}
