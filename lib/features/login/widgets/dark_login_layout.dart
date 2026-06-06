import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class DarkLoginColors {
  static const background = Color(0xFF111111);
  static const primaryText = Color(0xFFC9C9C9);
  static const secondaryText = Color(0xFF707070);
  static const linkText = Color(0xFF8EA0BA);
  static const divider = Color(0xFF1F1F1F);
  static const cursor = Color(0xFF07C160);
}

class DarkLoginLayout extends StatelessWidget {
  final String title;
  final List<Widget> formChildren;
  final bool buttonEnabled;
  final bool loading;
  final String buttonLabel;
  final VoidCallback? onButtonPressed;
  final VoidCallback onTabletLogin;

  const DarkLoginLayout({
    super.key,
    required this.title,
    required this.formChildren,
    required this.buttonEnabled,
    required this.loading,
    required this.buttonLabel,
    required this.onButtonPressed,
    required this.onTabletLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: DarkLoginColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final sidePadding = width * 0.05;
            final titleTop = height * 0.135;
            final formTop = height * 0.275;
            final buttonTop = height * 0.675;
            final tabletTop = height * 0.825;

            return Stack(
              children: [
                Positioned(
                  top: 18,
                  left: sidePadding - 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 28),
                    color: Colors.white,
                    splashRadius: 28,
                    onPressed: () => context.pop(),
                  ),
                ),
                Positioned(
                  top: titleTop,
                  left: 0,
                  right: 0,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: DarkLoginColors.primaryText,
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      height: 1,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                Positioned(
                  top: formTop,
                  left: sidePadding,
                  right: sidePadding,
                  child: Column(children: formChildren),
                ),
                Positioned(
                  top: buttonTop,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SizedBox(
                      width: width * 0.46,
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF242424),
                          disabledBackgroundColor: const Color(0xFF242424),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: const Color(0xFF5E5E5E),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: buttonEnabled ? onButtonPressed : null,
                        child: loading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: DarkLoginColors.primaryText,
                                ),
                              )
                            : Text(
                                buttonLabel,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: tabletTop,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: DarkLoginTextLink(
                      label: '作为平板登录',
                      fontSize: 18,
                      onTap: onTabletLogin,
                    ),
                  ),
                ),
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 20,
                  child: DarkLoginBottomLinks(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class DarkLoginRow extends StatelessWidget {
  final String label;
  final String? value;
  final String? hint;
  final TextEditingController? controller;
  final bool autofocus;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onSubmitted;

  const DarkLoginRow.display({
    super.key,
    required this.label,
    required this.value,
  }) : hint = null,
       controller = null,
       autofocus = false,
       obscureText = false,
       keyboardType = null,
       textInputAction = null,
       inputFormatters = null,
       onSubmitted = null;

  const DarkLoginRow.input({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.autofocus = false,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onSubmitted,
  }) : value = null;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: Row(
        children: [
          SizedBox(
            width: 106,
            child: Text(
              label,
              style: const TextStyle(
                color: DarkLoginColors.primaryText,
                fontSize: 18,
                height: 1,
              ),
            ),
          ),
          Expanded(
            child: value != null
                ? Text(
                    value!,
                    style: const TextStyle(
                      color: DarkLoginColors.primaryText,
                      fontSize: 18,
                      height: 1,
                    ),
                  )
                : TextField(
                    controller: controller,
                    autofocus: autofocus,
                    obscureText: obscureText,
                    keyboardType: keyboardType,
                    cursorColor: DarkLoginColors.cursor,
                    cursorWidth: 2,
                    textInputAction: textInputAction,
                    inputFormatters: inputFormatters,
                    onSubmitted: onSubmitted,
                    style: const TextStyle(
                      color: DarkLoginColors.primaryText,
                      fontSize: 18,
                      height: 1,
                    ),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: hint,
                      hintStyle: const TextStyle(
                        color: Color(0xFF5A5A5A),
                        fontSize: 18,
                        height: 1,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class DarkLoginHairline extends StatelessWidget {
  const DarkLoginHairline({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 0.6,
      color: DarkLoginColors.divider,
    );
  }
}

class DarkLoginTextLink extends StatelessWidget {
  final String label;
  final double fontSize;
  final VoidCallback onTap;

  const DarkLoginTextLink({
    super.key,
    required this.label,
    required this.fontSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: DarkLoginColors.linkText,
            fontSize: fontSize,
            height: 1,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class DarkLoginBottomLinks extends StatelessWidget {
  const DarkLoginBottomLinks({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '找回密码',
          style: TextStyle(
            color: DarkLoginColors.linkText,
            fontSize: 14,
            height: 1,
          ),
        ),
        _VerticalDivider(),
        Text(
          '导出聊天记录',
          style: TextStyle(
            color: DarkLoginColors.linkText,
            fontSize: 14,
            height: 1,
          ),
        ),
        _VerticalDivider(),
        Text(
          '更多',
          style: TextStyle(
            color: DarkLoginColors.linkText,
            fontSize: 14,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      color: DarkLoginColors.divider,
    );
  }
}
