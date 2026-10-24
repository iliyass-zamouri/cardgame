import 'dart:convert';
import 'dart:io';

import 'package:cardgame/app/daily_reward_providers.dart';
import 'package:cardgame/data/avatars/avatar_catalog.dart';
import 'package:cardgame/data/daily_reward/daily_reward_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Payloads captured from the server's own claim code on a scratch database.
Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/daily_reward/$name.json').readAsStringSync())
        as Map<String, dynamic>;

DailyRewardStatus status(String name) =>
    DailyRewardStatus.fromJson(fixture(name));

DailyClaimResult claim(String name) => DailyClaimResult.fromJson(fixture(name));

void main() {
  group('DailyRewardStatus', () {
    test('a new player can claim day 1 of the default week', () {
      final s = status('status_fresh');
      expect(s.enabled, isTrue);
      expect(s.state, DailyRewardState.claimable);
      expect(s.needsAttention, isTrue);
      expect(s.isEvent, isFalse);
      expect(s.nextDay, 1);
      expect(s.streakCount, 0);
      expect(s.days, hasLength(7));
      expect(s.days.first.status, DailyDayStatus.today);
      expect(
        s.days.skip(1).map((day) => day.status),
        everyElement(DailyDayStatus.upcoming),
      );
      expect(s.nextRewards.single, isA<CurrencyReward>());
      expect((s.nextRewards.single as CurrencyReward).amount, 200);
      expect(s.adBoostEnabled, isTrue);
      expect(s.adBoostMultiplier, 2);
      expect(s.coinBoostPercent, 25);
      expect(s.comebackAvailable, isFalse);
    });

    test('reads every kind of reward in the week', () {
      final days = status('status_fresh').days;
      expect(days[1].rewards.single, isA<CoinBoostReward>());
      expect((days[1].rewards.single as CoinBoostReward).minutes, 60);
      final chips = days[2].rewards.single as CurrencyReward;
      expect(chips.currency, CurrencyType.chips);
      expect(chips.amount, 1);
      expect(days[3].rewards[1], isA<StreakFreezeReward>());
      expect((days[3].rewards[1] as StreakFreezeReward).quantity, 1);
      expect(days[6].rewards[1], isA<ChestReward>());
      expect((days[6].rewards[1] as ChestReward).chestId, 'royal');
    });

    test('names each chest and gives its odds', () {
      final chest = status('status_fresh').chests['royal']!;
      expect(localizedTitle(chest.titles, 'fr'), 'Coffre royal');
      expect(localizedTitle(chest.titles, 'de'), 'Royal Chest');
      expect(chest.pool, hasLength(5));
      expect(chest.oddsOf(0), closeTo(0.6, 1e-9));
      expect(chest.oddsOf(4), closeTo(0.01, 1e-9));
      final queen = chest.pool[2].reward as AvatarReward;
      expect(queen.itemId, 'queen-of-heart');
      expect(queen.fallback!.amount, 1500);
    });

    test('a collected day counts down to the next', () {
      final s = status('status_claimed');
      expect(s.state, DailyRewardState.claimed);
      expect(s.needsAttention, isFalse);
      expect(s.position, 1);
      expect(s.nextDay, 2);
      expect(s.secondsUntilNextClaim, 39600);
      expect(s.days.map((day) => day.status).take(2), [
        DailyDayStatus.claimed,
        DailyDayStatus.next,
      ]);
    });

    test('a broken streak offers the chip rescue', () {
      final s = status('status_broken');
      expect(s.state, DailyRewardState.broken);
      expect(s.needsAttention, isTrue);
      expect(s.rescueAvailable, isTrue);
      expect(s.rescueChipCost, 3);
      expect(s.rescueLastDate, '2026-10-26');
      expect(s.streakCount, 5);
      expect(s.nextDay, 6);
      expect(s.missedDays, 2);
    });

    test('an event replaces the week and carries its title', () {
      final s = status('status_event');
      expect(s.isEvent, isTrue);
      expect(s.calendarId, 'halloween');
      expect(localizedTitle(s.calendarTitles, 'fr'), "Main d'Halloween");
      expect(localizedTitle(s.calendarTitles, 'ar'), 'يد الهالوين');
      expect(s.calendarEndsAt, '2026-10-31');
    });

    test("the player's day comes from the server clock and their offset", () {
      // Captured at 10:00 UTC for a player at UTC+1.
      expect(status('status_event').localDate, DateTime.utc(2026, 10, 24));
      final lateEvening = DailyRewardStatus.fromJson({
        'enabled': true,
        'state': 'claimable',
        'serverNow': DateTime.utc(2026, 10, 24, 23, 30).millisecondsSinceEpoch,
        'tzOffsetMinutes': 60,
      });
      expect(lateEvening.localDate, DateTime.utc(2026, 10, 25));
      final behind = DailyRewardStatus.fromJson({
        'enabled': true,
        'state': 'claimable',
        'serverNow': DateTime.utc(2026, 10, 24, 2).millisecondsSinceEpoch,
        'tzOffsetMinutes': -300,
      });
      expect(behind.localDate, DateTime.utc(2026, 10, 23));
    });

    test('a long absence brings the welcome-back gift and a new streak', () {
      final s = status('status_comeback');
      expect(s.comebackAvailable, isTrue);
      expect(s.needsAttention, isTrue);
      expect(s.resets, isTrue);
      expect(s.nextDay, 1);
      expect(s.comebackRewards, hasLength(2));
    });

    test('a switched-off streak needs nothing', () {
      final s = status('status_disabled');
      expect(s.enabled, isFalse);
      expect(s.state, DailyRewardState.disabled);
      expect(s.needsAttention, isFalse);
    });

    test('rewards from a newer server become mystery gifts', () {
      final s = DailyRewardStatus.fromJson({
        'enabled': true,
        'state': 'claimable',
        'days': [
          {
            'day': 1,
            'status': 'today',
            'rewards': [
              {'type': 'emote', 'itemId': 'wink'},
              {'type': 'booster', 'boosterId': 'xp_boost'},
              {'type': 'money'},
            ],
          },
        ],
      });
      final rewards = s.days.single.rewards;
      expect((rewards[0] as UnknownReward).type, 'emote');
      expect((rewards[1] as UnknownReward).type, 'booster');
      expect((rewards[2] as CurrencyReward).amount, 0);
    });
  });

  group('DailyClaimResult', () {
    test('day 1 pays money and returns the new balances', () {
      final result = claim('claim_day1');
      expect(result.alreadyClaimed, isFalse);
      expect(result.day, 1);
      expect(result.streakCount, 1);
      expect(result.granted.single.amountOf(CurrencyType.money), 200);
      expect(result.money, 700);
      expect(result.chips, 1);
      expect(result.status!.state, DailyRewardState.claimed);
    });

    test('a doubled day 4 pays twice the money and a Streak Freeze', () {
      final result = claim('claim_day4_boosted');
      expect(result.boosted, isTrue);
      final money = result.granted.fold<int>(
        0,
        (sum, grant) => sum + grant.amountOf(CurrencyType.money),
      );
      expect(money, 800);
      expect(result.granted[1].reward, isA<StreakFreezeReward>());
      expect(result.status!.freezes, 1);
    });

    test('day 2 starts a Coin Boost', () {
      final result = claim('claim_day2');
      expect((result.granted.single.reward as CoinBoostReward).minutes, 60);
      expect(result.status!.coinBoostRemainingSeconds, 3600);
    });

    test('a rescue spends chips and keeps the streak', () {
      final result = claim('claim_rescue');
      expect(result.rescued, isTrue);
      expect(result.chipsSpent, 3);
      expect(result.day, 6);
      expect(result.streakCount, 6);
      expect(result.chips, 4);
    });

    test('the jackpot chest can roll a new avatar', () {
      final result = claim('claim_day7');
      final chest = result.granted[1];
      expect(chest.reward, isA<ChestReward>());
      final loot = chest.loot!;
      expect((loot.reward as AvatarReward).itemId, 'queen-of-heart');
      expect(loot.duplicate, isFalse);
      expect(result.ownedAvatars, contains('queen-of-heart'));
      expect(chest.amountOf(CurrencyType.money), 0);
    });

    test('an avatar the player owns pays its fallback instead', () {
      final result = claim('claim_day7_duplicate');
      final loot = result.granted[1].loot!;
      expect(loot.duplicate, isTrue);
      expect(loot.converted!.amount, 1500);
      final money = result.granted.fold<int>(
        0,
        (sum, grant) => sum + grant.amountOf(CurrencyType.money),
      );
      expect(money, 2500);
    });

    test('the welcome-back claim has no day but still updates balances', () {
      final result = claim('claim_comeback');
      expect(result.day, isNull);
      expect(result.granted, hasLength(2));
      expect(result.money, 1000);
      expect(result.chips, 2);
      expect(result.status!.comebackAvailable, isFalse);
    });
  });

  test('a finished week stays full until the next one opens', () {
    final after = claim('claim_day7').status!;
    // The server already points at next week's day 1.
    expect(after.days.first.status, DailyDayStatus.next);
    expect(after.weekComplete, isTrue);
    expect(status('status_claimed').weekComplete, isFalse);
    expect(status('status_jackpot').weekComplete, isFalse);
  });

  test('a streak about to start over reads as 0', () {
    expect(status('status_comeback').streakCount, 4);
    expect(status('status_comeback').liveStreak, 0);
    expect(status('status_midweek').liveStreak, 3);
    expect(status('status_broken').liveStreak, 5);
  });

  test('the countdown runs from when the answer arrived', () {
    final s = status('status_claimed');
    final view = DailyRewardView(
      s,
      dailyRewardClock() - const Duration(seconds: 100),
    );
    expect(view.secondsUntilNextClaim(), inInclusiveRange(39499, 39500));
    final stale = DailyRewardView(
      s,
      dailyRewardClock() - const Duration(hours: 12),
    );
    expect(stale.secondsUntilNextClaim(), 0);
  });
}
