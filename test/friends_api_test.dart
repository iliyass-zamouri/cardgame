import 'dart:convert';
import 'package:cardgame/data/friends/friends_api.dart';
import 'package:cardgame/data/profile/profile_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ProfileApi', () {
    test('checkUsername parses available response', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/player/check-username');
        expect(request.url.queryParameters['username'], 'lucky_ace');
        return http.Response(
          jsonEncode({'available': true, 'username': 'lucky_ace'}),
          200,
        );
      });

      final api = ProfileApi(baseUrl: 'http://localhost', client: mockClient);
      final res = await api.checkUsername(username: 'lucky_ace');
      expect(res.available, isTrue);
      expect(res.username, 'lucky_ace');
    });

    test('updateProfile sends post payload', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/player/profile');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['playerId'], 'p1');
        expect(body['name'], 'New Name');
        expect(body['username'], 'new_user');
        return http.Response(
          jsonEncode({
            'playerId': 'p1',
            'name': 'New Name',
            'username': 'new_user',
          }),
          200,
        );
      });

      final api = ProfileApi(baseUrl: 'http://localhost', client: mockClient);
      final res = await api.updateProfile(
        playerId: 'p1',
        name: 'New Name',
        username: 'new_user',
      );
      expect(res['name'], 'New Name');
      expect(res['username'], 'new_user');
    });
  });

  group('FriendsApi', () {
    test('searchPlayers decodes player list and relationships', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/friends/search');
        expect(request.url.queryParameters['query'], 'alice');
        return http.Response(
          jsonEncode({
            'players': [
              {
                'playerId': 'p2',
                'name': 'Alice',
                'username': 'alice_w',
                'elo': 1200,
                'totalPoints': 50,
                'wins': 5,
                'losses': 2,
                'draws': 0,
                'relationship': 'none',
                'isOnline': true,
              },
            ],
          }),
          200,
        );
      });

      final api = FriendsApi(baseUrl: 'http://localhost', client: mockClient);
      final results = await api.searchPlayers(query: 'alice');
      expect(results.length, 1);
      expect(results.first.displayName, 'Alice');
      expect(results.first.username, 'alice_w');
      expect(results.first.relationship, FriendshipRelationship.none);
      expect(results.first.isOnline, isTrue);
    });

    test(
      'getFriends decodes friends, incoming and outgoing requests',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.url.path, '/friends');
          return http.Response(
            jsonEncode({
              'friends': [
                {
                  'friendshipId': 'f1',
                  'playerId': 'p2',
                  'name': 'Bob',
                  'username': 'bob_king',
                  'elo': 1100,
                  'totalPoints': 20,
                  'wins': 2,
                  'losses': 1,
                  'draws': 0,
                  'isOnline': false,
                },
              ],
              'incomingRequests': [],
              'outgoingRequests': [],
            }),
            200,
          );
        });

        final api = FriendsApi(baseUrl: 'http://localhost', client: mockClient);
        final data = await api.getFriends(playerId: 'p1');
        expect(data.friends.length, 1);
        expect(data.friends.first.name, 'Bob');
        expect(data.incomingRequests, isEmpty);
        expect(data.outgoingRequests, isEmpty);
      },
    );
  });
}
