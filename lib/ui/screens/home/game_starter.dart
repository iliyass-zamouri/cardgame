import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/app/game_session_state.dart';
import 'package:cardgame/gen/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int _backgroundDecodeWidth = 1080;

class StartGameWidget extends ConsumerStatefulWidget {
  const StartGameWidget({super.key});

  @override
  ConsumerState<StartGameWidget> createState() => _StartGameWidgetState();
}

class _StartGameWidgetState extends ConsumerState<StartGameWidget> {
  final _roomController = TextEditingController();

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

    return Material(
      child: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: ResizeImage(
              AssetImage(Assets.background.path),
              width: _backgroundDecodeWidth,
            ),
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.4),
              BlendMode.darken,
            ),
            fit: BoxFit.fitHeight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Card(
                color: Colors.black.withValues(alpha: 0.72),
                margin: const EdgeInsets.all(24),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Card Game',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        switch (connection) {
                          ConnectionStatus.connected => 'Server connected',
                          ConnectionStatus.connecting => 'Connecting…',
                          ConnectionStatus.disconnected => 'Server offline',
                        },
                        style: TextStyle(
                          color: connected ? Colors.greenAccent : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: connected
                            ? ref
                                .read(gameSessionProvider.notifier)
                                .createRoom
                            : null,
                        icon: const Icon(Icons.add),
                        label: const Text('Create room'),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('or', style: TextStyle(color: Colors.white)),
                      ),
                      TextField(
                        controller: _roomController,
                        enabled: connected,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 6,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Room code',
                          labelStyle: TextStyle(color: Colors.white70),
                          counterText: '',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: _joinRoom,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed:
                            connected ? () => _joinRoom(_roomController.text) : null,
                        child: const Text('Join room'),
                      ),
                      if (connection == ConnectionStatus.disconnected)
                        TextButton(
                          onPressed:
                              ref.read(gameSessionProvider.notifier).connect,
                          child: const Text('Retry connection'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _joinRoom(String roomId) {
    ref.read(gameSessionProvider.notifier).joinRoom(roomId);
  }
}
