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
import 'package:cardgame/ui/theme/casino_chrome.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/widgets/turn_countdown_ring.dart';
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

Map<String, dynamic> _snapshotJson({
  Map<String, dynamic>? turnTimer,
  int youMissedTurns = 0,
}) {
  return {
    'roomId': 'ROOM01',
    'version': 4,
    'status': 'playing',
    'ready': true,
    'deckCount': 40,
    'turn': 'you',
    'turnTimer': turnTimer,
    'you': {
      'connected': true,
      'playerId': 'guest-1',
      'launch': 'ended',
      'total': 0,
      'cards': [],
      'hasHandCard': false,
      'missedTurns': youMissedTurns,
    },
    'opponent': {
      'connected': true,
      'playerId': 'guest-2',
      'launch': 'ended',
      'total': 0,
      'cards': [],
      'hasHandCard': false,
      'missedTurns': 0,
    },
    'result': null,
    'lastAction': null,
  };
}

GameSnapshot _hudSnapshot({required bool isYourTurn, TurnTimer? turnTimer}) {
  return GameSnapshot(
    roomId: 'room-1',
    version: 1,
    status: GameStatus.playing,
    ready: true,
    deckCount: 30,
    discardTopTag: 'A2',
    discardRecentTags: const ['A2'],
    isYourTurn: isYourTurn,
    turnTimer: turnTimer,
    you: const PlayerSnapshot(
      connected: true,
      displayName: 'Alice',
      playerId: 'guest-1',
      launch: LaunchStatus.ended,
      total: 0,
      cards: [],
      handCardTag: null,
      hasHandCard: false,
    ),
    opponent: const PlayerSnapshot(
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
}

Future<void> _pumpGame(
  WidgetTester tester,
  GameSnapshot snapshot, {
  Widget body = const GameHud(),
}) async {
  const profile = PlayerProfile(
    playerId: 'guest-1',
    name: 'Alice',
    username: 'alice_ace',
    avatarId: 'golden-king',
  );
  final gameState = GameSessionState(
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
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: body),
      ),
    ),
  );
  // Pump rather than settle: the countdown keeps animating while it runs.
  await tester.pump();
}

Widget _ringHost(TurnTimer timer) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 60,
          height: 60,
          child: TurnCountdownRing(timer: timer),
        ),
      ),
    ),
  );
}

const _clock = TurnTimer(limitMs: 30000, remainingMs: 12000, maxMissedTurns: 3);

void main() {
  group('TurnTimer', () {
    test('tryParse reads the server clock and clamps remaining time', () {
      final timer = TurnTimer.tryParse({
        'limitMs': 30000,
        'remainingMs': 40000,
        'maxMissedTurns': 3,
      });
      expect(timer?.limitMs, 30000);
      expect(timer?.remainingMs, 30000);
      expect(timer?.maxMissedTurns, 3);
      expect(
        TurnTimer.tryParse({
          'limitMs': 30000,
          'remainingMs': -5,
          'maxMissedTurns': 0,
        })?.remainingMs,
        0,
      );
    });

    test('tryParse rejects a missing or malformed clock', () {
      expect(TurnTimer.tryParse(null), isNull);
      expect(TurnTimer.tryParse({'limitMs': 0, 'remainingMs': 0}), isNull);
      expect(TurnTimer.tryParse({'limitMs': 30000}), isNull);
    });
  });

  group('shouldReanchor', () {
    test('ignores jitter inside the tolerance and re-seeds on real drift', () {
      expect(shouldReanchor(10000, 10150), isFalse);
      expect(shouldReanchor(10000, 9400), isTrue);
    });
  });

  group('GameSnapshot turn clock', () {
    test('fromJson reads the turn clock and the missed-turn counts', () {
      final snapshot = GameSnapshot.fromJson(
        _snapshotJson(
          turnTimer: {
            'limitMs': 30000,
            'remainingMs': 12000,
            'maxMissedTurns': 3,
          },
          youMissedTurns: 1,
        ),
      );
      expect(snapshot.turnTimer?.remainingMs, 12000);
      expect(snapshot.you.missedTurns, 1);
      expect(snapshot.opponent?.missedTurns, 0);
    });

    test('fromJson leaves the clock off when the server sends none', () {
      final snapshot = GameSnapshot.fromJson(_snapshotJson());
      expect(snapshot.turnTimer, isNull);
      expect(snapshot.you.missedTurns, 0);
    });
  });

  testWidgets('the ring shows the seconds left and counts down', (
    tester,
  ) async {
    await tester.pumpWidget(
      _ringHost(
        const TurnTimer(limitMs: 30000, remainingMs: 3000, maxMissedTurns: 3),
      ),
    );
    expect(find.text('3'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('the ring turns urgent in the last five seconds and stops at 0', (
    tester,
  ) async {
    await tester.pumpWidget(
      _ringHost(
        const TurnTimer(limitMs: 30000, remainingMs: 5500, maxMissedTurns: 3),
      ),
    );
    expect(find.text('6'), findsOneWidget);
    expect(tester.widget<Text>(find.text('6')).style?.color, CasinoColors.gold);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('5'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('5')).style?.color,
      CasinoColors.foldHi,
    );
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('the countdown sits on the opponent seat during their turn', (
    tester,
  ) async {
    await _pumpGame(tester, _hudSnapshot(isYourTurn: false, turnTimer: _clock));
    final opponentSeat = find.ancestor(
      of: find.text('Bob'),
      matching: find.byType(CasinoTableSeat),
    );
    expect(
      find.descendant(
        of: opponentSeat,
        matching: find.byType(TurnCountdownRing),
      ),
      findsOneWidget,
    );
    expect(find.byType(TurnCountdownRing), findsOneWidget);
  });

  testWidgets('the countdown sits on my seat during my turn', (tester) async {
    await _pumpGame(tester, _hudSnapshot(isYourTurn: true, turnTimer: _clock));
    final mySeat = find.ancestor(
      of: find.text('Alice'),
      matching: find.byType(CasinoTableSeat),
    );
    expect(
      find.descendant(of: mySeat, matching: find.byType(TurnCountdownRing)),
      findsOneWidget,
    );
    expect(find.byType(TurnCountdownRing), findsOneWidget);
  });

  testWidgets('no countdown appears when the server sends no clock', (
    tester,
  ) async {
    await _pumpGame(tester, _hudSnapshot(isYourTurn: true));
    expect(find.byType(TurnCountdownRing), findsNothing);
  });

  group('timeout copy on the game over panel', () {
    GameSnapshot endedBy(String quitter) {
      return GameSnapshot(
        roomId: 'room-1',
        version: 9,
        status: GameStatus.ended,
        ready: true,
        deckCount: 0,
        discardTopTag: null,
        discardRecentTags: const [],
        isYourTurn: false,
        you: const PlayerSnapshot(
          connected: true,
          displayName: 'Alice',
          playerId: 'guest-1',
          launch: LaunchStatus.ended,
          total: 20,
          cards: [],
          handCardTag: null,
          hasHandCard: false,
        ),
        opponent: const PlayerSnapshot(
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
          scores: const [20, 12],
          winnerIndex: 1,
          reason: 'timeout',
          quitter: quitter,
        ),
        lastAction: null,
      );
    }

    testWidgets('a timeout forfeit by me says I ran out of time', (
      tester,
    ) async {
      await _pumpGame(tester, endedBy('you'), body: const GameOverPanel());
      expect(find.textContaining('You ran out of time'), findsOneWidget);
      expect(find.textContaining('You quit'), findsNothing);
    });

    testWidgets('a timeout forfeit by the opponent says they ran out of time', (
      tester,
    ) async {
      await _pumpGame(tester, endedBy('opponent'), body: const GameOverPanel());
      expect(find.textContaining('Opponent ran out of time'), findsOneWidget);
      expect(find.textContaining('Opponent quit'), findsNothing);
    });
  });
}
