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
    final observer = _LocaleObserver((locales) {
      // Only track system while user has not picked an override.
      if (_repo.loadCode() != null) return;
      state = LocaleRepository.fromDeviceLocales(locales ?? const []);
    });
    final binding = WidgetsBinding.instance;
    binding.addObserver(observer);
    ref.onDispose(() => binding.removeObserver(observer));

    return LocaleRepository.resolve(
      storedCode: _repo.loadCode(),
      deviceLocales: binding.platformDispatcher.locales,
    );
  }

  Future<void> setLocale(String languageCode) async {
    if (!LocaleRepository.supportedCodes.contains(languageCode)) return;
    await _repo.saveCode(languageCode);
    state = Locale(languageCode);
  }
}

class _LocaleObserver with WidgetsBindingObserver {
  _LocaleObserver(this._onLocalesChanged);

  final void Function(List<Locale>? locales) _onLocalesChanged;

  @override
  void didChangeLocales(List<Locale>? locales) => _onLocalesChanged(locales);
}
