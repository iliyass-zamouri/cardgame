import 'package:cardgame/data/avatars/avatar_catalog.dart';
import 'package:cardgame/data/boost/boost_models.dart';

int _int(Object? value, [int fallback = 0]) =>
    value is num ? value.toInt() : fallback;

String _string(Object? value) => value is String ? value : '';

List<Map<String, dynamic>> _maps(Object? value) =>
    value is List
        ? [
          for (final entry in value)
            if (entry is Map) Map<String, dynamic>.from(entry),
        ]
        : const [];

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

/// A 5-language title from the admin (event and chest names), English first.
Map<String, String> _titles(Object? value) => {
  if (value is Map)
    for (final entry in value.entries)
      if (entry.value is String && (entry.value as String).isNotEmpty)
        '${entry.key}': entry.value as String,
};

/// The title in [languageCode], else English, else null.
String? localizedTitle(Map<String, String> titles, String languageCode) =>
    titles[languageCode] ?? titles['en'];

/// One reward as the server describes it. A kind this app doesn't know (sent
/// by a newer server) becomes an [UnknownReward], shown as a mystery gift.
sealed class RewardItem {
  const RewardItem();

  factory RewardItem.fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    return switch (type) {
      'money' ||
      'chips' => CurrencyReward.tryParse(json) ?? UnknownReward(type: '$type'),
      'avatar' => AvatarReward(
        itemId: _string(json['itemId']),
        fallback: CurrencyReward.tryParse(json['fallback']),
      ),
      'deck' => DeckReward(
        itemId: _string(json['itemId']),
        fallback: CurrencyReward.tryParse(json['fallback']),
      ),
      'booster' => switch (json['boosterId']) {
        'coin_boost' => CoinBoostReward(
          minutes: _int(json['minutes']),
          presetId: _string(json['presetId']),
          preset: json['percent'] is num ? BoostPreset.fromJson(json) : null,
        ),
        'streak_freeze' => StreakFreezeReward(
          quantity: _int(json['quantity'], 1),
        ),
        _ => const UnknownReward(type: 'booster'),
      },
      'chest' => ChestReward(chestId: _string(json['chestId'])),
      _ => UnknownReward(type: '$type'),
    };
  }
}

final class CurrencyReward extends RewardItem {
  const CurrencyReward({required this.currency, required this.amount});

  final CurrencyType currency;
  final int amount;

  static CurrencyReward? tryParse(Object? value) {
    if (value is! Map) return null;
    final type = value['type'];
    if (type != 'money' && type != 'chips') return null;
    return CurrencyReward(
      currency: type == 'chips' ? CurrencyType.chips : CurrencyType.money,
      amount: _int(value['amount']),
    );
  }
}

final class AvatarReward extends RewardItem {
  const AvatarReward({required this.itemId, this.fallback});

  final String itemId;

  /// Paid instead when the player already owns the avatar.
  final CurrencyReward? fallback;
}

final class DeckReward extends RewardItem {
  const DeckReward({required this.itemId, this.fallback});

  final String itemId;

  /// Paid instead when the player already owns the deck.
  final CurrencyReward? fallback;
}

/// Extra money on match wins for [minutes], at the admin's preset
/// [presetId]. It waits in the player's boosts until they activate it.
final class CoinBoostReward extends RewardItem {
  const CoinBoostReward({
    required this.minutes,
    this.presetId = '',
    this.preset,
  });

  final int minutes;
  final String presetId;

  /// Its value: as a claim granted it, or the admin's preset that the
  /// status resolved. Null from a server that predates presets.
  final BoostPreset? preset;

  /// Its value: its own, else from [presets], else null.
  BoostPreset? presetIn(Map<String, BoostPreset> presets) =>
      preset ?? presets[presetId];
}

/// [reward] with its Coin Boost value filled in from [presets].
RewardItem _withPreset(RewardItem reward, Map<String, BoostPreset> presets) {
  if (reward is! CoinBoostReward || reward.preset != null) return reward;
  final preset = presets[reward.presetId];
  if (preset == null) return reward;
  return CoinBoostReward(
    minutes: reward.minutes,
    presetId: reward.presetId,
    preset: preset,
  );
}

/// Saves the streak through a missed day, [quantity] times.
final class StreakFreezeReward extends RewardItem {
  const StreakFreezeReward({required this.quantity});

  final int quantity;
}

/// One reward rolled on the server from the chest's pool.
final class ChestReward extends RewardItem {
  const ChestReward({required this.chestId});

  final String chestId;
}

final class UnknownReward extends RewardItem {
  const UnknownReward({required this.type});

  final String type;
}

/// What a claim actually paid: the reward, plus what became of it.
class GrantedReward {
  const GrantedReward({
    required this.reward,
    this.duplicate = false,
    this.converted,
    this.loot,
    this.boostItemId,
    this.boostActivated = false,
  });

  final RewardItem reward;

  /// The player already owned the item (or it left the shop), so
  /// [converted] was paid instead.
  final bool duplicate;
  final CurrencyReward? converted;

  /// What a chest rolled.
  final GrantedReward? loot;

  /// A Coin Boost waiting in the player's boosts, to activate by this id.
  final String? boostItemId;

  /// A Coin Boost the server started at once.
  final bool boostActivated;

  /// This grant, or the chest loot inside it, when that is a Coin Boost.
  GrantedReward? get boost =>
      reward is CoinBoostReward ? this : loot?.boost;

  factory GrantedReward.fromJson(Map<String, dynamic> json) {
    final loot = json['loot'];
    return GrantedReward(
      reward: RewardItem.fromJson(json),
      duplicate: json['duplicate'] == true || json['unknown'] == true,
      converted: CurrencyReward.tryParse(json['converted']),
      loot: loot is Map ? GrantedReward.fromJson(_map(loot)) : null,
      boostItemId: json['itemId'] is String ? json['itemId'] as String : null,
      boostActivated: json['activated'] == true,
    );
  }

  /// Money or chips this grant added, counting conversions and chest loot.
  int amountOf(CurrencyType currency) {
    final reward = this.reward;
    var total = 0;
    if (reward is CurrencyReward && reward.currency == currency) {
      total += reward.amount;
    }
    final converted = this.converted;
    if (converted != null && converted.currency == currency) {
      total += converted.amount;
    }
    return total + (loot?.amountOf(currency) ?? 0);
  }
}

enum DailyRewardState { claimable, claimed, broken, disabled }

enum DailyDayStatus { claimed, today, next, upcoming }

enum StreakChoice { rescue, restart }

class DailyDay {
  const DailyDay({
    required this.day,
    required this.status,
    required this.rewards,
  });

  final int day;
  final DailyDayStatus status;
  final List<RewardItem> rewards;

  factory DailyDay.fromJson(
    Map<String, dynamic> json, [
    Map<String, BoostPreset> presets = const {},
  ]) {
    return DailyDay(
      day: _int(json['day'], 1),
      status:
          DailyDayStatus.values.asNameMap()[json['status']] ??
          DailyDayStatus.upcoming,
      rewards: [
        for (final entry in _maps(json['rewards']))
          _withPreset(RewardItem.fromJson(entry), presets),
      ],
    );
  }
}

class ChestOdds {
  const ChestOdds({required this.weight, required this.reward});

  final int weight;
  final RewardItem reward;
}

class DailyChest {
  const DailyChest({required this.titles, required this.pool});

  final Map<String, String> titles;
  final List<ChestOdds> pool;

  /// Chance of pool entry [index], 0..1.
  double oddsOf(int index) {
    final total = pool.fold<int>(0, (sum, entry) => sum + entry.weight);
    return total <= 0 ? 0 : pool[index].weight / total;
  }

  factory DailyChest.fromJson(
    Map<String, dynamic> json, [
    Map<String, BoostPreset> presets = const {},
  ]) {
    return DailyChest(
      titles: _titles(json['title']),
      pool: [
        for (final entry in _maps(json['pool']))
          ChestOdds(
            weight: _int(entry['weight']),
            reward: _withPreset(
              RewardItem.fromJson(_map(entry['reward'])),
              presets,
            ),
          ),
      ],
    );
  }
}

/// GET /daily-reward. Times are seconds from when it arrived, never wall
/// clocks: the server owns the day.
class DailyRewardStatus {
  const DailyRewardStatus({
    required this.enabled,
    required this.state,
    this.tzOffsetMinutes = 0,
    this.localDate,
    this.calendarId = 'default',
    this.calendarTitles = const {},
    this.calendarEndsAt,
    this.streakCount = 0,
    this.bestStreak = 0,
    this.position = 0,
    this.cycle = 0,
    this.nextDay = 1,
    this.resets = false,
    this.days = const [],
    this.nextRewards = const [],
    this.secondsUntilNextClaim = 0,
    this.graceDays = 0,
    this.missedDays = 0,
    this.graceUsed = 0,
    this.freezes = 0,
    this.freezesWillUse = 0,
    this.rescueAvailable = false,
    this.rescueChipCost = 0,
    this.rescueLastDate,
    this.adBoostEnabled = false,
    this.adBoostMultiplier = 2,
    this.coinBoostRemainingSeconds = 0,
    this.coinBoostPercent = 0,
    this.comebackAvailable = false,
    this.comebackRewards = const [],
    this.chests = const {},
    this.boostPresets = const {},
  });

  static const disabled = DailyRewardStatus(
    enabled: false,
    state: DailyRewardState.disabled,
  );

  final bool enabled;
  final DailyRewardState state;
  final int tzOffsetMinutes;

  /// The player's day as the server counts it (its clock, their offset), as
  /// UTC midnight. Day counts come from this, never the device clock.
  final DateTime? localDate;

  /// The calendar in play: 'default' or an event's id with its title.
  final String calendarId;
  final Map<String, String> calendarTitles;

  /// Last day of a running event, as YYYY-MM-DD.
  final String? calendarEndsAt;

  final int streakCount;
  final int bestStreak;

  /// Last claimed day of the week, 0 before the first claim.
  final int position;

  /// Weeks completed.
  final int cycle;

  /// The day the next claim pays.
  final int nextDay;

  /// The next claim starts a new streak at day 1.
  final bool resets;

  final List<DailyDay> days;
  final List<RewardItem> nextRewards;
  final int secondsUntilNextClaim;
  final int graceDays;
  final int missedDays;
  final int graceUsed;
  final int freezes;
  final int freezesWillUse;
  final bool rescueAvailable;
  final int rescueChipCost;
  final String? rescueLastDate;
  final bool adBoostEnabled;
  final int adBoostMultiplier;
  final int coinBoostRemainingSeconds;
  final int coinBoostPercent;
  final bool comebackAvailable;
  final List<RewardItem> comebackRewards;
  final Map<String, DailyChest> chests;

  /// Every Coin Boost preset by id, to name and colour a boost reward.
  final Map<String, BoostPreset> boostPresets;

  bool get isEvent => calendarId != 'default' && calendarTitles.isNotEmpty;

  /// Day 7 was collected today. [days] already points at next week's day 1,
  /// but the finished week stays on the table until that claim opens.
  bool get weekComplete => state == DailyRewardState.claimed && position == 7;

  /// The streak as it stands for the next claim: 0 when that claim starts over.
  int get liveStreak => resets ? 0 : streakCount;

  /// Something to collect right now: today's card or a broken streak to settle.
  bool get needsAttention =>
      enabled &&
      (state == DailyRewardState.claimable ||
          state == DailyRewardState.broken ||
          comebackAvailable);

  factory DailyRewardStatus.fromJson(Map<String, dynamic> json) {
    if (json['enabled'] != true) return disabled;
    final calendar = _map(json['calendar']);
    final streak = _map(json['streak']);
    final grace = _map(json['grace']);
    final freezes = _map(json['freezes']);
    final rescue = _map(json['rescue']);
    final adBoost = _map(json['adBoost']);
    final coinBoost = _map(json['coinBoost']);
    final comeback = _map(json['comeback']);
    final chests = _map(json['chests']);
    final boostPresets = <String, BoostPreset>{
      for (final entry in _map(json['boostPresets']).entries)
        if (entry.value is Map)
          entry.key: BoostPreset.fromJson(_map(entry.value)),
    };
    final serverNow = json['serverNow'];
    final tzOffsetMinutes = _int(json['tzOffsetMinutes']);
    final local =
        serverNow is num
            ? DateTime.fromMillisecondsSinceEpoch(
              serverNow.toInt() + tzOffsetMinutes * 60000,
              isUtc: true,
            )
            : null;
    return DailyRewardStatus(
      enabled: true,
      state:
          DailyRewardState.values.asNameMap()[json['state']] ??
          DailyRewardState.disabled,
      tzOffsetMinutes: tzOffsetMinutes,
      localDate:
          local == null
              ? null
              : DateTime.utc(local.year, local.month, local.day),
      calendarId:
          calendar['id'] is String ? calendar['id'] as String : 'default',
      calendarTitles: _titles(calendar['title']),
      calendarEndsAt:
          calendar['endsAt'] is String ? calendar['endsAt'] as String : null,
      streakCount: _int(streak['count']),
      bestStreak: _int(streak['best']),
      position: _int(streak['position']),
      cycle: _int(streak['cycle']),
      nextDay: _int(streak['nextDay'], 1),
      resets: streak['resets'] == true,
      days: [
        for (final entry in _maps(json['days']))
          DailyDay.fromJson(entry, boostPresets),
      ],
      nextRewards: [
        for (final entry in _maps(_map(json['nextReward'])['rewards']))
          _withPreset(RewardItem.fromJson(entry), boostPresets),
      ],
      secondsUntilNextClaim: _int(json['secondsUntilNextClaim']),
      graceDays: _int(grace['days']),
      missedDays: _int(grace['missedDays']),
      graceUsed: _int(grace['graceUsed']),
      freezes: _int(freezes['count']),
      freezesWillUse: _int(freezes['willUse']),
      rescueAvailable: rescue['available'] == true,
      rescueChipCost: _int(rescue['chipCost']),
      rescueLastDate:
          rescue['lastDate'] is String ? rescue['lastDate'] as String : null,
      adBoostEnabled: adBoost['enabled'] == true,
      adBoostMultiplier: _int(adBoost['multiplier'], 2),
      coinBoostRemainingSeconds: _int(coinBoost['remainingSeconds']),
      coinBoostPercent: _int(coinBoost['percent']),
      comebackAvailable: comeback['available'] == true,
      comebackRewards: [
        for (final entry in _maps(comeback['rewards']))
          _withPreset(RewardItem.fromJson(entry), boostPresets),
      ],
      chests: {
        for (final entry in chests.entries)
          if (entry.value is Map)
            entry.key: DailyChest.fromJson(_map(entry.value), boostPresets),
      },
      boostPresets: boostPresets,
    );
  }
}

/// POST /daily-reward/claim (and the welcome-back claim).
class DailyClaimResult {
  const DailyClaimResult({
    required this.alreadyClaimed,
    required this.granted,
    this.day,
    this.chipsSpent = 0,
    this.freezesUsed = 0,
    this.graceUsed = 0,
    this.rescued = false,
    this.streakReset = false,
    this.boosted = false,
    this.streakCount,
    this.money,
    this.chips,
    this.ownedAvatars,
    this.ownedDecks,
    this.status,
  });

  final bool alreadyClaimed;
  final List<GrantedReward> granted;
  final int? day;
  final int chipsSpent;
  final int freezesUsed;
  final int graceUsed;
  final bool rescued;
  final bool streakReset;
  final bool boosted;
  final int? streakCount;

  /// Balances and owned items after the claim, straight from the server.
  final int? money;
  final int? chips;
  final List<String>? ownedAvatars;
  final List<String>? ownedDecks;

  /// The streak right after the claim.
  final DailyRewardStatus? status;

  factory DailyClaimResult.fromJson(Map<String, dynamic> json) {
    List<String>? strings(Object? value) =>
        value is List ? [for (final entry in value) '$entry'] : null;
    final status = json['status'];
    return DailyClaimResult(
      alreadyClaimed: json['alreadyClaimed'] == true,
      granted: [
        for (final entry in _maps(json['granted']))
          GrantedReward.fromJson(entry),
      ],
      day: json['day'] is num ? (json['day'] as num).toInt() : null,
      chipsSpent: _int(json['chipsSpent']),
      freezesUsed: _int(json['freezesUsed']),
      graceUsed: _int(json['graceUsed']),
      rescued: json['rescued'] == true,
      streakReset: json['streakReset'] == true,
      boosted: json['boosted'] == true,
      streakCount:
          _map(json['streak'])['count'] is num
              ? (_map(json['streak'])['count'] as num).toInt()
              : null,
      money: json['money'] is num ? (json['money'] as num).toInt() : null,
      chips: json['chips'] is num ? (json['chips'] as num).toInt() : null,
      ownedAvatars: strings(json['ownedAvatars']),
      ownedDecks: strings(json['ownedDecks']),
      status: status is Map ? DailyRewardStatus.fromJson(_map(status)) : null,
    );
  }
}
