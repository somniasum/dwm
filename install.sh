#!/bin/sh
# dwm-setup installer for Fedora.
#
# Usage (from the repo root):   ./install.sh [--no-packages] [--no-gdm] [--help]
#   --no-packages   skip the dnf install step
#   --no-gdm        don't register a dwm entry with GDM / edit /etc/gdm/custom.conf
#                   (use this if you log in from a TTY with `startx`)
#
# Safe to re-run: it rebuilds dwm/slstatus/st, refreshes scripts and configs, and
# never overwrites your wallpaper or your first ~/.xinitrc backup.
set -eu

REPO=$(cd "$(dirname "$0")" && pwd)
SRC="${SRC:-$HOME/suckless}"          # where the suckless sources live
DWM_REF="${DWM_REF:-6.8}"             # dwm tag used for fresh clones (the patch targets 6.8)
BIN_DIR=/usr/local/bin                # must match the paths in dwm/config.h

DO_PACKAGES=1
DO_GDM=1
for arg in "$@"; do
	case "$arg" in
		--no-packages) DO_PACKAGES=0 ;;
		--no-gdm)      DO_GDM=0 ;;
		-h|--help)     sed -n '2,11p' "$0"; exit 0 ;;
		*)             echo "unknown option: $arg (try --help)" >&2; exit 1 ;;
	esac
done

say() { printf '\n==> %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

# ---- sanity checks ---------------------------------------------------------
[ "$(id -u)" -ne 0 ] || die "run this as your normal user, not root (it calls sudo where needed)"
[ -r /etc/fedora-release ] || echo "warning: this does not look like Fedora; the package step may fail"
for f in dwm/config.h dwm/patches/centered-status.diff slstatus/config.h \
         bin/shot bin/kbd-led bin/kbd-lock config/xinitrc session/dwm.desktop \
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

# ---- 2. suckless sources (cloned only if missing) ---------------------------
say "Fetching suckless sources (only what is missing)"
mkdir -p "$SRC"
if [ ! -d "$SRC/dwm" ]; then
	git clone https://git.suckless.org/dwm "$SRC/dwm"
	git -C "$SRC/dwm" checkout -q "$DWM_REF"
fi
[ -d "$SRC/slstatus" ] || git clone https://git.suckless.org/slstatus "$SRC/slstatus"
[ -d "$SRC/st" ]       || git clone https://git.suckless.org/st "$SRC/st"

# ---- 3. dwm ----------------------------------------------------------------
say "Building dwm"
cd "$SRC/dwm"
if ! grep -q "centered status text" dwm.c; then
	patch -p1 --dry-run < "$REPO/dwm/patches/centered-status.diff" >/dev/null 2>&1 ||
		die "the centered-status patch does not apply to your dwm checkout. Run: git -C $SRC/dwm checkout $DWM_REF   and re-run."
	patch -p1 < "$REPO/dwm/patches/centered-status.diff"
fi
cp "$REPO/dwm/config.h" config.h
make clean >/dev/null
make
sudo make install

# ---- 4. slstatus (network interface + temperature sensor auto-detected) ------
say "Building slstatus"
iface=$(ip route show default 2>/dev/null | awk '/^default/ {print $5; exit}')
[ -n "$iface" ] || iface=eth0
tz=$(grep -l '^x86_pkg_temp$' /sys/class/thermal/thermal_zone*/type 2>/dev/null | head -n1 || true)
if [ -n "$tz" ]; then temp="$(dirname "$tz")/temp"; else temp=/sys/class/thermal/thermal_zone0/temp; fi
echo "    network interface: $iface"
echo "    temperature file:  $temp"
cd "$SRC/slstatus"
sed -e "s|@IFACE@|$iface|g" -e "s|@TEMP@|$temp|g" "$REPO/slstatus/config.h" > config.h
make clean >/dev/null
make
sudo make install

# ---- 5. st terminal (only if missing) ----------------------------------------
if [ ! -x "$BIN_DIR/st" ]; then
	say "Building st"
	cd "$SRC/st"
	make
	sudo make install
fi

# ---- 6. helper scripts, wallpapers, xinitrc ----------------------------------
say "Installing scripts, wallpapers and ~/.xinitrc"
for s in shot kbd-led kbd-lock; do
	sudo install -Dm755 "$REPO/bin/$s" "$BIN_DIR/$s"
done
mkdir -p "$HOME/.config/wallpapers" "$HOME/.cache" "$HOME/Pictures/Screenshots"
cp "$REPO"/wallpapers/*.png "$HOME/.config/wallpapers/"
[ -f "$HOME/.config/wallpaper.png" ] || cp "$REPO/wallpapers/dedsec-red.png" "$HOME/.config/wallpaper.png"
[ -f "$HOME/.xinitrc" ] && [ ! -f "$HOME/.xinitrc.bak" ] && cp "$HOME/.xinitrc" "$HOME/.xinitrc.bak"
install -m755 "$REPO/config/xinitrc" "$HOME/.xinitrc"

# ---- 7. GDM login entry ------------------------------------------------------
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

say "Done. Log out, pick 'dwm' from the gear menu on the login screen (or run startx from a TTY)."
