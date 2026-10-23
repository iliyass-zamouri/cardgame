import 'package:cardgame/app/friends_providers.dart';
import 'package:cardgame/app/ranking_providers.dart';
import 'package:cardgame/app/table_chat_controller.dart';
import 'package:cardgame/data/ranking/ranking_api.dart';
import 'package:cardgame/domain/models/game_snapshot.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/screens/home/home_screen.dart'
    show confirmCasinoAction;
import 'package:cardgame/ui/screens/profile/player_profile_screen.dart';
import 'package:cardgame/ui/theme/app_icons.dart';
import 'package:cardgame/ui/theme/casino_chrome.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:cardgame/ui/widgets/country_flag.dart';
import 'package:cardgame/ui/widgets/player_avatar.dart';
import 'package:cardgame/ui/widgets/suit_card_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

/// Quick profile card for the opponent, opened by tapping their seat.
Future<void> showOpponentProfileSheet(
  BuildContext context,
  PlayerSnapshot opponent,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => _OpponentProfileSheet(opponent: opponent),
  );
}

class _OpponentProfileSheet extends ConsumerStatefulWidget {
  const _OpponentProfileSheet({required this.opponent});

  final PlayerSnapshot opponent;

  @override
  ConsumerState<_OpponentProfileSheet> createState() =>
      _OpponentProfileSheetState();
}

class _OpponentProfileSheetState extends ConsumerState<_OpponentProfileSheet> {
  bool _requestSent = false;

  String get _playerId => widget.opponent.playerId ?? '';

  Future<void> _addFriend() async {
    final l10n = context.l10n;
    try {
      await ref
          .read(friendsDataProvider.notifier)
          .sendRequest(targetPlayerId: _playerId);
      if (!mounted) return;
      setState(() => _requestSent = true);
      CasinoToast.show(context, l10n.friendRequestSent);
    } catch (error) {
      if (mounted) CasinoToast.show(context, '$error', success: false);
    }
  }

  Future<void> _report(String name) async {
    final l10n = context.l10n;
    await confirmCasinoAction(
      context,
      title: l10n.reportPlayer,
      message: l10n.reportPlayerConfirm(name),
      confirmLabel: l10n.reportPlayer,
      tone: CasinoActionTone.fold,
      onConfirm: () async {
        final navigator = Navigator.of(context);
        try {
          await ref
              .read(friendsDataProvider.notifier)
              .reportPlayer(targetPlayerId: _playerId, reason: 'table_chat');
          if (!mounted) return;
          CasinoToast.show(context, l10n.reportedToast);
          navigator.pop();
        } catch (error) {
          if (mounted) CasinoToast.show(context, '$error', success: false);
        }
      },
    );
  }

  void _toggleMute(String name, bool muted) {
    ref.read(tableChatProvider.notifier).setOpponentMuted(!muted);
    if (!muted) {
      CasinoToast.show(context, context.l10n.opponentMutedToast(name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rankAsync = ref.watch(playerRankByIdProvider(_playerId));
    final entry = rankAsync.asData?.value;
    final muted = ref.watch(tableChatProvider.select((s) => s.opponentMuted));
    final friends = ref.watch(friendsDataProvider).asData?.value;
    final isFriend =
        friends?.friends.any((f) => f.playerId == _playerId) ?? false;
    final requested =
        _requestSent ||
        (friends?.outgoingRequests.any((r) => r.playerId == _playerId) ??
            false);
    final name =
        entry?.displayName ??
        (widget.opponent.displayName.isEmpty
            ? l10n.player
            : widget.opponent.displayName);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: CasinoGlass(
          borderRadius: BorderRadius.circular(22),
          rimColor: CasinoColors.gold,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              _Header(
                name: name,
                avatarId: widget.opponent.avatarId,
                entry: entry,
              ),
              const SizedBox(height: 14),
              if (rankAsync.isLoading && entry == null)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: SuitCardLoader(height: 24)),
                )
              else if (entry != null) ...[
                _StatsRow(entry: entry),
                const SizedBox(height: 12),
                _RecentForm(playerId: _playerId),
              ],
              const SizedBox(height: 16),
              // Equal-height tiles even when a label wraps to two lines.
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SheetAction(
                      icon: muted ? AppIcons.volume : AppIcons.volumeMute,
                      label: muted ? l10n.unmuteOpponent : l10n.muteOpponent,
                      onTap: () => _toggleMute(name, muted),
                    ),
                    if (!isFriend)
                      _SheetAction(
                        icon: AppIcons.personAdd,
                        label: requested ? l10n.requestSent : l10n.addFriend,
                        onTap: requested ? null : _addFriend,
                      ),
                    _SheetAction(
                      icon: AppIcons.flag,
                      label: l10n.reportPlayer,
                      color: CasinoColors.foldHi,
                      onTap: () => _report(name),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon-over-label action tile; four fit side by side on a phone.
class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = CasinoColors.gold,
  });

  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Opacity(
        opacity: onTap == null ? 0.45 : 1,
        child: Pressable(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [CasinoColors.leather, CasinoColors.leatherDeep],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                HugeIcon(icon: icon, size: 20, color: color),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CasinoColors.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.avatarId, this.entry});

  final String name;
  final String avatarId;
  final RankingEntry? entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entry = this.entry;
    final level = entry == null ? null : entry.totalPoints ~/ 100 + 1;
    final username = entry?.username;
    return Row(
      children: [
        PlayerAvatar(
          avatarId: avatarId,
          size: 64,
          borderWidth: 2,
          borderColor: CasinoColors.gold,
          showGlow: true,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: CasinoFonts.displayOf(context),
                        color: CasinoColors.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  if (flagEmoji(entry?.countryCode).isNotEmpty) ...[
                    const SizedBox(width: 8),
                    CountryFlag(code: entry?.countryCode, size: 18),
                  ],
                ],
              ),
              if (username != null && username.isNotEmpty)
                Text(
                  '@$username',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CasinoColors.goldSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (level != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${l10n.levelNumber(level)} · '
                  '${PlayerProfileScreen.getRankTitle(level, l10n)}',
                  style: const TextStyle(
                    color: CasinoColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.entry});

  final RankingEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final total = entry.wins + entry.losses + entry.draws;
    final winRate = total > 0 ? (entry.wins * 100 / total).round() : 0;
    return Row(
      children: [
        _Stat(label: l10n.elo, value: '${entry.elo}'),
        _Stat(label: '#', value: entry.rank > 0 ? '${entry.rank}' : '-'),
        _Stat(label: l10n.winRate, value: '$winRate%'),
        _Stat(
          label: '${l10n.colWins}/${l10n.colLosses}/${l10n.colDraws}',
          value: '${entry.wins}/${entry.losses}/${entry.draws}',
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CasinoColors.gold.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            FittedBox(
              child: Text(
                value,
                style: const TextStyle(
                  color: CasinoColors.gold,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CasinoColors.textMuted,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Last five results as W / L / D dots, newest first.
class _RecentForm extends ConsumerWidget {
  const _RecentForm({required this.playerId});

  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final matches = ref.watch(playerMatchesProvider(playerId)).asData?.value;
    if (matches == null) return const SizedBox(height: 22);
    final recent = matches.take(5).toList();
    return Row(
      children: [
        Text(
          l10n.recentForm,
          style: const TextStyle(
            color: CasinoColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 10),
        if (recent.isEmpty)
          Text(
            l10n.noRecentMatches,
            style: const TextStyle(color: CasinoColors.textMuted, fontSize: 12),
          )
        else
          for (final match in recent)
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsetsDirectional.only(end: 5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: switch (match.result) {
                  'win' => CasinoColors.success,
                  'loss' => CasinoColors.foldHi,
                  _ => CasinoColors.surfaceHi,
                },
              ),
              child: Text(
                switch (match.result) {
                  'win' => l10n.colWins,
                  'loss' => l10n.colLosses,
                  _ => l10n.colDraws,
                },
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
      ],
    );
  }
}
