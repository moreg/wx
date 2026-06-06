import re, urllib.parse, os

less_path = r'e:\minimax项目\wx\weui-temp\src\style\icon\weui-icon.less'
with open(less_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Match class names and their mask-image url(...)
pattern = re.compile(r'\.weui-icon-([a-zA-Z0-9_-]+)\s*\{\s*mask-image:\s*url\((?:\"|\')?data:image/svg\+xml,(.*?)(?:\"|\')?\);')
matches = pattern.findall(content)

output_dir = r'e:\minimax项目\wx\assets\icons'
if not os.path.exists(output_dir):
    os.makedirs(output_dir)

extracted = []
for name, svg_data in matches:
    # URL decode
    svg_str = urllib.parse.unquote(svg_data)
    out_path = os.path.join(output_dir, f'weui-{name}.svg')
    with open(out_path, 'w', encoding='utf-8') as f:
        f.write(svg_str)
    extracted.append(name)

print('Extracted:', extracted)
