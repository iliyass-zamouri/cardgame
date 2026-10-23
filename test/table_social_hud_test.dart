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

const _snapshot = GameSnapshot(
  roomId: 'room-1',
  version: 1,
  status: GameStatus.playing,
  ready: true,
  deckCount: 30,
  discardTopTag: 'A2',
  discardRecentTags: ['A2'],
  isYourTurn: true,
  potAmount: 0,
  stakePool: 0,
  stakePerPlayer: 0,
  matchType: 'random',
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
    avatarId: 'golden-king',
    launch: LaunchStatus.ended,
    total: 0,
    cards: [],
    handCardTag: null,
    hasHandCard: false,
  ),
  result: null,
  lastAction: null,
);

Future<void> _pumpHud(WidgetTester tester) async {
  // Phone-sized screen: the sheets must fit without overflow.
  tester.view.physicalSize = const Size(1080, 2220);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        gameSessionProvider.overrideWith(
          () => _FixedGameSessionController(
            const GameSessionState(
              connection: ConnectionStatus.connected,
              game: _snapshot,
              clientId: 'guest-1',
            ),
          ),
        ),
        sessionAuthRepositoryProvider.overrideWithValue(
          SessionAuthRepository.memory(SessionAuthStatus.guest),
        ),
        playerProfileRepositoryProvider.overrideWithValue(
          PlayerProfileRepository.memory(
            const PlayerProfile(
              playerId: 'guest-1',
              name: 'Alice',
              username: 'alice_ace',
            ),
          ),
        ),
        rankingApiProvider.overrideWithValue(
          RankingApi(
            baseUrl: 'http://localhost',
            client: MockClient((request) async {
              if (request.url.path == '/matches') {
                return http.Response(
                  '{"matches":[{"matchId":"m1","result":"win"},'
                  '{"matchId":"m2","result":"loss"}]}',
                  200,
                );
              }
              return http.Response(
                '{"rank":7,"playerId":"guest-2","name":"Bob",'
                '"username":"bob_king","elo":1234,"totalPoints":250,'
                '"wins":6,"losses":3,"draws":1}',
                200,
              );
            }),
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
        home: Scaffold(body: SizedBox.expand(child: GameHud())),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('tapping the opponent opens their profile card', (tester) async {
    await _pumpHud(tester);

    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();

    expect(find.text('@bob_king'), findsOneWidget);
    expect(find.text('1234'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
    expect(find.text('6/3/1'), findsOneWidget);
    expect(find.text('Level 3 · Card Shark'), findsOneWidget);
    expect(find.text('Mute player'), findsOneWidget);
    expect(find.text('Recent form'), findsOneWidget);
  });

  testWidgets('chat button opens phrases and emoji reactions', (tester) async {
    await _pumpHud(tester);

    await tester.tap(find.byTooltip('Chat'));
    await tester.pumpAndSettle();

    expect(find.text('Well played'), findsOneWidget);
    expect(find.text('😂'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
