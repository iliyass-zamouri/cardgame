import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/app/game_session_state.dart';
import 'package:cardgame/ui/screens/deck_preview_screen.dart';
import 'package:cardgame/ui/theme/casino_chrome.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _LobbyMode { create, join }

class StartGameWidget extends ConsumerStatefulWidget {
  const StartGameWidget({super.key});

  @override
  ConsumerState<StartGameWidget> createState() => _StartGameWidgetState();
}

class _StartGameWidgetState extends ConsumerState<StartGameWidget> {
  final _roomController = TextEditingController();
  _LobbyMode _mode = _LobbyMode.create;

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connection = ref.watch(
      gameSessionProvider.select((state) => state.connection),
    );
    final connected = connection == ConnectionStatus.connected;
    final joining = _mode == _LobbyMode.join;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'CARD GAME',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: CasinoColors.gold,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Private table · two players',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: CasinoColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 28),
                  CasinoPill(
                    padding: const EdgeInsets.all(4),
                    borderColor: CasinoColors.surfaceHi,
                    child: Row(
                      children: [
                        _LobbyTab(
                          label: 'Create',
                          selected: _mode == _LobbyMode.create,
                          onTap: () =>
                              setState(() => _mode = _LobbyMode.create),
                        ),
                        _LobbyTab(
                          label: 'Join',
                          selected: _mode == _LobbyMode.join,
                          onTap: () => setState(() => _mode = _LobbyMode.join),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (joining) ...[
                    TextField(
                      controller: _roomController,
                      enabled: connected,
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 6,
                      style: const TextStyle(
                        color: CasinoColors.text,
                        letterSpacing: 6,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                      inputFormatters: [UpperCaseFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Room code',
                        counterText: '',
                      ),
                      onSubmitted: (_) => _start(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _roomController,
                    builder: (context, value, _) {
                      final can =
                          connected &&
                          (!joining || value.text.trim().isNotEmpty);
                      return CasinoActionButton(
                        label: joining ? 'Join room' : 'Create room',
                        tone: CasinoActionTone.raise,
                        expanded: false,
                        onPressed: can ? _start : null,
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Text(
                    switch (connection) {
                      ConnectionStatus.connected => 'Connected',
                      ConnectionStatus.connecting => 'Connecting…',
                      ConnectionStatus.disconnected => 'Server offline',
                    },
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: connected
                          ? CasinoColors.raiseHi
                          : CasinoColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (connection == ConnectionStatus.disconnected) ...[
                    const SizedBox(height: 8),
                    CasinoActionButton(
                      label: 'Retry',
                      tone: CasinoActionTone.check,
                      expanded: false,
                      onPressed: ref.read(gameSessionProvider.notifier).connect,
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const DeckPreviewScreen(),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: CasinoColors.goldSoft,
                    ),
                    child: const Text('View deck'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _start() {
    final notifier = ref.read(gameSessionProvider.notifier);
    if (_mode == _LobbyMode.create) {
      notifier.createRoom();
      return;
    }
    notifier.joinRoom(_roomController.text.trim().toUpperCase());
  }
}

class _LobbyTab extends StatelessWidget {
  const _LobbyTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? CasinoColors.raise : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? CasinoColors.text : CasinoColors.textMuted,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
