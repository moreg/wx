import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/design_tokens.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WxColors.bg,
      appBar: AppBar(
        title: const Text('钱包', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18)),
        centerTitle: true,
        backgroundColor: WxColors.bg,
        elevation: 0,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: InkWell(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('账单 TODO'))),
                child: const Text('账单', style: TextStyle(fontSize: 16, color: WxColors.textPrimary)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: const <Widget>[
                SizedBox(height: 8),
                _WalletListGroup(
                  children: [
                    _WalletListItem(
                      icon: Icons.monetization_on_outlined,
                      iconColor: Color(0xFFFFC300),
                      label: '零钱',
                      trailingText: '¥0.74',
                    ),
                    _WalletListDivider(),
                    _WalletListItem(
                      icon: Icons.diamond_outlined, // Use diamond_outlined if exists, otherwise fallback
                      iconColor: Color(0xFFFFC300),
                      label: '零钱通',
                      subtitle: '收益率 0.93%',
                      trailingText: '¥0.39',
                    ),
                    _WalletListDivider(),
                    _WalletListItem(
                      icon: Icons.credit_card,
                      iconColor: Color(0xFF10AEFF),
                      label: '银行卡',
                    ),
                    _WalletListDivider(),
                    _WalletListItem(
                      icon: Icons.all_inclusive,
                      iconColor: Color(0xFFFA9D3B),
                      label: '亲属卡',
                    ),
                  ],
                ),
                SizedBox(height: 8),
                _WalletListGroup(
                  children: [
                    _WalletListItem(
                      icon: Icons.bubble_chart,
                      iconColor: Color(0xFF07C160),
                      label: '分付',
                      trailingText: '可用¥1.14',
                    ),
                  ],
                ),
                SizedBox(height: 8),
                _WalletListGroup(
                  children: [
                    _WalletListItem(
                      icon: Icons.verified_outlined,
                      iconColor: Color(0xFF07C160),
                      label: '支付分',
                    ),
                    _WalletListDivider(),
                    _WalletListItem(
                      icon: Icons.support_agent,
                      iconColor: Color(0xFF07C160),
                      label: '客服中心',
                    ),
                  ],
                ),
                SizedBox(height: WxSpace.huge),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () {},
                    child: const Text('身份信息', style: TextStyle(color: WxColors.linkBlue, fontSize: 13)),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('|', style: TextStyle(color: WxColors.divider, fontSize: 12)),
                  ),
                  InkWell(
                    onTap: () {},
                    child: const Text('支付设置', style: TextStyle(color: WxColors.linkBlue, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletListGroup extends StatelessWidget {
  final List<Widget> children;
  const _WalletListGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _WalletListItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final String? trailingText;

  const _WalletListItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.subtitle,
    this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label TODO'))),
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: <Widget>[
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  color: WxColors.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(width: 8),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFFA9D3B), // Orange subtitle
                  ),
                ),
              ],
              const Spacer(),
              if (trailingText != null) ...[
                Text(
                  trailingText!,
                  style: const TextStyle(
                    fontSize: 15,
                    color: WxColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const Icon(
                Icons.chevron_right,
                color: WxColors.textHint,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletListDivider extends StatelessWidget {
  const _WalletListDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 60),
      child: Container(
        height: 0.5,
        color: WxColors.divider,
      ),
    );
  }
}
