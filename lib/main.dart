import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/app/session_auth_repository.dart';
import 'package:cardgame/ui/background.dart';
import 'package:cardgame/ui/flame/card_fonts.dart';
import 'package:cardgame/ui/screens/auth/authentication_screen.dart';
import 'package:cardgame/ui/screens/home/home_screen.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/widgets/suit_card_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await ensureCardFontsLoaded();

  final sessionRepo = await SessionAuthRepository.open();
  final profileRepo = await PlayerProfileRepository.open();

  runApp(
    ProviderScope(
      overrides: [
        sessionAuthRepositoryProvider.overrideWithValue(sessionRepo),
        playerProfileRepositoryProvider.overrideWithValue(profileRepo),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionAuthProvider);

    return MaterialApp(
      title: 'CardGame',
      debugShowCheckedModeBanner: false,
      theme: buildCasinoTheme(),
      home: GameBackground(
        child: sessionAsync.when(
          loading: () => const Center(child: SuitCardLoader(height: 32)),
          error:
              (error, _) => Center(
                child: Text(
                  'Auth error: $error',
                  style: const TextStyle(color: CasinoColors.foldHi),
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
