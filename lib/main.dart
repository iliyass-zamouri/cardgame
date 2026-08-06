import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/dependency_injection.dart';
import 'core/config/server_config.dart';
import 'core/constants/app_theme.dart';
import 'core/network/api_client.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/boot_screen.dart';
import 'features/lobby/lobby_screen.dart';
import 'features/match/match_screen.dart';
import 'features/matchmaking/matchmaking_screen.dart';
import 'features/matchmaking/room_screen.dart';
import 'features/shop/shop_screen.dart';
import 'features/social/friends_screen.dart';

abstract final class ServerConfigHolder {
  static final config = ServerConfig.fromEnvironment();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final api = ApiClient(ServerConfigHolder.config);
  final session = SessionController(api, prefs);
  await session.restore();

  runApp(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(api),
        sessionProvider.overrideWith((ref) => session),
      ],
      child: const ShadowHandApp(),
    ),
  );
}

class ShadowHandApp extends ConsumerWidget {
  const ShadowHandApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = _buildRouter(ref);
    return MaterialApp.router(
      title: 'Shadow hand',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}

GoRouter _buildRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: _SessionListenable(ref),
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final loggingIn = state.matchedLocation == '/auth';
      if (!session.isAuthenticated &&
          !loggingIn &&
          state.matchedLocation != '/') {
        return '/auth';
      }
      if (session.isAuthenticated &&
          (state.matchedLocation == '/auth' ||
              state.matchedLocation == '/')) {
        return '/lobby';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const BootScreen(),
      ),
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(path: '/lobby', builder: (context, state) => const LobbyScreen()),
      GoRoute(path: '/shop', builder: (context, state) => const ShopScreen()),
      GoRoute(
        path: '/friends',
        builder: (context, state) => const FriendsScreen(),
      ),
      GoRoute(
        path: '/matchmaking',
        builder: (context, state) => const MatchmakingScreen(),
      ),
      GoRoute(path: '/room', builder: (context, state) => const RoomScreen()),
      GoRoute(path: '/match', builder: (context, state) => const MatchScreen()),
    ],
  );
}

class _SessionListenable extends ChangeNotifier {
  _SessionListenable(this.ref) {
    ref.listen<SessionState>(sessionProvider, (_, __) => notifyListeners());
  }

  final WidgetRef ref;
}
