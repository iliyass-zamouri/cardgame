import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Short one-shot / looped game SFX.
enum SfxKind {
  flip,
  draw,
  throwCard,
  win,
  lose,
  searching,
  buy,
  matchStart,
  changeTurn,
  shuffle,
  reveal,
}

/// Fire-and-forget card / match audio. Safe from Flame + Flutter UI.
class SfxService {
  SfxService._();
  static final SfxService instance = SfxService._();

  static const _assets = {
    SfxKind.flip: 'sounds/flip.wav',
    SfxKind.draw: 'sounds/draw.wav',
    SfxKind.throwCard: 'sounds/put.wav',
    SfxKind.win: 'sounds/win.wav',
    SfxKind.lose: 'sounds/lose.wav',
    SfxKind.searching: 'sounds/searching.wav',
    SfxKind.buy: 'sounds/buy.wav',
    SfxKind.matchStart: 'sounds/match_start.wav',
    SfxKind.changeTurn: 'sounds/change_turn.wav',
    SfxKind.shuffle: 'sounds/shuffle.wav',
    SfxKind.reveal: 'sounds/reveal.wav',
  };

  static const _searchPeriod = Duration(seconds: 1);
  static const _searchBreak = Duration(seconds: 3);
  static const _matchStartFlipMute = Duration(seconds: 3);

  /// lift+read+travel (~1.36s) + slack — wait for discard land before turn cue.
  static const _changeTurnAnimWait = Duration(milliseconds: 1800);

  /// After put/draw/flip SFX actually plays, gap then turn cue.
  /// Long enough that double-discard's second put can bump the timer.
  static const _changeTurnAfterAction = Duration(milliseconds: 1100);

  bool enabled = true;

  final List<AudioPlayer> _oneshots = [];
  Timer? _searchTimer;
  Timer? _changeTurnTimer;
  AudioPlayer? _searchPlayer;
  AudioPlayer? _shufflePlayer;
  bool _searching = false;
  bool _searchPulseBusy = false;
  DateTime? _muteFlipUntil;
  DateTime? _lastCardActionSfxAt;

  Future<void> play(SfxKind kind) async {
    if (!enabled || kind == SfxKind.searching) return;
    if (kind == SfxKind.flip &&
        _muteFlipUntil != null &&
        DateTime.now().isBefore(_muteFlipUntil!)) {
      return;
    }
    if (_isCardActionSfx(kind)) {
      _noteCardActionSfx();
    }
    try {
      final player = AudioPlayer();
      _oneshots.add(player);
      player.onPlayerComplete.listen((_) {
        _oneshots.remove(player);
        player.dispose();
      });
      await player.play(AssetSource(_assets[kind]!));
    } catch (e) {
      debugPrint('Sfx play($kind) failed: $e');
    }
  }

  bool _isCardActionSfx(SfxKind kind) =>
      kind == SfxKind.flip || kind == SfxKind.draw || kind == SfxKind.throwCard;

  void _noteCardActionSfx() {
    _lastCardActionSfxAt = DateTime.now();
    // Turn already queued — push it out until after this put/action.
    if (_changeTurnTimer != null) {
      scheduleChangeTurn();
    }
  }

  Future<void> startSearch() async {
    if (!enabled) return;
    if (_searching) return;
    _searching = true;
    unawaited(_fireSearchPulse());
    _searchTimer?.cancel();
    _searchTimer = Timer.periodic(_searchPeriod, (_) {
      unawaited(_fireSearchPulse());
    });
  }

  Future<void> _fireSearchPulse() async {
    if (!_searching || !enabled || _searchPulseBusy) return;
    _searchPulseBusy = true;
    try {
      final player = AudioPlayer();
      _searchPlayer = player;
      await player.setReleaseMode(ReleaseMode.release);
      await player.setPlaybackRate(1.0);
      await player.setVolume(0.55);
      await player.play(AssetSource(_assets[SfxKind.searching]!));
      try {
        await player.onPlayerComplete.first.timeout(const Duration(seconds: 5));
      } on TimeoutException {
        // Clip hung — continue search cadence anyway.
      }
      try {
        await player.dispose();
      } catch (_) {}
      if (_searchPlayer == player) _searchPlayer = null;
      if (!_searching) return;
      await Future<void>.delayed(_searchBreak);
    } catch (e) {
      debugPrint('Sfx search pulse failed: $e');
    } finally {
      _searchPulseBusy = false;
    }
  }

  Future<void> stopSearch() async {
    _searching = false;
    _searchTimer?.cancel();
    _searchTimer = null;
    final player = _searchPlayer;
    _searchPlayer = null;
    if (player == null) return;
    try {
      await player.stop();
      await player.dispose();
    } catch (e) {
      debugPrint('Sfx stopSearch failed: $e');
    }
  }

  /// Stop search cue, mute deal flips briefly, play match-found sting.
  Future<void> playMatchStart() async {
    cancelScheduledChangeTurn();
    await stopSearch();
    _muteFlipUntil = DateTime.now().add(_matchStartFlipMute);
    // Brief gap so search player release doesn't swallow the sting.
    await Future<void>.delayed(const Duration(milliseconds: 40));
    await play(SfxKind.matchStart);
  }

  void flip() => play(SfxKind.flip);
  void draw() => play(SfxKind.draw);
  void throwCard() => play(SfxKind.throwCard);
  void reveal() => play(SfxKind.reveal);
  void win() {
    cancelScheduledChangeTurn();
    play(SfxKind.win);
  }

  void lose() {
    cancelScheduledChangeTurn();
    play(SfxKind.lose);
  }

  void buy() => play(SfxKind.buy);

  /// Queue turn cue after discard-land (put) / other card SFX.
  void scheduleChangeTurn() {
    if (!enabled) return;
    _changeTurnTimer?.cancel();
    final now = DateTime.now();
    final last = _lastCardActionSfxAt;
    final actionIsFresh =
        last != null &&
        now.difference(last) < const Duration(milliseconds: 150);

    // Fresh put/draw/flip → short settle after it.
    // Otherwise turn flipped before discard land → wait for throw anim.
    final delay = actionIsFresh ? _changeTurnAfterAction : _changeTurnAnimWait;

    _changeTurnTimer = Timer(delay, () {
      _changeTurnTimer = null;
      play(SfxKind.changeTurn);
    });
  }

  void cancelScheduledChangeTurn() {
    _changeTurnTimer?.cancel();
    _changeTurnTimer = null;
  }

  /// Loop shuffle rustle for the duration of the queen shuffle anim.
  Future<void> startShuffle() async {
    if (!enabled) return;
    if (_shufflePlayer != null) return;
    _noteCardActionSfx();
    try {
      final player = AudioPlayer();
      _shufflePlayer = player;
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(0.85);
      await player.play(AssetSource(_assets[SfxKind.shuffle]!));
    } catch (e) {
      _shufflePlayer = null;
      debugPrint('Sfx startShuffle failed: $e');
    }
  }

  Future<void> stopShuffle() async {
    final player = _shufflePlayer;
    _shufflePlayer = null;
    if (player == null) return;
    try {
      await player.stop();
      await player.dispose();
    } catch (e) {
      debugPrint('Sfx stopShuffle failed: $e');
    }
  }
}
