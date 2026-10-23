import 'dart:async';

import 'package:cardgame/app/table_chat_controller.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/screens/home/table_social/table_social_catalog.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps a seat pill and shows that player's latest chat as a speech bubble
/// (text / phrase) or a floating emoji burst over their avatar.
class SeatChatOverlay extends ConsumerStatefulWidget {
  const SeatChatOverlay({
    super.key,
    required this.mine,
    required this.bubbleBelow,
    required this.child,
  });

  /// Seat of the local player (true) or the opponent (false).
  final bool mine;

  /// Bubble hangs under the pill (opponent, top of table) or above it.
  final bool bubbleBelow;
  final Widget child;

  @override
  ConsumerState<SeatChatOverlay> createState() => _SeatChatOverlayState();
}

class _SeatChatOverlayState extends ConsumerState<SeatChatOverlay> {
  static const _bubbleDuration = Duration(milliseconds: 3500);

  TableChatMessage? _bubble;
  TableChatMessage? _emoji;
  Timer? _bubbleTimer;

  @override
  void dispose() {
    _bubbleTimer?.cancel();
    super.dispose();
  }

  void _show(TableChatMessage message) {
    if (message.kind == TableChatKind.emoji) {
      setState(() => _emoji = message);
      return;
    }
    _bubbleTimer?.cancel();
    setState(() => _bubble = message);
    _bubbleTimer = Timer(_bubbleDuration, () {
      if (mounted) setState(() => _bubble = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      tableChatProvider.select(
        (s) => s.messages.isEmpty ? null : s.messages.last,
      ),
      (previous, next) {
        if (next == null || next.id == previous?.id) return;
        if (next.mine == widget.mine) _show(next);
      },
    );
    final l10n = context.l10n;
    final bubble = _bubble;
    final emoji = _emoji;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (bubble != null)
          Positioned(
            left: widget.mine ? 0 : null,
            right: widget.mine ? null : 0,
            top: widget.bubbleBelow ? 50 : null,
            bottom: widget.bubbleBelow ? null : 50,
            child: _SpeechBubble(
              key: ValueKey(bubble.id),
              text:
                  bubble.kind == TableChatKind.phrase
                      ? tablePhraseLabel(l10n, bubble.value)
                      : bubble.value,
              tailOnTop: widget.bubbleBelow,
              tailAtStart: widget.mine,
            ),
          ),
        if (emoji != null)
          Positioned(
            left: -14,
            top: -58,
            child: EmojiReactionBurst(
              key: ValueKey(emoji.id),
              emoji: tableEmojis[emoji.value] ?? '',
              onDone: () {
                if (mounted && _emoji?.id == emoji.id) {
                  setState(() => _emoji = null);
                }
              },
            ),
          ),
      ],
    );
  }
}

class _SpeechBubble extends StatefulWidget {
  const _SpeechBubble({
    super.key,
    required this.text,
    required this.tailOnTop,
    required this.tailAtStart,
  });

  final String text;
  final bool tailOnTop;
  final bool tailAtStart;

  @override
  State<_SpeechBubble> createState() => _SpeechBubbleState();
}

class _SpeechBubbleState extends State<_SpeechBubble>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tail = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: CustomPaint(
        size: const Size(12, 7),
        painter: _TailPainter(pointsUp: widget.tailOnTop),
      ),
    );
    final body = Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _bubbleColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        widget.text,
        style: const TextStyle(
          color: Color(0xFF2B1A12),
          fontSize: 13,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
    );
    return ScaleTransition(
      scale: CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
      alignment: Alignment(
        widget.tailAtStart ? -1 : 1,
        widget.tailOnTop ? -1 : 1,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            widget.tailAtStart
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
        children: widget.tailOnTop ? [tail, body] : [body, tail],
      ),
    );
  }
}

const _bubbleColor = Color(0xFFFFF4D6);

class _TailPainter extends CustomPainter {
  const _TailPainter({required this.pointsUp});

  final bool pointsUp;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (pointsUp) {
      path
        ..moveTo(0, size.height)
        ..lineTo(size.width / 2, 0)
        ..lineTo(size.width, size.height);
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0);
    }
    canvas.drawPath(path..close(), Paint()..color = _bubbleColor);
  }

  @override
  bool shouldRepaint(_TailPainter oldDelegate) =>
      oldDelegate.pointsUp != pointsUp;
}

/// Big emoji that pops in, floats up and fades out.
class EmojiReactionBurst extends StatefulWidget {
  const EmojiReactionBurst({
    super.key,
    required this.emoji,
    required this.onDone,
  });

  final String emoji;
  final VoidCallback onDone;

  @override
  State<EmojiReactionBurst> createState() => _EmojiReactionBurstState();
}

class _EmojiReactionBurstState extends State<EmojiReactionBurst>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  late final _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.2,
        end: 1.25,
      ).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 40,
    ),
    TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 15),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 45),
  ]).animate(_controller);
  late final _rise = Tween<double>(begin: 0, end: -36).animate(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 1, curve: Curves.easeIn),
    ),
  );
  late final _opacity = Tween<double>(begin: 1, end: 0).animate(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1, curve: Curves.easeIn),
    ),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder:
            (context, child) => Transform.translate(
              offset: Offset(0, _rise.value),
              child: Opacity(
                opacity: _opacity.value,
                child: Transform.scale(scale: _scale.value, child: child),
              ),
            ),
        child: Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                CasinoColors.gold.withValues(alpha: 0.45),
                CasinoColors.gold.withValues(alpha: 0),
              ],
            ),
          ),
          child: Text(widget.emoji, style: const TextStyle(fontSize: 44)),
        ),
      ),
    );
  }
}
