import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/app/game_session_state.dart';
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
    final theme = Theme.of(context);
    final connection = ref.watch(
      gameSessionProvider.select((state) => state.connection),
    );
    final connected = connection == ConnectionStatus.connected;
    final joining = _mode == _LobbyMode.join;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Card Game',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 32),
                  SegmentedButton<_LobbyMode>(
                    segments: const [
                      ButtonSegment(
                        value: _LobbyMode.create,
                        label: Text('Create'),
                      ),
                      ButtonSegment(
                        value: _LobbyMode.join,
                        label: Text('Join'),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (selection) =>
                        setState(() => _mode = selection.first),
                  ),
                  const SizedBox(height: 24),
                  if (joining) ...[
                    TextField(
                      controller: _roomController,
                      enabled: connected,
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 6,
                      inputFormatters: [UpperCaseFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Room code',
                        counterText: '',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _start(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _roomController,
                    builder: (context, value, _) => FilledButton(
                      onPressed:
                          connected && (!joining || value.text.trim().isNotEmpty)
                              ? _start
                              : null,
                      child: Text(joining ? 'Join room' : 'Create room'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    switch (connection) {
                      ConnectionStatus.connected => 'Connected',
                      ConnectionStatus.connecting => 'Connecting…',
                      ConnectionStatus.disconnected => 'Server offline',
                    },
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                  if (connection == ConnectionStatus.disconnected)
                    TextButton(
                      onPressed: ref.read(gameSessionProvider.notifier).connect,
                      child: const Text('Retry connection'),
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

class UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
