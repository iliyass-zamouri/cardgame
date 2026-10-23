import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Player choices for table chat and voice.
class TableSocialPrefs {
  const TableSocialPrefs({this.showChat = true, this.voiceEnabled = true});

  /// Show opponent chat bubbles, phrases and emoji reactions.
  final bool showChat;

  /// Allow voice chat at the table (mic button + hearing the opponent).
  final bool voiceEnabled;

  TableSocialPrefs copyWith({bool? showChat, bool? voiceEnabled}) {
    return TableSocialPrefs(
      showChat: showChat ?? this.showChat,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
    );
  }
}

/// Persists [TableSocialPrefs].
class TableSocialPrefsRepository {
  TableSocialPrefsRepository._(this._box, this._memory);

  static const boxName = 'table_social_prefs';
  static const _keyShowChat = 'showChat';
  static const _keyVoiceEnabled = 'voiceEnabled';

  final Box<dynamic>? _box;
  TableSocialPrefs _memory;

  static Future<TableSocialPrefsRepository> open() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return TableSocialPrefsRepository._(box, const TableSocialPrefs());
  }

  /// In-memory repo for tests (no Hive).
  factory TableSocialPrefsRepository.memory([
    TableSocialPrefs initial = const TableSocialPrefs(),
  ]) {
    return TableSocialPrefsRepository._(null, initial);
  }

  TableSocialPrefs load() {
    final box = _box;
    if (box == null) return _memory;
    return TableSocialPrefs(
      showChat: box.get(_keyShowChat, defaultValue: true) == true,
      voiceEnabled: box.get(_keyVoiceEnabled, defaultValue: true) == true,
    );
  }

  Future<void> save(TableSocialPrefs prefs) async {
    final box = _box;
    if (box == null) {
      _memory = prefs;
      return;
    }
    await box.putAll({
      _keyShowChat: prefs.showChat,
      _keyVoiceEnabled: prefs.voiceEnabled,
    });
  }
}

/// Overridden in main() with the Hive-backed repository.
final tableSocialPrefsRepositoryProvider = Provider<TableSocialPrefsRepository>(
  (ref) => TableSocialPrefsRepository.memory(),
);

final tableSocialPrefsProvider =
    NotifierProvider<TableSocialPrefsNotifier, TableSocialPrefs>(
      TableSocialPrefsNotifier.new,
    );

class TableSocialPrefsNotifier extends Notifier<TableSocialPrefs> {
  TableSocialPrefsRepository get _repo =>
      ref.read(tableSocialPrefsRepositoryProvider);

  @override
  TableSocialPrefs build() => _repo.load();

  Future<void> setShowChat(bool value) async {
    state = state.copyWith(showChat: value);
    await _repo.save(state);
  }

  Future<void> setVoiceEnabled(bool value) async {
    state = state.copyWith(voiceEnabled: value);
    await _repo.save(state);
  }
}
