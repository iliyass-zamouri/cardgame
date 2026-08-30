import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/app/ranking_providers.dart';
import 'package:cardgame/app/session_auth_status.dart';
import 'package:cardgame/data/ranking/ranking_api.dart';
import 'package:cardgame/l10n/app_localizations.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/screens/profile/avatar_selection_modal.dart';
import 'package:cardgame/ui/screens/settings_screen.dart';
import 'package:cardgame/ui/theme/casino_chrome.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/widgets/player_avatar.dart';
import 'package:cardgame/ui/widgets/suit_card_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlayerProfileScreen extends ConsumerWidget {
  const PlayerProfileScreen({super.key, this.targetPlayerId});

  final String? targetPlayerId;

  static String getRankTitle(int level, AppLocalizations l10n) {
    if (level <= 2) return l10n.rankTitleNovice;
    if (level <= 5) return l10n.rankTitleCardShark;
    if (level <= 9) return l10n.rankTitleHighRoller;
    if (level <= 14) return l10n.rankTitleTableMaster;
    if (level <= 19) return l10n.rankTitleGrandAce;
    return l10n.rankTitleShadowLegend;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final myProfile =
        ref.watch(playerProfileProvider).value ?? PlayerProfile.empty;
    final effectivePlayerId = targetPlayerId ?? myProfile.playerId;
    final isSelf = effectivePlayerId == myProfile.playerId;
    final authStatus = ref.watch(sessionAuthProvider).value;

    final rankAsync = ref.watch(playerRankByIdProvider(effectivePlayerId));
    final matchesAsync =
        isSelf
            ? ref.watch(matchHistoryProvider)
            : ref.watch(_targetMatchesProvider(effectivePlayerId));

    return Scaffold(
      backgroundColor: CasinoColors.bg,
      appBar: AppBar(
        backgroundColor: CasinoColors.surface,
        foregroundColor: CasinoColors.text,
        elevation: 0,
        title: Text(
          l10n.profile,
          style: const TextStyle(
            color: CasinoColors.gold,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (isSelf)
            IconButton(
              tooltip: l10n.editProfile,
              icon: const Icon(Icons.edit_rounded, color: CasinoColors.gold),
              onPressed: () => showEditProfileDialog(context, myProfile),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: CasinoColors.gold,
        backgroundColor: CasinoColors.surface,
        onRefresh: () async {
          ref.invalidate(playerRankByIdProvider(effectivePlayerId));
          if (isSelf) {
            ref.invalidate(matchHistoryProvider);
            ref.invalidate(myRankProvider);
          } else {
            ref.invalidate(_targetMatchesProvider(effectivePlayerId));
          }
        },
        child: Column(
          children: [
            rankAsync.when(
              loading:
                  () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: SuitCardLoader(height: 28),
                    ),
                  ),
              error:
                  (_, __) => _buildHeroCard(
                    context,
                    name:
                        isSelf
                            ? (myProfile.name.isEmpty
                                ? l10n.player
                                : myProfile.name)
                            : l10n.player,
                    username: isSelf ? myProfile.username : 'player',
                    avatarId: isSelf ? myProfile.avatarId : 'default',
                    elo: 1000,
                    totalPoints: 0,
                    rank: null,
                    wins: 0,
                    losses: 0,
                    draws: 0,
                    authStatus: isSelf ? authStatus : null,
                    isSelf: isSelf,
                    onEdit: () => showEditProfileDialog(context, myProfile),
                  ),
              data: (entry) {
                final name =
                    entry?.name?.isNotEmpty == true
                        ? entry!.name!
                        : (isSelf
                            ? (myProfile.name.isEmpty
                                ? l10n.player
                                : myProfile.name)
                            : l10n.player);
                final username =
                    entry?.username?.isNotEmpty == true
                        ? entry!.username!
                        : (isSelf ? myProfile.username : 'player');
                final avatarId = isSelf ? myProfile.avatarId : 'default';
                final elo = entry?.elo ?? 1000;
                final totalPoints = entry?.totalPoints ?? 0;
                final rank = entry?.rank;
                final wins = entry?.wins ?? 0;
                final losses = entry?.losses ?? 0;
                final draws = entry?.draws ?? 0;

                return _buildHeroCard(
                  context,
                  name: name,
                  username: username,
                  avatarId: avatarId,
                  elo: elo,
                  totalPoints: totalPoints,
                  rank: rank,
                  wins: wins,
                  losses: losses,
                  draws: draws,
                  authStatus: isSelf ? authStatus : null,
                  isSelf: isSelf,
                  onEdit: () => showEditProfileDialog(context, myProfile),
                );
              },
            ),
            Expanded(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    l10n.matchHistory.toUpperCase(),
                    style: const TextStyle(
                      color: CasinoColors.goldSoft,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  matchesAsync.when(
                    loading:
                        () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: SuitCardLoader(height: 24),
                          ),
                        ),
                    error:
                        (err, _) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              err.toString(),
                              style: const TextStyle(
                                color: CasinoColors.foldHi,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                    data: (matches) {
                      if (matches.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: CasinoColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: CasinoColors.surfaceHi),
                          ),
                          child: Center(
                            child: Text(
                              l10n.matchHistoryEmpty,
                              style: const TextStyle(
                                color: CasinoColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: matches.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = matches[index];
                          return _MatchCard(item: item);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(
    BuildContext context, {
    required String name,
    required String username,
    required String avatarId,
    required int elo,
    required int totalPoints,
    required int? rank,
    required int wins,
    required int losses,
    required int draws,
    required SessionAuthStatus? authStatus,
    required bool isSelf,
    required VoidCallback onEdit,
  }) {
    final l10n = context.l10n;
    final totalMatches = wins + losses + draws;
    final winRate =
        totalMatches > 0 ? ((wins / totalMatches) * 100).round() : 0;

    // Progression system: 100 XP per level
    final level = (totalPoints / 100).floor() + 1;
    final currentLevelXp = totalPoints % 100;
    const nextLevelXp = 100;
    final progress = (currentLevelXp / nextLevelXp).clamp(0.0, 1.0);
    final rankTitle = getRankTitle(level, l10n);

    final authLabel = switch (authStatus) {
      SessionAuthStatus.guest => l10n.guest,
      SessionAuthStatus.google => l10n.google,
      _ => null,
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: CasinoColors.surface),
      child: Column(
        children: [
          Row(
            children: [
              PlayerAvatar(
                avatarId: avatarId,
                size: 64,
                showGlow: true,
                showEditBadge: isSelf,
                onTap:
                    isSelf
                        ? () => showAvatarSelectionModal(
                          context,
                          currentAvatarId: avatarId,
                          playerLevel: level,
                        )
                        : null,
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
                            style: const TextStyle(
                              color: CasinoColors.text,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        if (authLabel != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: CasinoColors.bgElevated,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              authLabel,
                              style: const TextStyle(
                                color: CasinoColors.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: '@$username'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            content: CasinoToast(
                              message: l10n.copiedToClipboard,
                            ),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '@$username',
                            style: const TextStyle(
                              color: CasinoColors.goldSoft,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.copy_rounded,
                            size: 12,
                            color: CasinoColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: CasinoColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: CasinoColors.gold.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        '${l10n.levelNumber(level)} · $rankTitle',
                        style: const TextStyle(
                          color: CasinoColors.gold,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // XP Progress Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: CasinoColors.bgElevated,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${l10n.xp}: $currentLevelXp / $nextLevelXp',
                      style: const TextStyle(
                        color: CasinoColors.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${l10n.totalXp}: $totalPoints',
                      style: const TextStyle(
                        color: CasinoColors.goldSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      CasinoColors.gold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Stats Row
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  icon: Icons.trending_up_rounded,
                  iconColor: CasinoColors.gold,
                  value: '$elo',
                  label: l10n.elo,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatBox(
                  icon: Icons.emoji_events_rounded,
                  iconColor: CasinoColors.goldSoft,
                  value: rank != null ? '#$rank' : '—',
                  label: l10n.leaderboard,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatBox(
                  icon: Icons.pie_chart_rounded,
                  iconColor: CasinoColors.raiseHi,
                  value: '$winRate%',
                  label: l10n.winRate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Records Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: CasinoColors.bgElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.sports_esports_rounded,
                  size: 16,
                  color: CasinoColors.goldSoft,
                ),
                const SizedBox(width: 8),
                Text(
                  '${l10n.matchesPlayed}: $totalMatches   ·   ${l10n.recordWinsLossesDraws(wins, losses, draws)}',
                  style: const TextStyle(
                    color: CasinoColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: CasinoColors.bgElevated,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: CasinoColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: CasinoColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.item});

  final MatchHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isWin = item.result.toLowerCase() == 'win';
    final isLoss = item.result.toLowerCase() == 'loss';

    final resultColor =
        isWin
            ? CasinoColors.raiseHi
            : isLoss
            ? CasinoColors.foldHi
            : CasinoColors.textMuted;

    final resultLabel =
        isWin
            ? l10n.matchResultWin
            : isLoss
            ? l10n.matchResultLoss
            : l10n.matchResultDraw;

    final eloSign =
        item.eloDelta >= 0 ? '+${item.eloDelta}' : '${item.eloDelta}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CasinoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CasinoColors.surfaceHi),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: resultColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: resultColor.withValues(alpha: 0.5)),
            ),
            child: Text(
              resultLabel,
              style: TextStyle(
                color: resultColor,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'vs ${item.opponentName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CasinoColors.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.matchScoreLine(item.cardTotal, item.opponentCardTotal),
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
                eloSign,
                style: TextStyle(
                  color:
                      isWin
                          ? CasinoColors.raiseHi
                          : (isLoss
                              ? CasinoColors.foldHi
                              : CasinoColors.goldSoft),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              Text(
                '+${item.pointsEarned} ${l10n.xp}',
                style: const TextStyle(
                  color: CasinoColors.goldSoft,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final _targetMatchesProvider = FutureProvider.autoDispose
    .family<List<MatchHistoryItem>, String>((ref, playerId) async {
      if (playerId.isEmpty) return const [];
      return ref
          .watch(rankingApiProvider)
          .fetchMatchHistory(playerId: playerId);
    });
