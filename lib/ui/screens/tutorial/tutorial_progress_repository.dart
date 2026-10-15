import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Overridden in `main()` with the Hive-backed repo; in-memory otherwise.
final tutorialProgressRepositoryProvider = Provider<TutorialProgressRepository>(
  (ref) => TutorialProgressRepository.memory(),
);

/// Which tutorial lessons this device has finished (drives the checkmarks).
class TutorialProgressRepository {
  TutorialProgressRepository._(this._box);

  static const boxName = 'tutorial_progress';
  static const _keyCompleted = 'completed';

  final Box<dynamic>? _box;
  final Set<String> _memory = {};

  static Future<TutorialProgressRepository> open() async {
    return TutorialProgressRepository._(await Hive.openBox<dynamic>(boxName));
  }

  factory TutorialProgressRepository.memory() =>
      TutorialProgressRepository._(null);

  Set<String> completed() {
    final box = _box;
    if (box == null) return {..._memory};
    final stored = box.get(_keyCompleted) as List<dynamic>?;
    return {...?stored?.map((e) => e.toString())};
  }

  Future<void> markCompleted(String lessonId) async {
    final box = _box;
    if (box == null) {
      _memory.add(lessonId);
      return;
    }
    await box.put(_keyCompleted, {...completed(), lessonId}.toList());
  }
}
