import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:flutter/material.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: CasinoColors.bg,
      appBar: AppBar(
        backgroundColor: CasinoColors.surface,
        foregroundColor: CasinoColors.text,
        title: Text(
          l10n.marketplace,
          style: const TextStyle(
            color: CasinoColors.gold,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.style_rounded,
                size: 56,
                color: CasinoColors.gold.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.comingSoon,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: CasinoColors.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.marketplaceComingSoonBody,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: CasinoColors.textMuted,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
