import 'dart:convert';

import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/data/profile/profile_api.dart';
import 'package:cardgame/l10n/app_localizations.dart';
import 'package:cardgame/ui/screens/how_to_play_screen.dart';
import 'package:cardgame/ui/screens/tutorial/tutorial_prompt.dart';
import 'package:cardgame/ui/screens/tutorial/tutorial_screen.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  Future<(ProviderContainer, List<Map<String, dynamic>>)> pump(
    WidgetTester tester,
    Widget home, {
    PlayerProfile profile = PlayerProfile.empty,
  }) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final requests = <Map<String, dynamic>>[];
    final container = ProviderContainer(
      overrides: [
        playerProfileRepositoryProvider.overrideWithValue(
          PlayerProfileRepository.memory(profile),
        ),
        profileApiServiceProvider.overrideWithValue(
          ProfileApi(
            baseUrl: 'http://test',
            client: MockClient((request) async {
              requests.add(jsonDecode(request.body) as Map<String, dynamic>);
              return http.Response('{}', 200);
            }),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildCasinoTheme(),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: home,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    return (container, requests);
  }

  // Gold/leather buttons render their label in caps.
  Finder button(String label) => find.text(label.toUpperCase());

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('hub lists every lesson and the quick rules', (tester) async {
    await pump(tester, const HowToPlayScreen());

    expect(button(en.tutStartAll), findsOneWidget);
    expect(find.text(en.tutLessonValuesTitle), findsOneWidget);
    await tester.scrollUntilVisible(find.text(en.tutQuickRules), 200);
    expect(find.text(en.tutLessonTipsTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a lesson is played by tapping the table', (tester) async {
    await pump(tester, const HowToPlayScreen());

    await tester.tap(find.text(en.tutLessonSwapTitle));
    await settle(tester);
    expect(find.byType(TutorialScreen), findsOneWidget);
    expect(find.text(en.tutSwapIntro), findsOneWidget);

    await tester.tap(button(en.next));
    await settle(tester);
    expect(find.text(en.tutDrawPrompt), findsOneWidget);

    // Wrong spot: the coach explains and the step stays.
    await tester.tap(find.byKey(const ValueKey('tut-you-3')));
    await settle(tester);
    expect(find.text(en.tutTapHighlighted), findsOneWidget);
    expect(find.text(en.tutDrawPrompt), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tut-deck')));
    await settle(tester);
    expect(find.text(en.tutSwapPick), findsOneWidget);
    expect(find.byKey(const ValueKey('tut-drawn')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tut-you-1')));
    await settle(tester);
    expect(find.text(en.tutSwapDone), findsOneWidget);

    await tester.tap(button(en.next));
    await settle(tester);
    expect(find.text(en.tutLessonDone), findsOneWidget);

    await tester.tap(button(en.tutNextLesson));
    await settle(tester);
    expect(find.text(en.tutLessonThrowTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('first-run prompt', () {
    const newPlayer = PlayerProfile(
      playerId: 'p1',
      name: 'Ana',
      username: 'ana',
      accessToken: 'token',
    );

    setUp(TutorialPromptGate.resetForTest);

    testWidgets('offered once, and Not now marks it done on the server', (
      tester,
    ) async {
      final (container, requests) = await pump(
        tester,
        const TutorialPromptGate(child: Text('home')),
        profile: newPlayer,
      );
      await settle(tester);
      expect(find.text(en.tutPromptTitle), findsOneWidget);

      await tester.tap(button(en.tutPromptLater));
      await settle(tester);

      expect(find.text(en.tutPromptTitle), findsNothing);
      expect(container.read(playerProfileProvider).value?.tutorialDone, isTrue);
      expect(requests.single['tutorialDone'], isTrue);
      expect(requests.single['playerId'], 'p1');
    });

    testWidgets('Start tutorial opens the first lesson', (tester) async {
      await pump(
        tester,
        const TutorialPromptGate(child: Text('home')),
        profile: newPlayer,
      );
      await settle(tester);

      await tester.tap(button(en.tutStartAll));
      await settle(tester);
      await settle(tester);

      expect(find.byType(TutorialScreen), findsOneWidget);
      expect(find.text(en.tutValuesIntro), findsOneWidget);
    });

    testWidgets('returning players are not asked', (tester) async {
      await pump(
        tester,
        const TutorialPromptGate(child: Text('home')),
        profile: newPlayer.copyWith(tutorialDone: true),
      );
      await settle(tester);
      expect(find.text(en.tutPromptTitle), findsNothing);
    });
  });
}
