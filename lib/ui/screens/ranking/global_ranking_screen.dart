import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/app/ranking_providers.dart';
import 'package:cardgame/data/ranking/ranking_api.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/screens/profile/player_profile_screen.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/widgets/player_avatar.dart';
import 'package:cardgame/ui/widgets/suit_card_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GlobalRankingScreen extends ConsumerWidget {
  const GlobalRankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: CasinoColors.bg,
        appBar: AppBar(
          backgroundColor: CasinoColors.surface,
          foregroundColor: CasinoColors.text,
          title: Text(
            l10n.globalRanking,
            style: const TextStyle(
              color: CasinoColors.gold,
              fontWeight: FontWeight.w800,
            ),
          ),
          bottom: TabBar(
            indicatorColor: CasinoColors.gold,
            labelColor: CasinoColors.gold,
            unselectedLabelColor: CasinoColors.textMuted,
            tabs: [Tab(text: l10n.leaderboard), Tab(text: l10n.matchHistory)],
          ),
        ),
        body: const TabBarView(children: [_LeaderboardTab(), _HistoryTab()]),
      ),
    );
  }
}

enum _SelfSticky { none, top, bottom }

class _LeaderboardTab extends ConsumerStatefulWidget {
  const _LeaderboardTab();

  @override
  ConsumerState<_LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends ConsumerState<_LeaderboardTab> {
  static const _approxRow = 57.0;

  final _viewportKey = GlobalKey();
  final _selfKey = GlobalKey();
  final _scrollController = ScrollController();
  _SelfSticky _sticky = _SelfSticky.bottom;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateSticky({required int selfIndex}) {
    late final _SelfSticky next;

    if (selfIndex < 0) {
      next = _SelfSticky.bottom;
    } else {
      final selfCtx = _selfKey.currentContext;
      final vpCtx = _viewportKey.currentContext;
      final selfBox = selfCtx?.findRenderObject() as RenderBox?;
      final vpBox = vpCtx?.findRenderObject() as RenderBox?;

      if (selfBox != null &&
          vpBox != null &&
          selfBox.hasSize &&
          vpBox.hasSize) {
        final vpTop = vpBox.localToGlobal(Offset.zero).dy;
        final vpBottom = vpTop + vpBox.size.height;
        final selfTop = selfBox.localToGlobal(Offset.zero).dy;
        final selfBottom = selfTop + selfBox.size.height;

        next =
            selfBottom <= vpTop
                ? _SelfSticky.top
                : selfTop >= vpBottom
                ? _SelfSticky.bottom
                : _SelfSticky.none;
      } else if (_scrollController.hasClients) {
        // Row not built (recycled) → off-screen; pick top vs bottom.
        final itemCenter = selfIndex * _approxRow + _approxRow / 2;
        final offset = _scrollController.offset;
        next = itemCenter < offset ? _SelfSticky.top : _SelfSticky.bottom;
      } else {
        return;
      }
    }

    if (next != _sticky) setState(() => _sticky = next);
  }

  void _scheduleStickyUpdate({required int selfIndex}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateSticky(selfIndex: selfIndex);
    });
  }

  Widget _stickyRow({required RankingEntry entry, required String selfLabel}) {
    return Material(
      color: CasinoColors.surface,
      elevation: 6,
      shadowColor: Colors.black54,
      child: InkWell(
        onTap:
            () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder:
                    (_) => PlayerProfileScreen(targetPlayerId: entry.playerId),
              ),
            ),
        child: _RankRow(
          entry: entry,
          highlight: true,
          isSelf: true,
          selfLabel: selfLabel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final async = ref.watch(leaderboardProvider);
    final myId =
        (ref.watch(playerProfileProvider).value ?? PlayerProfile.empty)
            .playerId;
    final myRank = ref.watch(myRankProvider).asData?.value;

    return async.when(
      loading: () => const Center(child: SuitCardLoader(height: 32)),
      error:
          (error, _) => _ErrorPane(
            message: l10n.rankingLoadError,
            onRetry: () => ref.invalidate(leaderboardProvider),
          ),
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Text(
              l10n.rankingEmpty,
              style: const TextStyle(color: CasinoColors.textMuted),
            ),
          );
        }

        final selfIndex =
            myId.isEmpty ? -1 : entries.indexWhere((e) => e.playerId == myId);
        final stickyEntry = selfIndex >= 0 ? entries[selfIndex] : myRank;
        final showSticky = stickyEntry != null && _sticky != _SelfSticky.none;

        _scheduleStickyUpdate(selfIndex: selfIndex);

        return Column(
          children: [
            const _LeaderboardHeader(),
            Expanded(
              child: Stack(
                key: _viewportKey,
                children: [
                  NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.axis == Axis.vertical) {
                        _updateSticky(selfIndex: selfIndex);
                      }
                      return false;
                    },
                    child: RefreshIndicator(
                      color: CasinoColors.gold,
                      onRefresh: () async {
                        ref.invalidate(leaderboardProvider);
                        ref.invalidate(myRankProvider);
                        await ref.read(leaderboardProvider.future);
                      },
                      child: ListView.separated(
                        controller: _scrollController,
                        padding: EdgeInsets.only(
                          top: 4,
                          bottom:
                              showSticky && _sticky == _SelfSticky.bottom
                                  ? _approxRow + 8
                                  : 4,
                        ),
                        itemCount: entries.length,
                        separatorBuilder:
                            (_, _) => const Divider(
                              height: 1,
                              color: Color(0x22FFFFFF),
                            ),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          final isSelf = entry.playerId == myId;
                          return InkWell(
                            key: isSelf ? _selfKey : null,
                            onTap:
                                () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder:
                                        (_) => PlayerProfileScreen(
                                          targetPlayerId: entry.playerId,
                                        ),
                                  ),
                                ),
                            child: _RankRow(
                              entry: entry,
                              highlight: isSelf,
                              isSelf: isSelf,
                              selfLabel: l10n.you,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (showSticky && stickyEntry != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: _sticky == _SelfSticky.top ? 0 : null,
                      bottom: _sticky == _SelfSticky.bottom ? 0 : null,
                      child: _stickyRow(
                        entry: stickyEntry,
                        selfLabel: l10n.you,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(matchHistoryProvider);

    return async.when(
      loading: () => const Center(child: SuitCardLoader(height: 32)),
      error:
          (error, _) => _ErrorPane(
            message: l10n.rankingLoadError,
            onRetry: () => ref.invalidate(matchHistoryProvider),
          ),
      data: (matches) {
        if (matches.isEmpty) {
          return Center(
            child: Text(
              l10n.matchHistoryEmpty,
              style: const TextStyle(color: CasinoColors.textMuted),
            ),
          );
        }
        return RefreshIndicator(
          color: CasinoColors.gold,
          onRefresh: () async {
            ref.invalidate(matchHistoryProvider);
            await ref.read(matchHistoryProvider.future);
          },
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            itemCount: matches.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _HistoryTile(item: matches[index]);
            },
          ),
        );
      },
    );
  }
}

/// Shared column widths for header + rows.
abstract final class _LbCols {
  static const rank = 36.0;
  static const avatar = 36.0;
  static const gap = 10.0;
  static const stat = 36.0;
  static const elo = 48.0;
  static const hPad = 12.0;
}

class _LeaderboardHeader extends StatelessWidget {
  const _LeaderboardHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const style = TextStyle(
      color: CasinoColors.textMuted,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
    );
    return Container(
      color: CasinoColors.bgElevated,
      padding: const EdgeInsets.symmetric(
        horizontal: _LbCols.hPad,
        vertical: 8,
      ),
      child: Row(
        children: [
          const SizedBox(width: _LbCols.rank),
          const SizedBox(width: _LbCols.avatar + _LbCols.gap),
          const Expanded(child: SizedBox.shrink()),
          SizedBox(
            width: _LbCols.stat,
            child: Text(
              l10n.colWins,
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
          SizedBox(
            width: _LbCols.stat,
            child: Text(
              l10n.colLosses,
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
          SizedBox(
            width: _LbCols.stat,
            child: Text(
              l10n.colDraws,
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
          SizedBox(
            width: _LbCols.elo,
            child: Text(l10n.elo, textAlign: TextAlign.end, style: style),
          ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.entry,
    required this.highlight,
    required this.isSelf,
    required this.selfLabel,
  });

  final RankingEntry entry;
  final bool highlight;
  final bool isSelf;
  final String selfLabel;

  static Color? _crownColor(int rank) => switch (rank) {
    1 => CasinoColors.gold,
    2 => const Color(0xFFC0C0C0), // silver
    3 => const Color(0xFFCD7F32), // bronze
    _ => null,
  };

  static const _statStyle = TextStyle(
    color: CasinoColors.text,
    fontWeight: FontWeight.w600,
    fontSize: 13,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  @override
  Widget build(BuildContext context) {
    final name = isSelf ? selfLabel : entry.displayName;
    final crownColor = _crownColor(entry.rank);
    return Container(
      color: highlight ? CasinoColors.gold.withValues(alpha: 0.08) : null,
      padding: EdgeInsets.fromLTRB(
        _LbCols.hPad,
        crownColor != null ? 14 : 10,
        _LbCols.hPad,
        10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _LbCols.rank,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                color: highlight ? CasinoColors.gold : CasinoColors.textMuted,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          SizedBox(
            width: _LbCols.avatar,
            height: _LbCols.avatar,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                const PlayerAvatar(avatarId: 'default', size: 36),
                if (crownColor != null)
                  Positioned(
                    top: -12,
                    child: SvgPicture.asset(
                      'assets/crown.svg',
                      width: 20,
                      height: 16,
                      fit: BoxFit.contain,
                      colorFilter: ColorFilter.mode(
                        crownColor,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: _LbCols.gap),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: highlight ? CasinoColors.gold : CasinoColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: _LbCols.stat,
            child: Text(
              '${entry.wins}',
              textAlign: TextAlign.center,
              style: _statStyle.copyWith(color: const Color(0xFF5DCF8A)),
            ),
          ),
          SizedBox(
            width: _LbCols.stat,
            child: Text(
              '${entry.losses}',
              textAlign: TextAlign.center,
              style: _statStyle.copyWith(color: const Color(0xFFE07070)),
            ),
          ),
          SizedBox(
            width: _LbCols.stat,
            child: Text(
              '${entry.draws}',
              textAlign: TextAlign.center,
              style: _statStyle.copyWith(color: CasinoColors.textMuted),
            ),
          ),
          SizedBox(
            width: _LbCols.elo,
            child: Text(
              '${entry.elo}',
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: CasinoColors.goldSoft,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.item});

  final MatchHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final resultLabel = switch (item.result) {
      'win' => l10n.matchResultWin,
      'loss' => l10n.matchResultLoss,
      _ => l10n.matchResultDraw,
    };
    final resultColor = switch (item.result) {
      'win' => const Color(0xFF5DCF8A),
      'loss' => const Color(0xFFE07070),
      _ => CasinoColors.textMuted,
    };
    final eloSign = item.eloDelta > 0 ? '+' : '';
    final when = item.createdAt;
    final whenText =
        when == null
            ? ''
            : '${when.year}-${when.month.toString().padLeft(2, '0')}-${when.day.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: CasinoColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CasinoColors.gold.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 52,
            alignment: Alignment.center,
            child: Text(
              resultLabel,
              style: TextStyle(
                color: resultColor,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.opponentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CasinoColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  l10n.matchScoreLine(item.cardTotal, item.opponentCardTotal),
                  style: const TextStyle(
                    color: CasinoColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                if (whenText.isNotEmpty)
                  Text(
                    whenText,
                    style: const TextStyle(
                      color: CasinoColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${item.pointsEarned} ${l10n.points}',
                style: const TextStyle(
                  color: CasinoColors.goldSoft,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$eloSign${item.eloDelta} ${l10n.elo}',
                style: TextStyle(
                  color:
                      item.eloDelta >= 0
                          ? const Color(0xFF5DCF8A)
                          : const Color(0xFFE07070),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorPane extends StatelessWidget {
  const _ErrorPane({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: CasinoColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: CasinoColors.gold),
              child: Text(l10n.retryConnection),
            ),
          ],
        ),
      ),
    );
  }
}
