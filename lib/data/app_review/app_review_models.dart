/// Where a rating prompt came from. The server's rules (cooldowns, minimum
/// matches) apply to [win], [daily] and [launch]; the player asked for
/// [settings] and [push].
enum AppReviewTrigger {
  win,
  daily,
  launch,
  settings,
  push;

  bool get isAutomatic => this == win || this == daily || this == launch;
}

/// `gated`: our stars first, the store only at or above [AppReviewConfig.storeMinStars].
/// `nativeOnly`: straight to the platform's review sheet.
enum AppReviewFlow { gated, nativeOnly }

/// Reasons a player can tick after a low rating. Labels live in the ARB files.
enum AppReviewTag { bugs, ads, difficulty, economy, bots, performance, other }

/// What the admin Ratings tab set, as this platform needs it.
class AppReviewConfig {
  const AppReviewConfig({
    this.enabled = true,
    this.flow = AppReviewFlow.gated,
    this.hasStore = true,
    this.storeMinStars = 4,
    this.iosAppStoreId = '',
    this.askReason = true,
    this.tags = AppReviewTag.values,
  });

  final bool enabled;
  final AppReviewFlow flow;

  /// False where there is no store to send a rating to.
  final bool hasStore;
  final int storeMinStars;
  final String iosAppStoreId;
  final bool askReason;
  final List<AppReviewTag> tags;

  factory AppReviewConfig.fromJson(Map<String, dynamic> json) {
    final tags = json['tags'];
    final minStars = json['storeMinStars'];
    return AppReviewConfig(
      enabled: json['enabled'] != false,
      flow:
          json['flow'] == 'native_only'
              ? AppReviewFlow.nativeOnly
              : AppReviewFlow.gated,
      hasStore: json['hasStore'] != false,
      storeMinStars: minStars is num ? minStars.toInt().clamp(1, 5) : 4,
      iosAppStoreId: json['iosAppStoreId'] as String? ?? '',
      askReason: json['askReason'] != false,
      // Tags a newer server adds are skipped until the app knows their label.
      tags:
          tags is List
              ? [
                for (final tag in tags)
                  if (AppReviewTag.values.asNameMap()[tag] case final known?)
                    known,
              ]
              : AppReviewTag.values,
    );
  }

  /// Whether [stars] would be sent on to the store.
  bool sendsToStore(int stars) =>
      hasStore && (flow == AppReviewFlow.nativeOnly || stars >= storeMinStars);
}

class AppReviewStatus {
  const AppReviewStatus({
    required this.show,
    required this.reason,
    required this.config,
  });

  final bool show;

  /// Why not, when [show] is false (`cooldown`, `too_few_matches`…).
  final String reason;
  final AppReviewConfig config;

  factory AppReviewStatus.fromJson(Map<String, dynamic> json) {
    final config = json['config'];
    return AppReviewStatus(
      show: json['show'] == true,
      reason: json['reason'] as String? ?? '',
      config:
          config is Map<String, dynamic>
              ? AppReviewConfig.fromJson(config)
              : const AppReviewConfig(),
    );
  }
}

/// What the server did with a rating: `store` sends the player on to rate
/// publicly, `feedback` asks what could be better.
class AppReviewRateResult {
  const AppReviewRateResult({
    required this.reviewId,
    required this.sendToStore,
    required this.askReason,
  });

  /// Null when the rating couldn't be saved (offline).
  final int? reviewId;
  final bool sendToStore;
  final bool askReason;

  factory AppReviewRateResult.fromJson(Map<String, dynamic> json) {
    final id = json['reviewId'];
    return AppReviewRateResult(
      reviewId: id is num ? id.toInt() : null,
      sendToStore: json['action'] == 'store',
      askReason: json['askReason'] == true,
    );
  }
}
