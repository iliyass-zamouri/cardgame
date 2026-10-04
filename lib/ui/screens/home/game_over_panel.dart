import 'dart:math' as math;

import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/domain/models/game_snapshot.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/flame/suit_shapes.dart';
import 'package:cardgame/ui/theme/app_icons.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:cardgame/ui/widgets/currency_icon.dart';
import 'package:cardgame/ui/widgets/player_avatar.dart';
import 'package:cardgame/ui/widgets/suit_card_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons/hugeicons.dart';

enum _Outcome { win, lose, draw, none }

/// Match recap: scrim, leather panel with a staggered entrance, ivory score
/// cards and an outcome animation (gold rays + confetti on a win, a shaken
/// panel and falling spades on a loss).
class GameOverPanel extends ConsumerWidget {
  const GameOverPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final game = ref.watch(gameSessionProvider.select((state) => state.game));
    if (game == null) return const SizedBox.shrink();
    final notifier = ref.read(gameSessionProvider.notifier);
    final youAvatarId =
        ref.watch(playerProfileProvider).asData?.value.avatarId ?? 'default';
    final yourTotal = game.you.total;
    final opponentTotal = game.opponent?.total;
    // Lowest total wins.
    final youWin = opponentTotal != null && yourTotal < opponentTotal;
    final theyWin = opponentTotal != null && yourTotal > opponentTotal;
    final isDraw = opponentTotal != null && yourTotal == opponentTotal;
    final outcome =
        opponentTotal == null
            ? _Outcome.none
            : youWin
            ? _Outcome.win
            : theyWin
            ? _Outcome.lose
            : _Outcome.draw;
    final headline = switch (outcome) {
      _Outcome.none => l10n.gameOver,
      _Outcome.win => l10n.victory,
      _Outcome.lose => l10n.defeat,
      _Outcome.draw => l10n.draw,
    };

    final youId = game.you.playerId ?? '';
    final youRating = _findRating(game.result?.ratings, youId);
    final youXp =
        youRating?.pointsEarned ??
        _calculateXp(youWin, isDraw, yourTotal, opponentTotal);
    final youEloDelta = youRating?.eloDelta ?? _calculateElo(youWin, isDraw);

    final rematchReady = game.you.rematchReady;
    final opponentRematchReady = game.opponent?.rematchReady ?? false;
    final opponentName = game.opponent?.displayName ?? l10n.opponent;

    return _Recap(
      outcome: outcome,
      headline: headline,
      series: l10n.seriesScore(
        game.you.seriesWins,
        game.opponent?.seriesWins ?? 0,
      ),
      you: _SeatData(
        name: game.you.displayName,
        score: yourTotal,
        avatarId: youAvatarId,
        connected: game.you.connected,
        winner: youWin,
      ),
      opponent: _SeatData(
        name: opponentName,
        score: opponentTotal ?? 0,
        avatarId: 'default',
        connected: game.opponent?.connected ?? false,
        winner: theyWin,
        missing: opponentTotal == null,
      ),
      pot: game.potAmount,
      xp: youXp,
      eloDelta: youEloDelta,
      status:
          rematchReady && !opponentRematchReady
              ? _RematchStatus.waiting
              : !rematchReady && opponentRematchReady
              ? _RematchStatus.asked
              : _RematchStatus.none,
      rematchReady: rematchReady,
      onLeave: notifier.leaveRoom,
      onRematch: notifier.rematch,
    );
  }
}

enum _RematchStatus { none, waiting, asked }

class _SeatData {
  const _SeatData({
    required this.name,
    required this.score,
    required this.avatarId,
    required this.connected,
    required this.winner,
    this.missing = false,
  });

  final String name;
  final int score;
  final String avatarId;
  final bool connected;
  final bool winner;
  final bool missing;
}

class _Recap extends StatefulWidget {
  const _Recap({
    required this.outcome,
    required this.headline,
    required this.series,
    required this.you,
    required this.opponent,
    required this.pot,
    required this.xp,
    required this.eloDelta,
    required this.status,
    required this.rematchReady,
    required this.onLeave,
    required this.onRematch,
  });

  final _Outcome outcome;
  final String headline;
  final String series;
  final _SeatData you;
  final _SeatData opponent;
  final int pot;
  final int xp;
  final int eloDelta;
  final _RematchStatus status;
  final bool rematchReady;
  final VoidCallback onLeave;
  final VoidCallback onRematch;

  @override
  State<_Recap> createState() => _RecapState();
}

class _RecapState extends State<_Recap> with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _ambient;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _enter.dispose();
    _ambient.dispose();
    super.dispose();
  }

  /// Progress of [_enter] remapped to the [begin]..[end] slice.
  Animation<double> _slice(double begin, double end, [Curve? curve]) =>
      CurvedAnimation(
        parent: _enter,
        curve: Interval(begin, end, curve: curve ?? Curves.easeOutCubic),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final outcome = widget.outcome;
    final panelIn = _slice(0, 0.28, Curves.easeOutBack);
    final headIn = _slice(0.18, 0.5, Curves.elasticOut);
    final iconIn = _slice(0.22, 0.6, Curves.bounceOut);
    final cardsIn = _slice(0.32, 0.62);
    final countIn = _slice(0.38, 0.8);
    final chipsIn = _slice(0.66, 0.9);
    final buttonsIn = _slice(0.74, 1);

    final seatYou = _ResultCard(
      data: widget.you,
      count: countIn,
      fade: outcome == _Outcome.win || outcome == _Outcome.draw,
    );
    final seatOpp = _ResultCard(
      data: widget.opponent,
      count: countIn,
      fade: outcome == _Outcome.lose || outcome == _Outcome.draw,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        FadeTransition(
          opacity: _slice(0, 0.2),
          child: ColoredBox(
            color: Colors.black.withValues(alpha: 0.62),
            child:
                outcome == _Outcome.lose
                    ? AnimatedBuilder(
                      animation: _ambient,
                      builder:
                          (_, _) => DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                radius: 1.0,
                                colors: [
                                  Colors.transparent,
                                  CasinoColors.fold.withValues(
                                    alpha:
                                        0.18 +
                                        0.1 *
                                            math.sin(
                                              _ambient.value * 2 * math.pi,
                                            ),
                                  ),
                                ],
                                stops: const [0.55, 1],
                              ),
                            ),
                          ),
                    )
                    : null,
          ),
        ),
        if (outcome == _Outcome.win || outcome == _Outcome.lose)
          IgnorePointer(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _ambient,
                builder:
                    (_, _) => CustomPaint(
                      size: Size.infinite,
                      painter: _ParticlePainter(
                        t: _ambient.value,
                        win: outcome == _Outcome.win,
                      ),
                    ),
              ),
            ),
          ),
        Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_enter, _ambient]),
            builder: (context, child) {
              // Loss: a short damped horizontal shake right after landing.
              final shakeT = ((_enter.value - 0.25) / 0.2).clamp(0.0, 1.0);
              final shake =
                  outcome == _Outcome.lose
                      ? math.sin(shakeT * math.pi * 7) * (1 - shakeT) * 12
                      : 0.0;
              return Transform.translate(
                offset: Offset(shake, 0),
                child: Transform.scale(
                  scale: 0.78 + 0.22 * panelIn.value.clamp(0.0, 1.2),
                  child: Opacity(
                    opacity: panelIn.value.clamp(0.0, 1.0),
                    child: child!,
                  ),
                ),
              );
            },
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Header(
                      outcome: outcome,
                      headline: widget.headline,
                      series: widget.series,
                      headIn: headIn,
                      iconIn: iconIn,
                      ambient: _ambient,
                    ),
                    _PanelShell(
                      outcome: outcome,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: cardsIn,
                            builder:
                                (_, child) => Opacity(
                                  opacity: cardsIn.value.clamp(0.0, 1.0),
                                  child: Transform.translate(
                                    offset: Offset(0, 24 * (1 - cardsIn.value)),
                                    child: child,
                                  ),
                                ),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: seatYou),
                                  _VsDivider(label: l10n.vs),
                                  Expanded(child: seatOpp),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _RewardBlock(
                            outcome: outcome,
                            pot: widget.pot,
                            count: countIn,
                            drawLabel: l10n.draw,
                            prizeLabel: l10n.prize,
                            child: FadeTransition(
                              opacity: chipsIn,
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  _StatChip(
                                    label: '+${widget.xp} ${l10n.xp}',
                                    color: _inkGold,
                                  ),
                                  _StatChip(
                                    label:
                                        '${widget.eloDelta >= 0 ? '+${widget.eloDelta}' : '${widget.eloDelta}'} ${l10n.elo}',
                                    color:
                                        widget.eloDelta >= 0
                                            ? const Color(0xFF1E7A45)
                                            : CardInk.red,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (widget.status == _RematchStatus.waiting) ...[
                            const SizedBox(height: 14),
                            const SuitCardLoader(height: 24),
                            const SizedBox(height: 8),
                            Text(
                              l10n.waitingRematch,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _inkMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ] else if (widget.status == _RematchStatus.asked) ...[
                            const SizedBox(height: 14),
                            Text(
                              l10n.opponentAskingRematch(widget.opponent.name),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _inkGold,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          FadeTransition(
                            opacity: buttonsIn,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Semantics(
                                    button: true,
                                    label: l10n.leave,
                                    child: Pressable(
                                      onTap: widget.onLeave,
                                      child: Container(
                                        height: 48,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          color: CardInk.red.withValues(
                                            alpha: 0.08,
                                          ),
                                          border: Border.all(
                                            color: CardInk.red.withValues(
                                              alpha: 0.7,
                                            ),
                                          ),
                                        ),
                                        child: const Center(
                                          child: HugeIcon(
                                            icon: AppIcons.logout,
                                            size: 20,
                                            color: CardInk.red,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 3,
                                  child: GoldButton(
                                    label:
                                        widget.rematchReady
                                            ? l10n.waitingEllipsis
                                            : l10n.rematch,
                                    leading: const HugeIcon(
                                      icon: AppIcons.replay,
                                      size: 20,
                                      color: CardInk.black,
                                    ),
                                    onPressed:
                                        widget.rematchReady
                                            ? null
                                            : widget.onRematch,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The recap body: one large ivory playing card (corner pips, gold inner
/// frame) like the marketplace cards. The corner suit follows the outcome.
class _PanelShell extends StatelessWidget {
  const _PanelShell({required this.outcome, required this.child});

  final _Outcome outcome;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final suit = switch (outcome) {
      _Outcome.win => SuitShape.spades,
      _Outcome.lose => SuitShape.hearts,
      _Outcome.draw => SuitShape.diamonds,
      _Outcome.none => SuitShape.clubs,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: IvoryCard(
        radius: 22,
        suit: suit,
        highlighted: outcome == _Outcome.win,
        rimColor: outcome == _Outcome.lose ? CardInk.red : null,
        padding: const EdgeInsets.fromLTRB(26, 34, 26, 26),
        child: child,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.outcome,
    required this.headline,
    required this.series,
    required this.headIn,
    required this.iconIn,
    required this.ambient,
  });

  final _Outcome outcome;
  final String headline;
  final String series;
  final Animation<double> headIn;
  final Animation<double> iconIn;
  final Animation<double> ambient;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final win = outcome == _Outcome.win;
    final lose = outcome == _Outcome.lose;
    final color =
        win
            ? CasinoColors.gold
            : lose
            ? CasinoColors.foldHi
            : CasinoColors.silver;
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (win)
            Positioned(
              left: -700,
              right: -700,
              top: -600,
              bottom: -800,
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: ambient,
                  builder:
                      (_, _) =>
                          CustomPaint(painter: _RaysPainter(t: ambient.value)),
                ),
              ),
            ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 92,
                child: AnimatedBuilder(
                  animation: Listenable.merge([iconIn, ambient]),
                  builder: (context, _) {
                    // iconIn drops the symbol in (bounce); the win crown
                    // then bobs, the loss spade stays tilted.
                    final drop = (1 - iconIn.value) * -70;
                    final bob =
                        win ? math.sin(ambient.value * 2 * math.pi * 4) * 2 : 0;
                    return Opacity(
                      opacity: iconIn.value.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, drop + bob),
                        child:
                            win
                                ? SvgPicture.asset(
                                  'assets/crown.svg',
                                  width: 88,
                                  height: 88,
                                  colorFilter: const ColorFilter.mode(
                                    CasinoColors.gold,
                                    BlendMode.srcIn,
                                  ),
                                )
                                : Transform.rotate(
                                  angle: lose ? -0.35 * iconIn.value : 0,
                                  child: SuitGlyph(
                                    suit:
                                        lose
                                            ? SuitShape.spades
                                            : SuitShape.diamonds,
                                    size: 64,
                                    color: color.withValues(alpha: 0.9),
                                  ),
                                ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
              AnimatedBuilder(
                animation: Listenable.merge([headIn, ambient]),
                builder: (context, _) {
                  final pulse =
                      win
                          ? 0.5 +
                              0.5 * math.sin(ambient.value * 2 * math.pi * 2)
                          : 0.0;
                  return Opacity(
                    opacity: headIn.value.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.4 + 0.6 * headIn.value,
                      child: Text(
                        casinoButtonLabel(headline, locale),
                        style: TextStyle(
                          fontFamily: CasinoFonts.displayFor(locale),
                          color: color,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          shadows: [
                            if (win) ...[
                              Shadow(
                                color: CasinoColors.gold.withValues(
                                  alpha: 0.5 + 0.4 * pulse,
                                ),
                                blurRadius: 10 + 14 * pulse,
                              ),
                              Shadow(
                                color: CasinoColors.goldSoft.withValues(
                                  alpha: 0.4 * pulse,
                                ),
                                blurRadius: 24,
                              ),
                            ] else
                              const Shadow(
                                color: Color(0x99000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              FadeTransition(
                opacity: headIn,
                child: Text(
                  series,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: CasinoColors.goldSoft,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const _inkGold = Color(0xFF8A6119);
const _inkMuted = Color(0xFF5A4A2A);

/// One player's column on the card. The winner sits on a gold-tinted panel;
/// the other side is dimmed ([fade]).
class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.data,
    required this.count,
    required this.fade,
  });

  final _SeatData data;
  final Animation<double> count;
  final bool fade;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final winner = data.winner;
    return Opacity(
      opacity: data.missing ? 0.5 : (fade && !winner ? 0.8 : 1),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 12, 6, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: winner ? CasinoColors.gold.withValues(alpha: 0.16) : null,
          border: Border.all(
            color:
                winner
                    ? CasinoColors.gold
                    : CardInk.goldLine.withValues(alpha: 0.35),
            width: winner ? 1.4 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlayerAvatar(
              avatarId: data.avatarId,
              size: 60,
              borderWidth: winner ? 1.5 : 0,
              borderColor: CasinoColors.gold,
              showGlow: winner,
              glowColor: CasinoColors.gold.withValues(alpha: 0.35),
              statusDotColor:
                  data.connected ? const Color(0xFF1E7A45) : CardInk.red,
            ),
            const SizedBox(height: 8),
            Text(
              data.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: CasinoFonts.display,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedBuilder(
              animation: count,
              builder: (context, _) {
                final shown = (data.score * count.value).round();
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        data.missing ? '—' : '$shown',
                        style: TextStyle(
                          fontFamily: CasinoFonts.display,
                          color: winner ? _inkGold : CardInk.black,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      if (!data.missing) ...[
                        const SizedBox(width: 3),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            l10n.points,
                            style: const TextStyle(
                              color: _inkMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Vertical gold rule with a small "VS" medallion, like a card's centre line.
class _VsDivider extends StatelessWidget {
  const _VsDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(vertical: 6),
            color: CardInk.goldLine.withValues(alpha: 0.6),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            color: CardInk.ivory,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: CasinoFonts.display,
                color: _inkGold,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Prize amount (counting up) over the XP / Elo chips, in one inset block.
class _RewardBlock extends StatelessWidget {
  const _RewardBlock({
    required this.outcome,
    required this.pot,
    required this.count,
    required this.drawLabel,
    required this.prizeLabel,
    required this.child,
  });

  final _Outcome outcome;
  final int pot;
  final Animation<double> count;
  final String drawLabel;
  final String prizeLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final color = switch (outcome) {
      _Outcome.win => _inkGold,
      _Outcome.lose => CardInk.red,
      _ => _inkMuted,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: CardInk.ivoryShade.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CardInk.goldLine.withValues(alpha: 0.7)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pot > 0) ...[
            Text(
              prizeLabel.toUpperCase(),
              style: const TextStyle(
                fontFamily: CasinoFonts.display,
                color: _inkMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedBuilder(
              animation: count,
              builder: (context, _) {
                final shown = (pot * count.value).round();
                final done = count.value >= 1;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      done && outcome == _Outcome.draw
                          ? '$shown ($drawLabel)'
                          : '$shown',
                      style: TextStyle(
                        fontFamily: CasinoFonts.display,
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 34,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const CashIcon(size: 30),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Slowly turning gold rays that fade out radially, so the burst has no
/// visible edge.
class _RaysPainter extends CustomPainter {
  const _RaysPainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.43);
    final radius = size.width * 0.5;
    const rays = 20;
    final paint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              CasinoColors.gold.withValues(alpha: 0.28),
              CasinoColors.gold.withValues(alpha: 0.07),
              CasinoColors.gold.withValues(alpha: 0),
            ],
            stops: const [0, 0.45, 1],
          ).createShader(Rect.fromCircle(center: c, radius: radius));
    final base = t * 2 * math.pi;
    for (var i = 0; i < rays; i++) {
      final a0 = base + i * 2 * math.pi / rays;
      final a1 = a0 + math.pi / rays * 0.8;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy)
          ..lineTo(c.dx + math.cos(a0) * radius, c.dy + math.sin(a0) * radius)
          ..lineTo(c.dx + math.cos(a1) * radius, c.dy + math.sin(a1) * radius)
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RaysPainter old) => old.t != t;
}

class _Particle {
  const _Particle(
    this.x,
    this.y0,
    this.speed,
    this.sway,
    this.phase,
    this.spin,
    this.size,
    this.shape,
    this.color,
  );

  final double x;
  final double y0;
  final int speed;
  final int sway;
  final double phase;
  final int spin;
  final double size;
  final int shape;
  final Color color;
}

/// Full-screen falling confetti (gold suits and ribbons) for a win, or slow
/// dim spades for a loss. Every motion is an integer number of cycles per
/// [t] loop so the animation wraps seamlessly.
class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.t, required this.win});

  final double t;
  final bool win;

  static final List<_Particle> _winParts = _make(win: true);
  static final List<_Particle> _loseParts = _make(win: false);

  static List<_Particle> _make({required bool win}) {
    final rnd = math.Random(win ? 11 : 5);
    const winColors = [
      CasinoColors.gold,
      CasinoColors.goldSoft,
      Colors.white,
      Color(0xFFE53935),
      Color(0xFF26A69A),
    ];
    final count = win ? 44 : 14;
    return List.generate(count, (i) {
      return _Particle(
        rnd.nextDouble(),
        rnd.nextDouble(),
        win ? 2 + rnd.nextInt(3) : 1,
        1 + rnd.nextInt(3),
        rnd.nextDouble(),
        1 + rnd.nextInt(4),
        win ? 7 + rnd.nextDouble() * 8 : 14 + rnd.nextDouble() * 12,
        win ? rnd.nextInt(5) : 0,
        win
            ? winColors[rnd.nextInt(winColors.length)]
            : const Color(0xFF7A1A1A).withValues(alpha: 0.5),
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final parts = win ? _winParts : _loseParts;
    for (final p in parts) {
      final fy = (p.y0 + t * p.speed) % 1.0;
      final dx = math.sin(2 * math.pi * (t * p.sway + p.phase)) * 14;
      final pos = Offset(p.x * size.width + dx, fy * (size.height + 60) - 30);
      final angle = 2 * math.pi * (t * p.spin + p.phase);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(angle);
      final paint = Paint()..color = p.color;
      if (p.shape >= 4) {
        // Ribbon.
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size * 0.5,
            height: p.size * 1.6,
          ),
          paint,
        );
      } else {
        final suit = win ? SuitShape.values[p.shape % 4] : SuitShape.spades;
        canvas.scale(p.size);
        canvas.drawPath(suitPath(suit), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) =>
      old.t != t || old.win != win;
}

int _calculateXp(bool isWin, bool isDraw, int score, int? oppScore) {
  if (isDraw) return 8;
  if (!isWin) return 2;
  final diff = oppScore != null ? (oppScore - score).clamp(0, 100) : 0;
  final bonus = (diff * 1.5).round().clamp(0, 15);
  return 20 + bonus;
}

int _calculateElo(bool isWin, bool isDraw) {
  if (isDraw) return 0;
  return isWin ? 16 : -16;
}

PlayerResultRating? _findRating(List<PlayerResultRating>? ratings, String id) {
  if (ratings == null || id.isEmpty) return null;
  for (final r in ratings) {
    if (r.playerId == id) return r;
  }
  return null;
}
