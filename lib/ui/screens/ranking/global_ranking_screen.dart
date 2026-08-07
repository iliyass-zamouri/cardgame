import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/app/ranking_providers.dart';
import 'package:cardgame/data/ranking/ranking_api.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
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

class _LeaderboardTab extends ConsumerWidget {
  const _LeaderboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        return Column(
          children: [
            if (myRank != null)
              Material(
                color: CasinoColors.surface,
                child: _RankRow(
                  entry: myRank,
                  highlight: true,
                  isSelf: true,
                  selfLabel: l10n.you,
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                color: CasinoColors.gold,
                onRefresh: () async {
                  ref.invalidate(leaderboardProvider);
                  ref.invalidate(myRankProvider);
                  await ref.read(leaderboardProvider.future);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: entries.length,
                  separatorBuilder:
                      (_, _) =>
                          const Divider(height: 1, color: Color(0x22FFFFFF)),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _RankRow(
                      entry: entry,
                      highlight: entry.playerId == myId,
                      isSelf: entry.playerId == myId,
                      selfLabel: l10n.you,
                    );
                  },
                ),
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = isSelf ? selfLabel : entry.displayName;
    return Container(
      color: highlight ? CasinoColors.gold.withValues(alpha: 0.08) : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child:
                entry.rank == 1
                    ? SvgPicture.asset(
                      'assets/crown.svg',
                      width: 22,
                      height: 22,
                    )
                    : Text(
                      '#${entry.rank}',
                      style: TextStyle(
                        color:
                            highlight
                                ? CasinoColors.gold
                                : CasinoColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: CasinoColors.surface,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: CasinoColors.gold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: highlight ? CasinoColors.gold : CasinoColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  l10n.recordWinsLossesDraws(
                    entry.wins,
                    entry.losses,
                    entry.draws,
                  ),
                  style: const TextStyle(
                    color: CasinoColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${l10n.elo} ${entry.elo}',
                style: const TextStyle(
                  color: CasinoColors.goldSoft,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${l10n.points} ${entry.totalPoints}',
                style: const TextStyle(
                  color: CasinoColors.textMuted,
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
