#!/usr/bin/env python3
"""Apply the DEDSEC / Holy Lulz palette to a conventional suckless st config."""
from pathlib import Path
import re
import sys

path = Path(sys.argv[1] if len(sys.argv) > 1 else "config.h")
data = path.read_text()

# Only change the font if the upstream config has the conventional declaration.
font = re.compile(r'^(\s*static\s+char\s+\*font\s*=\s*)"[^"]*"(\s*;)', re.M)
data, nfont = font.subn(r'\1"DejaVu Sans Mono:size=10"\2', data, count=1)
if nfont == 0:
    print("DEDSEC theme: font declaration not found; keeping existing font", file=sys.stderr)

palette = [
    "#080808", "#ff1717", "#a00000", "#ff4545",
    "#777777", "#c00000", "#aaaaaa", "#e5e5e5",
    "#555555", "#ff3333", "#d00000", "#ff6666",
    "#999999", "#ff1744", "#cccccc", "#ffffff",
]
array = re.search(r'(static\s+const\s+char\s+\*colorname\[\]\s*=\s*\{)(.*?)(\n\s*\};)', data, re.S)
if not array:
    raise SystemExit(f"error: could not locate colorname[] in {path}; refusing to modify config")
body = array.group(2)
# Upstream st commonly uses a sequential list, but forks may add comments,
# index designators, or different indentation. Replace the first 16 hex color
# string literals inside the array regardless of line layout.
entries = list(re.finditer(r'"#[0-9a-fA-F]{3,8}"', body))
if len(entries) >= 16:
    # Standard st palette: preserve the array structure and replace first 16 colors.
    for entry, color in reversed(list(zip(entries[:16], palette))):
        body = body[:entry.start()] + '"' + color + '"' + body[entry.end():]
else:
    # Some st forks define only a few colors. Expand the palette to 16 indexed
    # ANSI colors, which is what defaultfg/defaultbg and terminal color codes use.
    indent_match = re.search(r'\n([ \t]*)', body)
    indent = indent_match.group(1) if indent_match else '\t'
    body = '\n' + ',\n'.join(
        f'{indent}[{i}] = "{color}"' for i, color in enumerate(palette)
    ) + '\n'

data = data[:array.start(2)] + body + data[array.end(2):]
# Forks of st differ in how they name default foreground/background colors.
# Set these only when the conventional declarations exist; do not reject a
# valid fork merely because it uses different names or hard-coded defaults.
for name, value in (("defaultfg", "7"), ("defaultbg", "0")):
    pattern = re.compile(r'^(\s*static\s+unsigned\s+int\s+' + name + r'\s*=\s*)[^;]+;', re.M)
    data, count = pattern.subn(lambda m, v=value: m.group(1) + v + ';', data, count=1)
    if count == 0:
        print(f"DEDSEC theme: {name} declaration not found; keeping fork defaults", file=sys.stderr)

path.write_text(data)
print(f"Applied DEDSEC / Holy Lulz palette to {path}")
