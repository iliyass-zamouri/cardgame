import 'dart:async';
import 'dart:math' as math;

import 'package:cardgame/app/auth_providers.dart';
import 'package:cardgame/app/game_session_controller.dart';
import 'package:cardgame/domain/models/game_snapshot.dart';
import 'package:cardgame/trailer/trailer_mode.dart';
import 'package:cardgame/app/navigation_providers.dart';
import 'package:cardgame/ui/screens/profile/player_profile_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' show MaterialPageRoute;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Runs the take named in the trailer config once the app is up.
class TrailerDirector extends ConsumerStatefulWidget {
  const TrailerDirector({super.key});

  @override
  ConsumerState<TrailerDirector> createState() => _TrailerDirectorState();
}

class _TrailerDirectorState extends ConsumerState<TrailerDirector> {
  final _clock = Stopwatch()..start();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_run()));
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();

  /// Printed to the system log so cuts line up with the recording.
  void mark(String label) {
    final t = (_clock.elapsedMilliseconds / 1000).toStringAsFixed(2);
    debugPrint(
      'TRAILER mark t=$t wall=${DateTime.now().millisecondsSinceEpoch} $label',
    );
  }

  Future<void> wait(double seconds) async {
    final end = _clock.elapsedMicroseconds + (seconds * 1e6).round();
    while (_clock.elapsedMicroseconds < end) {
      SchedulerBinding.instance.scheduleFrame();
      await SchedulerBinding.instance.endOfFrame;
    }
  }

  Future<bool> waitUntil(bool Function() test, {double timeout = 30}) async {
    final end = _clock.elapsedMicroseconds + (timeout * 1e6).round();
    while (!test()) {
      if (_clock.elapsedMicroseconds > end) return false;
      await wait(0.05);
    }
    return true;
  }

  GameSessionController get session => ref.read(gameSessionProvider.notifier);
  GameSnapshot? get game => ref.read(gameSessionProvider).game;

  Future<void> _run() async {
    try {
      final config = await TrailerMode.loadConfig();
      mark('config $config');
      TrailerMode.stakePool = int.tryParse(config['stake'] ?? '') ?? 0;
      await _seed(config);
      await wait(2.0);
      mark('home');
      switch (config['shot']) {
        case 'match':
          await _match(config);
        case 'home':
          await wait(double.tryParse(config['hold'] ?? '') ?? 6);
        case 'tour':
          await _tour();
        case 'tour2':
          await _tour2();
        default:
          mark('unknown shot');
      }
      mark('shot-done');
    } catch (error, stack) {
      debugPrint('TRAILER error: $error\n$stack');
    }
  }

  // ------------------------------------------------------------------ UI

  int _pointer = 900;

  /// Taps the first visible Text whose string matches [label] (any case),
  /// through the gesture system like a real finger.
  Future<bool> tapText(String label) async {
    Rect? hit;
    void visit(Element element) {
      if (hit != null) return;
      final widget = element.widget;
      final text =
          widget is Text
              ? (widget.data ?? widget.textSpan?.toPlainText())
              : null;
      if (text != null && text.trim().toLowerCase() == label.toLowerCase()) {
        final box = element.findRenderObject();
        if (box is RenderBox && box.attached && box.hasSize) {
          hit = box.localToGlobal(Offset.zero) & box.size;
          return;
        }
      }
      element.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);
    final rect = hit;
    if (rect == null) {
      mark('tap-miss $label');
      return false;
    }
    final pointer = _pointer++;
    GestureBinding.instance.handlePointerEvent(
      PointerDownEvent(pointer: pointer, position: rect.center),
    );
    await wait(0.08);
    GestureBinding.instance.handlePointerEvent(
      PointerUpEvent(pointer: pointer, position: rect.center),
    );
    return true;
  }

  Future<void> back() async {
    await ref.read(rootNavigatorKeyProvider).currentState?.maybePop();
  }

  Future<void> snap(String name, {double hold = 1.4}) async {
    await wait(0.3);
    mark('snap $name');
    await wait(hold);
  }

  /// Menu tour for the trailer and store screenshots.
  Future<void> _tour() async {
    await wait(1.0);
    await snap('01_home', hold: 2.5);
    for (final (label, name) in [
      ('Find match', '02_stakes'),
      ('Marketplace', '03_marketplace'),
      ('Leaderboard', '04_leaderboard'),
      ('Friends', '05_friends'),
      ('How to play', '06_how_to_play'),
    ]) {
      if (!await tapText(label)) continue;
      await wait(1.6);
      await snap(name, hold: 2.2);
      await back();
      await wait(1.2);
    }
  }

  /// Second tour: store tabs, profile and every stake table.
  Future<void> _tour2() async {
    await wait(1.0);
    if (await tapText('Marketplace')) {
      await wait(1.6);
      await snap('market_exchange', hold: 2.0);
      for (final tab in ['Avatars', 'Decks']) {
        if (await tapText(tab)) {
          await wait(1.2);
          await snap('market_${tab.toLowerCase()}', hold: 2.0);
        }
      }
      await back();
      await wait(1.2);
    }
    unawaited(
      ref
          .read(rootNavigatorKeyProvider)
          .currentState
          ?.push(
            MaterialPageRoute<void>(
              builder: (_) => const PlayerProfileScreen(),
            ),
          ),
    );
    await wait(1.8);
    await snap('profile', hold: 2.0);
    await back();
    await wait(1.2);
    if (await tapText('Find match')) {
      await wait(1.6);
      for (final pool in ['50', '100', '200', '500']) {
        if (await tapText(pool)) {
          await wait(0.9);
          await snap('stake_$pool', hold: 1.2);
        }
      }
      await back();
      await wait(1.0);
    }
  }

  /// Guest session + a showcase profile (avatar, deck, bankroll).
  Future<void> _seed(Map<String, String> config) async {
    final repo = ref.read(playerProfileRepositoryProvider);
    final current = repo.load();
    await repo.save(
      current.copyWith(
        playerId: current.playerId.isEmpty ? 'trailer' : null,
        name: config['name'] ?? 'Ace',
        avatarId: config['avatar'] ?? 'golden-king',
        deckId: config['deck'] ?? 'ornate_red',
        money: math.max(current.money, 48500),
        chips: math.max(current.chips, 1250),
      ),
    );
    ref.invalidate(playerProfileProvider);
    await ref.read(sessionAuthProvider.notifier).enterAsGuest();
  }

  // ------------------------------------------------------------------ match

  static int _value(String tag) {
    final v = int.parse(tag.substring(1));
    if (v == 14) return -1;
    if (v == 13 && (tag[0] == 'A' || tag[0] == 'D')) return 0;
    return v;
  }

  static int _rank(String tag) => int.parse(tag.substring(1));

  /// Plays vs the Robot like a sensible human: remembers its peeked cards,
  /// keeps low ones, swaps out high ones, uses Jack peeks and Queen shuffles.
  Future<void> _match(Map<String, String> config) async {
    final maxTurns = int.tryParse(config['turns'] ?? '') ?? 7;
    session.playVsRobot();
    await waitUntil(() => game != null);
    mark('dealt');
    await wait(2.2);

    session.launch();
    mark('peek');
    final known = <int, String>{};
    await waitUntil(() => game?.you.launch == LaunchStatus.launched);
    for (final card in game!.you.cards) {
      if (card.visible && card.tag != null) known[card.index] = card.tag!;
    }
    final city = TrailerMode.stakePool;
    await wait(0.6);
    mark('snap peek_$city');
    await waitUntil(() => game?.bothRevealed ?? false, timeout: 15);
    mark('play');

    var turns = 0;
    while (game?.status == GameStatus.playing && turns < maxTurns) {
      final ready = await waitUntil(
        () =>
            game?.status != GameStatus.playing ||
            ((game?.isYourTurn ?? false) &&
                !(game?.abilityLockActive ?? false) &&
                !(game?.you.hasHandCard ?? true)),
        timeout: 25,
      );
      if (!ready || game?.status != GameStatus.playing) break;
      turns++;
      await wait(0.9);
      mark('turn $turns draw');
      session.drawCard();
      await waitUntil(() => game?.you.hasHandCard ?? false, timeout: 5);
      await wait(1.0);
      if (turns == 1) mark('snap draw_$city');
      final g = game!;
      final hand = g.you.handCardTag;
      if (hand == null) continue;

      if (_rank(hand) == 11 && g.canJackPeek) {
        final target = (g.opponent?.cards.length ?? 4) > 1 ? 1 : 0;
        mark('turn $turns jack');
        session.jackPeek(side: 'opponent', cardIndex: target);
        await wait(1.0);
        mark('snap jack_$city');
        await wait(1.6);
        continue;
      }
      if (_rank(hand) == 12 && g.canQueenAbility) {
        mark('turn $turns queen');
        session.enterQueenShufflePick();
        await wait(0.8);
        mark('snap queenpick_$city');
        await wait(0.6);
        session.queenShuffle(side: 'opponent');
        await wait(0.5);
        mark('snap queen_$city');
        await wait(1.5);
        continue;
      }

      final value = _value(hand);
      final cards = g.you.cards.map((c) => c.index).toList();
      final unknown = cards.where((i) => !known.containsKey(i)).toList();
      int? worst;
      for (final i in cards) {
        final tag = known[i];
        if (tag != null &&
            (worst == null || _value(tag) > _value(known[worst]!))) {
          worst = i;
        }
      }
      int? target;
      if (worst != null && value < _value(known[worst]!)) {
        target = worst;
      } else if (value <= 4 && unknown.isNotEmpty) {
        target = unknown.first;
      }
      if (target != null) {
        mark('turn $turns swap $hand -> $target');
        session.tapCard(target);
        known[target] = hand;
      } else {
        mark('turn $turns throw $hand');
        session.throwHandCard();
      }
      await wait(1.2);
    }

    if (game?.status == GameStatus.playing) {
      await waitUntil(
        () => (game?.isYourTurn ?? false) && !(game?.you.hasHandCard ?? true),
        timeout: 20,
      );
      await wait(0.6);
      mark('call-end');
      session.endGame();
    }
    await waitUntil(() => game?.status == GameStatus.ended, timeout: 20);
    mark('result');
    await wait(2.4);
    final end = game;
    final won = end != null && end.you.total < (end.opponent?.total ?? 999);
    mark('snap result_${won ? 'win' : 'lose'}_$city');
    await wait(3.6);
  }
}
