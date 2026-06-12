// 聊天输入栏
//
// 三种状态互斥（PLAN §7.9.10）：
// - 键盘：输入框 focus，键盘弹起
// - 表情：表情按钮点击，键盘收起，表情面板从底部弹出
// - "+"：加号按钮点击，键盘收起，6 宫格面板弹出
// - 全无：默认
//
// 三种状态之间切换时，键盘要自动收起（通过 FocusScope.unfocus 实现）。
// 表情和 "+" 面板互斥切换；再次点同一个按钮收起面板回到"全无"状态。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/design_tokens.dart';
import 'emoji_panel.dart';
import 'plus_panel.dart';

enum InputPanelState { none, emoji, plus }

class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String>? onSend;
  final VoidCallback? onLongPressVoice;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    this.onSend,
    this.onLongPressVoice,
  });

  @override
  State<ChatInputBar> createState() => ChatInputBarState();
}

class ChatInputBarState extends State<ChatInputBar> {
  InputPanelState _panelState = InputPanelState.none;

  void toggleEmoji() {
    setState(() {
      _panelState = _panelState == InputPanelState.emoji
          ? InputPanelState.none
          : InputPanelState.emoji;
    });
    if (_panelState == InputPanelState.emoji) {
      FocusScope.of(context).unfocus();
    }
  }

  void togglePlus() {
    setState(() {
      _panelState = _panelState == InputPanelState.plus
          ? InputPanelState.none
          : InputPanelState.plus;
    });
    if (_panelState == InputPanelState.plus) {
      FocusScope.of(context).unfocus();
    }
  }

  void _onTapTextField() {
    if (_panelState != InputPanelState.none) {
      setState(() => _panelState = InputPanelState.none);
    }
  }

  void _send() {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend?.call(text);
    widget.controller.clear();
    HapticFeedback.selectionClick();
  }

  void _voicePressed() {
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    if (_panelState != InputPanelState.none) {
      setState(() => _panelState = InputPanelState.none);
    }
    widget.onLongPressVoice?.call();
    _toast('按住说话');
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: WxColors.bgLight,
        border: Border(top: BorderSide(color: WxColors.divider, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: WxSpace.sm,
                vertical: WxSpace.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _voicePressed,
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: SvgPicture.asset(
                        'assets/icons/voice-outlined.svg',
                        width: 26,
                        height: 26,
                        theme: const SvgTheme(currentColor: WxColors.textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: WxSpace.xs),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 36,
                        maxHeight: 100,
                      ),
                      decoration: BoxDecoration(
                        color: WxColors.card,
                        borderRadius: BorderRadius.circular(WxRadius.sm),
                      ),
                      child: TextField(
                        controller: widget.controller,
                        focusNode: widget.focusNode,
                        onTap: _onTapTextField,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        maxLines: null,
                        style: const TextStyle(
                          fontSize: WxFontSize.bodyLarge,
                          color: WxColors.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: WxSpace.sm,
                            vertical: 8,
                          ),
                          hintText: '轻触说话转文字 ->',
                          hintStyle: TextStyle(
                            color: WxColors.textHint,
                            fontSize: 15,
                          ),
                          isDense: true,
                          suffixIcon: Icon(
                            Icons.mic_none,
                            color: WxColors.textSecondary,
                            size: 20,
                          ),
                          suffixIconConstraints: BoxConstraints(
                            minWidth: 32,
                            minHeight: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: WxSpace.xs),
                  GestureDetector(
                    onTap: toggleEmoji,
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: _panelState == InputPanelState.emoji
                          ? const Icon(Icons.keyboard, color: WxColors.textPrimary, size: 28)
                          : SvgPicture.asset(
                              'assets/icons/sticker-outlined.svg',
                              width: 26,
                              height: 26,
                              theme: const SvgTheme(currentColor: WxColors.textPrimary),
                            ),
                    ),
                  ),
                  const SizedBox(width: WxSpace.xs),
                  if (widget.controller.text.isEmpty)
                    GestureDetector(
                      onTap: togglePlus,
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: _panelState == InputPanelState.plus
                            ? const Icon(Icons.keyboard, color: WxColors.textPrimary, size: 28)
                            : SvgPicture.asset(
                                'assets/icons/plus-circle.svg',
                                width: 26,
                                height: 26,
                                theme: const SvgTheme(currentColor: WxColors.textPrimary),
                              ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(left: WxSpace.xs),
                      child: ElevatedButton(
                        onPressed: _send,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WxColors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: WxSpace.md,
                            vertical: 6,
                          ),
                          minimumSize: const Size(56, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(WxRadius.sm),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          '发送',
                          style: TextStyle(fontSize: WxFontSize.body),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_panelState != InputPanelState.none)
              SizedBox(
                height: 280,
                child: _panelState == InputPanelState.emoji
                    ? EmojiPanel(
                        onEmojiTap: (emoji) {
                          final c = widget.controller;
                          final text = c.text;
                          final selection = c.selection;
                          final start = selection.isValid
                              ? selection.start
                              : text.length;
                          final end = selection.isValid
                              ? selection.end
                              : text.length;
                          final newText = text.replaceRange(start, end, emoji);
                          c.value = TextEditingValue(
                            text: newText,
                            selection: TextSelection.collapsed(
                              offset: start + emoji.length,
                            ),
                          );
                        },
                      )
                    : PlusPanel(
                        onItemTap: (item) {
                          _toast(item);
                          setState(() => _panelState = InputPanelState.none);
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }

  void _toast(String msg) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: 320,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: WxSpace.lg,
              vertical: WxSpace.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(WxRadius.sm),
            ),
            child: Text(
              '$msg (Mock)',
              style: const TextStyle(
                color: Colors.white,
                fontSize: WxFontSize.body,
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 1200), entry.remove);
  }
}
