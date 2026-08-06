import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/dependency_injection.dart';
import '../../core/constants/camo_colors.dart';
import '../../core/constants/camo_spacing.dart';
import '../../core/constants/camo_typography.dart';
import '../../core/widgets/auth_provider_buttons.dart';
import '../../core/widgets/camo_game_title.dart';
import '../../core/widgets/game_background.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _termsAccepted = true;

  Future<void> _afterAuth(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) return;
    if (ref.read(sessionProvider).isAuthenticated) {
      context.go('/lobby');
    }
  }

  Future<void> _signIn(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    if (!_termsAccepted) return;
    await action();
    if (context.mounted) await _afterAuth(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final loading = session.loading;

    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: CamoSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                const CamoGameTitle(
                  'Shadow Hand',
                  fontSize: 44,
                  stacked: true,
                ),
                const Spacer(flex: 3),
                GoogleAuthButton(
                  onPressed: loading
                      ? () {}
                      : () => _signIn(
                            context,
                            () => ref
                                .read(sessionProvider.notifier)
                                .signInGoogle(),
                          ),
                ),
                const SizedBox(height: CamoSpacing.lg),
                GuestAuthButton(
                  onPressed: loading
                      ? () {}
                      : () => _signIn(
                            context,
                            () => ref
                                .read(sessionProvider.notifier)
                                .signInGuest(),
                          ),
                ),
                const SizedBox(height: CamoSpacing.md),
                AppleAuthButton(
                  onPressed: loading
                      ? () {}
                      : () => _signIn(
                            context,
                            () => ref
                                .read(sessionProvider.notifier)
                                .signInApple(),
                          ),
                ),
                if (session.error != null) ...[
                  const SizedBox(height: CamoSpacing.md),
                  Text(
                    session.error!,
                    textAlign: TextAlign.center,
                    style: CamoTypography.bodyLg(CamoColors.danger),
                  ),
                ],
                if (loading) ...[
                  const SizedBox(height: CamoSpacing.lg),
                  const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: CamoColors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                ],
                const Spacer(flex: 2),
                _TermsRow(
                  accepted: _termsAccepted,
                  onChanged: (v) => setState(() => _termsAccepted = v),
                ),
                const SizedBox(height: CamoSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TermsRow extends StatelessWidget {
  const _TermsRow({
    required this.accepted,
    required this.onChanged,
  });

  final bool accepted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!accepted),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: accepted ? CamoColors.tertiary : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: accepted ? CamoColors.tertiary : CamoColors.onSurfaceVariant,
                width: 2,
              ),
            ),
            child: accepted
                ? const Icon(Icons.check, color: CamoColors.white, size: 14)
                : null,
          ),
          const SizedBox(width: CamoSpacing.sm),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: CamoTypography.bodyLg(
                  CamoColors.white.withValues(alpha: 0.8),
                ),
                children: const [
                  TextSpan(text: 'I have read and agreed to the '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                  TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
