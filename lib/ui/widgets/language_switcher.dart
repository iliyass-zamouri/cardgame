import 'package:cardgame/app/locale_provider.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Compact EN | FR | ع language switcher.
class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({super.key});

  static const _options = <(String, String)>[
    ('en', 'EN'),
    ('fr', 'FR'),
    ('ar', 'ع'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider).languageCode;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: CasinoColors.bgElevated.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (code, label) in _options) ...[
            _Chip(
              label: label,
              selected: current == code,
              onTap: () => ref.read(localeProvider.notifier).setLocale(code),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: selected ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? CasinoColors.gold.withValues(alpha: 0.22) : null,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? CasinoColors.gold : CasinoColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}
