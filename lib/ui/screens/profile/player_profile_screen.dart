import 'package:cardgame/ui/widgets/country_flag.dart';
import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/app/ranking_providers.dart';
import 'package:cardgame/app/session_auth_status.dart';
import 'package:cardgame/data/decks/deck_catalog.dart';
import 'package:cardgame/data/ranking/ranking_api.dart';
import 'package:cardgame/l10n/app_localizations.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/flame/suit_shapes.dart';
import 'package:cardgame/ui/screens/deck_preview_screen.dart';
import 'package:cardgame/ui/screens/profile/avatar_selection_modal.dart';
import 'package:cardgame/ui/screens/settings_screen.dart';
import 'package:cardgame/ui/theme/casino_chrome.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/widgets/deck_fan_preview.dart';
import 'package:cardgame/ui/widgets/player_avatar.dart';
import 'package:cardgame/ui/widgets/suit_card_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:cardgame/ui/theme/app_icons.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';

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

    return FeltScaffold(
      title: l10n.profile,
      actions: [
        if (isSelf)
          FeltIconButton(
            tooltip: l10n.editProfile,
            icon: AppIcons.edit,
            onTap: () => showEditProfileDialog(context, myProfile),
          ),
      ],
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
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                    deckId: isSelf ? myProfile.deckId : 'default',
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
                final remoteDeckId = entry?.deckId;
                final deckId =
                    (remoteDeckId != null && remoteDeckId.isNotEmpty)
                        ? remoteDeckId
                        : (isSelf ? myProfile.deckId : 'default');
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
                  deckId: deckId,
                  countryCode: entry?.countryCode,
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
            const SizedBox(height: 22),
            FeltSectionHeader(label: l10n.matchHistory, suit: SuitShape.clubs),
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
                  return FeltPanel(
                    padding: const EdgeInsets.all(24),
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
    );
  }

  Widget _buildHeroCard(
    BuildContext context, {
    required String name,
    required String username,
    required String avatarId,
    required String deckId,
    String? countryCode,
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
    final deck = DeckCatalog.getById(deckId);
    final deckName = l10n.deckName(deck);

    final authLabel = switch (authStatus) {
      SessionAuthStatus.guest => l10n.guest,
      SessionAuthStatus.google => l10n.google,
      _ => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IvoryCard(
          suit: SuitShape.clubs,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Row(
            children: [
              PlayerAvatar(
                avatarId: avatarId,
                size: 74,
                borderWidth: 2,
                borderColor: CasinoColors.gold,
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
                            style: TextStyle(
                              fontFamily: CasinoFonts.displayOf(context),
                              color: CardInk.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 19,
                            ),
                          ),
                        ),
                        if (flagEmoji(countryCode).isNotEmpty) ...[
                          const SizedBox(width: 8),
                          CountryFlag(code: countryCode, size: 20),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: '@$username'));
                        CasinoToast.show(context, l10n.copiedToClipboard);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              '@$username',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _deepGold,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const HugeIcon(
                            icon: AppIcons.copy,
                            size: 12,
                            color: _brownInk,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _GoldBadge(
                          label: '${l10n.levelNumber(level)} · $rankTitle',
                        ),
                        if (authLabel != null) _OutlineBadge(label: authLabel),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Pressable(
                onTap:
                    () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder:
                            (context) => DeckPreviewScreen(
                              title: deckName,
                              backSkinId: deck.skinId,
                            ),
                      ),
                    ),
                child: DeckFanPreview(
                  skinId: deck.skinId,
                  cardWidth: 48,
                  spread: 7,
                  heightPadding: 8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                suit: SuitShape.spades,
                value: '$elo',
                label: l10n.elo,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                suit: SuitShape.hearts,
                value: rank != null ? '#$rank' : '—',
                label: l10n.leaderboard,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                suit: SuitShape.diamonds,
                value: '$winRate%',
                label: l10n.winRate,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        IvoryCard(
          suit: SuitShape.spades,
          padding: const EdgeInsets.fromLTRB(26, 16, 26, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${l10n.xp}: $currentLevelXp / $nextLevelXp',
                      style: TextStyle(
                        fontFamily: CasinoFonts.displayOf(context),
                        color: CardInk.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${l10n.totalXp}: $totalPoints',
                    style: const TextStyle(
                      color: _deepGold,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GoldProgressBar(
                value: progress,
                trackColor: _brownInk.withValues(alpha: 0.14),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const HugeIcon(
                    icon: AppIcons.game,
                    size: 15,
                    color: _brownInk,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${l10n.matchesPlayed}: $totalMatches   ·   ${l10n.recordWinsLossesDraws(wins, losses, draws)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _brownInk,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Ink tones for text on the profile's ivory cards.
const _brownInk = Color(0xFF5A4A2A);
const _deepGold = Color(0xFF8A6512);

class _GoldBadge extends StatelessWidget {
  const _GoldBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE08A), CasinoColors.gold],
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: CardInk.black,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _OutlineBadge extends StatelessWidget {
  const _OutlineBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _brownInk.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _brownInk,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// A stat shown as a small ivory playing card with the value in suit ink.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.suit,
    required this.value,
    required this.label,
  });

  final SuitShape suit;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return IvoryCard(
      suit: suit,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: CasinoFonts.display,
                color: suitColor(suit),
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            casinoButtonLabel(label, locale),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF5A4A2A),
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
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

    final (resultLabel, resultInk, suit) =
        isWin
            ? (l10n.matchResultWin, const Color(0xFF1E7A45), SuitShape.spades)
            : isLoss
            ? (l10n.matchResultLoss, CardInk.red, SuitShape.hearts)
            : (l10n.matchResultDraw, const Color(0xFF6B5A3A), SuitShape.clubs);

    final eloSign =
        item.eloDelta >= 0 ? '+${item.eloDelta}' : '${item.eloDelta}';
    final eloColor =
        isWin
            ? CasinoColors.raiseHi
            : (isLoss ? CasinoColors.foldHi : CasinoColors.goldSoft);

    return FeltPanel(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          // Result as a tiny playing card.
          Container(
            width: 46,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [CardInk.ivory, CardInk.ivoryShade],
              ),
              border: Border.all(color: resultInk.withValues(alpha: 0.6)),
            ),
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SuitGlyph(suit: suit, size: 16, color: resultInk),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.quit ? l10n.matchResultQuit : resultLabel,
                    style: TextStyle(
                      color: resultInk,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.vs} ${item.opponentName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CasinoColors.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
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
                '$eloSign ${l10n.elo}',
                style: TextStyle(
                  color: eloColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${item.pointsEarned >= 0 ? '+' : ''}${item.pointsEarned} ${l10n.xp}',
                style: const TextStyle(
                  color: CasinoColors.goldSoft,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
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
      final profile = ref.watch(playerProfileProvider).value;
      return ref
          .watch(rankingApiProvider)
          .fetchMatchHistory(
            playerId: playerId,
            accessToken: profile?.accessToken,
          );
    });
