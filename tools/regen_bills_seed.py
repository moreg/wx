import json
import sys

with open(r'E:\minimax项目\wx\lib\data\mock\bills_seed.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

lines = []
for b in data:
    parts = []
    parts.append(f"transTime: DateTime.parse('{b['transTime']}')")
    parts.append(f"type: {json.dumps(b.get('type',''), ensure_ascii=False)}")
    parts.append(f"counterparty: {json.dumps(b.get('counterparty',''), ensure_ascii=False)}")
    direction = b.get('direction','')
    dart_dir = 'BillDirection.neutral'
    if '收' in direction:
        dart_dir = 'BillDirection.income'
    elif '支' in direction:
        dart_dir = 'BillDirection.expense'
    product = b.get('product')
    if product:
        parts.append(f'product: {json.dumps(product, ensure_ascii=False)}')
    parts.append(f'direction: {dart_dir}')
    parts.append(f'amount: {b["amount"]}')
    parts.append(f"payMethod: {json.dumps(b.get('payMethod','零钱'), ensure_ascii=False)}")
    parts.append(f"status: {json.dumps(b.get('status','支付成功'), ensure_ascii=False)}")
    parts.append(f"transId: {json.dumps(b['transId'], ensure_ascii=False)}")
    merchant = b.get('merchantId')
    if merchant:
        parts.append(f'merchantId: {json.dumps(merchant, ensure_ascii=False)}')
    remark = b.get('remark')
    if remark:
        parts.append(f'remark: {json.dumps(remark, ensure_ascii=False)}')
    parts.append(f"category: {json.dumps(b.get('category','其他'), ensure_ascii=False)}")
    inner = ',\n      '.join(parts)
    lines.append(f'  Bill(\n    id: {json.dumps(b["transId"], ensure_ascii=False)},\n    {inner},\n  )')

with open(r'E:\minimax项目\wx\lib\data\mock\bills_seed.dart.tmp', 'w', encoding='utf-8') as f:
    f.write('// GENERATED FROM bills_seed.json — DO NOT EDIT.\n'
            '// 修改请改 bills_seed.json，然后运行 tools/regen_bills_seed.py。\n'
            'import \'../models/bill.dart\';\n\n'
            'final List<Bill> billsSeed = <Bill>[\n')
    f.write(',\n'.join(lines))
    f.write('\n];\n')
print(f'Generated {len(lines)} entries to bills_seed.dart.tmp')
