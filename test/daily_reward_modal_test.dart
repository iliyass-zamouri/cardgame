import 'dart:convert';
import 'dart:io';

import 'package:cardgame/ads/rewarded_ad_service.dart';
import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/boost_providers.dart';
import 'package:cardgame/app/daily_reward_providers.dart';
import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/data/boost/boost_models.dart';
import 'package:cardgame/data/daily_reward/daily_reward_api.dart';
import 'package:cardgame/data/daily_reward/daily_reward_models.dart';
import 'package:cardgame/l10n/app_localizations.dart';
import 'package:cardgame/services/analytics_service.dart';
import 'package:cardgame/services/sfx_service.dart';
import 'package:cardgame/ui/screens/daily_reward/claim_celebration.dart';
import 'package:cardgame/ui/screens/daily_reward/comeback_modal.dart';
import 'package:cardgame/ui/screens/daily_reward/daily_entry_pill.dart';
import 'package:cardgame/ui/screens/daily_reward/daily_reward_modal.dart';
import 'package:cardgame/ui/screens/daily_reward/streak_card.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:cardgame/ui/widgets/insufficient_funds_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Payloads captured from the server's own claim code on a scratch database.
Map<String, dynamic> _fixture(String name) =>
    jsonDecode(File('test/fixtures/daily_reward/$name.json').readAsStringSync())
        as Map<String, dynamic>;

DailyRewardStatus _status(String name) =>
    DailyRewardStatus.fromJson(_fixture(name));

DailyClaimResult _result(String name) =>
    DailyClaimResult.fromJson(_fixture(name));

/// The streak without a server: a fixed status, and canned replies for each
/// kind of claim ('claim', 'boosted', 'rescue', 'restart', 'comeback').
class _FakeDailyRewards extends DailyRewardController {
  _FakeDailyRewards(this.initial, {this.replies = const {}, this.fail = false});

  final DailyRewardStatus? initial;
  final Map<String, DailyClaimResult> replies;
  final bool fail;
  final calls = <String>[];
  int refreshes = 0;

  @override
  Future<DailyRewardView?> build() async {
    if (fail) throw const SocketException('offline');
    final status = initial;
    return status == null ? null : DailyRewardView(status, dailyRewardClock());
  }

  @override
  Future<void> refresh() async => refreshes++;

  @override
  Future<DailyClaimResult> claim({
    bool boosted = false,
    StreakChoice? choice,
  }) async => _reply(choice?.name ?? (boosted ? 'boosted' : 'claim'));

  @override
  Future<DailyClaimResult> claimComeback() async => _reply('comeback');

  DailyClaimResult _reply(String kind) {
    calls.add(kind);
    final result = replies[kind];
    if (result == null) {
      throw DailyRewardApiException('refused', statusCode: 500);
    }
    final status = result.status;
    if (status != null) {
      state = AsyncData(DailyRewardView(status, dailyRewardClock()));
    }
    return result;
  }
}

/// Boosts without a server: a fixed state, and activations that succeed.
class _FakeBoosts extends BoostController {
  _FakeBoosts([this.initial = BoostState.empty]);

  final BoostState initial;
  final activated = <String>[];

  @override
  Future<BoostView?> build() async => BoostView(initial, dailyRewardClock());

  @override
  Future<void> refresh() async {}

  @override
  Future<BoostActivation> activate(String itemId) async {
    activated.add(itemId);
    final result = BoostActivation.fromJson(
      jsonDecode(
            File('test/fixtures/boost/activate_start.json').readAsStringSync(),
          )
          as Map<String, dynamic>,
    );
    state = AsyncData(BoostView(result.state, dailyRewardClock()));
    return result;
  }
}

class _FakeAds extends RewardedAdService {
  _FakeAds({bool ready = false, this.result = RewardedShowResult.rewarded})
    : _ready = ValueNotifier(ready);

  final ValueNotifier<bool> _ready;
  final RewardedShowResult result;
  int shows = 0;

  @override
  ValueListenable<bool> get ready => _ready;

  @override
  void preload() {}

  @override
  Future<RewardedShowResult> show() async {
    shows++;
    return result;
  }
}

class _Analytics extends AnalyticsService {
  final events = <String>[];

  @override
  Future<void> dailyReward({
    required String action,
    Map<String, Object>? parameters,
  }) async => events.add(action);
}

const _profile = PlayerProfile(
  playerId: 'p-1',
  name: 'Iliyass',
  username: 'iliyass_ace',
  money: 500,
  chips: 5,
  accessToken: 'token',
  tutorialDone: true,
);

/// A bare home with buttons that open the streak, and the entry pill when
/// [pill] is set.
class _Home extends ConsumerWidget {
  const _Home({this.pill = false});

  final bool pill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(dailyRewardProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (pill) const DailyEntryPill(),
              TextButton(
                onPressed:
                    () => openDailyRewards(context, ref, source: 'launch'),
                child: const Text('launch'),
              ),
              TextButton(
                onPressed: () => showDailyRewardModal(context, source: 'home'),
                child: const Text('open'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required _FakeDailyRewards rewards,
  PlayerProfile profile = _profile,
  _FakeAds? ads,
  _Analytics? analytics,
  String locale = 'en',
  Size size = const Size(390, 844),
  double textScale = 1,
  bool pill = false,
  _FakeBoosts? boosts,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        playerProfileRepositoryProvider.overrideWithValue(
          PlayerProfileRepository.memory(profile),
        ),
        dailyRewardProvider.overrideWith(() => rewards),
        boostProvider.overrideWith(() => boosts ?? _FakeBoosts()),
        rewardedAdProvider.overrideWithValue(ads ?? _FakeAds()),
        analyticsServiceProvider.overrideWithValue(analytics ?? _Analytics()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildCasinoTheme(locale: Locale(locale)),
        locale: Locale(locale),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // Reduced motion: every reveal lands at once, so flows settle.
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                disableAnimations: true,
                textScaler: TextScaler.linear(textScale),
              ),
              child: child!,
            ),
        home: _Home(pill: pill),
      ),
    ),
  );
  await tester.pump();
  return ProviderScope.containerOf(tester.element(find.byType(_Home)));
}

Future<void> _open(WidgetTester tester, [String button = 'open']) async {
  await tester.tap(find.text(button));
  await tester.pumpAndSettle();
}

PlayerProfile _profileOf(ProviderContainer container) =>
    container.read(playerProfileProvider).requireValue;

Finder _label(String text) => find.text(text.toUpperCase());

/// Inside the reveal, which covers the table and its cards.
Finder _reveal(Finder finder) =>
    find.descendant(of: find.byType(ClaimCelebration), matching: finder);

Future<void> _font(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    loader.addFont(rootBundle.load('assets/fonts/$file'));
  }
  await loader.load();
}

void main() {
  setUpAll(() async {
    await _font('DM Sans', ['DMSans-Regular.ttf', 'DMSans-Bold.ttf']);
    await _font('Cinzel', ['Cinzel-Regular.ttf', 'Cinzel-Bold.ttf']);
    await _font('Cairo', ['Cairo-Regular.ttf', 'Cairo-Bold.ttf']);
  });

  setUp(() => SfxService.instance.enabled = false);

  testWidgets('claiming day 1 reveals it and pays it into the profile', (
    tester,
  ) async {
    final analytics = _Analytics();
    final rewards = _FakeDailyRewards(
      _status('status_fresh'),
      replies: {'claim': _result('claim_day1')},
    );
    final container = await _pump(
      tester,
      rewards: rewards,
      analytics: analytics,
    );
    await _open(tester);

    expect(find.byType(DailyRewardModal), findsOneWidget);
    expect(find.byType(StreakDayCard), findsNWidgets(7));
    expect(find.text('Start your streak'), findsOneWidget);
    expect(find.text('Day 1 of 7'), findsOneWidget);
    expect(analytics.events, ['view']);

    await tester.tap(_label('Claim'));
    await tester.pumpAndSettle();

    expect(rewards.calls, ['claim']);
    expect(find.byType(ClaimCelebration), findsOneWidget);
    expect(_reveal(_label('Day 1 reward')), findsOneWidget);
    expect(_reveal(find.text('+200')), findsOneWidget);
    // Paid when the coins land, not before.
    expect(_profileOf(container).money, 500);

    await tester.tap(_label('Collect'));
    await tester.pumpAndSettle();

    expect(find.byType(ClaimCelebration), findsNothing);
    expect(_profileOf(container).money, 700);
    expect(find.text('1-day streak'), findsOneWidget);
    expect(_label('Come back tomorrow'), findsOneWidget);
    expect(find.textContaining('Day 2'), findsOneWidget);
    expect(analytics.events, ['view', 'claim']);

    await tester.tap(_label('Come back tomorrow'));
    await tester.pumpAndSettle();
    expect(find.byType(DailyRewardModal), findsNothing);
  });

  testWidgets('a won boost waits in the boosts and starts from the reveal', (
    tester,
  ) async {
    final boosts = _FakeBoosts();
    final rewards = _FakeDailyRewards(
      _status('status_fresh'),
      replies: {'claim': _result('claim_day2_inventory')},
    );
    await _pump(tester, rewards: rewards, boosts: boosts);
    await _open(tester);
    await tester.tap(_label('Claim'));
    await tester.pumpAndSettle();

    final grant = _result('claim_day2_inventory').granted.single;
    expect(_reveal(find.text('Coin Boost · 1h')), findsOneWidget);
    expect(_reveal(find.text('+25% money on match wins')), findsOneWidget);

    await tester.tap(_reveal(_label('Activate now')));
    await tester.pumpAndSettle();
    expect(boosts.activated, [grant.boostItemId]);
    expect(_reveal(find.text('Active')), findsOneWidget);
    expect(_reveal(_label('Activate now')), findsNothing);
  });

  testWidgets('a won boost of another value waits while one runs', (
    tester,
  ) async {
    final running = BoostState.fromJson(
      jsonDecode(
            File('test/fixtures/boost/state_active.json').readAsStringSync(),
          )
          as Map<String, dynamic>,
    );
    final boosts = _FakeBoosts(running);
    final rewards = _FakeDailyRewards(
      _status('status_fresh'),
      replies: {'claim': _result('claim_day2_inventory')},
    );
    await _pump(tester, rewards: rewards, boosts: boosts);
    await _open(tester);
    await tester.tap(_label('Claim'));
    await tester.pumpAndSettle();

    expect(_reveal(find.text('Saved to your boosts')), findsOneWidget);
    expect(_reveal(_label('Activate now')), findsNothing);
  });

  testWidgets('the ad button doubles the claim once an ad is ready', (
    tester,
  ) async {
    final ads = _FakeAds(ready: true);
    final rewards = _FakeDailyRewards(
      _status('status_midweek'),
      replies: {'boosted': _result('claim_day4_boosted')},
    );
    final container = await _pump(tester, rewards: rewards, ads: ads);
    await _open(tester);

    expect(find.text('×2'), findsOneWidget);
    await tester.tap(find.text('×2'));
    await tester.pumpAndSettle();

    expect(ads.shows, 1);
    expect(rewards.calls, ['boosted']);
    expect(_reveal(find.text('×2 ad boost')), findsOneWidget);
    expect(_reveal(find.text('+800')), findsOneWidget);
    expect(_reveal(find.text('Streak Freeze ×1')), findsOneWidget);

    await tester.tap(_label('Collect'));
    await tester.pumpAndSettle();
    expect(_profileOf(container).money, 1300);
  });

  testWidgets('a skipped ad claims nothing', (tester) async {
    final ads = _FakeAds(ready: true, result: RewardedShowResult.dismissed);
    final rewards = _FakeDailyRewards(_status('status_midweek'));
    await _pump(tester, rewards: rewards, ads: ads);
    await _open(tester);

    await tester.tap(find.text('×2'));
    await tester.pumpAndSettle();

    expect(ads.shows, 1);
    expect(rewards.calls, isEmpty);
    expect(_label('Claim'), findsOneWidget);
  });

  testWidgets('no ad button without an ad to show', (tester) async {
    await _pump(tester, rewards: _FakeDailyRewards(_status('status_midweek')));
    await _open(tester);

    expect(_label('Claim'), findsOneWidget);
    expect(find.text('×2'), findsNothing);
  });

  testWidgets('the jackpot chest opens on a new avatar that can be equipped', (
    tester,
  ) async {
    final rewards = _FakeDailyRewards(
      _status('status_jackpot'),
      replies: {'claim': _result('claim_day7')},
    );
    final container = await _pump(tester, rewards: rewards);
    await _open(tester);

    await tester.tap(_label('Claim'));
    await tester.pumpAndSettle();

    expect(_reveal(_label('Jackpot!')), findsOneWidget);
    expect(_reveal(find.text('Royal Chest')), findsOneWidget);
    expect(_reveal(_label('New!')), findsOneWidget);

    await tester.tap(_reveal(_label('Equip')));
    await tester.pumpAndSettle();
    expect(_profileOf(container).avatarId, 'queen-of-heart');
    expect(_reveal(_label('Equipped')), findsOneWidget);

    await tester.tap(_label('Collect'));
    await tester.pumpAndSettle();
    final profile = _profileOf(container);
    expect(profile.money, 1500);
    expect(profile.ownedAvatars, contains('queen-of-heart'));
    // The finished week stays full until next week opens.
    final cards = tester.widgetList<StreakDayCard>(find.byType(StreakDayCard));
    expect(cards.map((card) => card.look), everyElement(DayCardLook.claimed));
  });

  testWidgets('an avatar already owned shows what it turned into', (
    tester,
  ) async {
    final rewards = _FakeDailyRewards(
      _status('status_jackpot'),
      replies: {'claim': _result('claim_day7_duplicate')},
    );
    final container = await _pump(tester, rewards: rewards);
    await _open(tester);

    await tester.tap(_label('Claim'));
    await tester.pumpAndSettle();

    expect(_reveal(find.text('Already owned')), findsOneWidget);
    expect(_reveal(find.text('+1,500')), findsOneWidget);
    expect(_reveal(_label('Equip')), findsNothing);

    await tester.tap(_label('Collect'));
    await tester.pumpAndSettle();
    expect(_profileOf(container).money, 3000);
  });

  testWidgets('a broken streak is restored with chips', (tester) async {
    final rewards = _FakeDailyRewards(
      _status('status_broken'),
      replies: {'rescue': _result('claim_rescue')},
    );
    final container = await _pump(tester, rewards: rewards);
    await _open(tester);

    expect(find.text('Your streak broke'), findsOneWidget);
    expect(
      find.text(
        'Restore it to carry on at Day 6, or start a new streak from Day 1.',
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byType(GoldButton), matching: find.text('3')),
      findsOneWidget,
    );

    await tester.tap(_label('Restore'));
    await tester.pumpAndSettle();
    expect(rewards.calls, ['rescue']);

    await tester.tap(_label('Collect'));
    await tester.pumpAndSettle();
    expect(_profileOf(container).chips, 4);
    expect(find.text('6-day streak'), findsOneWidget);
  });

  testWidgets('restoring without the chips offers a top-up first', (
    tester,
  ) async {
    final rewards = _FakeDailyRewards(_status('status_broken'));
    await _pump(
      tester,
      rewards: rewards,
      profile: const PlayerProfile(
        playerId: 'p-1',
        name: 'Iliyass',
        username: 'iliyass_ace',
        chips: 1,
        tutorialDone: true,
      ),
    );
    await _open(tester);

    await tester.tap(_label('Restore'));
    await tester.pumpAndSettle();

    expect(find.byType(InsufficientFundsSheet), findsOneWidget);
    expect(rewards.calls, isEmpty);
  });

  testWidgets('starting over claims day 1 of a new streak', (tester) async {
    final rewards = _FakeDailyRewards(
      _status('status_broken'),
      replies: {'restart': _result('claim_day1')},
    );
    await _pump(tester, rewards: rewards);
    await _open(tester);

    await tester.tap(_label('Start over'));
    await tester.pumpAndSettle();

    expect(rewards.calls, ['restart']);
    expect(_reveal(_label('Day 1 reward')), findsOneWidget);
    await tester.tap(_label('Collect'));
    await tester.pumpAndSettle();
    expect(find.text('1-day streak'), findsOneWidget);
  });

  testWidgets('a collected day counts down to the next', (tester) async {
    await _pump(tester, rewards: _FakeDailyRewards(_status('status_claimed')));
    await _open(tester);

    expect(find.text('10:59:59'), findsNothing);
    expect(find.textContaining(RegExp(r'^1[01]:\d\d:\d\d$')), findsOneWidget);
    expect(_label('Come back tomorrow'), findsOneWidget);
    expect(_label('Claim'), findsNothing);
  });

  testWidgets('a failed claim keeps the table and says so', (tester) async {
    final rewards = _FakeDailyRewards(_status('status_midweek'));
    await _pump(tester, rewards: rewards);
    await _open(tester);

    await tester.tap(_label('Claim'));
    await tester.pumpAndSettle();

    expect(rewards.calls, ['claim']);
    expect(find.byType(ClaimCelebration), findsNothing);
    expect(find.text("Couldn't collect right now. Try again."), findsOneWidget);
    expect(_label('Claim'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('a streak that will not load can be retried', (tester) async {
    final rewards = _FakeDailyRewards(null, fail: true);
    await _pump(tester, rewards: rewards);
    await _open(tester);

    expect(find.text("Couldn't load your streak."), findsOneWidget);
    await tester.tap(_label('Try again'));
    await tester.pumpAndSettle();
    expect(rewards.refreshes, 1);
  });

  testWidgets('an event shows its own title and end date', (tester) async {
    await _pump(
      tester,
      rewards: _FakeDailyRewards(_status('status_event')),
      locale: 'fr',
    );
    await _open(tester);

    expect(find.text("MAIN D'HALLOWEEN"), findsOneWidget);
    // Counted from the server's day (Oct 24) to the last day (Oct 31).
    expect(find.text('Se termine dans 7 jours'), findsOneWidget);
    expect(find.byType(StreakDayCard), findsNWidgets(7));
  });

  testWidgets('a returning player gets the welcome-back gift, then the week', (
    tester,
  ) async {
    final rewards = _FakeDailyRewards(
      _status('status_comeback'),
      replies: {
        'comeback': _result('claim_comeback'),
        'claim': _result('claim_day1'),
      },
    );
    final container = await _pump(tester, rewards: rewards);
    await _open(tester, 'launch');

    expect(find.byType(ComebackModal), findsOneWidget);
    expect(_label('Welcome back!'), findsOneWidget);
    await tester.tap(_label('Collect'));
    await tester.pumpAndSettle();
    expect(rewards.calls, ['comeback']);
    expect(find.byType(ClaimCelebration), findsOneWidget);

    await tester.tap(_label('Collect'));
    await tester.pumpAndSettle();
    expect(_profileOf(container).money, 1000);
    expect(_profileOf(container).chips, 2);
    expect(find.byType(ComebackModal), findsNothing);

    // The streak was waiting too: it follows, starting over at day 1.
    expect(find.byType(DailyRewardModal), findsOneWidget);
    expect(find.text('Start your streak'), findsOneWidget);
    expect(find.text('A new streak starts today'), findsOneWidget);
  });

  testWidgets('a second open while the streak shows is ignored', (
    tester,
  ) async {
    // The launch prompt and a notification tap can race on a cold start.
    await _pump(tester, rewards: _FakeDailyRewards(_status('status_midweek')));
    final launch = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'launch'),
    );
    launch.onPressed!();
    launch.onPressed!();
    await tester.pumpAndSettle();
    expect(find.byType(DailyRewardModal), findsOneWidget);

    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(find.byType(DailyRewardModal), findsNothing);
    launch.onPressed!();
    await tester.pumpAndSettle();
    expect(find.byType(DailyRewardModal), findsOneWidget);
  });

  group('entry pill', () {
    testWidgets('calls out a waiting reward and opens the streak', (
      tester,
    ) async {
      await _pump(
        tester,
        rewards: _FakeDailyRewards(_status('status_midweek')),
        pill: true,
      );

      expect(find.text('Day 4 reward is ready'), findsOneWidget);
      expect(_label('Claim'), findsOneWidget);
      await tester.tap(find.byType(DailyEntryPill));
      await tester.pumpAndSettle();
      expect(find.byType(DailyRewardModal), findsOneWidget);
    });

    testWidgets('counts down once today is collected', (tester) async {
      await _pump(
        tester,
        rewards: _FakeDailyRewards(_status('status_claimed')),
        pill: true,
      );

      expect(find.textContaining('Next reward in'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('stays hidden while the streak is switched off', (
      tester,
    ) async {
      await _pump(
        tester,
        rewards: _FakeDailyRewards(_status('status_disabled')),
        pill: true,
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(_Home)),
      );

      expect(container.read(dailyEntryVisibleProvider), isFalse);
      expect(find.textContaining('DAILY STREAK'), findsNothing);
    });
  });

  // Overflows surface as exceptions in widget tests.
  for (final (name, locale, size, scale) in [
    ('en', 'en', const Size(390, 844), 1.0),
    ('ar', 'ar', const Size(390, 844), 1.0),
    ('fr_small', 'fr', const Size(320, 568), 1.0),
    ('es_large_text', 'es', const Size(360, 640), 1.3),
    ('pt', 'pt', const Size(390, 844), 1.0),
  ]) {
    for (final fixture in [
      'status_midweek',
      'status_broken',
      'status_claimed',
      'status_event',
    ]) {
      testWidgets('layout fits: $name $fixture', (tester) async {
        await _pump(
          tester,
          rewards: _FakeDailyRewards(_status(fixture)),
          ads: _FakeAds(ready: true),
          locale: locale,
          size: size,
          textScale: scale,
        );
        await _open(tester);

        expect(tester.takeException(), isNull);
        expect(find.byType(StreakDayCard), findsNWidgets(7));
      });
    }
  }

  testWidgets('the reveal fits a small phone in Arabic', (tester) async {
    await _pump(
      tester,
      rewards: _FakeDailyRewards(
        _status('status_jackpot'),
        replies: {'claim': _result('claim_day7_duplicate')},
      ),
      locale: 'ar',
      size: const Size(320, 568),
      textScale: 1.3,
    );
    await _open(tester);
    await tester.tap(find.text('استلام'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ClaimCelebration), findsOneWidget);
  });
}
