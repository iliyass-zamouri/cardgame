import 'dart:math' as math;

import 'package:cardgame/data/daily_reward/daily_reward_models.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/flame/suit_shapes.dart';
import 'package:cardgame/ui/screens/daily_reward/reward_art.dart';
import 'package:cardgame/ui/theme/app_icons.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:cardgame/ui/widgets/deck_fan_preview.dart';
import 'package:cardgame/ui/widgets/gold_burst.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// How a day card is drawn.
enum DayCardLook { upcoming, today, next, claimed }

DayCardLook dayCardLook(DailyDayStatus status) => switch (status) {
  DailyDayStatus.claimed => DayCardLook.claimed,
  DailyDayStatus.today => DayCardLook.today,
  DailyDayStatus.next => DayCardLook.next,
  DailyDayStatus.upcoming => DayCardLook.upcoming,
};

/// The suit pip on day [day]'s card.
SuitShape daySuit(int day) =>
    SuitShape.values[(day - 1) % SuitShape.values.length];

/// One day of the week as a playing card. Upcoming days lie face up so the
/// player can see what is coming; today's card glows. A collected day turns
/// face down, showing the player's own card back sealed in gold. The wide
/// day-7 jackpot card gets a "collected" stamp instead of turning over.
class StreakDayCard extends StatelessWidget {
  const StreakDayCard({
    super.key,
    required this.day,
    required this.look,
    required this.deckSkinId,
    required this.ambient,
    this.chests = const {},
    this.faceLook,
    this.flip,
    this.seal,
    this.lift = 0,
    this.wide = false,
  });

  final DailyDay day;
  final DayCardLook look;
  final String deckSkinId;

  /// Loops 0..1 and drives today's glow and shimmer.
  final Animation<double> ambient;
  final Map<String, DailyChest> chests;

  /// How the face is drawn while a just-collected card turns over.
  final DayCardLook? faceLook;

  /// 0 face up to 1 face down. Defaults to face down once collected.
  final double? flip;

  /// The seal stamped on a collected card, 0..1.
  final double? seal;

  /// Raised while today's claim is on its way.
  final double lift;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final collected = look == DayCardLook.claimed;
    final flip = this.flip ?? (collected ? 1.0 : 0.0);
    final seal = this.seal ?? (collected ? 1.0 : 0.0);
    final face = _CardFace(
      day: day,
      look: faceLook ?? look,
      chests: chests,
      ambient: ambient,
      wide: wide,
      stamp: wide ? seal : 0,
    );

    Widget card;
    if (wide) {
      card = face;
    } else {
      final angle = flip.clamp(0.0, 1.0) * math.pi;
      card = Transform(
        alignment: Alignment.center,
        transform:
            Matrix4.identity()
              ..setEntry(3, 2, 0.0014)
              ..rotateY(angle),
        child:
            angle > math.pi / 2
                ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(math.pi),
                  child: _CardBack(
                    day: day.day,
                    deckSkinId: deckSkinId,
                    seal: seal,
                  ),
                )
                : face,
      );
    }
    if (lift > 0) {
      card = Transform.translate(
        offset: Offset(0, -10 * lift),
        child: Transform.scale(scale: 1 + 0.05 * lift, child: card),
      );
    }

    final status = switch (look) {
      DayCardLook.today => l10n.dailyToday,
      DayCardLook.next => l10n.dailyTomorrow,
      DayCardLook.claimed => l10n.dailyCollected,
      DayCardLook.upcoming => null,
    };
    final rewards = day.rewards
        .map(
          (reward) => rewardTitle(
            l10n,
            reward,
            chests: chests,
            languageCode: languageCode,
          ),
        )
        .join(', ');
    return Semantics(
      label: [
        l10n.dailyDay(day.day),
        if (status != null) status,
        rewards,
      ].join(', '),
      child: ExcludeSemantics(child: card),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.day,
    required this.look,
    required this.chests,
    required this.ambient,
    required this.wide,
    required this.stamp,
  });

  final DailyDay day;
  final DayCardLook look;
  final Map<String, DailyChest> chests;
  final Animation<double> ambient;
  final bool wide;

  /// The jackpot card's "collected" stamp, 0..1.
  final double stamp;

  @override
  Widget build(BuildContext context) {
    final today = look == DayCardLook.today;
    final collectedWide = wide && look == DayCardLook.claimed;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final unit = wide ? size.height : size.width;
        final radius = BorderRadius.circular(unit * 0.11);
        final body = DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [CardInk.ivory, CardInk.ivoryShade],
            ),
            border: Border.all(
              color:
                  today || wide
                      ? CasinoColors.gold
                      : CardInk.goldLine.withValues(alpha: 0.7),
              width: today ? 2 : (wide ? 1.6 : 1.1),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x80000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (wide) _JackpotBackdrop(ambient: ambient),
                Container(
                  margin: EdgeInsets.all(unit * 0.04),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(unit * 0.08),
                    border: Border.all(
                      color: CardInk.goldLine.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                if (wide)
                  _JackpotLayout(
                    day: day,
                    look: look,
                    chests: chests,
                    unit: unit,
                  )
                else ...[
                  PositionedDirectional(
                    top: unit * 0.07,
                    start: unit * 0.08,
                    child: _CornerIndex(
                      day: day.day,
                      unit: unit,
                      jackpot: false,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      unit * 0.06,
                      unit * 0.24,
                      unit * 0.06,
                      unit * 0.27,
                    ),
                    child: _Rewards(
                      rewards: day.rewards,
                      chests: chests,
                      wide: false,
                      unit: unit,
                    ),
                  ),
                  PositionedDirectional(
                    bottom: unit * 0.07,
                    start: 0,
                    end: 0,
                    child: Center(
                      child: _Tag(look: look, day: day.day, unit: unit),
                    ),
                  ),
                ],
                if (today) _Shimmer(ambient: ambient),
                if (collectedWide || stamp > 0)
                  _CollectedStamp(
                    progress: collectedWide ? stamp : 0,
                    unit: unit,
                  ),
              ],
            ),
          ),
        );
        final dimmed =
            look == DayCardLook.upcoming
                ? Opacity(opacity: 0.9, child: body)
                : body;
        if (!today) return dimmed;
        // Today's card glows, breathing slowly.
        return AnimatedBuilder(
          animation: ambient,
          child: dimmed,
          builder: (context, child) {
            final breath =
                0.5 + 0.5 * math.sin(ambient.value * 2 * math.pi * 3);
            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: [
                  BoxShadow(
                    color: CasinoColors.gold.withValues(
                      alpha: 0.35 + 0.3 * breath,
                    ),
                    blurRadius: 14 + 8 * breath,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: child,
            );
          },
        );
      },
    );
  }
}

/// The wide jackpot card: rank and tag down the start edge, the rewards in
/// the rest, so a long tag (PREMIO MAYOR) never runs into them.
class _JackpotLayout extends StatelessWidget {
  const _JackpotLayout({
    required this.day,
    required this.look,
    required this.chests,
    required this.unit,
  });

  final DailyDay day;
  final DayCardLook look;
  final Map<String, DailyChest> chests;
  final double unit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        unit * 0.08,
        unit * 0.07,
        unit * 0.1,
        unit * 0.07,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: unit * 1.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Shrinks only on the smallest tables, so the tag still fits.
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.topStart,
                    child: _CornerIndex(
                      day: day.day,
                      unit: unit,
                      jackpot: true,
                    ),
                  ),
                ),
                _Tag(look: look, day: day.day, unit: unit, jackpot: true),
              ],
            ),
          ),
          SizedBox(width: unit * 0.1),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: unit * 0.03),
              child: _Rewards(
                rewards: day.rewards,
                chests: chests,
                wide: true,
                unit: unit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerIndex extends StatelessWidget {
  const _CornerIndex({
    required this.day,
    required this.unit,
    required this.jackpot,
  });

  final int day;
  final double unit;
  final bool jackpot;

  @override
  Widget build(BuildContext context) {
    final suit = daySuit(day);
    final color = suitColor(suit);
    final rankSize = unit * (jackpot ? 0.24 : 0.17);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          day == 1 ? 'A' : '$day',
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            fontFamily: CasinoFonts.display,
            color: color,
            fontSize: rankSize,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        SizedBox(height: unit * 0.015),
        SuitGlyph(suit: suit, size: rankSize * 0.72, color: color),
      ],
    );
  }
}

/// Bottom label: TODAY / TOMORROW pills, or the plain day number.
class _Tag extends StatelessWidget {
  const _Tag({
    required this.look,
    required this.day,
    required this.unit,
    this.jackpot = false,
  });

  final DayCardLook look;
  final int day;
  final double unit;
  final bool jackpot;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final label = switch (look) {
      DayCardLook.today => l10n.dailyToday,
      DayCardLook.next => l10n.dailyTomorrow,
      DayCardLook.claimed => jackpot ? l10n.dailyCollected : l10n.dailyDay(day),
      DayCardLook.upcoming => jackpot ? l10n.dailyJackpot : l10n.dailyDay(day),
    };
    final today = look == DayCardLook.today;
    final next = look == DayCardLook.next;
    final fontSize = (unit * (jackpot ? 0.13 : 0.095)).clamp(8.0, 12.0);
    final text = Text(
      casinoButtonLabel(label, locale),
      maxLines: 1,
      textScaler: TextScaler.noScaling,
      style: TextStyle(
        fontFamily: CasinoFonts.uiFor(locale),
        color: today ? CardInk.black : const Color(0xFF7A5A0E),
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: locale.languageCode == 'ar' ? 0 : 0.8,
        height: 1.1,
      ),
    );
    if (!today && !next && !(jackpot && look == DayCardLook.upcoming)) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: unit * 0.06),
        child: FittedBox(fit: BoxFit.scaleDown, child: text),
      );
    }
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize * 0.8,
        vertical: fontSize * 0.28,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(fontSize),
        gradient:
            today
                ? LinearGradient(
                  colors: [
                    CasinoColors.goldHi,
                    CasinoColors.gold,
                    CasinoColors.goldLo,
                  ],
                )
                : null,
        border: Border.all(
          color: const Color(0xFF7A5A0E).withValues(alpha: today ? 0.6 : 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (jackpot) ...[
            HugeIcon(
              icon: AppIcons.crown,
              size: fontSize * 1.2,
              color: today ? CardInk.black : const Color(0xFF7A5A0E),
            ),
            SizedBox(width: fontSize * 0.35),
          ],
          // Long words (AUJOURD'HUI) shrink rather than lose letters.
          Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: text)),
        ],
      ),
    );
  }
}

/// The card's rewards: one large, or two or three side by side.
class _Rewards extends StatelessWidget {
  const _Rewards({
    required this.rewards,
    required this.chests,
    required this.wide,
    required this.unit,
  });

  final List<RewardItem> rewards;
  final Map<String, DailyChest> chests;
  final bool wide;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final count = math.max(1, rewards.length);
    final art =
        wide
            ? unit * 0.46
            : unit *
                switch (count) {
                  1 => 0.44,
                  2 => 0.33,
                  _ => 0.26,
                };
    final captionSize = (wide ? unit * 0.14 : unit * (count == 1 ? 0.13 : 0.1))
        .clamp(8.5, 15.0);
    final gap = unit * 0.03;
    return LayoutBuilder(
      builder: (context, constraints) {
        // The caption keeps a readable size on tiny cards, so the art gives
        // way instead. The jackpot's caption may wrap when there is room.
        final line = captionSize * 1.05;
        final lines =
            wide && constraints.maxHeight >= art + gap + line * 2 + 1 ? 2 : 1;
        final room = constraints.maxHeight - gap - line * lines - 1;
        final artSize =
            constraints.hasBoundedHeight
                ? math.min(art, math.max(0.0, room))
                : art;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final (i, reward) in rewards.indexed) ...[
              if (i > 0) SizedBox(width: wide ? unit * 0.12 : unit * 0.02),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RewardArt(reward: reward, size: artSize),
                    SizedBox(height: gap),
                    _fit(
                      // On one line the jackpot's names shrink a little
                      // rather than lose their end.
                      wide && lines == 1,
                      Text(
                        rewardCaption(
                          l10n,
                          reward,
                          chests: chests,
                          languageCode: languageCode,
                        ),
                        maxLines: lines,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          fontFamily:
                              reward is CurrencyReward
                                  ? CasinoFonts.display
                                  : CasinoFonts.uiFor(
                                    Localizations.localeOf(context),
                                  ),
                          color: CardInk.black,
                          fontSize: captionSize,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  static Widget _fit(bool fit, Widget child) =>
      fit ? FittedBox(fit: BoxFit.scaleDown, child: child) : child;
}

/// A gold sheen and slowly turning rays behind the jackpot's rewards.
class _JackpotBackdrop extends StatelessWidget {
  const _JackpotBackdrop({required this.ambient});

  final Animation<double> ambient;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(rtl ? -0.35 : 0.35, 0),
              radius: 1.2,
              colors: [
                CasinoColors.goldSoft.withValues(alpha: 0.45),
                Colors.transparent,
              ],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: ambient,
          // A quarter turn per loop: five ray widths, so the loop is seamless.
          builder:
              (context, _) => CustomPaint(
                painter: GoldRaysPainter(
                  t: ambient.value / 4,
                  center: Offset(rtl ? 0.36 : 0.64, 0.5),
                  intensity: 0.9,
                ),
              ),
        ),
      ],
    );
  }
}

/// A light band that sweeps across today's card now and then.
class _Shimmer extends StatelessWidget {
  const _Shimmer({required this.ambient});

  final Animation<double> ambient;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: ambient,
        builder:
            (context, _) =>
                CustomPaint(painter: _ShimmerPainter(ambient.value)),
      ),
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  const _ShimmerPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // One sweep in the first third of every loop.
    final p = (t * 3 % 1) / 0.45;
    if (p >= 1) return;
    final x = -size.width * 0.6 + p * size.width * 2.2;
    final band = Rect.fromLTWH(
      x,
      -size.height * 0.2,
      size.width * 0.45,
      size.height * 1.4,
    );
    canvas.save();
    canvas.translate(band.center.dx, band.center.dy);
    canvas.rotate(0.35);
    canvas.translate(-band.center.dx, -band.center.dy);
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(band),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter oldDelegate) =>
      oldDelegate.t != t;
}

/// Face down: the player's own card back, a day chip and the gold seal.
class _CardBack extends StatelessWidget {
  const _CardBack({
    required this.day,
    required this.deckSkinId,
    required this.seal,
  });

  final int day;
  final String deckSkinId;
  final double seal;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final unit = constraints.maxWidth;
        final radius = BorderRadius.circular(unit * 0.11);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: CasinoColors.gold.withValues(alpha: 0.7),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x80000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DeckBackPreview(skinId: deckSkinId),
                ColoredBox(color: Colors.black.withValues(alpha: 0.22)),
                Center(child: GoldSeal(size: unit * 0.46, progress: seal)),
                PositionedDirectional(
                  top: unit * 0.06,
                  start: unit * 0.06,
                  child: Container(
                    width: unit * 0.2,
                    height: unit * 0.2,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          CasinoColors.goldHi,
                          CasinoColors.gold,
                          CasinoColors.goldLo,
                        ],
                      ),
                      border: Border.all(
                        color: const Color(0xFF7A5A0E),
                        width: 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x99000000),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      '$day',
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        fontFamily: CasinoFonts.display,
                        color: const Color(0xFF3A2A06),
                        fontSize: unit * 0.115,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Gold wax-style seal with a tick, stamped in as [progress] runs 0..1.
class GoldSeal extends StatelessWidget {
  const GoldSeal({super.key, required this.size, this.progress = 1});

  final double size;
  final double progress;

  @override
  Widget build(BuildContext context) {
    if (progress <= 0) return const SizedBox.shrink();
    final t = Curves.easeOutBack.transform(progress.clamp(0.0, 1.0));
    return Opacity(
      opacity: progress.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: 1.8 - 0.8 * t,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment(-0.3, -0.35),
              colors: [Color(0xFFFFF0A8), Color(0xFFF5C542), Color(0xFFB8860B)],
              stops: [0, 0.55, 1],
            ),
            border: Border.all(
              color: const Color(0xFF7A5A0E),
              width: size * 0.04,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x99000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Container(
            margin: EdgeInsets.all(size * 0.12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF7A5A0E).withValues(alpha: 0.6),
                width: size * 0.025,
              ),
            ),
            child: Center(
              child: HugeIcon(
                icon: AppIcons.check,
                size: size * 0.48,
                strokeWidth: 2.8,
                color: const Color(0xFF4A3708),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Diagonal "collected" stamp across the jackpot card.
class _CollectedStamp extends StatelessWidget {
  const _CollectedStamp({required this.progress, required this.unit});

  final double progress;
  final double unit;

  @override
  Widget build(BuildContext context) {
    if (progress <= 0) return const SizedBox.shrink();
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final t = Curves.easeOutBack.transform(progress.clamp(0.0, 1.0));
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.18 * progress),
      child: Center(
        child: Opacity(
          opacity: progress.clamp(0.0, 1.0),
          child: Transform.rotate(
            angle: -0.12,
            child: Transform.scale(
              scale: 1.6 - 0.6 * t,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: unit * 0.18,
                  vertical: unit * 0.05,
                ),
                decoration: BoxDecoration(
                  color: CardInk.ivory.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(unit * 0.08),
                  border: Border.all(
                    color: const Color(0xFFB8860B),
                    width: 2.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GoldSeal(size: unit * 0.26),
                    SizedBox(width: unit * 0.08),
                    Text(
                      casinoButtonLabel(l10n.dailyCollected, locale),
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        fontFamily: CasinoFonts.displayFor(locale),
                        color: const Color(0xFF7A5A0E),
                        fontSize: unit * 0.17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: locale.languageCode == 'ar' ? 0 : 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
