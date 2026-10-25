import 'dart:convert';

import 'package:cardgame/app/app_review_providers.dart';
import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/data/app_review/app_review_api.dart';
import 'package:cardgame/data/app_review/app_review_models.dart';
import 'package:cardgame/l10n/app_localizations.dart';
import 'package:cardgame/services/analytics_service.dart';
import 'package:cardgame/services/app_review_prefs_repository.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/widgets/app_review_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Records what the dialog asks of the app.
class _FakeSession {
  _FakeSession({this.config = const AppReviewConfig()});

  final AppReviewConfig config;
  final rated = <int>[];
  final feedback = <(int?, List<AppReviewTag>, String?)>[];
  final storeOpens = <bool>[];

  AppReviewSession get session => AppReviewSession(
    config: config,
    rate: (stars) async {
      rated.add(stars);
      final toStore = config.sendsToStore(stars);
      return AppReviewRateResult(
        reviewId: 7,
        sendToStore: toStore,
        askReason: !toStore && config.askReason,
      );
    },
    sendFeedback:
        (id, tags, comment) async => feedback.add((id, tags, comment)),
    openStore: ({bool preferSheet = true}) async => storeOpens.add(preferSheet),
  );
}

class _Analytics extends AnalyticsService {
  final events = <String>[];

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async => events.add(name);
}

class _FakeLauncher extends StoreReviewLauncher {
  final opens = <bool>[];

  @override
  Future<void> openStore({
    required String appStoreId,
    bool preferSheet = true,
  }) async => opens.add(preferSheet);
}

Future<void> _font(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    loader.addFont(rootBundle.load('assets/fonts/$file'));
  }
  await loader.load();
}

Widget _app({
  required Widget home,
  String locale = 'en',
  double textScale = 1,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildCasinoTheme(locale: Locale(locale)),
      locale: Locale(locale),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder:
          (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: true,
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          ),
      home: home,
    ),
  );
}

/// A button that opens the dialog with [fake].
Future<void> _openDialog(
  WidgetTester tester,
  _FakeSession fake, {
  String locale = 'en',
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _app(
      locale: locale,
      textScale: textScale,
      home: Scaffold(
        body: Builder(
          builder:
              (context) => Center(
                child: TextButton(
                  onPressed: () => showAppReviewDialog(context, fake.session),
                  child: const Text('open'),
                ),
              ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Finder _star(int n) => find.byKey(ValueKey('app-review-star-$n'));

void main() {
  setUpAll(() async {
    await _font('DM Sans', ['DMSans-Regular.ttf', 'DMSans-Bold.ttf']);
    await _font('Cinzel', ['Cinzel-Regular.ttf', 'Cinzel-Bold.ttf']);
    await _font('Cairo', ['Cairo-Regular.ttf', 'Cairo-Bold.ttf']);
  });

  testWidgets('a low rating asks why, sends the answer and thanks', (
    tester,
  ) async {
    final fake = _FakeSession();
    await _openDialog(tester, fake);
    expect(find.text('Enjoying ShadowHand?'), findsOneWidget);

    await tester.tap(_star(2));
    await tester.pumpAndSettle();
    expect(fake.rated, [2]);
    expect(find.text('Sorry to hear that'), findsOneWidget);
    expect(fake.storeOpens, isEmpty);

    await tester.tap(find.text('Too many ads'));
    await tester.tap(find.text('Bots'));
    await tester.tap(find.text('Too many ads'));
    await tester.tap(find.text('Bugs or crashes'));
    await tester.enterText(find.byType(TextField), '  Lag on my phone ');
    await tester.tap(find.text('SEND'));
    await tester.pumpAndSettle();

    final (reviewId, tags, comment) = fake.feedback.single;
    expect(reviewId, 7);
    expect(tags, [AppReviewTag.bugs, AppReviewTag.bots]);
    expect(comment, 'Lag on my phone');
    expect(find.text('Thank you!'), findsOneWidget);
    expect(find.textContaining('straight to our team'), findsOneWidget);

    await tester.tap(find.text('DONE'));
    await tester.pumpAndSettle();
    expect(find.byType(AppReviewDialog), findsNothing);
  });

  testWidgets('skipping the reason keeps the rating and still thanks', (
    tester,
  ) async {
    final fake = _FakeSession();
    await _openDialog(tester, fake);
    await tester.tap(_star(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SKIP'));
    await tester.pumpAndSettle();
    expect(fake.rated, [1]);
    expect(fake.feedback, isEmpty);
    expect(find.text('Thank you!'), findsOneWidget);
  });

  testWidgets('a happy rating opens the store review and offers the page', (
    tester,
  ) async {
    final fake = _FakeSession();
    await _openDialog(tester, fake);
    await tester.tap(_star(4));
    await tester.pumpAndSettle();
    expect(fake.rated, [4]);
    expect(fake.storeOpens, [true]);
    expect(find.textContaining('Glad you’re enjoying it'), findsOneWidget);

    await tester.tap(find.text('RATE IN THE STORE'));
    await tester.pumpAndSettle();
    expect(fake.storeOpens, [true, false]);
  });

  testWidgets('the store threshold comes from the config', (tester) async {
    final fake = _FakeSession(config: const AppReviewConfig(storeMinStars: 5));
    await _openDialog(tester, fake);
    await tester.tap(_star(4));
    await tester.pumpAndSettle();
    expect(fake.storeOpens, isEmpty);
    expect(find.text('Sorry to hear that'), findsOneWidget);
  });

  testWidgets('with the reason question off, a low rating just thanks', (
    tester,
  ) async {
    final fake = _FakeSession(config: const AppReviewConfig(askReason: false));
    await _openDialog(tester, fake);
    await tester.tap(_star(3));
    await tester.pumpAndSettle();
    expect(find.text('Thank you!'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('Not now closes without rating', (tester) async {
    final fake = _FakeSession();
    await _openDialog(tester, fake);
    await tester.tap(find.text('NOT NOW'));
    await tester.pumpAndSettle();
    expect(find.byType(AppReviewDialog), findsNothing);
    expect(fake.rated, isEmpty);
  });

  testWidgets('in Arabic the first star sits on the right', (tester) async {
    final fake = _FakeSession();
    await _openDialog(tester, fake, locale: 'ar');
    expect(tester.takeException(), isNull);
    final first = tester.getCenter(_star(1)).dx;
    final last = tester.getCenter(_star(5)).dx;
    expect(first, greaterThan(last));
    await tester.tap(_star(1));
    await tester.pumpAndSettle();
    expect(find.text('نأسف لسماع ذلك'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // The narrowest phone, a common phone and a desktop window, in the
  // longest languages, at normal and large text, through every step.
  for (final size in const [Size(320, 568), Size(390, 844), Size(1280, 800)]) {
    for (final language in ['en', 'fr', 'es', 'ar']) {
      for (final textScale in [1.0, 1.3]) {
        testWidgets(
          'fits ${size.width.toInt()}px, $language, text x$textScale',
          (tester) async {
            final fake = _FakeSession(
              config: const AppReviewConfig(tags: AppReviewTag.values),
            );
            await _openDialog(
              tester,
              fake,
              locale: language,
              size: size,
              textScale: textScale,
            );
            expect(tester.takeException(), isNull, reason: 'stars');
            await tester.tap(_star(2));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: 'feedback');
            final panel = tester.getSize(find.byType(AppReviewDialog));
            expect(panel.width, lessThanOrEqualTo(size.width));
            await tester.enterText(find.byType(TextField), 'x' * 400);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: 'long comment');
          },
        );
      }
    }
  }

  testWidgets('the happy thank-you fits a small phone in Arabic', (
    tester,
  ) async {
    final fake = _FakeSession();
    await _openDialog(
      tester,
      fake,
      locale: 'ar',
      size: const Size(320, 568),
      textScale: 1.3,
    );
    await tester.tap(_star(5));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(fake.storeOpens, [true]);
  });

  group('AppReviewController', () {
    late List<http.Request> requests;
    late Map<String, dynamic> status;
    late _FakeLauncher launcher;
    late _Analytics analytics;

    setUp(() {
      PackageInfo.setMockInitialValues(
        appName: 'ShadowHand',
        packageName: 'com.hailsom.shadowhand',
        version: '1.1.0',
        buildNumber: '13',
        buildSignature: '',
      );
      requests = [];
      status = {
        'show': true,
        'reason': 'eligible',
        'config': {'flow': 'gated', 'storeMinStars': 4, 'hasStore': true},
      };
      launcher = _FakeLauncher();
      analytics = _Analytics();
    });

    AppReviewApi api() => AppReviewApi(
      baseUrl: 'https://cards.test',
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path == '/app-review/status') {
          return http.Response(jsonEncode(status), 200);
        }
        if (request.url.path == '/app-review/rate') {
          return http.Response(
            '{"reviewId":9,"action":"feedback","askReason":true}',
            200,
          );
        }
        return http.Response('{"ok":true}', 200);
      }),
    );

    Future<AppReviewController> pumpController(
      WidgetTester tester, {
      AppReviewPrefsRepository? prefs,
      String? token = 'token-1',
    }) async {
      await tester.pumpWidget(
        _app(
          overrides: [
            appReviewApiProvider.overrideWithValue(api()),
            appReviewPrefsRepositoryProvider.overrideWithValue(
              prefs ?? AppReviewPrefsRepository.memory(),
            ),
            storeReviewLauncherProvider.overrideWithValue(launcher),
            analyticsServiceProvider.overrideWithValue(analytics),
            playerAuthProvider.overrideWithValue((
              playerId: 'p-1',
              accessToken: token,
            )),
          ],
          home: const Scaffold(body: SizedBox.expand()),
        ),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold)),
      );
      return container.read(appReviewControllerProvider);
    }

    BuildContext ctx(WidgetTester tester) =>
        tester.element(find.byType(Scaffold));

    /// Lets the HTTP calls and any dialog settle before reading [result].
    Future<T> settle<T>(WidgetTester tester, Future<T> result) async {
      await tester.pumpAndSettle();
      return result;
    }

    List<String> paths() => [for (final r in requests) r.url.path];

    testWidgets('a win opens the prompt once per session', (tester) async {
      final controller = await pumpController(tester);
      controller.noteWin();
      final shown = controller.maybePromptInLobby(ctx(tester));
      await tester.pumpAndSettle();
      expect(find.byType(AppReviewDialog), findsOneWidget);
      expect(requests.first.url.queryParameters['trigger'], 'win');

      await tester.tap(find.text('NOT NOW'));
      await tester.pumpAndSettle();
      expect(await shown, isTrue);
      expect(paths(), [
        '/app-review/status',
        '/app-review/shown',
        '/app-review/dismiss',
      ]);
      expect(analytics.events, ['app_review_shown', 'app_review_dismissed']);

      // Another win in the same session doesn't even ask the server.
      controller.noteWin();
      expect(
        await settle(tester, controller.maybePromptInLobby(ctx(tester))),
        isFalse,
      );
      expect(paths(), hasLength(3));
    });

    testWidgets('a rating goes to the server, and feedback to the review', (
      tester,
    ) async {
      final controller = await pumpController(tester);
      final shown = controller.maybePrompt(ctx(tester), AppReviewTrigger.daily);
      await tester.pumpAndSettle();
      await tester.tap(_star(2));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Prices and rewards'));
      await tester.tap(find.text('SEND'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();
      expect(await shown, isTrue);
      expect(paths(), [
        '/app-review/status',
        '/app-review/shown',
        '/app-review/rate',
        '/app-review/9/feedback',
      ]);
      expect(jsonDecode(requests[2].body)['stars'], 2);
      expect(jsonDecode(requests[3].body), {
        'tags': ['economy'],
      });
      expect(analytics.events, [
        'app_review_shown',
        'app_review_rated',
        'app_review_feedback',
      ]);
    });

    testWidgets('a held-back prompt shows nothing', (tester) async {
      status['show'] = false;
      final controller = await pumpController(tester);
      expect(
        await settle(
          tester,
          controller.maybePrompt(ctx(tester), AppReviewTrigger.daily),
        ),
        isFalse,
      );
      expect(find.byType(AppReviewDialog), findsNothing);
      expect(paths(), ['/app-review/status']);
    });

    testWidgets('automatic checks are spaced out between app starts', (
      tester,
    ) async {
      final prefs = AppReviewPrefsRepository.memory(
        lastCheckMs: DateTime.now().millisecondsSinceEpoch,
      );
      final controller = await pumpController(tester, prefs: prefs);
      expect(
        await settle(
          tester,
          controller.maybePrompt(ctx(tester), AppReviewTrigger.launch),
        ),
        isFalse,
      );
      expect(requests, isEmpty);
    });

    testWidgets('Settings opens the store page when the prompt is off', (
      tester,
    ) async {
      status['show'] = false;
      final controller = await pumpController(tester);
      await settle(tester, controller.openFromSettings(ctx(tester)));
      expect(requests.single.url.queryParameters['trigger'], 'settings');
      expect(launcher.opens, [false]);
    });

    testWidgets('the native-only flow skips our stars', (tester) async {
      status['config'] = {'flow': 'native_only', 'hasStore': true};
      final controller = await pumpController(tester);
      expect(
        await settle(
          tester,
          controller.maybePrompt(ctx(tester), AppReviewTrigger.win),
        ),
        isTrue,
      );
      expect(find.byType(AppReviewDialog), findsNothing);
      expect(launcher.opens, [true]);
    });

    testWidgets('the rating push marks the push opened', (tester) async {
      final controller = await pumpController(tester);
      final opened = controller.openFromPush(ctx(tester));
      await tester.pumpAndSettle();
      expect(find.byType(AppReviewDialog), findsOneWidget);
      await tester.tap(find.text('NOT NOW'));
      await tester.pumpAndSettle();
      await opened;
      expect(paths(), contains('/app-review/push-opened'));
      expect(
        requests
            .firstWhere((r) => r.url.path == '/app-review/status')
            .url
            .queryParameters['trigger'],
        'push',
      );
    });

    testWidgets('without a session nothing is asked', (tester) async {
      final controller = await pumpController(tester, token: null);
      expect(
        await settle(
          tester,
          controller.maybePrompt(ctx(tester), AppReviewTrigger.win),
        ),
        isFalse,
      );
      expect(requests, isEmpty);
    });
  });
}
