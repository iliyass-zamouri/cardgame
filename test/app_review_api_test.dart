import 'dart:convert';
import 'dart:io';

import 'package:cardgame/data/app_review/app_review_api.dart';
import 'package:cardgame/data/app_review/app_review_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Bodies built by the server's own clientView (server/app_review_config.js).
String fixture(String name) =>
    File('test/fixtures/app_review/$name.json').readAsStringSync();

http.Response reply(String body, int status) =>
    http.Response.bytes(utf8.encode(body), status, headers: _json);

const _json = {'content-type': 'application/json'};

const AppReviewDevice _device = (
  platform: 'ios',
  appVersion: '1.1.0+13',
  locale: 'fr',
);

void main() {
  test('status sends the trigger, device and session token', () async {
    late http.Request sent;
    final api = AppReviewApi(
      baseUrl: 'https://cards.test',
      client: MockClient((request) async {
        sent = request;
        return reply(fixture('status_show'), 200);
      }),
    );

    final status = await api.fetchStatus(
      trigger: AppReviewTrigger.win,
      device: _device,
      accessToken: 'token-1',
    );

    expect(sent.method, 'GET');
    expect(sent.url.path, '/app-review/status');
    expect(sent.url.queryParameters, {
      'trigger': 'win',
      'platform': 'ios',
      'appVersion': '1.1.0+13',
      'locale': 'fr',
    });
    expect(sent.headers['Authorization'], 'Bearer token-1');
    expect(status.show, isTrue);
    expect(status.config.flow, AppReviewFlow.gated);
    expect(status.config.storeMinStars, 4);
    expect(status.config.iosAppStoreId, '6450001234');
    expect(status.config.tags, [
      AppReviewTag.bugs,
      AppReviewTag.ads,
      AppReviewTag.difficulty,
      AppReviewTag.economy,
      AppReviewTag.bots,
      AppReviewTag.other,
    ]);
  });

  test('status reads a held-back prompt and the native-only flow', () async {
    final api = AppReviewApi(
      baseUrl: 'https://cards.test',
      client: MockClient((_) async => reply(fixture('status_cooldown'), 200)),
    );
    final status = await api.fetchStatus(
      trigger: AppReviewTrigger.daily,
      device: _device,
    );
    expect(status.show, isFalse);
    expect(status.reason, 'cooldown');
    expect(status.config.flow, AppReviewFlow.nativeOnly);
    expect(status.config.sendsToStore(1), isTrue);
  });

  test('config skips tags this build has no label for', () {
    final config = AppReviewConfig.fromJson({
      'tags': ['ads', 'brand_new_reason', 'bots'],
      'storeMinStars': 9,
    });
    expect(config.tags, [AppReviewTag.ads, AppReviewTag.bots]);
    expect(config.storeMinStars, 5);
  });

  test('sendsToStore follows the threshold and the store', () {
    const config = AppReviewConfig(storeMinStars: 4);
    expect(config.sendsToStore(3), isFalse);
    expect(config.sendsToStore(4), isTrue);
    const noStore = AppReviewConfig(hasStore: false);
    expect(noStore.sendsToStore(5), isFalse);
  });

  test('rate posts the stars and reads the action', () async {
    late http.Request sent;
    final api = AppReviewApi(
      baseUrl: 'https://cards.test',
      client: MockClient((request) async {
        sent = request;
        return reply(fixture('rate_feedback'), 200);
      }),
    );

    final result = await api.rate(
      stars: 2,
      trigger: AppReviewTrigger.daily,
      device: _device,
      accessToken: 'token-1',
    );

    expect(sent.method, 'POST');
    expect(sent.url.path, '/app-review/rate');
    expect(jsonDecode(sent.body), {
      'stars': 2,
      'trigger': 'daily',
      'platform': 'ios',
      'appVersion': '1.1.0+13',
      'locale': 'fr',
    });
    expect(result.reviewId, 42);
    expect(result.sendToStore, isFalse);
    expect(result.askReason, isTrue);
  });

  test('feedback posts tags and a trimmed comment to the review', () async {
    late http.Request sent;
    final api = AppReviewApi(
      baseUrl: 'https://cards.test',
      client: MockClient((request) async {
        sent = request;
        return reply('{"ok":true}', 200);
      }),
    );

    await api.sendFeedback(
      reviewId: 42,
      tags: [AppReviewTag.ads, AppReviewTag.bugs],
      comment: '  Too many ads  ',
    );

    expect(sent.url.path, '/app-review/42/feedback');
    expect(jsonDecode(sent.body), {
      'tags': ['ads', 'bugs'],
      'comment': 'Too many ads',
    });
  });

  test('server errors carry their code', () async {
    final api = AppReviewApi(
      baseUrl: 'https://cards.test',
      client: MockClient(
        (_) async => reply(
          '{"error":"too_soon","message":"You just rated the app"}',
          429,
        ),
      ),
    );
    expect(
      api.rate(stars: 5, trigger: AppReviewTrigger.win, device: _device),
      throwsA(
        isA<AppReviewApiException>()
            .having((e) => e.code, 'code', 'too_soon')
            .having((e) => e.statusCode, 'statusCode', 429),
      ),
    );
  });
}
