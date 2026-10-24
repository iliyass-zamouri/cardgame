import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/app/game_session_state.dart';
import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/app/ranking_providers.dart';
import 'package:cardgame/app/session_auth_repository.dart';
import 'package:cardgame/app/session_auth_status.dart';
import 'package:cardgame/data/ranking/ranking_api.dart';
import 'package:cardgame/domain/models/game_snapshot.dart';
import 'package:cardgame/l10n/app_localizations.dart';
import 'package:cardgame/ui/flame/board_layout.dart';
import 'package:cardgame/ui/screens/home/home_screen.dart';
import 'package:cardgame/ui/theme/casino_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FixedGameSessionController extends GameSessionController {
  _FixedGameSessionController(this._initialState);
  final GameSessionState _initialState;

  @override
  GameSessionState build() => _initialState;
}

/// Pumps the HUD over a game in play: Alice (you) against Bob.
Future<void> _pumpHud(WidgetTester tester) async {
  const profile = PlayerProfile(
    playerId: 'guest-1',
    name: 'Alice',
    username: 'alice_ace',
    avatarId: 'golden-king',
  );

  const snapshot = GameSnapshot(
    roomId: 'room-1',
    version: 1,
    status: GameStatus.playing,
    ready: true,
    deckCount: 30,
    discardTopTag: 'A2',
    discardRecentTags: ['A2'],
    isYourTurn: true,
    potAmount: 100,
    stakePool: 100,
    stakePerPlayer: 50,
    you: PlayerSnapshot(
      connected: true,
      displayName: 'Alice',
      playerId: 'guest-1',
      launch: LaunchStatus.ended,
      total: 0,
      cards: [],
      handCardTag: null,
      hasHandCard: false,
    ),
    opponent: PlayerSnapshot(
      connected: true,
      displayName: 'Bob',
      playerId: 'guest-2',
      launch: LaunchStatus.ended,
      total: 0,
      cards: [],
      handCardTag: null,
      hasHandCard: false,
    ),
    result: null,
    lastAction: null,
  );

  const gameState = GameSessionState(
    connection: ConnectionStatus.connected,
    game: snapshot,
    clientId: 'guest-1',
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        gameSessionProvider.overrideWith(
          () => _FixedGameSessionController(gameState),
        ),
        sessionAuthRepositoryProvider.overrideWithValue(
          SessionAuthRepository.memory(SessionAuthStatus.guest),
        ),
        playerProfileRepositoryProvider.overrideWithValue(
          PlayerProfileRepository.memory(profile),
        ),
        rankingApiProvider.overrideWithValue(
          RankingApi(
            baseUrl: 'http://localhost',
            client: MockClient(
              (_) async => http.Response('{"matches":[],"elo":1200}', 200),
            ),
          ),
        ),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: GameHud()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets(
    'GameHud renders opponent above deck and current player below deck',
    (tester) async {
      await _pumpHud(tester);

      // Verify pot is rendered
      expect(find.textContaining('100'), findsWidgets);

      // Verify both player seats are rendered
      final seats = find.byType(CasinoTableSeat);
      expect(seats, findsNWidgets(2));

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);

      // Verify Bob (opponent) is below his cards to the right
      // and Alice (current player) is above her cards to the left
      final bobPosition = tester.getTopLeft(find.text('Bob'));
      final alicePosition = tester.getTopLeft(find.text('Alice'));
      expect(bobPosition.dy < alicePosition.dy, isTrue);
      expect(bobPosition.dx > alicePosition.dx, isTrue);
    },
  );

  testWidgets('a wide window seats the players at the centred table', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _pumpHud(tester);

    // The table is centred, so seats ride its edges, not the window's.
    final side = BoardLayout.sideInset(
      const Size(1280, 800 - BoardLayout.hudTop - BoardLayout.hudBottom),
    );
    expect(side, greaterThan(300));
    final seats = find.byType(CasinoTableSeat);
    final alice = tester.getRect(
      find.ancestor(of: find.text('Alice'), matching: seats),
    );
    final bob = tester.getRect(
      find.ancestor(of: find.text('Bob'), matching: seats),
    );
    expect(alice.left, moreOrLessEquals(side + 12));
    expect(bob.right, moreOrLessEquals(1280 - side - 12));
  });
}
