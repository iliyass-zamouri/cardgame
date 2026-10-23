import 'package:flutter_webrtc/flutter_webrtc.dart';

typedef VoiceSignalSink = void Function(Map<String, dynamic> signal);

/// One WebRTC audio link to the opponent. Signaling goes through the game
/// socket; media flows peer to peer (or via our TURN relay).
///
/// Both sides negotiate a single `sendrecv` audio transceiver, so turning a
/// microphone on later is a `replaceTrack` with no renegotiation.
class VoicePeer {
  VoicePeer({
    required this.iceServers,
    required this.onSignal,
    required this.onConnectedChanged,
  });

  final List<Map<String, dynamic>> iceServers;
  final VoiceSignalSink onSignal;
  final void Function(bool connected) onConnectedChanged;

  RTCPeerConnection? _pc;
  RTCRtpTransceiver? _audio;
  MediaStreamTrack? _remoteTrack;
  final List<RTCIceCandidate> _pendingCandidates = [];
  bool _remoteDescriptionSet = false;
  DateTime? _offeredAt;
  bool _remoteMuted = false;
  bool _closed = false;

  /// We sent an offer and are still waiting for the answer.
  bool get awaitingAnswer => _offeredAt != null && !_remoteDescriptionSet;

  /// How long our offer has been waiting for an answer.
  Duration get offerAge {
    final offeredAt = _offeredAt;
    return offeredAt == null
        ? Duration.zero
        : DateTime.now().difference(offeredAt);
  }

  set remoteMuted(bool muted) {
    _remoteMuted = muted;
    _remoteTrack?.enabled = !muted;
  }

  Future<RTCPeerConnection> _ensurePeerConnection() async {
    final existing = _pc;
    if (existing != null) return existing;
    final pc = await createPeerConnection({
      'iceServers': iceServers,
      'sdpSemantics': 'unified-plan',
    });
    pc.onIceCandidate = (candidate) {
      if (_closed || candidate.candidate == null) return;
      onSignal({
        'kind': 'ice',
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };
    pc.onConnectionState = (connectionState) {
      if (_closed) return;
      onConnectedChanged(
        connectionState ==
            RTCPeerConnectionState.RTCPeerConnectionStateConnected,
      );
    };
    pc.onTrack = (event) {
      if (event.track.kind != 'audio') return;
      _remoteTrack = event.track;
      event.track.enabled = !_remoteMuted;
    };
    _pc = pc;
    return pc;
  }

  /// Starts the call as the offering side.
  Future<void> call(MediaStreamTrack? localTrack) async {
    final pc = await _ensurePeerConnection();
    _audio = await pc.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.SendRecv),
    );
    if (localTrack != null) await _audio!.sender.replaceTrack(localTrack);
    final offer = await pc.createOffer({});
    await pc.setLocalDescription(offer);
    _offeredAt = DateTime.now();
    onSignal({'kind': 'offer', 'sdp': offer.sdp});
  }

  /// Answers the opponent's offer. Works with the microphone off.
  Future<void> answer(String sdp, MediaStreamTrack? localTrack) async {
    final pc = await _ensurePeerConnection();
    await pc.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));
    await _remoteDescriptionReady();
    final transceivers = await pc.getTransceivers();
    _audio = transceivers.isEmpty ? null : transceivers.first;
    await _audio?.setDirection(TransceiverDirection.SendRecv);
    if (localTrack != null) await _audio?.sender.replaceTrack(localTrack);
    final answer = await pc.createAnswer({});
    await pc.setLocalDescription(answer);
    onSignal({'kind': 'answer', 'sdp': answer.sdp});
  }

  Future<void> acceptAnswer(String sdp) async {
    final pc = _pc;
    if (pc == null || !awaitingAnswer) return;
    await pc.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
    await _remoteDescriptionReady();
  }

  Future<void> addCandidate(Map<String, dynamic> json) async {
    final candidate = RTCIceCandidate(
      json['candidate'] as String?,
      json['sdpMid'] as String?,
      (json['sdpMLineIndex'] as num?)?.toInt(),
    );
    final pc = _pc;
    if (pc == null || !_remoteDescriptionSet) {
      _pendingCandidates.add(candidate);
      return;
    }
    await pc.addCandidate(candidate);
  }

  Future<void> setLocalTrack(MediaStreamTrack? track) async {
    await _audio?.sender.replaceTrack(track);
  }

  Future<void> _remoteDescriptionReady() async {
    _remoteDescriptionSet = true;
    final pc = _pc;
    if (pc == null) return;
    for (final candidate in _pendingCandidates) {
      await pc.addCandidate(candidate);
    }
    _pendingCandidates.clear();
  }

  Future<void> dispose() async {
    if (_closed) return;
    _closed = true;
    _pendingCandidates.clear();
    final pc = _pc;
    _pc = null;
    await pc?.close();
  }
}
