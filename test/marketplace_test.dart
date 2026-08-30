import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/data/avatars/avatar_catalog.dart';
import 'package:cardgame/data/decks/deck_catalog.dart';
import 'package:cardgame/data/marketplace/marketplace_api.dart';
import 'package:cardgame/domain/models/game_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Marketplace Catalogs and Models', () {
    test('AvatarCatalog items have valid pricing and currencies', () {
      final avatars = AvatarCatalog.all;
      expect(avatars, isNotEmpty);

      final defaultAvatar = AvatarCatalog.defaultAvatar;
      expect(defaultAvatar.price, 0);
      expect(defaultAvatar.currency, CurrencyType.money);

      final blue = AvatarCatalog.getById('blue');
      expect(blue.price, 200);
      expect(blue.currency, CurrencyType.money);
      expect(blue.isPremium, isFalse);

      final silver = AvatarCatalog.getById('silver');
      expect(silver.price, 1);
      expect(silver.currency, CurrencyType.chips);
      expect(silver.isPremium, isTrue);
    });

    test('DeckCatalog items have valid pricing and rarities', () {
      final defaultDeck = DeckCatalog.defaultDeck;
      expect(defaultDeck.id, 'default');
      expect(defaultDeck.chipPrice, 0);
      expect(defaultDeck.rarity, DeckRarity.standard);

      final gold = DeckCatalog.getById('gold_luxury');
      expect(gold.chipPrice, 2);
      expect(gold.rarity, DeckRarity.rare);
    });
  });

  group('PlayerProfile Currency and Inventory', () {
    test('PlayerProfile has default money and chips', () {
      const profile = PlayerProfile.empty;
      expect(profile.money, 500);
      expect(profile.chips, 1);
      expect(profile.ownsAvatar('default'), isTrue);
      expect(profile.ownsAvatar('silver'), isFalse);
      expect(profile.ownsDeck('default'), isTrue);
      expect(profile.ownsDeck('gold_luxury'), isFalse);
    });

    test('PlayerProfile accurately checks owned items', () {
      const profile = PlayerProfile(
        playerId: 'p1',
        name: 'Player 1',
        username: 'p1',
        money: 1000,
        chips: 5,
        ownedAvatars: ['default', 'silver', 'king'],
        ownedDecks: ['default', 'shadow_neon'],
      );

      expect(profile.ownsAvatar('silver'), isTrue);
      expect(profile.ownsAvatar('king'), isTrue);
      expect(profile.ownsAvatar('blue'), isFalse);
      expect(profile.ownsDeck('shadow_neon'), isTrue);
      expect(profile.ownsDeck('gold_luxury'), isFalse);
    });

    test('PlayerProfileRepository memory stores and restores inventory', () async {
      final repo = PlayerProfileRepository.memory();
      const profile = PlayerProfile(
        playerId: 'p100',
        name: 'Rich Player',
        username: 'rich',
        money: 2500,
        chips: 8,
        ownedAvatars: ['default', 'queen'],
        ownedDecks: ['default', 'gold_luxury'],
      );

      await repo.save(profile);
      final loaded = repo.load();

      expect(loaded.playerId, 'p100');
      expect(loaded.money, 2500);
      expect(loaded.chips, 8);
      expect(loaded.ownsAvatar('queen'), isTrue);
      expect(loaded.ownsDeck('gold_luxury'), isTrue);
    });
  });

  group('Marketplace API Models', () {
    test('PlayerInventory.fromJson parses valid payload', () {
      final json = {
        'playerId': 'user-123',
        'money': 1500,
        'chips': 3,
        'ownedAvatars': ['default', 'blue'],
        'ownedDecks': ['default'],
      };

      final inv = PlayerInventory.fromJson(json);
      expect(inv.playerId, 'user-123');
      expect(inv.money, 1500);
      expect(inv.chips, 3);
      expect(inv.ownedAvatars, ['default', 'blue']);
      expect(inv.ownedDecks, ['default']);
    });
  });

  group('GameSnapshot with Stakes and Pot', () {
    test('GameSnapshot parses stakePool, stakePerPlayer, and potAmount', () {
      final json = {
        'roomId': 'ROOM1',
        'version': 1,
        'status': 'playing',
        'ready': true,
        'matchType': 'random',
        'stakePool': 100,
        'stakePerPlayer': 50,
        'potAmount': 100,
        'deckCount': 20,
        'turn': 'you',
        'you': {
          'connected': true,
          'displayName': 'Alice',
          'cards': [],
        },
      };

      final snapshot = GameSnapshot.fromJson(json);
      expect(snapshot.stakePool, 100);
      expect(snapshot.stakePerPlayer, 50);
      expect(snapshot.potAmount, 100);
      expect(snapshot.matchType, 'random');
    });
  });
}
