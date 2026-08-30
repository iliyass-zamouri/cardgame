import 'package:cardgame/ads/ad_ids.dart';
import 'package:cardgame/ads/interstitial_ad_service.dart';
import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/locale_provider.dart';
import 'package:cardgame/app/locale_repository.dart';
import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/app/session_auth_repository.dart';
import 'package:cardgame/core/monetization/purchases_service.dart';
import 'package:cardgame/firebase_options.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/services/analytics_service.dart';
import 'package:cardgame/services/app_tracking_service.dart';
import 'package:cardgame/ui/background.dart';
import 'package:cardgame/ui/flame/card_fonts.dart';
import 'package:cardgame/ui/screens/auth/authentication_screen.dart';
import 'package:cardgame/ui/screens/home/home_screen.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/widgets/suit_card_loader.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Firebase init failed (non-fatal): $e');
    }
  }

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

  runApp(
    ProviderScope(
      overrides: [
        sessionAuthRepositoryProvider.overrideWithValue(sessionRepo),
        playerProfileRepositoryProvider.overrideWithValue(profileRepo),
        localeRepositoryProvider.overrideWithValue(localeRepo),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(interstitialAdProvider).preload();
    final sessionAsync = ref.watch(sessionAuthProvider);
    final locale = ref.watch(localeProvider);
    final analyticsObserver = ref.watch(analyticsServiceProvider).observer;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      navigatorObservers: [if (analyticsObserver != null) analyticsObserver],
      supportedLocales: AppLocalizations.supportedLocales,
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
