import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/data/avatars/avatar_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AvatarCatalog', () {
    test('default avatar is configured correctly', () {
      final defaultAvatar = AvatarCatalog.defaultAvatar;
      expect(defaultAvatar.id, 'default');
      expect(defaultAvatar.assetPath, 'assets/avatars/default.png');
      expect(defaultAvatar.isDefault, isTrue);
      expect(defaultAvatar.isUnlocked(1), isTrue);
    });

    test('getById returns matching avatar or fallback to default', () {
      expect(AvatarCatalog.getById('default').id, 'default');
      expect(AvatarCatalog.getById('blue').id, 'blue');
      expect(AvatarCatalog.getById('queen').id, 'queen');
      expect(AvatarCatalog.getById('non_existent').id, 'default');
      expect(AvatarCatalog.getById(null).id, 'default');
    });

    test('unlock condition checks player level requirement', () {
      const lockedAvatar = AvatarItem(
        id: 'high_tier',
        assetPath: 'assets/avatars/default.png',
        nameKey: 'highTier',
        requiredLevel: 10,
      );

      expect(lockedAvatar.isUnlocked(1), isFalse);
      expect(lockedAvatar.isUnlocked(9), isFalse);
      expect(lockedAvatar.isUnlocked(10), isTrue);
      expect(lockedAvatar.isUnlocked(15), isTrue);
    });
  });

  group('PlayerProfile avatar persistence', () {
    test('PlayerProfile defaults to avatarId "default"', () {
      const profile = PlayerProfile(
        playerId: 'p1',
        name: 'Player 1',
        username: 'p1',
      );
      expect(profile.avatarId, 'default');
    });

    test(
      'PlayerProfileRepository memory stores and updates avatarId',
      () async {
        final repo = PlayerProfileRepository.memory();
        expect(repo.load().avatarId, 'default');

        const updated = PlayerProfile(
          playerId: 'p2',
          name: 'Player 2',
          username: 'p2',
          avatarId: 'app_mascot',
        );

        await repo.save(updated);
        expect(repo.load().avatarId, 'app_mascot');
      },
    );
  });
}
