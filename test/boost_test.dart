import 'dart:convert';
import 'dart:io';

import 'package:cardgame/app/boost_providers.dart';
import 'package:cardgame/app/daily_reward_providers.dart';
import 'package:cardgame/data/boost/boost_api.dart';
import 'package:cardgame/data/boost/boost_models.dart';
import 'package:cardgame/data/daily_reward/daily_reward_models.dart';
import 'package:cardgame/domain/models/game_snapshot.dart';
import 'package:cardgame/l10n/app_localizations.dart';
import 'package:cardgame/ui/screens/boost/boost_play_tag.dart';
import 'package:cardgame/ui/screens/boost/boost_sheet.dart';
import 'package:cardgame/ui/screens/home/home_menu_widgets.dart';
import 'package:cardgame/ui/theme/app_icons.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/widgets/boost_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Payloads captured from the server's own boost code on a scratch database.
String _raw(String dir, String name) =>
    File('test/fixtures/$dir/$name.json').readAsStringSync();

Map<String, dynamic> _fixture(String dir, String name) =>
    jsonDecode(_raw(dir, name)) as Map<String, dynamic>;

BoostState _state(String name) => BoostState.fromJson(_fixture('boost', name));

const _json = {'content-type': 'application/json; charset=utf-8'};

/// Text as shown, whatever case a casino label puts it in.
Finder _text(String text) =>
    find.textContaining(RegExp(RegExp.escape(text), caseSensitive: false));

/// A button label, matched whole.
Finder _button(String label) => find.textContaining(
  RegExp('^${RegExp.escape(label)}\$', caseSensitive: false),
);

/// Boosts without a server: a fixed state and a canned activation.
class _FakeBoosts extends BoostController {
  _FakeBoosts(this.initial, {this.reply, this.error});

  final BoostState? initial;
  final BoostActivation? reply;
  final BoostApiException? error;
  final activated = <String>[];

  @override
  Future<BoostView?> build() async {
    final state = initial;
    return state == null ? null : BoostView(state, dailyRewardClock());
  }

  @override
  Future<void> refresh() async {}

  @override
  Future<BoostActivation> activate(String itemId) async {
    activated.add(itemId);
    final error = this.error;
    if (error != null) {
      if (error.state != null) {
        state = AsyncData(BoostView(error.state!, dailyRewardClock()));
      }
      throw error;
    }
    state = AsyncData(BoostView(reply!.state, dailyRewardClock()));
    return reply!;
  }
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required _FakeBoosts boosts,
  String locale = 'en',
}) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [boostProvider.overrideWith(() => boosts)],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildCasinoTheme(locale: Locale(locale)),
        locale: Locale(locale),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: true),
              child: child!,
            ),
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('models', () {
    test('a ready state groups waiting boosts by value, strongest first', () {
      final state = _state('state_ready');
      expect(state.active, isNull);
      expect(state.readyCount, 3);
      expect(state.inventory.map((group) => group.preset.percent), [50, 25]);
      final silver = state.inventory[1];
      expect(silver.preset.tier, BoostTier.silver);
      expect(silver.items.map((item) => item.minutes).toSet(), {60, 240});
      expect(silver.blocked, isFalse);
      expect(state.presets.map((preset) => preset.id), ['standard', 'gold']);
      expect(state.presets[1].nameFor('fr'), 'Boost doré');
      expect(state.presets[1].nameFor('xx'), 'Gold Boost');
    });

    test('a running boost blocks other values and knows its whole run', () {
      final state = _state('state_active');
      final active = state.active!;
      expect(active.preset.percent, 50);
      expect(active.preset.tier, BoostTier.gold);
      expect(active.remainingSeconds, 1200);
      expect(active.totalSeconds, 1800);
      expect(boostFraction(active, 1200), closeTo(2 / 3, 0.001));
      expect(state.inventory.single.blocked, isTrue);
    });

    test('an extension reads as one, and the bonus stops at the cap', () {
      final extended = BoostActivation.fromJson(
        _fixture('boost', 'activate_extend'),
      );
      expect(extended.kind, BoostActivationKind.extend);
      expect(extended.minutes, anyOf(30, 60));
      expect(extended.state.active!.totalSeconds, 90 * 60);

      const preset = BoostPreset(id: 'standard', percent: 25, maxBonus: 2000);
      expect(preset.bonusFor(400), 100);
      expect(preset.bonusFor(50000), 2000);
    });

    test('a boost claimed with the inventory waits under its item id', () {
      final result = DailyClaimResult.fromJson(
        _fixture('daily_reward', 'claim_day2_inventory'),
      );
      final grant = result.granted.single;
      expect(grant.boost, same(grant));
      expect(grant.boostActivated, isFalse);
      expect(grant.boostItemId, startsWith('boost-'));
      final reward = grant.reward as CoinBoostReward;
      expect(reward.preset!.percent, 25);
      expect(reward.minutes, 60);
    });

    test('calendar boosts carry their preset from the status', () {
      final status = DailyRewardStatus.fromJson(
        _fixture('daily_reward', 'status_boosting'),
      );
      expect(status.boostPresets.keys, ['standard', 'gold']);
      final boosts = [
        for (final day in status.days)
          for (final reward in day.rewards)
            if (reward is CoinBoostReward) reward,
      ];
      expect(boosts, isNotEmpty);
      expect(boosts.every((reward) => reward.preset?.percent == 25), isTrue);
      expect(status.coinBoostRemainingSeconds, greaterThan(0));
    });

    test('a match snapshot carries your boost and what it paid', () {
      final rating = PlayerResultRating.fromJson({
        'playerId': 'p1',
        'result': 'win',
        'pointsEarned': 20,
        'eloDelta': 16,
        'boostBonus': 50,
        'boostPercent': 25,
      });
      expect(rating.boostBonus, 50);
      expect(rating.boostPercent, 25);
      expect(
        PlayerResultRating.fromJson({'result': 'loss'}).boostBonus,
        0,
        reason: 'an older server sends no bonus',
      );

      final snapshot = GameSnapshot.fromJson({
        'roomId': 'R1',
        'version': 1,
        'status': 'playing',
        'stakeCurrency': 'money',
        'yourBoost': {
          'presetId': 'gold',
          'percent': 50,
          'maxBonus': 5000,
          'tier': 'gold',
        },
        'you': {'connected': true, 'cards': []},
      });
      expect(snapshot.yourBoost!.percent, 50);
      expect(snapshot.yourBoost!.tier, BoostTier.gold);
    });
  });

  group('api', () {
    test('activate posts the item and reads the boosts back', () async {
      late http.Request sent;
      final api = BoostApi(
        baseUrl: 'https://cards.test',
        client: MockClient((request) async {
          sent = request;
          return http.Response(_raw('boost', 'activate_start'), 200, headers: _json);
        }),
      );
      final result = await api.activate(itemId: 'boost-1', accessToken: 't');
      expect(sent.url.path, '/boosts/activate');
      expect(sent.headers['Authorization'], 'Bearer t');
      expect(jsonDecode(sent.body), {'itemId': 'boost-1'});
      expect(result.kind, BoostActivationKind.start);
      expect(result.state.active!.preset.percent, 50);
    });

    test('a conflict names the running boost', () async {
      final api = BoostApi(
        baseUrl: 'https://cards.test',
        client: MockClient(
          (_) async => http.Response(_raw('boost', 'conflict'), 409, headers: _json),
        ),
      );
      await expectLater(
        api.activate(itemId: 'boost-2'),
        throwsA(
          isA<BoostApiException>()
              .having((error) => error.isConflict, 'isConflict', isTrue)
              .having(
                (error) => error.state?.active?.preset.percent,
                'running percent',
                50,
              ),
        ),
      );
    });
  });

  group('play card tag', () {
    testWidgets('a running boost shows its value and its clock', (
      tester,
    ) async {
      await _pump(
        tester,
        const BoostPlayTag(),
        boosts: _FakeBoosts(_state('state_active')),
      );
      expect(find.text('+50%'), findsOneWidget);
      expect(find.text('20:00'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'\+50% active')), findsOneWidget);
    });

    testWidgets('waiting boosts show how many are ready', (tester) async {
      await _pump(
        tester,
        const BoostPlayTag(),
        boosts: _FakeBoosts(_state('state_ready')),
      );
      expect(find.text('3 boosts ready'), findsOneWidget);
    });

    testWidgets('nothing to show leaves the card bare', (tester) async {
      await _pump(
        tester,
        const BoostPlayTag(),
        boosts: _FakeBoosts(BoostState.empty),
      );
      expect(find.byType(BoostCoin), findsNothing);
    });

    testWidgets('the tag rides the Play card and opens the boosts', (
      tester,
    ) async {
      var played = 0;
      await _pump(
        tester,
        Padding(
          padding: const EdgeInsets.all(24),
          child: PrimaryPlayCard(
            title: 'Find match',
            subtitle: 'Winner takes all',
            icon: AppIcons.bolt,
            onTap: () => played++,
            tag: const BoostPlayTag(),
            glow: BoostMetal.gold.glow,
          ),
        ),
        boosts: _FakeBoosts(_state('state_active')),
      );
      final card = tester.getRect(find.byType(PrimaryPlayCard));
      final tag = tester.getRect(find.text('+50%'));
      expect(tag.top, lessThan(card.top), reason: 'pinned across the top');

      await tester.tap(find.text('+50%'));
      await tester.pumpAndSettle();
      expect(find.byType(BoostSheet), findsOneWidget);
      expect(played, 0, reason: 'the tag takes its own tap');
    });
  });

  group('sheet', () {
    testWidgets('activates a waiting boost and celebrates', (tester) async {
      final boosts = _FakeBoosts(
        _state('state_ready'),
        reply: BoostActivation.fromJson(_fixture('boost', 'activate_start')),
      );
      await _pump(tester, const BoostSheet(), boosts: boosts);
      expect(find.text('No boost running'), findsOneWidget);
      expect(_text('3 boosts ready'), findsOneWidget);

      await tester.tap(_button('Activate').first);
      await tester.pump();
      expect(boosts.activated, hasLength(1));
      expect(find.text('+50% boost is on!'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.textContaining('Money wins pay +50%'), findsOneWidget);
    });

    testWidgets('a different value waits its turn', (tester) async {
      await _pump(
        tester,
        const BoostSheet(),
        boosts: _FakeBoosts(_state('state_active')),
      );
      expect(find.text('Available when your +50% ends'), findsOneWidget);
      expect(find.text('20:00 left'), findsOneWidget);
    });

    testWidgets('the same value as the running boost adds its time', (
      tester,
    ) async {
      final same = _state('state_active');
      final mixed = BoostState(
        active: same.active,
        presets: same.presets,
        inventory: [
          BoostGroup(
            preset: same.active!.preset,
            items: const [BoostItem(id: 'boost-gold', minutes: 60)],
          ),
        ],
      );
      await _pump(tester, const BoostSheet(), boosts: _FakeBoosts(mixed));
      expect(_text('Add 1h'), findsOneWidget);
    });

    testWidgets('a refusal from the server says which boost is in the way', (
      tester,
    ) async {
      final conflict = _fixture('boost', 'conflict');
      final boosts = _FakeBoosts(
        _state('state_ready'),
        error: BoostApiException(
          'busy',
          statusCode: 409,
          code: 'boost_conflict',
          state: BoostState.fromJson(conflict['boosts'] as Map<String, dynamic>),
        ),
      );
      await _pump(tester, const BoostSheet(), boosts: boosts);
      await tester.tap(_button('Activate').last);
      await tester.pump();
      expect(find.text('Available when your +50% ends'), findsWidgets);
    });

    testWidgets('lays out in Arabic without overflow', (tester) async {
      await _pump(
        tester,
        const BoostSheet(),
        boosts: _FakeBoosts(_state('state_active')),
        locale: 'ar',
      );
      expect(tester.takeException(), isNull);
      expect(find.text('المعزز الذهبي'.toUpperCase()), findsOneWidget);
    });
  });
}
