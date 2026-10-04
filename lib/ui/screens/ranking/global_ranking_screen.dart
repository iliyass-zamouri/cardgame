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
import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:cardgame/ui/flame/suit_shapes.dart';

class GlobalRankingScreen extends ConsumerWidget {
  const GlobalRankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 2,
      child: FeltScaffold(
        title: l10n.globalRanking,
        tabs: TabBar(
          tabs: [Tab(text: l10n.leaderboard), Tab(text: l10n.matchHistory)],
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
  static const _approxRow = 72.0;

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap:
              () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder:
                      (_) =>
                          PlayerProfileScreen(targetPlayerId: entry.playerId),
                ),
              ),
          child: Ink(
            decoration: leatherPanelDecoration(radius: 14, highlighted: true),
            child: _RankRow(
              entry: entry,
              highlight: true,
              isSelf: true,
              selfLabel: selfLabel,
            ),
          ),
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
        final showStickyOverlay =
            stickyEntry != null && _sticky != _SelfSticky.none;

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
                        padding: EdgeInsets.fromLTRB(
                          12,
                          6,
                          12,
                          showStickyOverlay && _sticky == _SelfSticky.bottom
                              ? _approxRow + 16
                              : 16,
                        ),
                        itemCount: entries.length,
                        separatorBuilder:
                            (_, index) => SizedBox(
                              height:
                                  entries[index].rank == 3 &&
                                          index + 1 < entries.length
                                      ? 16
                                      : 8,
                            ),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          final isSelf = entry.playerId == myId;
                          if (entry.rank >= 1 && entry.rank <= 3) {
                            return KeyedSubtree(
                              key: isSelf ? _selfKey : null,
                              child: _PodiumCard(
                                entry: entry,
                                isSelf: isSelf,
                                selfLabel: l10n.you,
                                onTap:
                                    () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder:
                                            (_) => PlayerProfileScreen(
                                              targetPlayerId: entry.playerId,
                                            ),
                                      ),
                                    ),
                              ),
                            );
                          }
                          return Material(
                            key: isSelf ? _selfKey : null,
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap:
                                  () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder:
                                          (_) => PlayerProfileScreen(
                                            targetPlayerId: entry.playerId,
                                          ),
                                    ),
                                  ),
                              child: Ink(
                                decoration: leatherPanelDecoration(
                                  radius: 14,
                                  highlighted: isSelf,
                                ),
                                child: _RankRow(
                                  entry: entry,
                                  highlight: isSelf,
                                  isSelf: isSelf,
                                  selfLabel: l10n.you,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (stickyEntry != null && showStickyOverlay)
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
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            itemCount: matches.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
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
  static const avatar = 56.0;
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
      color: CasinoColors.goldSoft,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.8,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(
        _LbCols.hPad + 12,
        10,
        _LbCols.hPad + 12,
        4,
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
    this.onIvory = false,
  });

  final RankingEntry entry;
  final bool highlight;
  final bool isSelf;
  final String selfLabel;

  /// Podium rows sit on ivory cards and use dark card ink.
  final bool onIvory;

  static String? _badgeAsset(int rank) => switch (rank) {
    1 => 'assets/ranking/rank_1.png',
    2 => 'assets/ranking/rank_2.png',
    3 => 'assets/ranking/rank_3.png',
    _ => null,
  };

  static Color _rankColor(int rank) => switch (rank) {
    1 => CasinoColors.gold,
    2 => CasinoColors.silver,
    3 => CasinoColors.checkHi,
    _ => CasinoColors.textMuted,
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
    final badge = _badgeAsset(entry.rank);
    final rankColor = _rankColor(entry.rank);
    final isPodium = badge != null;
    final nameColor =
        onIvory
            ? CardInk.black
            : (highlight ? CasinoColors.gold : CasinoColors.text);
    final winColor =
        onIvory ? const Color(0xFF1E7A45) : const Color(0xFF5DCF8A);
    final lossColor = onIvory ? CardInk.red : const Color(0xFFE07070);
    final drawColor =
        onIvory ? const Color(0xFF6B5A3A) : CasinoColors.textMuted;
    final eloColor = onIvory ? const Color(0xFF8A6512) : CasinoColors.goldSoft;
    final podium = onIvory ? _Podium.of(entry.rank) : null;
    return Container(
      padding: EdgeInsets.fromLTRB(
        _LbCols.hPad,
        isPodium ? 8 : 10,
        _LbCols.hPad,
        isPodium ? 8 : 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _LbCols.rank,
            child:
                podium != null
                    ? _CornerIndex(podium: podium)
                    : Text(
                      '#${entry.rank}',
                      style: TextStyle(
                        fontFamily: CasinoFonts.display,
                        color: rankColor,
                        fontWeight: FontWeight.w800,
                        fontSize: isPodium ? 17 : 14,
                      ),
                    ),
          ),
          SizedBox(
            width: _LbCols.avatar,
            child:
                isPodium
                    ? Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Image.asset(
                          badge,
                          width: 54,
                          height: 54,
                          fit: BoxFit.contain,
                        ),
                        Transform.translate(
                          offset: const Offset(0, 4),
                          child: const PlayerAvatar(
                            avatarId: 'default',
                            size: 34,
                          ),
                        ),
                      ],
                    )
                    : const Center(
                      child: PlayerAvatar(avatarId: 'default', size: 36),
                    ),
          ),
          const SizedBox(width: _LbCols.gap),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: onIvory ? CasinoFonts.display : null,
                color: nameColor,
                fontWeight: onIvory ? FontWeight.w800 : FontWeight.w700,
                fontSize: onIvory ? 16 : null,
              ),
            ),
          ),
          SizedBox(
            width: _LbCols.stat,
            child: Text(
              '${entry.wins}',
              textAlign: TextAlign.center,
              style: _statStyle.copyWith(color: winColor),
            ),
          ),
          SizedBox(
            width: _LbCols.stat,
            child: Text(
              '${entry.losses}',
              textAlign: TextAlign.center,
              style: _statStyle.copyWith(color: lossColor),
            ),
          ),
          SizedBox(
            width: _LbCols.stat,
            child: Text(
              '${entry.draws}',
              textAlign: TextAlign.center,
              style: _statStyle.copyWith(color: drawColor),
            ),
          ),
          SizedBox(
            width: _LbCols.elo,
            child: Text(
              '${entry.elo}',
              textAlign: TextAlign.end,
              style: TextStyle(
                color: eloColor,
                fontWeight: onIvory ? FontWeight.w900 : FontWeight.w700,
                fontSize: 13,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Medal styling for the top three: card rank, suit and rim colour.
class _Podium {
  const _Podium(this.letter, this.suit, this.rim);

  final String letter;
  final SuitShape suit;
  final Color rim;

  static _Podium? of(int rank) => switch (rank) {
    1 => const _Podium('A', SuitShape.spades, Color(0xFFD4A21C)),
    2 => const _Podium('K', SuitShape.hearts, Color(0xFF9EA4AE)),
    3 => const _Podium('Q', SuitShape.diamonds, Color(0xFFB8733A)),
    _ => null,
  };
}

/// A top-three leaderboard row dealt as an ivory playing card.
class _PodiumCard extends StatelessWidget {
  const _PodiumCard({
    required this.entry,
    required this.isSelf,
    required this.selfLabel,
    required this.onTap,
  });

  final RankingEntry entry;
  final bool isSelf;
  final String selfLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final podium = _Podium.of(entry.rank)!;
    return IvoryCard(
      radius: 14,
      padding: EdgeInsets.zero,
      highlighted: isSelf,
      rimColor: podium.rim,
      onTap: onTap,
      child: _RankRow(
        entry: entry,
        highlight: isSelf,
        isSelf: isSelf,
        selfLabel: selfLabel,
        onIvory: true,
      ),
    );
  }
}

/// Card-style corner index (rank letter over suit) for podium rows.
class _CornerIndex extends StatelessWidget {
  const _CornerIndex({required this.podium});

  final _Podium podium;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          podium.letter,
          style: TextStyle(
            fontFamily: CasinoFonts.display,
            color: suitColor(podium.suit),
            fontWeight: FontWeight.w800,
            fontSize: 22,
            height: 1,
          ),
        ),
        const SizedBox(height: 3),
        SuitGlyph(suit: podium.suit, size: 14),
      ],
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
      decoration: leatherPanelDecoration(radius: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 56,
            margin: const EdgeInsetsDirectional.only(end: 12),
            padding: const EdgeInsets.symmetric(vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: resultColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: resultColor.withValues(alpha: 0.6)),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                resultLabel,
                style: TextStyle(
                  color: resultColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
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
            GoldButton(
              label: l10n.retryConnection,
              compact: true,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
