// 账单筛选页 (S11)
//
// 4 类筛选条件：
//   1. 时间范围：起始/结束日期（"全部" / "本月" / "近 3 个月" / 自定义）
//   2. 收/支：全部 / 支出 / 收入 / 其他
//   3. 交易类型：自动从 mock 数据中提取全部出现过的 type
//   4. 金额区间：最小值 ~ 最大值（¥ 文本输入）
//
// 选完后按"确定"写入 [billFilterProvider]，列表页自动 rebuild。
// "重置"恢复 BillFilter 默认值。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/design_tokens.dart';
import '../../data/models/bill.dart';
import '../../data/repositories/bill_repo.dart';

class BillFilterPage extends ConsumerStatefulWidget {
  const BillFilterPage({super.key});

  @override
  ConsumerState<BillFilterPage> createState() => _BillFilterPageState();
}

class _BillFilterPageState extends ConsumerState<BillFilterPage> {
  late BillFilter _draft;
  final TextEditingController _minCtrl = TextEditingController();
  final TextEditingController _maxCtrl = TextEditingController();

  static const List<_DatePreset> _datePresets = [
    _DatePreset('全部', null, null),
    _DatePreset('本月', _PresetKind.thisMonth, null),
    _DatePreset('近 3 个月', _PresetKind.threeMonths, null),
    _DatePreset('近 6 个月', _PresetKind.sixMonths, null),
  ];

  @override
  void initState() {
    super.initState();
    _draft = ref.read(billFilterProvider);
    if (_draft.minAmount != null) {
      _minCtrl.text = _draft.minAmount!.toStringAsFixed(0);
    }
    if (_draft.maxAmount != null) {
      _maxCtrl.text = _draft.maxAmount!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  void _onDatePreset(_DatePreset p) {
    setState(() {
      if (p.startKind == null && p.endKind == null) {
        _draft = _draft.copyWith(clearStart: true, clearEnd: true);
      } else {
        final now = DateTime.now();
        DateTime? start;
        DateTime? end;
        if (p.startKind == _PresetKind.thisMonth) {
          start = DateTime(now.year, now.month, 1);
          end = DateTime(now.year, now.month + 1, 1)
              .subtract(const Duration(seconds: 1));
        } else if (p.startKind == _PresetKind.threeMonths) {
          start = DateTime(now.year, now.month - 2, 1);
          end = DateTime(now.year, now.month + 1, 1)
              .subtract(const Duration(seconds: 1));
        } else if (p.startKind == _PresetKind.sixMonths) {
          start = DateTime(now.year, now.month - 5, 1);
          end = DateTime(now.year, now.month + 1, 1)
              .subtract(const Duration(seconds: 1));
        }
        _draft = _draft.copyWith(startDate: start, endDate: end);
      }
    });
  }

  void _onPickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _draft.startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _draft = _draft.copyWith(startDate: picked);
    });
  }

  void _onPickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _draft.endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _draft = _draft.copyWith(
        endDate: DateTime(picked.year, picked.month, picked.day, 23, 59, 59),
      );
    });
  }

  void _onDirectionChanged(BillDirection? d) {
    setState(() {
      _draft = _draft.copyWith(
        direction: d,
        clearDirection: d == null,
      );
    });
  }

  void _onTypeChanged(String? t) {
    setState(() {
      _draft = _draft.copyWith(type: t, clearType: t == null);
    });
  }

  void _onApplyAmount() {
    final min = double.tryParse(_minCtrl.text.trim());
    final max = double.tryParse(_maxCtrl.text.trim());
    setState(() {
      _draft = _draft.copyWith(
        minAmount: min,
        maxAmount: max,
      );
    });
  }

  void _onReset() {
    setState(() {
      _draft = const BillFilter();
      _minCtrl.clear();
      _maxCtrl.clear();
    });
  }

  void _onApply() {
    ref.read(billFilterProvider.notifier).state = _draft;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bills = ref.watch(billRepoProvider);
    // 自动从数据中提取全部出现过的 type（去重 + 排序）
    final allTypes = <String>{
      for (final b in bills) b.type,
    }.toList()
      ..sort();

    return Scaffold(
      backgroundColor: WxColors.bg,
      appBar: AppBar(
        title: const Text('筛选账单'),
        actions: [
          TextButton(
            onPressed: _onReset,
            child: const Text('重置',
                style: TextStyle(
                  color: WxColors.linkBlue,
                  fontSize: WxFontSize.body,
                )),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(WxSpace.lg),
        children: [
          _FilterGroup(
            title: '时间范围',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: WxSpace.sm,
                  runSpacing: WxSpace.sm,
                  children: [
                    for (final p in _datePresets)
                      _ChipButton(
                        label: p.label,
                        selected: _matchesPreset(p),
                        onTap: () => _onDatePreset(p),
                      ),
                  ],
                ),
                const SizedBox(height: WxSpace.md),
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: '起始',
                        value: _draft.startDate,
                        onTap: _onPickStart,
                      ),
                    ),
                    const SizedBox(width: WxSpace.sm),
                    Expanded(
                      child: _DateField(
                        label: '截止',
                        value: _draft.endDate,
                        onTap: _onPickEnd,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          _FilterGroup(
            title: '收/支',
            child: Wrap(
              spacing: WxSpace.sm,
              runSpacing: WxSpace.sm,
              children: [
                _ChipButton(
                  label: '全部',
                  selected: _draft.direction == null,
                  onTap: () => _onDirectionChanged(null),
                ),
                _ChipButton(
                  label: '支出',
                  selected: _draft.direction == BillDirection.expense,
                  onTap: () => _onDirectionChanged(BillDirection.expense),
                ),
                _ChipButton(
                  label: '收入',
                  selected: _draft.direction == BillDirection.income,
                  onTap: () => _onDirectionChanged(BillDirection.income),
                ),
                _ChipButton(
                  label: '其他',
                  selected: _draft.direction == BillDirection.neutral,
                  onTap: () => _onDirectionChanged(BillDirection.neutral),
                ),
              ],
            ),
          ),

          _FilterGroup(
            title: '交易类型',
            child: Wrap(
              spacing: WxSpace.sm,
              runSpacing: WxSpace.sm,
              children: [
                _ChipButton(
                  label: '全部',
                  selected: _draft.type == null,
                  onTap: () => _onTypeChanged(null),
                ),
                for (final t in allTypes)
                  _ChipButton(
                    label: t,
                    selected: _draft.type == t,
                    onTap: () => _onTypeChanged(t),
                  ),
              ],
            ),
          ),

          _FilterGroup(
            title: '金额区间',
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    onChanged: (_) => _onApplyAmount(),
                    decoration: _inputDeco('最小 ¥', '不限'),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: WxSpace.sm),
                  child: Text('~',
                      style: TextStyle(
                        color: WxColors.textSecondary,
                        fontSize: WxFontSize.bodyLarge,
                      )),
                ),
                Expanded(
                  child: TextField(
                    controller: _maxCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    onChanged: (_) => _onApplyAmount(),
                    decoration: _inputDeco('最大 ¥', '不限'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(WxSpace.lg),
          child: SizedBox(
            height: 44,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: WxColors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(WxRadius.sm),
                ),
              ),
              onPressed: _onApply,
              child: const Text('确 定',
                  style: TextStyle(
                    fontSize: WxFontSize.bodyLarge,
                    color: Colors.white,
                    fontWeight: WxFontWeight.medium,
                    letterSpacing: 4,
                  )),
            ),
          ),
        ),
      ),
    );
  }

  bool _matchesPreset(_DatePreset p) {
    final now = DateTime.now();
    if (p.startKind == null && p.endKind == null) {
      return _draft.startDate == null && _draft.endDate == null;
    }
    if (p.startKind == _PresetKind.thisMonth) {
      final expectedStart = DateTime(now.year, now.month, 1);
      final expectedEnd = DateTime(now.year, now.month + 1, 1)
          .subtract(const Duration(seconds: 1));
      return _draft.startDate == expectedStart && _draft.endDate == expectedEnd;
    }
    if (p.startKind == _PresetKind.threeMonths) {
      final expectedStart = DateTime(now.year, now.month - 2, 1);
      final expectedEnd = DateTime(now.year, now.month + 1, 1)
          .subtract(const Duration(seconds: 1));
      return _draft.startDate == expectedStart && _draft.endDate == expectedEnd;
    }
    if (p.startKind == _PresetKind.sixMonths) {
      final expectedStart = DateTime(now.year, now.month - 5, 1);
      final expectedEnd = DateTime(now.year, now.month + 1, 1)
          .subtract(const Duration(seconds: 1));
      return _draft.startDate == expectedStart && _draft.endDate == expectedEnd;
    }
    return false;
  }

  InputDecoration _inputDeco(String hint, String placeholder) {
    return InputDecoration(
      hintText: hint,
      helperText: '',
      filled: true,
      fillColor: WxColors.card,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: WxSpace.md, vertical: WxSpace.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(WxRadius.md),
        borderSide: const BorderSide(color: WxColors.divider, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(WxRadius.md),
        borderSide: const BorderSide(color: WxColors.divider, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(WxRadius.md),
        borderSide: const BorderSide(color: WxColors.green, width: 1),
      ),
      hintStyle: const TextStyle(
        color: WxColors.textHint,
        fontSize: WxFontSize.body,
      ),
    );
  }
}

// =====================================================================
// Helper widgets
// =====================================================================

class _FilterGroup extends StatelessWidget {
  final String title;
  final Widget child;
  const _FilterGroup({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: WxSpace.lg),
      padding: const EdgeInsets.all(WxSpace.lg),
      decoration: BoxDecoration(
        color: WxColors.card,
        borderRadius: BorderRadius.circular(WxRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                fontSize: WxFontSize.bodyLarge,
                color: WxColors.textPrimary,
                fontWeight: WxFontWeight.medium,
              )),
          const SizedBox(height: WxSpace.md),
          child,
        ],
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WxRadius.round),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: WxSpace.md, vertical: WxSpace.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? WxColors.green : WxColors.bgLight,
          borderRadius: BorderRadius.circular(WxRadius.round),
          border: Border.all(
            color: selected ? WxColors.green : WxColors.divider,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: WxFontSize.small,
            color: selected ? Colors.white : WxColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WxRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: WxSpace.md, vertical: WxSpace.md,
        ),
        decoration: BoxDecoration(
          color: WxColors.bgLight,
          borderRadius: BorderRadius.circular(WxRadius.md),
          border: Border.all(color: WxColors.divider, width: 0.5),
        ),
        child: Row(
          children: [
            Text(label,
                style: const TextStyle(
                  fontSize: WxFontSize.small,
                  color: WxColors.textSecondary,
                )),
            const SizedBox(width: WxSpace.sm),
            Expanded(
              child: Text(
                value == null ? '不限' : DateFormat('yyyy-MM-dd').format(value!),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: WxFontSize.body,
                  color: WxColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.calendar_today_rounded,
                size: 14, color: WxColors.textHint),
          ],
        ),
      ),
    );
  }
}

enum _PresetKind { thisMonth, threeMonths, sixMonths }

class _DatePreset {
  final String label;
  final _PresetKind? startKind;
  final _PresetKind? endKind;
  const _DatePreset(this.label, this.startKind, this.endKind);
}
