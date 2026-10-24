import 'package:flutter/material.dart';

/// Shows [value], counting up from the previous value when it rises (a
/// reward landing) and jumping straight down when it falls (a stake).
class CountingAmount extends StatefulWidget {
  const CountingAmount({
    super.key,
    required this.value,
    required this.builder,
    this.duration = const Duration(milliseconds: 900),
  });

  final int value;
  final Widget Function(BuildContext context, int shown) builder;
  final Duration duration;

  @override
  State<CountingAmount> createState() => _CountingAmountState();
}

class _CountingAmountState extends State<CountingAmount>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late int _from = widget.value;

  int get _shown {
    if (!_controller.isAnimating) return widget.value;
    final t = Curves.easeOutCubic.transform(_controller.value);
    return (_from + (widget.value - _from) * t).round();
  }

  @override
  void didUpdateWidget(CountingAmount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == oldWidget.value) return;
    if (widget.value > oldWidget.value &&
        !MediaQuery.disableAnimationsOf(context)) {
      _from = _shown == widget.value ? oldWidget.value : _shown;
      _controller.forward(from: 0);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => widget.builder(context, _shown),
    );
  }
}
