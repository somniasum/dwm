#!/bin/sh
# dwm-setup installer for Fedora (dwm + slstatus + st, "Holy Lulz" theme).
# Usage (from the repo root): ./install.sh [--no-packages] [--no-fonts] [--no-gdm]
#   --no-packages  skip the dnf step
#   --no-fonts     skip downloading the 0xProto Nerd Font
#   --no-gdm       skip the GDM login entry (use startx from a TTY instead)
# Safe to re-run: it rebuilds everything from this repo's files.
set -eu
REPO=$(cd "$(dirname "$0")" && pwd)
SRC="${SRC:-$HOME/suckless}"
DWM_REF="${DWM_REF:-6.8}"
BIN_DIR=/usr/local/bin
DO_PACKAGES=1
DO_FONTS=1
DO_GDM=1
for arg in "$@"; do
  case "$arg" in
  --no-packages) DO_PACKAGES=0 ;;
  --no-fonts) DO_FONTS=0 ;;
  --no-gdm) DO_GDM=0 ;;
  -h | --help)
    sed -n '2,8p' "$0"
    exit 0
    ;;
  *)
    echo "unknown option: $arg (try --help)" >&2
    exit 1
    ;;
  esac
done
say() { printf '\n==> %s\n' "$*"; }
die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

# ---- sanity checks ---------------------------------------------------------
[ "$(id -u)" -ne 0 ] || die "run this as your normal user, not root (it calls sudo where needed)"
[ -r /etc/fedora-release ] || echo "warning: this does not look like Fedora; the package step may fail"
for f in dwm/config.h dwm/patches/centered-status.diff dwm/patches/restart.diff \
  slstatus/config.h st/colors.h st/apply-theme.sh \
  bin/shot bin/kbd-led bin/kbd-lock bin/volume config/xinitrc session/dwm.desktop \
  packages/fedora.txt wallpapers/dedsec-red.png; do
  [ -f "$REPO/$f" ] || die "missing $f in $REPO (is this the complete repo?)"
done

# ---- 1. packages -----------------------------------------------------------
if [ "$DO_PACKAGES" -eq 1 ]; then
  say "Installing packages"
  pkgs=$(grep -vE '^[[:space:]]*(#|$)' "$REPO/packages/fedora.txt")
  # shellcheck disable=SC2086
  sudo dnf install -y $pkgs
fi

# ---- 2. font (single source of truth: the FONT line in dwm/config.h) ---------
FONT=$(sed -n 's/^#define FONT[[:space:]]*"\([^"]*\)".*/\1/p' "$REPO/dwm/config.h")
FAMILY=${FONT%%:*}
if [ "$DO_FONTS" -eq 1 ] && ! fc-list 2>/dev/null | grep -qi "$FAMILY"; then
  case "$FAMILY" in
  0xProto*)
    say "Downloading the 0xProto Nerd Font"
    tmp=$(mktemp -d)
    if curl -fL --retry 2 -o "$tmp/0xProto.tar.xz" \
      https://github.com/ryanoasis/nerd-fonts/releases/latest/download/0xProto.tar.xz &&
      mkdir -p "$HOME/.local/share/fonts/0xProto" &&
      tar -xf "$tmp/0xProto.tar.xz" -C "$HOME/.local/share/fonts/0xProto"; then
      fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1 || true
    else
      echo "    warning: font download failed; dwm and st will fall back to the default monospace font" >&2
    fi
    rm -rf "$tmp"
    ;;
  *) echo "    note: font '$FAMILY' is not installed (install it yourself or edit FONT in dwm/config.h)" ;;
  esac
fi

# ---- 3. suckless sources (cloned only if missing) ----------------------------
say "Preparing suckless sources"
mkdir -p "$SRC"
if [ ! -d "$SRC/dwm" ]; then
  git clone https://git.suckless.org/dwm "$SRC/dwm"
  git -C "$SRC/dwm" checkout -q "$DWM_REF"
fi
[ -d "$SRC/slstatus" ] || git clone https://git.suckless.org/slstatus "$SRC/slstatus"
[ -d "$SRC/st" ] || git clone https://git.suckless.org/st "$SRC/st"
# older installs built as root and left root-owned files behind; make is run as you
if find "$SRC" ! -user "$(id -un)" -print -quit 2>/dev/null | grep -q .; then
  sudo chown -R "$(id -un):$(id -gn)" "$SRC"
fi

# ---- 4. dwm (+ every patch in dwm/patches) ------------------------------------
say "Building dwm"
cd "$SRC/dwm"
for p in "$REPO"/dwm/patches/*.diff; do
  name=$(basename "$p")
  if patch -p1 -R --dry-run -s <"$p" >/dev/null 2>&1; then
    echo "    $name: already applied"
  elif patch -p1 --dry-run -s <"$p" >/dev/null 2>&1; then
    patch -p1 -s <"$p"
    echo "    $name: applied"
  else
    die "$name does not apply to your dwm checkout. Run: git -C $SRC/dwm checkout $DWM_REF   and re-run."
  fi
done
cp "$REPO/dwm/config.h" config.h
make clean >/dev/null
make
sudo make install

# ---- 5. slstatus (temperature file and volume file filled in) ------------------
say "Building slstatus"
tz=$(grep -l '^x86_pkg_temp$' /sys/class/thermal/thermal_zone*/type 2>/dev/null | head -n1 || true)
if [ -n "$tz" ]; then temp="$(dirname "$tz")/temp"; else temp=/sys/class/thermal/thermal_zone0/temp; fi
rundir="/run/user/$(id -u)"
[ -d "$rundir" ] || rundir=/tmp # same fallback as bin/volume
iface=$(ip route show default 2>/dev/null | awk '/^default/ {print $5; exit}')
[ -n "$iface" ] || iface=eth0
echo "    temperature file: $temp"
echo "    volume file:      $rundir/volume"
cd "$SRC/slstatus"
sed -e "s|@TEMP@|$temp|g" -e "s|@RUNDIR@|$rundir|g" -e "s|@IFACE@|$iface|g" \
  "$REPO/slstatus/config.h" >config.h
make clean >/dev/null
make
sudo make install

# ---- 6. st: pristine config.def.h + palette + font -> config.h ------------------
say "Building st (Holy Lulz theme)"
cd "$SRC/st"
sh "$REPO/st/apply-theme.sh" "$SRC/st" "$FONT:antialias=true:autohint=true"
make clean >/dev/null
make
sudo make install

# ---- 7. scripts, wallpapers, ~/.xinitrc ----------------------------------------
say "Installing scripts, wallpapers and ~/.xinitrc"
for s in shot kbd-led kbd-lock volume; do
  sudo install -Dm755 "$REPO/bin/$s" "$BIN_DIR/$s"
done
mkdir -p "$HOME/.config/wallpapers" "$HOME/.cache" "$HOME/Pictures/Screenshots"
cp "$REPO"/wallpapers/*.png "$HOME/.config/wallpapers/"
[ -f "$HOME/.config/wallpaper.png" ] || cp "$REPO/wallpapers/dedsec-red.png" "$HOME/.config/wallpaper.png"
[ -f "$HOME/.xinitrc" ] && [ ! -f "$HOME/.xinitrc.bak" ] && cp "$HOME/.xinitrc" "$HOME/.xinitrc.bak"
install -m755 "$REPO/config/xinitrc" "$HOME/.xinitrc"

# ---- 8. GDM login entry --------------------------------------------------------
if [ "$DO_GDM" -eq 1 ]; then
  say "Registering the dwm session with GDM"
  sed "s|@HOME@|$HOME|g" "$REPO/session/dwm.desktop" | sudo tee /usr/share/xsessions/dwm.desktop >/dev/null
  conf=/etc/gdm/custom.conf
  if [ -f "$conf" ] && ! grep -q '^XorgEnable=true' "$conf"; then
    [ -f "$conf.bak" ] || sudo cp "$conf" "$conf.bak"
    if grep -q '^XorgEnable=' "$conf"; then
      sudo sed -i 's|^XorgEnable=.*|XorgEnable=true|' "$conf"
    elif grep -q '^#[[:space:]]*XorgEnable' "$conf"; then
      sudo sed -i 's|^#[[:space:]]*XorgEnable=.*|XorgEnable=true|' "$conf"
    elif grep -q '^\[daemon\]' "$conf"; then
      sudo sed -i '/^\[daemon\]/a XorgEnable=true' "$conf"
    else
      printf '\n[daemon]\nXorgEnable=true\n' | sudo tee -a "$conf" >/dev/null
    fi
    echo "    enabled XorgEnable=true in $conf (backup: $conf.bak)"
  fi
fi

say "Done. Already in dwm? Press Super+Shift+r to restart it (no logout). Otherwise log out and pick 'dwm' (or run startx)."
