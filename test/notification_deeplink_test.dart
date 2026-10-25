import 'package:cardgame/services/notification_deeplink.dart';
import 'package:cardgame/ui/screens/collection_screen.dart';
import 'package:cardgame/ui/screens/how_to_play_screen.dart';
import 'package:cardgame/ui/screens/marketplace_screen.dart';
import 'package:cardgame/ui/screens/ranking/global_ranking_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ResolvedNotificationNav? _route(String route, [Map<String, dynamic>? extra]) =>
    resolveNotificationNav({'type': 'marketing', 'route': route, ...?extra});

void main() {
  group('resolveNotificationNav', () {
    test('maps every plain route to its screen', () {
      const expected = {
        '/': NotificationDestination.home,
        '/play': NotificationDestination.play,
        '/robot': NotificationDestination.robot,
        '/daily': NotificationDestination.daily,
        '/shop': NotificationDestination.shop,
        '/collection': NotificationDestination.collection,
        '/friends': NotificationDestination.friends,
        '/ranking': NotificationDestination.ranking,
        '/profile': NotificationDestination.profile,
        '/notifications': NotificationDestination.notifications,
        '/settings': NotificationDestination.settings,
        '/rules': NotificationDestination.rules,
        '/tutorial': NotificationDestination.tutorial,
      };
      expected.forEach((route, destination) {
        expect(_route(route)?.destination, destination, reason: route);
      });
      expect(_route('/shop/')?.destination, NotificationDestination.shop);
    });

    test('reads the pot, shop tab and ranking tab', () {
      final cairo = _route('/play?pot=cairo')!;
      expect(cairo.destination, NotificationDestination.play);
      expect(cairo.potId, 'cairo');
      expect(_route('/play?pot=new_york')!.potId, 'new_york');
      // An unknown pot still opens the picker.
      final vegas = _route('/play?pot=vegas')!;
      expect(vegas.destination, NotificationDestination.play);
      expect(vegas.potId, isNull);

      expect(_route('/shop?tab=exchange')!.shopTab, MarketplaceTab.exchange);
      expect(_route('/shop?tab=gems')!.shopTab, isNull);
      expect(_route('/ranking?tab=history')!.rankingTab, RankingTab.history);
    });

    test('room invites come from the route or the type', () {
      final invite = _route('/join?roomId=ab12cd')!;
      expect(invite.destination, NotificationDestination.tableInvite);
      expect(invite.roomId, 'AB12CD');
      expect(_route('/table?roomId=AB12CD')!.roomId, 'AB12CD');
      expect(_route('/join', {'roomId': 'ff00aa'})!.roomId, 'FF00AA');

      final typed =
          resolveNotificationNav({'type': 'table_invite', 'roomId': 'c0ffee'})!;
      expect(typed.destination, NotificationDestination.tableInvite);
      expect(typed.roomId, 'C0FFEE');
    });

    test('falls back to the notification type', () {
      expect(
        resolveNotificationNav({'type': 'friend_request'})!.destination,
        NotificationDestination.friends,
      );
      expect(
        resolveNotificationNav({'type': 'rank_passed'})!.destination,
        NotificationDestination.ranking,
      );
      expect(
        resolveNotificationNav({
          'type': 'friend_accepted',
          'route': '/nowhere',
        })!.destination,
        NotificationDestination.friends,
      );
      expect(resolveNotificationNav({'type': 'marketing'}), isNull);
      expect(_route('/casino'), isNull);
    });
  });

  group('notificationPageFor', () {
    test('opens shop and ranking on the asked tab', () {
      final shop = notificationPageFor(_route('/shop?tab=avatars')!);
      expect(shop, isA<MarketplaceScreen>());
      expect((shop! as MarketplaceScreen).initialTab, MarketplaceTab.avatars);

      final ranking = notificationPageFor(_route('/ranking?tab=history')!);
      expect((ranking! as GlobalRankingScreen).initialTab, RankingTab.history);

      final tutorial = notificationPageFor(_route('/tutorial')!);
      expect((tutorial! as HowToPlayScreen).autoStart, isTrue);
      expect(
        notificationPageFor(_route('/collection')!),
        isA<CollectionScreen>(),
      );
    });

    test('has no page for destinations that are not pages', () {
      for (final route in [
        '/',
        '/play',
        '/robot',
        '/daily',
        '/notifications',
      ]) {
        expect(notificationPageFor(_route(route)!), isNull, reason: route);
      }
    });
  });

  group('NotificationNavigator', () {
    late GlobalKey<NavigatorState> key;
    late DeeplinkActions actions;
    late NotificationNavigator navigator;
    late List<String> calls;
    late bool canStart;

    Widget page(String name) => Scaffold(
      appBar: AppBar(title: Text('page:$name')),
      body: const SizedBox.expand(),
    );

    setUp(() {
      key = GlobalKey<NavigatorState>();
      calls = [];
      canStart = true;
      actions =
          DeeplinkActions()
            ..joinRoom = ((roomId) => calls.add('join:$roomId'))
            ..canStartMatch = (() => canStart)
            ..openDailyRewards = ((_) async => calls.add('daily'))
            ..openInbox = ((_) async => calls.add('inbox'))
            ..playVsRobot = ((_) => calls.add('robot'));
      navigator = NotificationNavigator(
        navigatorKey: key,
        actions: actions,
        pageBuilder:
            (nav) =>
                notificationPageFor(nav) == null
                    ? null
                    : page(nav.destination.name),
        openPotPicker: (context, potId) async {
          calls.add('pot:$potId');
          await Navigator.of(context).push<void>(
            MaterialPageRoute<void>(builder: (_) => page('pot:$potId')),
          );
        },
      );
    });

    Future<void> pumpApp(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: key,
          home: const Scaffold(body: Text('home')),
        ),
      );
    }

    Future<void> go(WidgetTester tester, String route) async {
      navigator.navigate(_route(route)!);
      await tester.pumpAndSettle();
    }

    Future<void> systemBack(WidgetTester tester) async {
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }

    testWidgets('system back from a deeplinked page returns home', (
      tester,
    ) async {
      await pumpApp(tester);
      for (final route in [
        '/shop?tab=exchange',
        '/collection',
        '/friends',
        '/ranking',
        '/profile',
        '/settings',
        '/rules',
        '/tutorial',
      ]) {
        await go(tester, route);
        expect(find.textContaining('page:'), findsOneWidget, reason: route);
        await systemBack(tester);
        expect(find.text('home'), findsOneWidget, reason: route);
        expect(find.textContaining('page:'), findsNothing, reason: route);
      }
    });

    testWidgets('the app bar back button returns home', (tester) async {
      await pumpApp(tester);
      await go(tester, '/friends');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('a second tap replaces the first page instead of stacking', (
      tester,
    ) async {
      await pumpApp(tester);
      await go(tester, '/shop');
      await go(tester, '/friends');
      expect(find.text('page:friends'), findsOneWidget);
      await systemBack(tester);
      expect(find.text('home'), findsOneWidget);
      expect(find.textContaining('page:'), findsNothing);
    });

    testWidgets('opens above home from deep in another screen', (tester) async {
      await pumpApp(tester);
      key.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => page('elsewhere')),
      );
      key.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => page('deeper')),
      );
      await tester.pumpAndSettle();
      await go(tester, '/ranking');
      await systemBack(tester);
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('a pot link opens the picker on that pot, then back', (
      tester,
    ) async {
      await pumpApp(tester);
      await go(tester, '/play?pot=cairo');
      expect(calls, ['pot:cairo']);
      expect(find.text('page:pot:cairo'), findsOneWidget);
      await systemBack(tester);
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('no picker or robot game while a match is on', (tester) async {
      await pumpApp(tester);
      canStart = false;
      await go(tester, '/play?pot=tokyo');
      await go(tester, '/robot');
      expect(calls, isEmpty);
      expect(find.text('home'), findsOneWidget);

      canStart = true;
      await go(tester, '/robot');
      expect(calls, ['robot']);
    });

    testWidgets('daily and inbox links use the bound actions', (tester) async {
      await pumpApp(tester);
      await go(tester, '/daily');
      await go(tester, '/notifications');
      expect(calls, ['daily', 'inbox']);
    });

    testWidgets('a room invite asks before joining', (tester) async {
      await pumpApp(tester);
      await go(tester, '/join?roomId=ab12cd');
      expect(find.text('Join room AB12CD?'), findsOneWidget);
      await tester.tap(find.text('Join'));
      await tester.pumpAndSettle();
      expect(calls, ['join:AB12CD']);
    });
  });
}
