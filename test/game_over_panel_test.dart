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
import 'package:cardgame/ui/screens/home/home_screen.dart';
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

void main() {
  testWidgets('GameOverPanel renders XP earned, Elo delta, and prize winner', (
    tester,
  ) async {
    const profile = PlayerProfile(
      playerId: 'guest-1',
      name: 'Alice',
      username: 'alice_ace',
      avatarId: 'golden-king',
    );

    const snapshot = GameSnapshot(
      roomId: 'room-1',
      version: 2,
      status: GameStatus.ended,
      ready: true,
      deckCount: 0,
      discardTopTag: 'A2',
      discardRecentTags: ['A2'],
      isYourTurn: false,
      potAmount: 100,
      stakePool: 100,
      stakePerPlayer: 50,
      you: PlayerSnapshot(
        connected: true,
        displayName: 'Alice',
        playerId: 'guest-1',
        launch: LaunchStatus.ended,
        total: 5,
        cards: [],
        handCardTag: null,
        hasHandCard: false,
      ),
      opponent: PlayerSnapshot(
        connected: true,
        displayName: 'Bob',
        playerId: 'guest-2',
        launch: LaunchStatus.ended,
        total: 12,
        cards: [],
        handCardTag: null,
        hasHandCard: false,
      ),
      result: GameResult(
        scores: [5, 12],
        winnerIndex: 0,
        ratings: [
          PlayerResultRating(
            playerId: 'guest-1',
            result: 'win',
            pointsEarned: 30,
            eloDelta: 16,
          ),
          PlayerResultRating(
            playerId: 'guest-2',
            result: 'loss',
            pointsEarned: 2,
            eloDelta: -16,
          ),
        ],
      ),
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
          home: Scaffold(body: GameOverPanel()),
        ),
      ),
    );
    await tester.pump();

    // Verify Headline & Series
    expect(find.text('VICTORY'), findsOneWidget);

    // Verify Prize banner with winner name and pot amount
    expect(find.textContaining('Prize: 100 (Alice)'), findsOneWidget);

    // Verify XP and Elo earned for current player in middle
    expect(find.text('+30 XP'), findsOneWidget);
    expect(find.text('+16 Elo'), findsOneWidget);

    // Verify opponent XP and Elo are NOT shown
    expect(find.text('+2 XP'), findsNothing);
    expect(find.text('-16 Elo'), findsNothing);
  });
}
