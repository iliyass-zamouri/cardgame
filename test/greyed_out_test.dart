import 'package:cardgame/ui/widgets/greyed_out.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a disabled child ignores taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GreyedOut(
            enabled: false,
            child: GestureDetector(
              key: const Key('target'),
              behavior: HitTestBehavior.opaque,
              onTap: () => taps++,
              child: const SizedBox(width: 120, height: 48),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('target')), warnIfMissed: false);
    expect(taps, 0);
  });

  testWidgets('an enabled child takes taps as before', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GreyedOut(
            enabled: true,
            child: GestureDetector(
              key: const Key('target'),
              behavior: HitTestBehavior.opaque,
              onTap: () => taps++,
              child: const SizedBox(width: 120, height: 48),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('target')));
    expect(taps, 1);
  });
}
