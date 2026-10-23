import 'dart:async';

import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/app/table_chat_controller.dart';
import 'package:cardgame/app/table_social_prefs.dart';
import 'package:cardgame/data/auth/auth_config.dart';
import 'package:cardgame/data/voice/voice_api.dart';
import 'package:cardgame/services/voice_chat_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VoiceChatState {
  const VoiceChatState({
    this.micOn = false,
    this.peerMicOn = false,
    this.connected = false,
    this.permissionDenied = false,
  });

  final bool micOn;
  final bool peerMicOn;

  /// Audio link with the opponent is up.
  final bool connected;
  final bool permissionDenied;

  VoiceChatState copyWith({
    bool? micOn,
    bool? peerMicOn,
    bool? connected,
    bool? permissionDenied,
  }) {
    return VoiceChatState(
      micOn: micOn ?? this.micOn,
      peerMicOn: peerMicOn ?? this.peerMicOn,
      connected: connected ?? this.connected,
      permissionDenied: permissionDenied ?? this.permissionDenied,
    );
  }
}

final voiceApiProvider = Provider<VoiceApi>(
  (ref) => VoiceApi(baseUrl: httpBaseUrl),
);

final voiceChatProvider = NotifierProvider<VoiceChatController, VoiceChatState>(
  VoiceChatController.new,
);

/// Table voice chat. Mic is off by default; the opponent is heard as soon as
/// they turn theirs on (unless muted or voice is disabled in settings).
class VoiceChatController extends Notifier<VoiceChatState> {
  static const _glareWindow = Duration(seconds: 5);

  VoicePeer? _peer;
  MediaStream? _localStream;
  List<Map<String, dynamic>>? _iceServers;

  /// Signaling steps are async; run them one at a time, in arrival order.
  Future<void> _queue = Future.value();

  @override
  VoiceChatState build() {
    ref.listen(gameSessionProvider.select((state) => state.game?.roomId), (
      previous,
      next,
    ) {
      if (previous != next) _enqueue(_reset);
    });
    ref.listen(
      gameSessionProvider.select(
        (state) => state.game?.opponent?.connected ?? false,
      ),
      (previous, next) {
        if (previous == true && !next) {
          _enqueue(_closePeer);
        } else if (previous != true && next && state.micOn) {
          _enqueue(_startCall);
        }
      },
    );
    ref.listen(tableChatProvider.select((state) => state.opponentMuted), (
      _,
      muted,
    ) {
      _peer?.remoteMuted = muted;
    });
    ref.listen(tableSocialPrefsProvider.select((prefs) => prefs.voiceEnabled), (
      _,
      enabled,
    ) {
      if (!enabled) _enqueue(() => _reset(notifyPeer: true));
    });
    final subscription = ref
        .watch(gameSessionProvider.notifier)
        .tableEvents
        .listen(receive);
    ref.onDispose(() {
      unawaited(subscription.cancel());
      unawaited(_peer?.dispose());
      _peer = null;
      _stopLocalStream();
    });
    return const VoiceChatState();
  }

  void toggleMic() => _enqueue(() => state.micOn ? _micOff() : _micOn());

  /// Incoming `voiceSignal` / `voiceState` from the game socket.
  void receive(Map<String, dynamic> message) {
    if (!ref.read(tableSocialPrefsProvider).voiceEnabled) return;
    switch (message['type']) {
      case 'voiceState':
        state = state.copyWith(peerMicOn: message['micOn'] == true);
      case 'voiceSignal':
        final signal = message['signal'];
        if (signal is! Map) return;
        final fromPlayerId = message['fromPlayerId'] as String? ?? '';
        _enqueue(
          () => _onSignal(Map<String, dynamic>.from(signal), fromPlayerId),
        );
    }
  }

  void _enqueue(Future<void> Function() step) {
    _queue = _queue.then((_) => step()).catchError((Object error) {
      debugPrint('[voice] $error');
    });
  }

  Future<void> _micOn() async {
    if (state.micOn) return;
    state = state.copyWith(permissionDenied: false);
    final track = await _ensureLocalTrack();
    if (track == null) return;
    track.enabled = true;
    await _useSpeaker();
    state = state.copyWith(micOn: true);
    _sendState(true);
    final peer = _peer;
    if (peer != null) {
      await peer.setLocalTrack(track);
    } else if (_opponentConnected) {
      await _startCall();
    }
  }

  Future<void> _micOff() async {
    if (!state.micOn) return;
    for (final track
        in _localStream?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = false;
    }
    state = state.copyWith(micOn: false);
    _sendState(false);
  }

  Future<MediaStreamTrack?> _ensureLocalTrack() async {
    final existing = _localStream?.getAudioTracks();
    if (existing != null && existing.isNotEmpty) return existing.first;
    try {
      final stream = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
      });
      _localStream = stream;
      final tracks = stream.getAudioTracks();
      return tracks.isEmpty ? null : tracks.first;
    } catch (error) {
      debugPrint('[voice] microphone unavailable: $error');
      state = state.copyWith(permissionDenied: true);
      return null;
    }
  }

  MediaStreamTrack? get _localTrack {
    final tracks = _localStream?.getAudioTracks();
    if (tracks == null || tracks.isEmpty) return null;
    return tracks.first;
  }

  bool get _opponentConnected =>
      ref.read(gameSessionProvider).game?.opponent?.connected ?? false;

  Future<void> _startCall() async {
    if (_peer != null) return;
    final peer = await _newPeer();
    await peer.call(_localTrack);
  }

  Future<void> _onSignal(
    Map<String, dynamic> signal,
    String fromPlayerId,
  ) async {
    switch (signal['kind']) {
      case 'offer':
        final sdp = signal['sdp'] as String?;
        if (sdp == null) return;
        final existing = _peer;
        if (existing != null) {
          // Both offered at once: the lower player id keeps its offer. An
          // older unanswered offer (opponent had voice off) just gives way.
          final youId = ref.read(gameSessionProvider).game?.you.playerId ?? '';
          if (existing.awaitingAnswer &&
              existing.offerAge < _glareWindow &&
              youId.compareTo(fromPlayerId) < 0) {
            return;
          }
          await _closePeer();
        }
        final peer = await _newPeer();
        await peer.answer(sdp, state.micOn ? _localTrack : null);
      case 'answer':
        final sdp = signal['sdp'] as String?;
        if (sdp != null) await _peer?.acceptAnswer(sdp);
      case 'ice':
        final candidate = signal['candidate'];
        if (candidate is Map) {
          await _peer?.addCandidate(Map<String, dynamic>.from(candidate));
        }
      case 'hangup':
        await _closePeer();
        state = state.copyWith(peerMicOn: false);
    }
  }

  Future<VoicePeer> _newPeer() async {
    _iceServers ??= await ref
        .read(voiceApiProvider)
        .fetchIceServers(
          accessToken: ref.read(playerProfileProvider).value?.accessToken,
        );
    final peer = VoicePeer(
      iceServers: _iceServers!,
      onSignal:
          (signal) =>
              ref.read(gameSessionProvider.notifier).sendVoiceSignal(signal),
      onConnectedChanged: (connected) {
        if (!ref.mounted) return;
        state = state.copyWith(connected: connected);
        // Play the opponent on the loudspeaker, not the earpiece.
        if (connected) unawaited(_useSpeaker());
      },
    );
    peer.remoteMuted = ref.read(tableChatProvider).opponentMuted;
    _peer = peer;
    return peer;
  }

  Future<void> _useSpeaker() async {
    try {
      await Helper.setSpeakerphoneOn(true);
    } catch (_) {
      // Not supported on this platform.
    }
  }

  Future<void> _closePeer() async {
    final peer = _peer;
    _peer = null;
    await peer?.dispose();
    state = state.copyWith(connected: false);
  }

  /// Drops the call and the microphone. [notifyPeer] when still at the
  /// table; on leaving the room the server tells the opponent itself.
  Future<void> _reset({bool notifyPeer = false}) async {
    final hadPeer = _peer != null;
    await _closePeer();
    if (notifyPeer && hadPeer) {
      ref.read(gameSessionProvider.notifier).sendVoiceSignal({
        'kind': 'hangup',
      });
    }
    if (notifyPeer && state.micOn) _sendState(false);
    _stopLocalStream();
    _iceServers = null;
    state = const VoiceChatState();
  }

  void _stopLocalStream() {
    final stream = _localStream;
    _localStream = null;
    if (stream == null) return;
    for (final track in stream.getTracks()) {
      unawaited(track.stop());
    }
    unawaited(stream.dispose());
  }

  void _sendState(bool micOn) {
    ref.read(gameSessionProvider.notifier).sendVoiceState(micOn);
  }
}
