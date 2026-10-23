import 'package:cardgame/app/table_chat_controller.dart';
import 'package:cardgame/l10n/l10n_ext.dart';
import 'package:cardgame/ui/screens/home/table_social/table_social_catalog.dart';
import 'package:cardgame/ui/theme/app_icons.dart';
import 'package:cardgame/ui/theme/casino_chrome.dart';
import 'package:cardgame/ui/theme/casino_theme.dart';
import 'package:cardgame/ui/theme/felt_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

/// Quick phrases, emoji reactions and free text for the current table.
Future<void> showTableChatPanel(BuildContext context, WidgetRef ref) {
  final chat = ref.read(tableChatProvider.notifier);
  chat.setPanelOpen(true);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (_) => const _TableChatPanel(),
  ).whenComplete(() => chat.setPanelOpen(false));
}

class _TableChatPanel extends ConsumerStatefulWidget {
  const _TableChatPanel();

  @override
  ConsumerState<_TableChatPanel> createState() => _TableChatPanelState();
}

class _TableChatPanelState extends ConsumerState<_TableChatPanel> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  void _sendText() {
    if (ref.read(tableChatProvider.notifier).sendText(_textController.text)) {
      _textController.clear();
      _close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final chat = ref.read(tableChatProvider.notifier);
    final messages = ref.watch(tableChatProvider.select((s) => s.messages));
    final media = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: CasinoGlass(
            borderRadius: BorderRadius.circular(22),
            rimColor: CasinoColors.gold,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: media.size.height * 0.75),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (messages.isNotEmpty) ...[
                      _ChatLog(messages: messages),
                      const SizedBox(height: 10),
                    ],
                    _SectionLabel(l10n.quickPhrases),
                    const SizedBox(height: 6),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: 2.6,
                      children: [
                        for (final id in tablePhraseIds)
                          _PhraseChip(
                            label: tablePhraseLabel(l10n, id),
                            onTap: () {
                              chat.sendPhrase(id);
                              _close();
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (final entry in tableEmojis.entries)
                          _EmojiButton(
                            emoji: entry.value,
                            onTap: () {
                              chat.sendEmoji(entry.key);
                              _close();
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            maxLength: TableChatController.maxTextLength,
                            maxLengthEnforcement: MaxLengthEnforcement.enforced,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendText(),
                            style: const TextStyle(
                              color: CasinoColors.text,
                              fontSize: 14,
                            ),
                            cursorColor: CasinoColors.gold,
                            decoration: InputDecoration(
                              hintText: l10n.chatHint,
                              hintStyle: const TextStyle(
                                color: CasinoColors.textMuted,
                              ),
                              counterText: '',
                              isDense: true,
                              filled: true,
                              fillColor: Colors.black.withValues(alpha: 0.3),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CasinoHudButton(
                          icon: AppIcons.send,
                          tooltip: l10n.chat,
                          onPressed: _sendText,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: CasinoColors.goldSoft,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    );
  }
}

class _PhraseChip extends StatelessWidget {
  const _PhraseChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [CasinoColors.leather, CasinoColors.leatherDeep],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CasinoColors.gold.withValues(alpha: 0.35)),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CasinoColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmojiButton extends StatelessWidget {
  const _EmojiButton({required this.emoji, required this.onTap});

  final String emoji;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: SizedBox(
        width: 36,
        height: 40,
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
      ),
    );
  }
}

/// Most recent messages, newest at the bottom.
class _ChatLog extends StatelessWidget {
  const _ChatLog({required this.messages});

  final List<TableChatMessage> messages;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 130),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(14),
        ),
        child: ListView.builder(
          reverse: true,
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[messages.length - 1 - index];
            final text = switch (message.kind) {
              TableChatKind.text => message.value,
              TableChatKind.phrase => tablePhraseLabel(l10n, message.value),
              TableChatKind.emoji => tableEmojis[message.value] ?? '',
            };
            return Align(
              alignment:
                  message.mine
                      ? AlignmentDirectional.centerEnd
                      : AlignmentDirectional.centerStart,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color:
                      message.mine
                          ? CasinoColors.gold.withValues(alpha: 0.22)
                          : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color: CasinoColors.text,
                    fontSize: message.kind == TableChatKind.emoji ? 20 : 13,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Unread count dot for the chat button.
class ChatUnreadBadge extends StatelessWidget {
  const ChatUnreadBadge({super.key, required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0)
          PositionedDirectional(
            top: -4,
            end: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18),
              height: 18,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: CasinoColors.foldHi,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: CasinoColors.leatherDeep, width: 1.5),
              ),
              child: Center(
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Opponent voice status shown on their seat pill.
class VoiceSeatIndicator extends StatelessWidget {
  const VoiceSeatIndicator({super.key, required this.muted});

  final bool muted;

  @override
  Widget build(BuildContext context) {
    return HugeIcon(
      icon: muted ? AppIcons.volumeMute : AppIcons.mic,
      size: 14,
      color: muted ? CasinoColors.textMuted : const Color(0xFF7ED50E),
    );
  }
}
