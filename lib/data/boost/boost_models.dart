import 'package:cardgame/data/daily_reward/daily_reward_models.dart';

int _int(Object? value, [int fallback = 0]) =>
    value is num ? value.toInt() : fallback;

String _string(Object? value) => value is String ? value : '';

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

List<Map<String, dynamic>> _maps(Object? value) =>
    value is List
        ? [
          for (final entry in value)
            if (entry is Map) Map<String, dynamic>.from(entry),
        ]
        : const [];

Map<String, String> _names(Object? value) => {
  if (value is Map)
    for (final entry in value.entries)
      if (entry.value is String && (entry.value as String).isNotEmpty)
        '${entry.key}': entry.value as String,
};

/// How a boost looks: its metal, from the admin's preset.
enum BoostTier {
  bronze,
  silver,
  gold,
  diamond;

  static BoostTier parse(Object? value) =>
      BoostTier.values.asNameMap()[value] ?? BoostTier.silver;
}

/// A Coin Boost value the admin defined: [percent] more money on match wins,
/// up to [maxBonus] a match.
class BoostPreset {
  const BoostPreset({
    required this.id,
    required this.percent,
    required this.maxBonus,
    this.tier = BoostTier.silver,
    this.names = const {},
  });

  final String id;
  final int percent;
  final int maxBonus;
  final BoostTier tier;
  final Map<String, String> names;

  /// The name in [languageCode], else English, else null.
  String? nameFor(String languageCode) => localizedTitle(names, languageCode);

  /// The extra money winning a pot of [stake] each would pay.
  int bonusFor(int stake) {
    final bonus = stake * percent ~/ 100;
    return bonus < maxBonus ? bonus : maxBonus;
  }

  factory BoostPreset.fromJson(Map<String, dynamic> json) => BoostPreset(
    id: _string(json['id'] ?? json['presetId']),
    percent: _int(json['percent']),
    maxBonus: _int(json['maxBonus']),
    tier: BoostTier.parse(json['tier']),
    names: _names(json['name']),
  );
}

/// The boost running now. [remainingSeconds] is from when it arrived.
class ActiveBoost {
  const ActiveBoost({
    required this.preset,
    required this.remainingSeconds,
    this.totalSeconds,
  });

  final BoostPreset preset;
  final int remainingSeconds;

  /// The whole run, extensions included. Null for a boost from before runs
  /// were timed.
  final int? totalSeconds;

  factory ActiveBoost.fromJson(Map<String, dynamic> json) => ActiveBoost(
    preset: BoostPreset.fromJson(json),
    remainingSeconds: _int(json['remainingSeconds']),
    totalSeconds:
        json['totalSeconds'] is num
            ? (json['totalSeconds'] as num).toInt()
            : null,
  );
}

/// One claimed boost waiting to be activated.
class BoostItem {
  const BoostItem({required this.id, required this.minutes});

  final String id;
  final int minutes;
}

/// Waiting boosts of one value. [blocked] while a different value runs.
class BoostGroup {
  const BoostGroup({
    required this.preset,
    required this.items,
    this.blocked = false,
  });

  final BoostPreset preset;
  final List<BoostItem> items;
  final bool blocked;

  factory BoostGroup.fromJson(Map<String, dynamic> json) => BoostGroup(
    preset: BoostPreset.fromJson(json),
    blocked: json['blocked'] == true,
    items: [
      for (final entry in _maps(json['items']))
        BoostItem(id: _string(entry['id']), minutes: _int(entry['minutes'])),
    ],
  );
}

/// GET /boosts: the running boost and the ones waiting.
class BoostState {
  const BoostState({
    this.active,
    this.inventory = const [],
    this.presets = const [],
  });

  static const empty = BoostState();

  final ActiveBoost? active;
  final List<BoostGroup> inventory;
  final List<BoostPreset> presets;

  /// Boosts waiting to be activated.
  int get readyCount =>
      inventory.fold(0, (sum, group) => sum + group.items.length);

  factory BoostState.fromJson(Map<String, dynamic> json) {
    final active = json['active'];
    return BoostState(
      active: active is Map ? ActiveBoost.fromJson(_map(active)) : null,
      inventory: [
        for (final entry in _maps(json['inventory'])) BoostGroup.fromJson(entry),
      ],
      presets: [
        for (final entry in _maps(json['presets'])) BoostPreset.fromJson(entry),
      ],
    );
  }
}

enum BoostActivationKind { start, extend }

/// POST /boosts/activate.
class BoostActivation {
  const BoostActivation({
    required this.kind,
    required this.minutes,
    required this.state,
  });

  final BoostActivationKind kind;
  final int minutes;
  final BoostState state;

  factory BoostActivation.fromJson(Map<String, dynamic> json) =>
      BoostActivation(
        kind:
            json['action'] == 'extend'
                ? BoostActivationKind.extend
                : BoostActivationKind.start,
        minutes: _int(json['minutes']),
        state: BoostState.fromJson(_map(json['boosts'])),
      );
}
