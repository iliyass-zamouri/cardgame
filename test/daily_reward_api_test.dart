import 'dart:convert';
import 'dart:io';

import 'package:cardgame/data/daily_reward/daily_reward_api.dart';
import 'package:cardgame/data/daily_reward/daily_reward_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String fixture(String name) =>
    File('test/fixtures/daily_reward/$name.json').readAsStringSync();

/// A reply as the server sends it: JSON with no charset, which must still be
/// read as UTF-8 (the fixtures carry Arabic titles).
http.Response reply(String body, int status) =>
    http.Response.bytes(utf8.encode(body), status, headers: _json);

const _json = {'content-type': 'application/json'};

void main() {
  test('status sends the timezone and the session token', () async {
    late http.Request sent;
    final api = DailyRewardApi(
      baseUrl: 'https://cards.test',
      client: MockClient((request) async {
        sent = request;
        return reply(fixture('status_midweek'), 200);
      }),
    );

    final status = await api.fetchStatus(
      tzOffsetMinutes: 60,
      accessToken: 'token-1',
    );

    expect(sent.method, 'GET');
    expect(sent.url.path, '/daily-reward');
    expect(sent.url.queryParameters, {'tzOffset': '60'});
    expect(sent.headers['Authorization'], 'Bearer token-1');
    expect(status.nextDay, 4);
    expect(
      localizedTitle(status.chests['royal']!.titles, 'ar'),
      'الصندوق الملكي',
    );
  });

  test('claim posts the boost and the streak choice', () async {
    late http.Request sent;
    final api = DailyRewardApi(
      baseUrl: 'https://cards.test',
      client: MockClient((request) async {
        sent = request;
        return reply(fixture('claim_rescue'), 200);
      }),
    );

    final result = await api.claim(
      tzOffsetMinutes: -300,
      boosted: true,
      choice: StreakChoice.rescue,
      accessToken: 'token-1',
    );

    expect(sent.method, 'POST');
    expect(sent.url.path, '/daily-reward/claim');
    expect(jsonDecode(sent.body), {
      'tzOffsetMinutes': -300,
      'boosted': true,
      'streakChoice': 'rescue',
    });
    expect(result.rescued, isTrue);
  });

  test('a plain claim leaves the choice out', () async {
    late http.Request sent;
    final api = DailyRewardApi(
      baseUrl: 'https://cards.test',
      client: MockClient((request) async {
        sent = request;
        return reply(fixture('claim_day1'), 200);
      }),
    );

    await api.claim(tzOffsetMinutes: 0);

    expect(jsonDecode(sent.body), {'tzOffsetMinutes': 0, 'boosted': false});
    expect(sent.headers.containsKey('Authorization'), isFalse);
  });

  test('the welcome-back claim has its own route', () async {
    late http.Request sent;
    final api = DailyRewardApi(
      baseUrl: 'https://cards.test',
      client: MockClient((request) async {
        sent = request;
        return reply(fixture('claim_comeback'), 200);
      }),
    );

    final result = await api.claimComeback(tzOffsetMinutes: 60);

    expect(sent.url.path, '/daily-reward/comeback/claim');
    expect(jsonDecode(sent.body), {'tzOffsetMinutes': 60});
    expect(result.money, 1000);
  });

  test('server refusals keep their code and details', () async {
    final api = DailyRewardApi(
      baseUrl: 'https://cards.test',
      client: MockClient(
        (_) async => reply(
          jsonEncode({
            'error': 'insufficient_funds',
            'message': 'Not enough chips',
            'required': 3,
            'chips': 1,
          }),
          409,
        ),
      ),
    );

    await expectLater(
      api.claim(tzOffsetMinutes: 0, choice: StreakChoice.rescue),
      throwsA(
        isA<DailyRewardApiException>()
            .having((e) => e.statusCode, 'statusCode', 409)
            .having((e) => e.code, 'code', 'insufficient_funds')
            .having((e) => e.message, 'message', 'Not enough chips')
            .having((e) => e.details['required'], 'required', 3),
      ),
    );
  });

  test('a broken gateway still fails cleanly', () async {
    final api = DailyRewardApi(
      baseUrl: 'https://cards.test',
      client: MockClient((_) async => http.Response('<html>502</html>', 502)),
    );

    await expectLater(
      api.fetchStatus(tzOffsetMinutes: 0),
      throwsA(
        isA<DailyRewardApiException>()
            .having((e) => e.statusCode, 'statusCode', 502)
            .having((e) => e.code, 'code', isNull),
      ),
    );
  });
}
