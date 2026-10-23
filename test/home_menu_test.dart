import 'package:cardgame/app/home_menu_providers.dart';
import 'package:cardgame/data/app/app_config_api.dart';
import 'package:cardgame/data/app/home_menu_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeConfigApi extends AppConfigApi {
  _FakeConfigApi(this.result) : super(baseUrl: '');

  final Future<AppConfig> Function() result;
  int calls = 0;

  @override
  Future<AppConfig> fetch() {
    calls++;
    return result();
  }
}

const _served = HomeMenuConfig(
  modes: [HomeMode.joinRoom],
  nav: [HomeNavTab.home, HomeNavTab.shop],
);

void main() {
  group('HomeMenuConfig.fromJson', () {
    test('keeps order and drops unknown or duplicate ids', () {
      final config = HomeMenuConfig.fromJson(const {
        'modes': ['playVsRobot', 'tournament', 'createRoom', 'playVsRobot'],
        'nav': ['rules', 'home', 'shop'],
      });
      expect(config.modes, [HomeMode.playVsRobot, HomeMode.createRoom]);
      expect(config.nav, [HomeNavTab.rules, HomeNavTab.home, HomeNavTab.shop]);
    });

    test('falls back per list when a field is missing or malformed', () {
      final config = HomeMenuConfig.fromJson(const {'modes': 'oops'});
      expect(config, HomeMenuConfig.fallback);
    });

    test('always keeps the home tab', () {
      final config = HomeMenuConfig.fromJson(const {
        'nav': ['shop', 'friends'],
      });
      expect(config.nav, [
        HomeNavTab.shop,
        HomeNavTab.home,
        HomeNavTab.friends,
      ]);
    });

    test('round-trips through json', () {
      expect(HomeMenuConfig.fromJson(_served.toJson()), _served);
    });
  });

  group('homeMenuProvider', () {
    ProviderContainer container(HomeMenuRepository repo, AppConfigApi api) {
      final c = ProviderContainer(
        overrides: [
          homeMenuRepositoryProvider.overrideWithValue(repo),
          appConfigApiProvider.overrideWithValue(api),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('serves the cache first, then the server config', () async {
      final repo = HomeMenuRepository.memory();
      final api = _FakeConfigApi(
        () async => const AppConfig(homeMenu: _served),
      );
      final c = container(repo, api);
      final seen = <HomeMenuConfig>[];
      c.listen(homeMenuProvider, (_, next) => seen.add(next));

      expect(c.read(homeMenuProvider), HomeMenuConfig.fallback);
      await pumpEventQueue();
      expect(c.read(homeMenuProvider), _served);
      expect(repo.read(), _served);
      expect(seen, [_served]);
    });

    test('does not notify when the server config is unchanged', () async {
      final api = _FakeConfigApi(
        () async => const AppConfig(homeMenu: _served),
      );
      final c = container(HomeMenuRepository.memory(_served), api);
      final seen = <HomeMenuConfig>[];
      c.listen(homeMenuProvider, (_, next) => seen.add(next));

      await pumpEventQueue();
      expect(api.calls, 1);
      expect(seen, isEmpty);
    });

    test('keeps the cache when the server is down or predates menus', () async {
      for (final api in [
        _FakeConfigApi(() async => throw Exception('offline')),
        _FakeConfigApi(() async => const AppConfig()),
      ]) {
        final c = container(HomeMenuRepository.memory(_served), api);
        c.read(homeMenuProvider);
        await pumpEventQueue();
        expect(c.read(homeMenuProvider), _served);
      }
    });
  });
}
