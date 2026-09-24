import 'dart:async';

import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/app/locale_provider.dart';
import 'package:cardgame/app/locale_repository.dart';
import 'package:cardgame/app/navigation_providers.dart';
import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/app/push_providers.dart';
import 'package:cardgame/app/session_auth_repository.dart';
import 'package:cardgame/core/monetization/purchases_service.dart';
import 'package:cardgame/firebase_options.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/services/analytics_service.dart';
import 'package:cardgame/services/app_tracking_service.dart';
import 'package:cardgame/services/crashlytics_service.dart';
import 'package:cardgame/services/push_prefs_repository.dart';
import 'package:cardgame/services/guest_link_prefs_repository.dart';
import 'package:cardgame/data/auth/guest_google_link.dart';
import 'package:cardgame/ui/background.dart';
import 'package:cardgame/ui/flame/card_fonts.dart';
import 'package:cardgame/ui/screens/auth/authentication_screen.dart';
import 'package:cardgame/ui/screens/home/home_screen.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/widgets/suit_card_loader.dart';
import 'package:cardgame/ads/ad_ids.dart';
import 'package:cardgame/ads/interstitial_ad_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        try {
          if (defaultTargetPlatform == TargetPlatform.android) {
            await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            );
          } else {
            try {
              await Firebase.initializeApp(
                options: DefaultFirebaseOptions.currentPlatform,
              );
            } catch (_) {
              // iOS may lack GoogleService-Info.plist until FlutterFire configure.
              await Firebase.initializeApp();
            }
          }
        } catch (e) {
          debugPrint('Firebase init failed (non-fatal): $e');
        }
      }

      final crashlytics = CrashlyticsService();
      await crashlytics.enableCollection();
      crashlytics.installFlutterErrorHandlers();

      // Request ATT on iOS before initializing mobile ads
      try {
        await AppTrackingService().requestTrackingAuthorization();
      } catch (e) {
        debugPrint('ATT request failed: $e');
      }

      if (AdIds.isSupported) {
        try {
          await MobileAds.instance.initialize();
        } catch (e) {
          debugPrint('MobileAds init failed: $e');
        }
      }

      try {
        await PurchasesService.instance.configure();
      } catch (e) {
        debugPrint('PurchasesService init failed: $e');
      }

      await Hive.initFlutter();
      await Future.wait([ensureCardFontsLoaded(), ensureArabicUiFontLoaded()]);

      final sessionRepo = await SessionAuthRepository.open();
      final profileRepo = await PlayerProfileRepository.open();
      final localeRepo = await LocaleRepository.open();
      final pushPrefsRepo = await PushPrefsRepository.open();
      final guestLinkPrefsRepo = await GuestLinkPrefsRepository.open();

      runApp(
        ProviderScope(
          overrides: [
            sessionAuthRepositoryProvider.overrideWithValue(sessionRepo),
            playerProfileRepositoryProvider.overrideWithValue(profileRepo),
            localeRepositoryProvider.overrideWithValue(localeRepo),
            pushPrefsRepositoryProvider.overrideWithValue(pushPrefsRepo),
            guestLinkPrefsRepositoryProvider.overrideWithValue(
              guestLinkPrefsRepo,
            ),
          ],
          child: const MyApp(),
        ),
      );
    },
    (error, stack) {
      debugPrint('Uncaught zone error: $error');
      CrashlyticsService().recordError(error, stack, fatal: true);
    },
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _pushStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapPush());
  }

  Future<void> _bootstrapPush() async {
    if (_pushStarted) return;
    _pushStarted = true;
    ref.read(joinRoomBinderProvider).callback = (roomId) {
      ref.read(gameSessionProvider.notifier).joinRoom(roomId);
    };
    final navigator = ref.read(notificationNavigatorProvider);
    final push = ref.read(pushNotificationServiceProvider);
    push.onInboxChanged = () {
      ref.read(notificationsInboxProvider.notifier).refresh();
    };
    await push.start(navigator: navigator);
    final playerId = ref.read(playerProfileProvider).value?.playerId;
    await push.bindPlayerId(playerId);
  }

  @override
  Widget build(BuildContext context) {
    ref.read(interstitialAdProvider).preload();
    final sessionAsync = ref.watch(sessionAuthProvider);
    final locale = ref.watch(localeProvider);
    final analyticsObserver = ref.watch(analyticsServiceProvider).observer;
    final rootKey = ref.watch(rootNavigatorKeyProvider);

    // Keep FCM token bound to current player.
    ref.listen(playerProfileProvider, (previous, next) {
      final playerId = next.value?.playerId;
      unawaited(
        ref.read(pushNotificationServiceProvider).bindPlayerId(playerId),
      );
      unawaited(
        ref
            .read(crashlyticsServiceProvider)
            .setUserId(playerId?.isNotEmpty == true ? playerId : null),
      );
    });

    return MaterialApp(
      navigatorKey: rootKey,
      debugShowCheckedModeBanner: false,
      locale: locale,
      navigatorObservers: [if (analyticsObserver != null) analyticsObserver],
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: (deviceLocales, supported) {
        return LocaleRepository.fromDeviceLocales(deviceLocales ?? const []);
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateTitle: (context) => context.l10n.appTitle,
      theme: buildCasinoTheme(locale: locale),
      builder: (context, child) {
        return DefaultTextStyle(
          style: TextStyle(
            fontFamily: CasinoFonts.uiFor(locale),
            color: CasinoColors.text,
            decoration: TextDecoration.none,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: GameBackground(
        child: sessionAsync.when(
          loading: () => const Center(child: SuitCardLoader(height: 32)),
          error:
              (error, _) => Center(
                child: Builder(
                  builder: (context) {
                    return Text(
                      context.l10n.authError('$error'),
                      style: const TextStyle(color: CasinoColors.foldHi),
                    );
                  },
                ),
              ),
          data: (status) {
            if (status.isInApp) {
              return const HomeScreen();
            }
            return const AuthenticationScreen();
          },
        ),
      ),
    );
  }
}
