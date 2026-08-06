import 'package:cardgame/app/locale_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localeRepositoryProvider = Provider<LocaleRepository>((ref) {
  throw UnimplementedError(
    'localeRepositoryProvider must be overridden in main()',
  );
});

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

class LocaleNotifier extends Notifier<Locale> {
  LocaleRepository get _repo => ref.read(localeRepositoryProvider);

  @override
  Locale build() {
    return LocaleRepository.resolveInitial(
      storedCode: _repo.loadCode(),
      deviceLocales: WidgetsBinding.instance.platformDispatcher.locales,
    );
  }

  Future<void> setLocale(String languageCode) async {
    if (!LocaleRepository.supportedCodes.contains(languageCode)) return;
    await _repo.saveCode(languageCode);
    state = Locale(languageCode);
  }
}
