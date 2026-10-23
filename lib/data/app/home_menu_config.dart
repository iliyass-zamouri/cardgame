import 'package:flutter/foundation.dart';

/// Secondary play modes shown as cards under the primary play action.
enum HomeMode { createRoom, joinRoom, playVsRobot }

/// Tabs of the home bottom navigation bar.
enum HomeNavTab { shop, friends, home, collection, rules }

/// Which home menu entries show and in what order, served by GET /app/config.
/// The client owns each entry's look and action, so unknown ids are skipped.
@immutable
class HomeMenuConfig {
  const HomeMenuConfig({required this.modes, required this.nav});

  static const fallback = HomeMenuConfig(
    modes: HomeMode.values,
    nav: HomeNavTab.values,
  );

  final List<HomeMode> modes;
  final List<HomeNavTab> nav;

  factory HomeMenuConfig.fromJson(Map<dynamic, dynamic> json) {
    final nav = _parse(json['nav'], HomeNavTab.values, fallback.nav);
    // Home is the screen itself, so its tab can never be hidden.
    if (!nav.contains(HomeNavTab.home)) {
      nav.insert(nav.length ~/ 2, HomeNavTab.home);
    }
    return HomeMenuConfig(
      modes: List.unmodifiable(
        _parse(json['modes'], HomeMode.values, fallback.modes),
      ),
      nav: List.unmodifiable(nav),
    );
  }

  Map<String, Object> toJson() => {
    'modes': [for (final mode in modes) mode.name],
    'nav': [for (final tab in nav) tab.name],
  };

  static List<T> _parse<T extends Enum>(
    Object? raw,
    List<T> values,
    List<T> fallback,
  ) {
    if (raw is! List) return [...fallback];
    final byName = values.asNameMap();
    return [
      ...{
        for (final id in raw)
          if (byName[id] case final value?) value,
      },
    ];
  }

  @override
  bool operator ==(Object other) =>
      other is HomeMenuConfig &&
      listEquals(other.modes, modes) &&
      listEquals(other.nav, nav);

  @override
  int get hashCode => Object.hash(Object.hashAll(modes), Object.hashAll(nav));
}
