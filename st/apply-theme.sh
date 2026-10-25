#!/bin/sh
# apply-theme.sh <st-source-dir> <font-string>
# Builds <st-source-dir>/config.h from the pristine config.def.h, with this repo's palette and font.
# Always starts from config.def.h, so it is idempotent and never leaves a half-edited config.h.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
dir=${1:?usage: apply-theme.sh <st-source-dir> <font-string>}
font=${2:?usage: apply-theme.sh <st-source-dir> <font-string>}
def="$dir/config.def.h"

[ -f "$def" ] || { echo "apply-theme: $def not found" >&2; exit 1; }
grep -q '^static const char \*colorname\[\] = {' "$def" || { echo "apply-theme: colorname[] not found in $def" >&2; exit 1; }
for d in 'defaultfg = 258' 'defaultbg = 259' 'defaultcs = 256' 'defaultrcs = 257'; do
	grep -q "$d;" "$def" || { echo "apply-theme: st changed its default colour indexes ($d missing); update st/colors.h" >&2; exit 1; }
done

# swap the whole colorname[] block for ours, and set the font
awk -v repl="$here/colors.h" '
	/^static const char \*colorname\[\] = \{/ { while ((getline line < repl) > 0) print line; skip = 1; next }
	skip && /^\};/ { skip = 0; next }
	!skip { print }
' "$def" | sed "s|^static char \*font = .*|static char *font = \"$font\";|" > "$dir/config.h"

grep -q 'colorname_must_have_260_entries' "$dir/config.h" || { echo "apply-theme: palette was not applied" >&2; exit 1; }
echo "st theme applied to $dir/config.h"
