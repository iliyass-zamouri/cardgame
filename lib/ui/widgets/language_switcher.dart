import 'package:cardgame/app/locale_provider.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LangOption {
  const LangOption({
    required this.code,
    required this.name,
    required this.flagAsset,
  });

  final String code;
  final String name;
  final String flagAsset;
}

/// Globe button that opens a language picker modal (name + SVG flag).
class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({super.key, this.showLabel = false});

  /// When true, shows "Change language" beside the globe (auth screen).
  final bool showLabel;

  static const options = <LangOption>[
    LangOption(code: 'en', name: 'English', flagAsset: 'assets/flags/en.svg'),
    LangOption(code: 'fr', name: 'Français', flagAsset: 'assets/flags/fr.svg'),
    LangOption(code: 'es', name: 'Español', flagAsset: 'assets/flags/es.svg'),
    LangOption(code: 'pt', name: 'Português', flagAsset: 'assets/flags/pt.svg'),
    LangOption(code: 'ar', name: 'العربية', flagAsset: 'assets/flags/ar.svg'),
  ];

  static LangOption optionFor(String code) {
    return options.firstWhere(
      (o) => o.code == code,
      orElse: () => options.first,
    );
  }

  static Future<void> openPicker(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => const _LanguagePickerDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!showLabel) {
      return Material(
        color: CasinoColors.bgElevated.withValues(alpha: 0.85),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => openPicker(context),
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              Icons.public_rounded,
              color: CasinoColors.goldSoft,
              size: 22,
            ),
          ),
        ),
      );
    }

    final l10n = context.l10n;
    return Material(
      color: CasinoColors.bgElevated.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openPicker(context),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 14, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.public_rounded,
                color: CasinoColors.goldSoft,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.changeLanguage,
                style: const TextStyle(
                  color: CasinoColors.goldSoft,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguagePickerDialog extends ConsumerWidget {
  const _LanguagePickerDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = ref.watch(localeProvider).languageCode;

    return Dialog(
      backgroundColor: CasinoColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.public_rounded,
                    color: CasinoColors.goldSoft,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.language,
                      style: const TextStyle(
                        color: CasinoColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: CasinoColors.textMuted,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (final option in LanguageSwitcher.options) ...[
              _LanguageTile(
                option: option,
                selected: current == option.code,
                onTap: () async {
                  await ref
                      .read(localeProvider.notifier)
                      .setLocale(option.code);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final LangOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color:
            selected
                ? CasinoColors.gold.withValues(alpha: 0.16)
                : CasinoColors.bgElevated.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: selected ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                _FlagBadge(asset: option.flagAsset),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    option.name,
                    style: TextStyle(
                      color:
                          selected ? CasinoColors.goldSoft : CasinoColors.text,
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_rounded,
                    color: CasinoColors.gold,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FlagBadge extends StatelessWidget {
  const _FlagBadge({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white24, width: 0.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: SvgPicture.asset(asset, width: 32, height: 22, fit: BoxFit.cover),
    );
  }
}
