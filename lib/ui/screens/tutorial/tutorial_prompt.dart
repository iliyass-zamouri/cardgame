import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/player_profile_repository.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/trailer/trailer_mode.dart';
import 'package:cardgame/ui/screens/how_to_play_screen.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:cardgame/ui/widgets/playing_card_face.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Offers the tutorial once to players who never saw it. Either answer marks
/// it done on the server, so returning players are never asked again.
class TutorialPromptGate extends ConsumerStatefulWidget {
  const TutorialPromptGate({super.key, required this.child});

  final Widget child;

  /// Once per app run, even if the home menu is rebuilt.
  static bool _shownThisRun = false;

  @visibleForTesting
  static void resetForTest() => _shownThisRun = false;

  @override
  ConsumerState<TutorialPromptGate> createState() => _TutorialPromptGateState();
}

class _TutorialPromptGateState extends ConsumerState<TutorialPromptGate> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybePrompt(ref.read(playerProfileProvider).value),
    );
  }

  void _maybePrompt(PlayerProfile? profile) {
    if (TutorialPromptGate._shownThisRun || !mounted || TrailerMode.enabled) {
      return;
    }
    if (profile == null || profile.isEmpty || profile.tutorialDone) return;
    TutorialPromptGate._shownThisRun = true;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TutorialPromptSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PlayerProfile?>(
      playerProfileProvider.select((value) => value.value),
      (_, profile) => _maybePrompt(profile),
    );
    return widget.child;
  }
}

class TutorialPromptSheet extends ConsumerWidget {
  const TutorialPromptSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    void answer({required bool start}) {
      ref.read(playerProfileProvider.notifier).markTutorialDone().ignore();
      final navigator = Navigator.of(context)..pop();
      if (start) {
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => const HowToPlayScreen(autoStart: true),
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [CasinoColors.leather, CasinoColors.leatherDeep],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: CasinoColors.gold, width: 1.5)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final (i, tag) in const ['D13', 'A14', 'C12'].indexed)
                  Transform.rotate(
                    angle: (i - 1) * 0.18,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: PlayingCardFace(tag: tag, width: 50),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.tutPromptTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CasinoColors.gold,
                fontWeight: FontWeight.w800,
                fontFamily: CasinoFonts.displayOf(context),
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tutPromptBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CasinoColors.text,
                fontSize: 14.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            GoldButton(
              label: l10n.tutStartAll,
              onPressed: () => answer(start: true),
            ),
            const SizedBox(height: 10),
            LeatherButton(
              label: l10n.tutPromptLater,
              onPressed: () => answer(start: false),
            ),
          ],
        ),
      ),
    );
  }
}
