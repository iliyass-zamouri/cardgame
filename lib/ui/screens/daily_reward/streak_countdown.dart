import 'dart:async';

import 'package:cardgame/app/daily_reward_providers.dart';
import 'package:flutter/widgets.dart';

/// "05:07:09".
String formatCountdown(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(s ~/ 3600)}:${two(s % 3600 ~/ 60)}:${two(s % 60)}';
}

/// Ticks down to the next claim from what the server said, once a second.
/// [onDone] runs once when it reaches zero, so the streak can be refetched.
class StreakCountdown extends StatefulWidget {
  const StreakCountdown({
    super.key,
    required this.view,
    required this.builder,
    this.onDone,
  });

  final DailyRewardView view;
  final Widget Function(BuildContext context, String time) builder;
  final VoidCallback? onDone;

  @override
  State<StreakCountdown> createState() => _StreakCountdownState();
}

class _StreakCountdownState extends State<StreakCountdown> {
  Timer? _timer;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(StreakCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.view, widget.view)) _done = false;
  }

  void _tick() {
    if (!mounted) return;
    final left = widget.view.secondsUntilNextClaim();
    if (left <= 0 && !_done) {
      _done = true;
      widget.onDone?.call();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(
    context,
    formatCountdown(widget.view.secondsUntilNextClaim()),
  );
}
