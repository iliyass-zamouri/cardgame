import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:cardgame/domain/models/game_snapshot.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';

/// Re-seeds the countdown only when the server's remaining time differs from
/// ours by more than [toleranceMs], so snapshot jitter doesn't make it twitch.
bool shouldReanchor(
  int localRemainingMs,
  int serverRemainingMs, {
  int toleranceMs = 400,
}) => (localRemainingMs - serverRemainingMs).abs() > toleranceMs;

/// Countdown ring over a seat's avatar: how long the seat has to act. The
/// server owns the clock, so this only animates the time it reports.
class TurnCountdownRing extends StatefulWidget {
  const TurnCountdownRing({super.key, required this.timer, this.accent});

  final TurnTimer timer;
  final Color? accent;

  @override
  State<TurnCountdownRing> createState() => _TurnCountdownRingState();
}

class _TurnCountdownRingState extends State<TurnCountdownRing> {
  static const _urgentMs = 5000;

  /// Ten steps a second. The arc creeps a few pixels a second, so this looks
  /// smooth, and unlike a vsync ticker it lets the app go idle between steps
  /// instead of drawing full frames for the whole turn.
  static const _step = Duration(milliseconds: 100);

  Timer? _ticker;
  int _remainingMs = 0;

  @override
  void initState() {
    super.initState();
    _anchor(widget.timer);
  }

  @override
  void didUpdateWidget(TurnCountdownRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    final timer = widget.timer;
    if (timer.limitMs != oldWidget.timer.limitMs ||
        shouldReanchor(_remainingMs, timer.remainingMs)) {
      _anchor(timer);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _anchor(TurnTimer timer) {
    _ticker?.cancel();
    _ticker = null;
    final anchorMs = timer.remainingMs.clamp(0, timer.limitMs).toInt();
    _remainingMs = anchorMs;
    if (anchorMs <= 0) return;
    _ticker = Timer.periodic(_step, (ticker) {
      // `tick` counts elapsed periods, late callbacks included, so the
      // countdown never drifts behind the clock.
      final remaining = math.max(
        0,
        anchorMs - ticker.tick * _step.inMilliseconds,
      );
      if (remaining <= 0) ticker.cancel();
      if (!mounted) return;
      setState(() => _remainingMs = remaining);
    });
  }

  @override
  Widget build(BuildContext context) {
    final limitMs = widget.timer.limitMs;
    final remainingMs = _remainingMs;
    final color =
        remainingMs <= _urgentMs
            ? CasinoColors.foldHi
            : (widget.accent ?? CasinoColors.gold);
    return RepaintBoundary(
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _TurnArcPainter(
              fraction: remainingMs / limitMs,
              color: color,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: -8,
            child: Center(
              child: _SecondsPill(
                seconds: (remainingMs / 1000).ceil(),
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Track plus the share of the turn still left, drawn over the avatar's edge.
class _TurnArcPainter extends CustomPainter {
  const _TurnArcPainter({required this.fraction, required this.color});

  /// Share of the turn still left, from 0 to 1.
  final double fraction;
  final Color color;

  static const _strokeWidth = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_strokeWidth / 2);
    final track =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _strokeWidth
          ..color = color.withValues(alpha: 0.25);
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);
    if (fraction <= 0) return;
    final progress =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = color;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * fraction, false, progress);
  }

  @override
  bool shouldRepaint(_TurnArcPainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.color != color;
}

class _SecondsPill extends StatelessWidget {
  const _SecondsPill({required this.seconds, required this.color});

  final int seconds;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xE6000000),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        child: Text(
          '$seconds',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
