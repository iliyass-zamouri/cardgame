import 'dart:async';

import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/data/app_review/app_review_api.dart';
import 'package:cardgame/data/app_review/app_review_models.dart';
import 'package:cardgame/data/auth/auth_config.dart';
import 'package:cardgame/services/analytics_service.dart';
import 'package:cardgame/services/app_review_prefs_repository.dart';
import 'package:cardgame/trailer/trailer_mode.dart';
import 'package:cardgame/ui/widgets/app_review_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';

final appReviewApiProvider = Provider<AppReviewApi>(
  (ref) => AppReviewApi(baseUrl: httpBaseUrl),
);

final appReviewPrefsRepositoryProvider = Provider<AppReviewPrefsRepository>((
  ref,
) {
  throw UnimplementedError(
    'appReviewPrefsRepositoryProvider must be overridden in main()',
  );
});

final storeReviewLauncherProvider = Provider<StoreReviewLauncher>(
  (ref) => StoreReviewLauncher(),
);

final appReviewControllerProvider = Provider<AppReviewController>(
  (ref) => AppReviewController(ref),
);

/// Sends a player to rate the app in the Play Store / App Store.
class StoreReviewLauncher {
  /// [preferSheet] tries the in-app review sheet first. The OS may quietly
  /// skip it (it limits how often it shows), so a button the player tapped
  /// to rate opens the store page instead.
  Future<void> openStore({
    required String appStoreId,
    bool preferSheet = true,
  }) async {
    final review = InAppReview.instance;
    try {
      if (preferSheet && await review.isAvailable()) {
        await review.requestReview();
        return;
      }
      await review.openStoreListing(
        appStoreId: appStoreId.isEmpty ? null : appStoreId,
      );
    } catch (error) {
      debugPrint('Store review failed: $error');
    }
  }
}

/// Decides when the rate-the-app prompt opens. The server holds the rules
/// (see server/app_review.js); this keeps it to one prompt per app session
/// and spaces out the automatic checks.
class AppReviewController {
  AppReviewController(this._ref, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final Ref _ref;
  final DateTime Function() _clock;

  bool _promptedThisSession = false;
  bool _pendingWin = false;
  bool _launchChecked = false;
  bool _busy = false;
  String? _appVersion;

  /// The last config the server sent, for the Settings fallback.
  AppReviewConfig? _lastConfig;

  /// Called when the player wins a match. The prompt waits until they are
  /// back in the lobby.
  void noteWin() => _pendingWin = true;

  /// The lobby is on screen with nothing else to show: ask after a win, or
  /// once per app start.
  Future<bool> maybePromptInLobby(BuildContext context) async {
    if (_pendingWin) {
      _pendingWin = false;
      return maybePrompt(context, AppReviewTrigger.win);
    }
    if (_launchChecked) return false;
    _launchChecked = true;
    return maybePrompt(context, AppReviewTrigger.launch);
  }

  /// "Rate us" in Settings. When the prompt is off, the player still asked
  /// to rate, so the store page opens.
  Future<void> openFromSettings(BuildContext context) async {
    final shown = await maybePrompt(context, AppReviewTrigger.settings);
    if (shown) return;
    await _ref
        .read(storeReviewLauncherProvider)
        .openStore(
          appStoreId: _lastConfig?.iosAppStoreId ?? '',
          preferSheet: false,
        );
  }

  /// Opened from the rating push.
  Future<void> openFromPush(BuildContext context) async {
    final token = _ref.read(playerAuthProvider).accessToken;
    unawaited(
      _ref
          .read(appReviewApiProvider)
          .markPushOpened(accessToken: token)
          .catchError((_) {}),
    );
    await maybePrompt(context, AppReviewTrigger.push);
  }

  /// Shows the prompt if the server says so. Returns true if it opened.
  /// Never throws: a rating prompt must not get in the way of play.
  Future<bool> maybePrompt(
    BuildContext context,
    AppReviewTrigger trigger,
  ) async {
    try {
      return await _maybePrompt(context, trigger);
    } catch (error) {
      debugPrint('App review prompt skipped: $error');
      return false;
    }
  }

  Future<bool> _maybePrompt(
    BuildContext context,
    AppReviewTrigger trigger,
  ) async {
    if (_busy || TrailerMode.enabled) return false;
    if (trigger.isAutomatic && _promptedThisSession) return false;
    final prefs = _ref.read(appReviewPrefsRepositoryProvider);
    if (trigger.isAutomatic && !prefs.mayCheck(_clock())) return false;
    final token = _ref.read(playerAuthProvider).accessToken;
    if (token == null || token.isEmpty) return false;

    _busy = true;
    try {
      final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
      final device = (
        platform: _platform(),
        appVersion: await _readAppVersion(),
        locale: locale,
      );
      final api = _ref.read(appReviewApiProvider);
      if (trigger.isAutomatic) await prefs.markChecked(_clock());
      final AppReviewStatus status;
      try {
        status = await api.fetchStatus(
          trigger: trigger,
          device: device,
          accessToken: token,
        );
      } catch (error) {
        debugPrint('App review status failed: $error');
        return false;
      }
      _lastConfig = status.config;
      if (!status.show || !context.mounted) return false;

      _promptedThisSession = true;
      unawaited(api.markShown(trigger, accessToken: token).catchError((_) {}));
      _log('app_review_shown', {'trigger': trigger.name});

      final config = status.config;
      final launcher = _ref.read(storeReviewLauncherProvider);
      if (config.flow == AppReviewFlow.nativeOnly && config.hasStore) {
        await launcher.openStore(
          appStoreId: config.iosAppStoreId,
          preferSheet: trigger != AppReviewTrigger.settings,
        );
        return true;
      }

      var rated = false;
      await showAppReviewDialog(
        context,
        AppReviewSession(
          config: config,
          rate: (stars) async {
            rated = true;
            final result = await _rate(
              api,
              stars,
              trigger,
              device,
              token,
              config,
            );
            _log('app_review_rated', {
              'trigger': trigger.name,
              'stars': stars,
              'store': result.sendToStore ? 1 : 0,
            });
            return result;
          },
          sendFeedback: (reviewId, tags, comment) async {
            _log('app_review_feedback', {
              'tags': tags.length,
              'comment': (comment?.trim().isNotEmpty ?? false) ? 1 : 0,
            });
            if (reviewId == null) return;
            try {
              await api.sendFeedback(
                reviewId: reviewId,
                tags: tags,
                comment: comment,
                accessToken: token,
              );
            } catch (error) {
              debugPrint('App review feedback failed: $error');
            }
          },
          // Opened from Settings, the player came to rate: skip the sheet
          // the OS may quietly hold back.
          openStore:
              ({bool preferSheet = true}) => launcher.openStore(
                appStoreId: config.iosAppStoreId,
                preferSheet:
                    preferSheet && trigger != AppReviewTrigger.settings,
              ),
        ),
      );
      if (!rated) {
        _log('app_review_dismissed', {'trigger': trigger.name});
        unawaited(
          api.markDismissed(trigger, accessToken: token).catchError((_) {}),
        );
      }
      return true;
    } finally {
      _busy = false;
    }
  }

  /// Saves the rating. Offline, the app still answers from the config so the
  /// player is never left on a spinner.
  Future<AppReviewRateResult> _rate(
    AppReviewApi api,
    int stars,
    AppReviewTrigger trigger,
    AppReviewDevice device,
    String token,
    AppReviewConfig config,
  ) async {
    try {
      return await api.rate(
        stars: stars,
        trigger: trigger,
        device: device,
        accessToken: token,
      );
    } catch (error) {
      debugPrint('App review rate failed: $error');
      final toStore = config.sendsToStore(stars);
      return AppReviewRateResult(
        reviewId: null,
        sendToStore: toStore,
        askReason: !toStore && config.askReason,
      );
    }
  }

  void _log(String name, Map<String, Object> parameters) {
    unawaited(
      _ref
          .read(analyticsServiceProvider)
          .logEvent(name: name, parameters: parameters)
          .catchError((_) {}),
    );
  }

  Future<String?> _readAppVersion() async {
    if (_appVersion != null) return _appVersion;
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = '${info.version}+${info.buildNumber}';
    } catch (_) {}
    return _appVersion;
  }

  static String _platform() {
    if (kIsWeb) return 'other';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      _ => 'other',
    };
  }
}
