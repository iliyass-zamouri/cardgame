import 'dart:async';

import 'package:cardgame/data/app_review/app_review_models.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/screens/daily_reward/reward_shell.dart';
import 'package:cardgame/ui/theme/app_icons.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:cardgame/ui/theme/game_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const appReviewCommentMax = 1000;

/// What the rating dialog asks of the app. AppReviewController fills it in;
/// tests pass fakes.
class AppReviewSession {
  const AppReviewSession({
    required this.config,
    required this.rate,
    required this.sendFeedback,
    required this.openStore,
  });

  final AppReviewConfig config;

  /// Saves the stars as soon as they are tapped.
  final Future<AppReviewRateResult> Function(int stars) rate;

  /// The optional "what could be better" answer. [reviewId] is null when
  /// the rating itself couldn't be saved.
  final Future<void> Function(
    int? reviewId,
    List<AppReviewTag> tags,
    String? comment,
  )
  sendFeedback;

  /// Sends the player on to rate in the store. [preferSheet] tries the
  /// in-app review sheet before the store page.
  final Future<void> Function({bool preferSheet}) openStore;
}

Future<void> showAppReviewDialog(
  BuildContext context,
  AppReviewSession session,
) {
  return showRewardDialog<void>(
    context,
    builder: (_) => AppReviewDialog(session: session),
  );
}

enum _Step { stars, feedback, thanks }

/// Stars first. A happy rating thanks the player and opens the store review;
/// a lower one asks, optionally, what could be better, then thanks them.
class AppReviewDialog extends StatefulWidget {
  const AppReviewDialog({super.key, required this.session});

  final AppReviewSession session;

  @override
  State<AppReviewDialog> createState() => _AppReviewDialogState();
}

class _AppReviewDialogState extends State<AppReviewDialog> {
  var _step = _Step.stars;
  int _stars = 0;
  bool _busy = false;
  bool _happy = false;
  int? _reviewId;
  final _tags = <AppReviewTag>{};
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  Future<void> _pickStars(int stars) async {
    if (_busy) return;
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _stars = stars;
      _busy = true;
    });
    // Let the stars light up before the dialog moves on.
    final results = await Future.wait([
      widget.session.rate(stars),
      Future<void>.delayed(const Duration(milliseconds: 450)),
    ]);
    if (!mounted) return;
    final result = results.first as AppReviewRateResult;
    setState(() {
      _busy = false;
      _reviewId = result.reviewId;
      _happy = result.sendToStore;
      _step = result.askReason ? _Step.feedback : _Step.thanks;
    });
    if (result.sendToStore) {
      unawaited(widget.session.openStore(preferSheet: true));
    }
  }

  Future<void> _send() async {
    if (_busy) return;
    final comment = _comment.text.trim();
    if (_tags.isEmpty && comment.isEmpty) {
      setState(() => _step = _Step.thanks);
      return;
    }
    setState(() => _busy = true);
    await widget.session.sendFeedback(
      _reviewId,
      AppReviewTag.values.where(_tags.contains).toList(),
      comment.isEmpty ? null : comment,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _step = _Step.thanks;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: inset),
      child: RewardPanel(
        title: l10n.appReviewRibbon,
        maxWidth: 400,
        onClose: _busy ? null : _close,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(
                key: ValueKey(_step),
                child: switch (_step) {
                  _Step.stars => _starsStep(l10n),
                  _Step.feedback => _feedbackStep(l10n),
                  _Step.thanks => _thanksStep(l10n),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _starsStep(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Heading(l10n.appReviewQuestion),
        const SizedBox(height: 6),
        _Body(l10n.appReviewTapStars),
        const SizedBox(height: 16),
        StarRow(value: _stars, onPick: _busy ? null : _pickStars),
        const SizedBox(height: 18),
        SizedBox(
          height: 36,
          child: Center(
            child:
                _busy
                    ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: CasinoColors.gold,
                      ),
                    )
                    : LeatherButton(
                      label: l10n.appReviewNotNow,
                      compact: true,
                      onPressed: _close,
                    ),
          ),
        ),
      ],
    );
  }

  Widget _feedbackStep(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Heading(l10n.appReviewFeedbackTitle),
        const SizedBox(height: 6),
        _Body(l10n.appReviewFeedbackBody),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in widget.session.config.tags)
              _TagChip(
                label: appReviewTagLabel(l10n, tag),
                selected: _tags.contains(tag),
                onTap:
                    () => setState(() {
                      if (!_tags.remove(tag)) _tags.add(tag);
                    }),
              ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _comment,
          minLines: 2,
          maxLines: 4,
          maxLength: appReviewCommentMax,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(color: CasinoColors.text, fontSize: 14),
          cursorColor: CasinoColors.gold,
          decoration: InputDecoration(
            hintText: l10n.appReviewCommentHint,
            hintStyle: TextStyle(color: CasinoColors.textMuted),
            counterText: '',
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.25),
            contentPadding: const EdgeInsets.all(12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: CasinoColors.gold.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: CasinoColors.gold),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: LeatherButton(
                label: l10n.appReviewSkip,
                onPressed:
                    _busy ? null : () => setState(() => _step = _Step.thanks),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GoldButton(
                label: l10n.appReviewSend,
                onPressed: _busy ? null : _send,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _thanksStep(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 4),
        GameIcon(icon: AppIcons.star, size: 48, color: CasinoColors.gold),
        const SizedBox(height: 10),
        _Heading(l10n.appReviewThanksTitle),
        const SizedBox(height: 6),
        _Body(
          _happy ? l10n.appReviewThanksHappy : l10n.appReviewThanksFeedback,
        ),
        const SizedBox(height: 18),
        if (_happy) ...[
          LeatherButton(
            label: l10n.appReviewRateInStore,
            leading: GameIcon(
              icon: AppIcons.star,
              size: 18,
              color: CasinoColors.gold,
            ),
            // The sheet already had its chance; a tap opens the store page.
            onPressed: () => widget.session.openStore(preferSheet: false),
          ),
          const SizedBox(height: 10),
        ],
        GoldButton(label: l10n.appReviewDone, onPressed: _close),
      ],
    );
  }
}

String appReviewTagLabel(AppLocalizations l10n, AppReviewTag tag) {
  return switch (tag) {
    AppReviewTag.bugs => l10n.appReviewTagBugs,
    AppReviewTag.ads => l10n.appReviewTagAds,
    AppReviewTag.difficulty => l10n.appReviewTagDifficulty,
    AppReviewTag.economy => l10n.appReviewTagEconomy,
    AppReviewTag.bots => l10n.appReviewTagBots,
    AppReviewTag.performance => l10n.appReviewTagPerformance,
    AppReviewTag.other => l10n.appReviewTagOther,
  };
}

/// Five stars, filled up to [value]. They follow the reading direction, so
/// in Arabic the first star is on the right.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.value, required this.onPick});

  final int value;
  final ValueChanged<int>? onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        // 42 a star, smaller on a narrow phone so all five fit.
        final size = (constraints.maxWidth / 5 - 10).clamp(24.0, 42.0);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var star = 1; star <= 5; star++)
              Semantics(
                button: true,
                selected: star <= value,
                label: l10n.appReviewStarLabel(star),
                child: InkResponse(
                  key: ValueKey('app-review-star-$star'),
                  radius: 30,
                  onTap: onPick == null ? null : () => onPick!(star),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: AnimatedScale(
                      scale: star <= value ? 1.12 : 1,
                      duration: Duration(milliseconds: 140 + star * 40),
                      curve: Curves.easeOutBack,
                      child: GameIcon(
                        icon: AppIcons.star,
                        size: size,
                        color:
                            star <= value
                                ? CasinoColors.goldHi
                                : CasinoColors.textMuted.withValues(
                                  alpha: 0.35,
                                ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color:
            selected
                ? CasinoColors.gold.withValues(alpha: 0.22)
                : Colors.black.withValues(alpha: 0.22),
        shape: StadiumBorder(
          side: BorderSide(
            color:
                selected
                    ? CasinoColors.gold
                    : CasinoColors.gold.withValues(alpha: 0.28),
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  GameIcon(
                    icon: AppIcons.check,
                    size: 14,
                    color: CasinoColors.goldHi,
                  ),
                  const SizedBox(width: 5),
                ],
                // A long translation wraps inside the chip.
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? CasinoColors.goldHi : CasinoColors.text,
                      fontFamily: CasinoFonts.uiOf(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: CasinoColors.gold,
        fontFamily: CasinoFonts.displayOf(context),
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: CasinoColors.text.withValues(alpha: 0.85),
        fontFamily: CasinoFonts.uiOf(context),
        fontSize: 14,
        height: 1.35,
      ),
    );
  }
}
