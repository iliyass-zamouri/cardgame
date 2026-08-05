import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/ui/screens/home/game_starter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_game_socket.dart';

void main() {
  testWidgets('shows start screen', (WidgetTester tester) async {
    final socket = FakeGameSocket();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameSocketFactoryProvider.overrideWithValue(() => socket),
        ],
        child: const MaterialApp(home: StartGameWidget()),
      ),
    );
    await tester.pump();

    expect(find.text('Card Game'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
    expect(find.text('Create room'), findsOneWidget);
  });
}
