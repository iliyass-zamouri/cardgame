import 'dart:ui';

import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/data/avatars/avatar_catalog.dart';
import 'package:cardgame/data/decks/deck_catalog.dart';
import 'package:cardgame/data/marketplace/marketplace_api.dart';
import 'package:cardgame/domain/models/game_snapshot.dart';
import 'package:cardgame/ui/flame/card_back_skins.dart';
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
      expect(defaultDeck.skinId, 'ornate_blue');

      final onyx = DeckCatalog.getById('black_onyx');
      expect(onyx.chipPrice, 20);
      expect(onyx.rarity, DeckRarity.legendary);
      expect(onyx.skinId, 'black_onyx');
      expect(DeckCatalog.skinIdFor('black_onyx'), 'black_onyx');
      expect(DeckCatalog.skinIdFor('unknown'), 'ornate_blue');
      expect(DeckCatalog.all.map((d) => d.id), ['default', 'black_onyx']);
    });

    test('Onyx Black skin is registered for in-game backs', () {
      expect(CardBackSkins.byId('black_onyx').id, 'black_onyx');
      expect(CardBackSkins.byId('ornate_blue').id, 'ornate_blue');
    });

    test(
      'CardFaceTheme customizes black onyx card face and preserves classic default',
      () {
        final defaultSkin = CardBackSkins.byId('ornate_blue');
        expect(defaultSkin.faceTheme.blackColor, const Color(0xFF1A1A1A));
        expect(defaultSkin.faceTheme.redColor, const Color(0xFFA31819));

        final onyxSkin = CardBackSkins.byId('black_onyx');
        expect(onyxSkin.faceTheme.blackColor, const Color(0xFFF5F5F7));
        expect(onyxSkin.faceTheme.redColor, const Color(0xFFFF453A));
        expect(
          onyxSkin.faceTheme.backgroundGradientColors.length,
          greaterThanOrEqualTo(2),
        );
        expect(
          onyxSkin.faceTheme.backgroundGradientColors.first,
          const Color(0xFF16171E),
        );
      },
    );
  });

  group('PlayerProfile Currency and Inventory', () {
    test('PlayerProfile has default money and chips', () {
      const profile = PlayerProfile.empty;
      expect(profile.money, 500);
      expect(profile.chips, 1);
      expect(profile.ownsAvatar('default'), isTrue);
      expect(profile.ownsAvatar('silver'), isFalse);
      expect(profile.ownsDeck('default'), isTrue);
      expect(profile.ownsDeck('black_onyx'), isFalse);
      expect(profile.deckId, 'default');
    });

    test('PlayerProfile accurately checks owned items', () {
      const profile = PlayerProfile(
        playerId: 'p1',
        name: 'Player 1',
        username: 'p1',
        money: 1000,
        chips: 5,
        ownedAvatars: ['default', 'silver', 'king'],
        ownedDecks: ['default', 'black_onyx'],
        deckId: 'black_onyx',
      );

      expect(profile.ownsAvatar('silver'), isTrue);
      expect(profile.ownsAvatar('king'), isTrue);
      expect(profile.ownsAvatar('blue'), isFalse);
      expect(profile.ownsDeck('black_onyx'), isTrue);
      expect(profile.ownsDeck('gold_luxury'), isFalse);
      expect(profile.deckId, 'black_onyx');
    });

    test(
      'PlayerProfileRepository memory stores and restores inventory',
      () async {
        final repo = PlayerProfileRepository.memory();
        const profile = PlayerProfile(
          playerId: 'p100',
          name: 'Rich Player',
          username: 'rich',
          money: 2500,
          chips: 8,
          ownedAvatars: ['default', 'queen'],
          ownedDecks: ['default', 'black_onyx'],
          deckId: 'black_onyx',
        );

        await repo.save(profile);
        final loaded = repo.load();

        expect(loaded.playerId, 'p100');
        expect(loaded.money, 2500);
        expect(loaded.chips, 8);
        expect(loaded.ownsAvatar('queen'), isTrue);
        expect(loaded.ownsDeck('black_onyx'), isTrue);
        expect(loaded.deckId, 'black_onyx');
      },
    );
  });

  group('Marketplace API Models', () {
    test('PlayerInventory.fromJson parses valid payload', () {
      final json = {
        'playerId': 'user-123',
        'money': 1500,
        'chips': 3,
        'adRewardMoney': 100,
        'ownedAvatars': ['default', 'blue'],
        'ownedDecks': ['default'],
      };

      final inv = PlayerInventory.fromJson(json);
      expect(inv.playerId, 'user-123');
      expect(inv.money, 1500);
      expect(inv.chips, 3);
      expect(inv.adRewardMoney, 100);
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
        'discardTop': 'D10',
        'discardRecent': ['D10'],
        'discardDeckId': 'black_onyx',
        'turn': 'you',
        'you': {
          'connected': true,
          'displayName': 'Alice',
          'deckId': 'black_onyx',
          'cards': [],
        },
      };

      final snapshot = GameSnapshot.fromJson(json);
      expect(snapshot.stakePool, 100);
      expect(snapshot.stakePerPlayer, 50);
      expect(snapshot.potAmount, 100);
      expect(snapshot.matchType, 'random');
      expect(snapshot.you.deckId, 'black_onyx');
      expect(snapshot.discardDeckId, 'black_onyx');
    });

    test('PlayerResultRating parses moneyAfter and chipsAfter', () {
      final rating = PlayerResultRating.fromJson({
        'playerId': 'player-1',
        'result': 'win',
        'pointsEarned': 30,
        'eloDelta': 16,
        'moneyAfter': 1050,
        'chipsAfter': 10,
      });
      expect(rating.moneyAfter, 1050);
      expect(rating.chipsAfter, 10);
    });
  });
}
