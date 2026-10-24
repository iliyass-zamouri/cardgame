import 'package:cardgame/ui/flame/board_layout.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:cardgame/ui/theme/wide_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The board a [window] leaves between the HUD bands.
Size _board(Size window) => Size(
  window.width,
  window.height - BoardLayout.hudTop - BoardLayout.hudBottom,
);

void main() {
  group('BoardLayout', () {
    test('phones and portrait tablets keep a full-width table', () {
      for (final window in const [
        Size(360, 640),
        Size(390, 844),
        Size(430, 932),
        Size(820, 1180),
      ]) {
        expect(BoardLayout.sideInset(_board(window)), 0, reason: '$window');
      }
    });

    test('a wide window centres a table no wider than it is tall', () {
      final board = _board(const Size(1280, 800));
      final side = BoardLayout.sideInset(board);
      final table = board.width - side * 2;

      expect(side, greaterThan(0));
      expect(table, lessThan(board.height));
      expect(table, greaterThan(board.height * 0.8));
    });

    test('a short wide board still leaves room for a hand and its seat', () {
      final board = _board(const Size(932, 430));

      expect(board.width - BoardLayout.sideInset(board) * 2, 420);
    });

    test('cards scale with the board, up to 1.2x', () {
      expect(BoardLayout(_board(const Size(390, 844))).zoom, lessThan(1));
      expect(BoardLayout(_board(const Size(1920, 1080))).zoom, 1.2);
    });
  });

  group('FeltScaffold', () {
    Future<Size> bodySize(WidgetTester tester, Size window) async {
      tester.view.physicalSize = window;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const body = Key('body');
      await tester.pumpWidget(
        const MaterialApp(
          home: FeltScaffold(title: 'Shop', body: SizedBox.expand(key: body)),
        ),
      );
      return tester.getSize(find.byKey(body));
    }

    testWidgets('a phone body fills the width', (tester) async {
      final size = await bodySize(tester, const Size(390, 844));

      expect(size.width, 390);
    });

    testWidgets('a wide window keeps the body readable and centred', (
      tester,
    ) async {
      final size = await bodySize(tester, const Size(1280, 800));

      expect(size.width, WideLayout.readableMaxWidth);
      expect(
        tester.getCenter(find.byKey(const Key('body'))).dx,
        moreOrLessEquals(640),
      );
    });
  });
}
