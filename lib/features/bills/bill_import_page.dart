// 账单导入页
//
// 流程（PLAN §7.3 / §3）：
//   1. 用户点"选择文件" → file_picker 弹窗，过滤 .csv
//   2. 用 [WechatBillCsvParser] 解析 → 得到 [ParseResult]
//   3. 用 [BillClassifier] 给每条归类（预览时只展示类别，不入库）
//   4. 展示预览（前 20 条）+ 汇总"将新增 N 条，跳过 M 条重复"
//   5. 用户点"确认导入" → 用 [BillRepository.addBill] 批量入库
//      addBill 内部按 transId 去重，重复的返回 false
//   6. 弹 SnackBar Toast 报告结果
//
// 状态用 [BillImportState] 单文件管理，简洁够用。
// 数据源是 [billRepoProvider]（来自 bills-core Track），
// 通过 ref.watch 拿到当前所有账单 → 用来算"已存在 transIds"。
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/design_tokens.dart';
import '../../data/models/bill.dart';
import '../../data/repositories/bill_repo.dart';
import '../../shared/classifier.dart';
import '../../shared/csv_parser.dart';

/// 导入页状态。
///
/// 整个流程共用一个不可变状态对象（用 [copyWith] 推进），方便
/// 在 widget 树中传递和测试。
class BillImportState {
  /// 当前选中的文件名（仅展示用）。
  final String? fileName;

  /// 解析结果。
  final ParseResult? parseResult;

  /// 转换后的 [Bill]（含分类）。
  final List<Bill> previewBills;

  /// 解析时被跳过的行数。
  final int skippedParse;

  /// 与仓库中已有 transId 重复的条数（即将被跳过）。
  final int skippedDuplicate;

  /// 是否正在做 IO（pick / parse / import）。
  final bool busy;

  /// 错误信息（最近一次失败）。null = 无错。
  final String? errorMessage;

  const BillImportState({
    this.fileName,
    this.parseResult,
    this.previewBills = const <Bill>[],
    this.skippedParse = 0,
    this.skippedDuplicate = 0,
    this.busy = false,
    this.errorMessage,
  });

  static const empty = BillImportState();

  bool get hasResult => parseResult != null;
  int get willAdd => previewBills.length;

  BillImportState copyWith({
    String? fileName,
    ParseResult? parseResult,
    List<Bill>? previewBills,
    int? skippedParse,
    int? skippedDuplicate,
    bool? busy,
    String? errorMessage,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return BillImportState(
      fileName: clearResult ? null : (fileName ?? this.fileName),
      parseResult: clearResult ? null : (parseResult ?? this.parseResult),
      previewBills: clearResult
          ? const <Bill>[]
          : (previewBills ?? this.previewBills),
      skippedParse: clearResult ? 0 : (skippedParse ?? this.skippedParse),
      skippedDuplicate:
          clearResult ? 0 : (skippedDuplicate ?? this.skippedDuplicate),
      busy: busy ?? this.busy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class BillImportPage extends ConsumerStatefulWidget {
  const BillImportPage({super.key});

  @override
  ConsumerState<BillImportPage> createState() => _BillImportPageState();
}

class _BillImportPageState extends ConsumerState<BillImportPage> {
  BillImportState _state = BillImportState.empty;
  final WechatBillCsvParser _parser = const WechatBillCsvParser();
  final BillClassifier _classifier = const BillClassifier();

  // ---------------------------------------------------------------
  // 文件选择 / 解析
  // ---------------------------------------------------------------

  Future<void> _onPickFile() async {
    setState(() {
      _state = _state.copyWith(
        busy: true,
        clearError: true,
        clearResult: true,
      );
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['csv'],
        allowMultiple: false,
        withData: true, // 让 web/移动端也能直接拿 bytes
      );
      if (result == null || result.files.isEmpty) {
        // 用户取消
        if (!mounted) return;
        setState(() {
          _state = _state.copyWith(busy: false);
        });
        return;
      }
      final picked = result.files.single;
      final raw = await _readPickedFile(picked);
      if (!mounted) return;
      _onParsed(raw, picked.name);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _state.copyWith(
          busy: false,
          errorMessage: '读取文件失败：$e',
        );
      });
    }
  }

  Future<String> _readPickedFile(PlatformFile f) async {
    // 优先用 bytes（跨平台安全），再退到 path
    if (f.bytes != null) {
      return _decodeBytes(f.bytes!);
    }
    if (f.path != null) {
      return File(f.path!).readAsString();
    }
    throw StateError('文件内容为空');
  }

  String _decodeBytes(List<int> bytes) {
    // 微信 CSV 是 UTF-8（带 BOM），直接解；非 UTF-8 时尝试 GBK 回退
    try {
      return String.fromCharCodes(_stripBom(bytes));
    } catch (_) {
      return String.fromCharCodes(bytes);
    }
  }

  List<int> _stripBom(List<int> bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return bytes.sublist(3);
    }
    return bytes;
  }

  void _onParsed(String raw, String fileName) {
    final result = _parser.parse(raw);
    if (result.bills.isEmpty && result.errors.isNotEmpty) {
      setState(() {
        _state = _state.copyWith(
          busy: false,
          fileName: fileName,
          parseResult: result,
          errorMessage: '解析失败：${result.errors.first}',
        );
      });
      return;
    }
    // 拿到仓库里已存在的 transId 集合，用于预览时算"重复"数
    final repo = ref.read(billRepoProvider.notifier);
    final existing = repo.state.map((b) => b.transId).toSet();
    final converter = CsvToBillConverter(_classifier);
    final preview = <Bill>[];
    var dupCount = 0;
    for (final p in result.bills) {
      if (existing.contains(p.transId)) {
        dupCount++;
        continue;
      }
      final b = converter.convert(p, existingTransIds: <String>{});
      if (b != null) preview.add(b);
    }
    setState(() {
      _state = _state.copyWith(
        busy: false,
        fileName: fileName,
        parseResult: result,
        previewBills: preview,
        skippedParse: result.errors.length,
        skippedDuplicate: dupCount,
      );
    });
  }

  // ---------------------------------------------------------------
  // 确认导入
  // ---------------------------------------------------------------

  Future<void> _onConfirmImport() async {
    if (_state.previewBills.isEmpty) return;
    setState(() {
      _state = _state.copyWith(busy: true, clearError: true);
    });
    final notifier = ref.read(billRepoProvider.notifier);
    var added = 0;
    var skipped = 0;
    for (final b in _state.previewBills) {
      if (notifier.addBill(b)) {
        added++;
      } else {
        skipped++;
      }
    }
    if (!mounted) return;
    setState(() {
      _state = _state.copyWith(
        busy: false,
        previewBills: const <Bill>[],
        skippedDuplicate: _state.skippedDuplicate + skipped,
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '导入完成：新增 $added 条'
          '${skipped > 0 ? '，跳过 $skipped 条重复' : ''}',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: WxColors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WxColors.bg,
      appBar: AppBar(
        title: const Text('导入账单'),
        backgroundColor: WxColors.bgLight,
      ),
      body: ListView(
        padding: const EdgeInsets.all(WxSpace.lg),
        children: <Widget>[
          if (_state.errorMessage != null) _ErrorBanner(_state.errorMessage!),
          _HeaderCard(
            onPick: _onPickFile,
            busy: _state.busy,
            fileName: _state.fileName,
          ),
          const SizedBox(height: WxSpace.lg),
          if (_state.hasResult) _SummaryCard(state: _state),
          if (_state.hasResult) ...<Widget>[
            const SizedBox(height: WxSpace.lg),
            const Text(
              '预览（前 20 条）',
              style: TextStyle(
                fontSize: WxFontSize.body,
                color: WxColors.textSecondary,
              ),
            ),
            const SizedBox(height: WxSpace.sm),
            ..._buildPreviewList(),
            const SizedBox(height: WxSpace.xl),
            _ConfirmButton(
              enabled: _state.willAdd > 0 && !_state.busy,
              willAdd: _state.willAdd,
              onPressed: _onConfirmImport,
            ),
          ],
          if (_state.hasResult && _state.skippedParse > 0) ...<Widget>[
            const SizedBox(height: WxSpace.lg),
            _ParseErrorFootnote(count: _state.skippedParse),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildPreviewList() {
    final list = _state.previewBills.take(20).toList();
    if (list.isEmpty) {
      return <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(vertical: WxSpace.xl),
          alignment: Alignment.center,
          child: const Text(
            '没有可新增的账单（全部已存在）',
            style: TextStyle(color: WxColors.textSecondary),
          ),
        ),
      ];
    }
    return list
        .map((b) => _PreviewRow(bill: b))
        .toList(growable: false);
  }
}

// =====================================================================
// 子组件
// =====================================================================

class _HeaderCard extends StatelessWidget {
  final VoidCallback onPick;
  final bool busy;
  final String? fileName;
  const _HeaderCard({required this.onPick, required this.busy, this.fileName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(WxSpace.lg),
      decoration: BoxDecoration(
        color: WxColors.card,
        borderRadius: BorderRadius.circular(WxRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            '从微信支付导出的 CSV 账单导入',
            style: TextStyle(
              fontSize: WxFontSize.bodyLarge,
              fontWeight: WxFontWeight.medium,
              color: WxColors.textPrimary,
            ),
          ),
          const SizedBox(height: WxSpace.sm),
          const Text(
            '支持微信支付账单文件（含 UTF-8 BOM、约 16 行头部）。\n'
            '导入时按"交易单号"去重，已存在的不会重复入库。',
            style: TextStyle(
              fontSize: WxFontSize.small,
              color: WxColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: WxSpace.lg),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: busy ? null : onPick,
              style: ElevatedButton.styleFrom(
                backgroundColor: WxColors.green,
                foregroundColor: WxColors.textOnGreen,
                disabledBackgroundColor: WxColors.divider,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(WxRadius.md),
                ),
              ),
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(WxColors.textOnGreen),
                      ),
                    )
                  : const Icon(Icons.upload_file, size: 18),
              label: Text(
                busy
                    ? '解析中…'
                    : (fileName == null ? '选择 CSV 文件' : '重新选择'),
                style: const TextStyle(fontSize: WxFontSize.bodyLarge),
              ),
            ),
          ),
          if (fileName != null) ...<Widget>[
            const SizedBox(height: WxSpace.sm),
            Row(
              children: <Widget>[
                const Icon(
                  Icons.description_outlined,
                  size: WxIconSize.tiny,
                  color: WxColors.textSecondary,
                ),
                const SizedBox(width: WxSpace.xs),
                Expanded(
                  child: Text(
                    fileName!,
                    style: const TextStyle(
                      fontSize: WxFontSize.small,
                      color: WxColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final BillImportState state;
  const _SummaryCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(WxSpace.lg),
      decoration: BoxDecoration(
        color: WxColors.card,
        borderRadius: BorderRadius.circular(WxRadius.lg),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _SummaryItem(
              label: '将新增',
              value: state.willAdd.toString(),
              color: WxColors.income,
            ),
          ),
          Container(
            width: 0.5,
            height: 32,
            color: WxColors.divider,
          ),
          Expanded(
            child: _SummaryItem(
              label: '跳过重复',
              value: state.skippedDuplicate.toString(),
              color: WxColors.textSecondary,
            ),
          ),
          Container(
            width: 0.5,
            height: 32,
            color: WxColors.divider,
          ),
          Expanded(
            child: _SummaryItem(
              label: '解析异常',
              value: state.skippedParse.toString(),
              color: state.skippedParse > 0
                  ? WxColors.warning
                  : WxColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: TextStyle(
            fontSize: WxFontSize.titleLarge,
            fontWeight: WxFontWeight.semibold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: WxFontSize.small,
            color: WxColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final Bill bill;
  const _PreviewRow({required this.bill});

  static final NumberFormat _money = NumberFormat('#,##0.00');

  @override
  Widget build(BuildContext context) {
    final isIncome = bill.direction == BillDirection.income;
    final isExpense = bill.direction == BillDirection.expense;
    final sign = isIncome ? '+' : (isExpense ? '-' : '');
    final color = isIncome
        ? WxColors.income
        : (isExpense ? WxColors.expense : WxColors.textPrimary);
    return Container(
      margin: const EdgeInsets.only(bottom: WxSpace.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: WxSpace.md,
        vertical: WxSpace.sm,
      ),
      decoration: BoxDecoration(
        color: WxColors.card,
        borderRadius: BorderRadius.circular(WxRadius.md),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  bill.counterparty.isEmpty ? bill.type : bill.counterparty,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: WxFontSize.body,
                    fontWeight: WxFontWeight.medium,
                    color: WxColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_fmtTime(bill.transTime)} · ${bill.category}'
                  '${(bill.product ?? '').isNotEmpty ? ' · ${bill.product}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: WxFontSize.small,
                    color: WxColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: WxSpace.sm),
          Text(
            '$sign¥${_money.format(bill.amount)}',
            style: TextStyle(
              fontSize: WxFontSize.bodyLarge,
              fontWeight: WxFontWeight.semibold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} '
        '${two(t.hour)}:${two(t.minute)}';
  }
}

class _ConfirmButton extends StatelessWidget {
  final bool enabled;
  final int willAdd;
  final VoidCallback onPressed;
  const _ConfirmButton({
    required this.enabled,
    required this.willAdd,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: WxColors.green,
          foregroundColor: WxColors.textOnGreen,
          disabledBackgroundColor: WxColors.divider,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WxRadius.md),
          ),
        ),
        child: Text(
          enabled ? '确认导入 $willAdd 条' : '无可导入账单',
          style: const TextStyle(
            fontSize: WxFontSize.bodyLarge,
            fontWeight: WxFontWeight.medium,
          ),
        ),
      ),
    );
  }
}

class _ParseErrorFootnote extends StatelessWidget {
  final int count;
  const _ParseErrorFootnote({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(WxSpace.md),
      decoration: BoxDecoration(
        color: WxColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(WxRadius.md),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.warning_amber_rounded,
            color: WxColors.warning,
            size: WxIconSize.small,
          ),
          const SizedBox(width: WxSpace.sm),
          Expanded(
            child: Text(
              '有 $count 行数据无法解析，已跳过',
              style: const TextStyle(
                fontSize: WxFontSize.small,
                color: WxColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: WxSpace.lg),
      padding: const EdgeInsets.all(WxSpace.md),
      decoration: BoxDecoration(
        color: WxColors.expense.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(WxRadius.md),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.error_outline,
            color: WxColors.expense,
            size: WxIconSize.small,
          ),
          const SizedBox(width: WxSpace.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: WxFontSize.small,
                color: WxColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
