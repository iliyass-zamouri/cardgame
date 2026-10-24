import 'dart:typed_data';

import 'package:cardgame/ui/theme/app_icons.dart';
import 'package:cardgame/ui/theme/game_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _icons = {
  'add': AppIcons.add,
  'remove': AppIcons.remove,
  'arrowBack': AppIcons.arrowBack,
  'arrowForward': AppIcons.arrowForward,
  'chevronRight': AppIcons.chevronRight,
  'close': AppIcons.close,
  'clear': AppIcons.clear,
  'check': AppIcons.check,
  'checkCircle': AppIcons.checkCircle,
  'menu': AppIcons.menu,
  'moreVert': AppIcons.moreVert,
  'settings': AppIcons.settings,
  'notifications': AppIcons.notifications,
  'info': AppIcons.info,
  'search': AppIcons.search,
  'refresh': AppIcons.refresh,
  'replay': AppIcons.replay,
  'restore': AppIcons.restore,
  'edit': AppIcons.edit,
  'copy': AppIcons.copy,
  'send': AppIcons.send,
  'exit': AppIcons.exit,
  'enter': AppIcons.enter,
  'language': AppIcons.language,
  'lock': AppIcons.lock,
  'reveal': AppIcons.reveal,
  'peek': AppIcons.peek,
  'shuffle': AppIcons.shuffle,
  'swap': AppIcons.swap,
  'endGame': AppIcons.endGame,
  'report': AppIcons.report,
  'trash': AppIcons.trash,
  'shield': AppIcons.shield,
  'document': AppIcons.document,
  'rules': AppIcons.rules,
  'people': AppIcons.people,
  'friends': AppIcons.friends,
  'person': AppIcons.person,
  'personAdd': AppIcons.personAdd,
  'personRemove': AppIcons.personRemove,
  'avatars': AppIcons.avatars,
  'chat': AppIcons.chat,
  'mic': AppIcons.mic,
  'micOff': AppIcons.micOff,
  'volume': AppIcons.volume,
  'volumeMute': AppIcons.volumeMute,
  'mail': AppIcons.mail,
  'bolt': AppIcons.bolt,
  'robot': AppIcons.robot,
  'home': AppIcons.home,
  'createRoom': AppIcons.createRoom,
  'decks': AppIcons.decks,
  'hourglass': AppIcons.hourglass,
  'timer': AppIcons.timer,
  'trophy': AppIcons.trophy,
  'medal': AppIcons.medal,
  'crown': AppIcons.crown,
  'diamond': AppIcons.diamond,
  'sparkles': AppIcons.sparkles,
  'gift': AppIcons.gift,
  'fire': AppIcons.fire,
  'freeze': AppIcons.freeze,
  'watchAd': AppIcons.watchAd,
  'playCircle': AppIcons.playCircle,
  'ranking': AppIcons.ranking,
  'shop': AppIcons.shop,
};

const _gold = Color(0xFFF5C542);
const _ink = Color(0xFF17171C);

/// Paints [icon] alone and returns its RGBA pixels, one per logical pixel.
Future<ByteData> _render(WidgetTester tester, Widget icon) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    Center(child: RepaintBoundary(key: key, child: icon)),
  );
  late ByteData pixels;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    pixels = (await image.toByteData())!;
    image.dispose();
  });
  return pixels;
}

/// The red channel at (x, y): enough to tell dark from light here.
int _red(ByteData pixels, int size, int x, int y) =>
    pixels.getUint8((y * size + x) * 4);

void main() {
  testWidgets('every icon paints on light and dark tints', (
    tester,
  ) async {
    const size = 48;
    for (final MapEntry(key: name, value: icon) in _icons.entries) {
      for (final tint in [_gold, _ink]) {
        final pixels = await _render(
          tester,
          GameIcon(icon: icon, size: size.toDouble(), color: tint),
        );
        var covered = 0;
        for (var i = 3; i < pixels.lengthInBytes; i += 4) {
          if (pixels.getUint8(i) > 128) covered++;
        }
        expect(
          covered / (size * size),
          greaterThan(0.08),
          reason: '$name painted almost nothing in $tint',
        );
      }
    }
  });

  testWidgets('ink details flip to ivory on a dark tint', (tester) async {
    const size = 100;
    // The dot of the "i" sits at (50, 29); (25, 50) is solid disc.
    final gold = await _render(
      tester,
      const GameIcon(icon: AppIcons.info, size: 100, color: _gold),
    );
    expect(_red(gold, size, 50, 29), lessThan(80));
    expect(_red(gold, size, 25, 50), greaterThan(200));

    final lacquer = await _render(
      tester,
      const GameIcon(icon: AppIcons.info, size: 100, color: _ink),
    );
    expect(_red(lacquer, size, 50, 29), greaterThan(200));
    expect(_red(lacquer, size, 25, 50), lessThan(80));
  });

  testWidgets('falls back to the ambient icon colour', (tester) async {
    final pixels = await _render(
      tester,
      const IconTheme(
        data: IconThemeData(color: _ink),
        child: GameIcon(icon: AppIcons.info, size: 100),
      ),
    );
    expect(_red(pixels, 100, 50, 29), greaterThan(200));
  });
}
