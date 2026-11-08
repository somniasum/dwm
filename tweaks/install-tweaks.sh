#!/bin/sh
# dwm-setup performance tweaks. Run from anywhere inside the repo, as your normal user:
#   tweaks/install-tweaks.sh [--dry-run] [--packages] [--flat-mouse] [--no-gpu-boost] [--revert]
#
# default        sysctl + BFQ for HDDs + NTSYNC + iGPU clock pin + gamemode/picom configs + bin/compositor
# --packages     also dnf install packages/gaming.txt and packages/dev.txt
# --flat-mouse   also turn off pointer acceleration (needs an X restart)
# --no-gpu-boost skip the Intel iGPU minimum-clock pin
# --dry-run      print what would happen, change nothing
# --revert       remove everything this script installed system-wide (your ~/.config files stay)
# Safe to re-run. It never edits /etc/fstab: it only tells you what to add.
set -eu

HERE=$(cd "$(dirname "$0")" && pwd)
REPO=$(dirname "$HERE")
BIN_DIR=/usr/local/bin
CONF_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

DO_GPU=1 DO_MOUSE=0 DO_PKGS=0 DRY=0 REVERT=0
for arg in "$@"; do
	case "$arg" in
		--dry-run) DRY=1 ;;
		--packages) DO_PKGS=1 ;;
		--flat-mouse) DO_MOUSE=1 ;;
		--no-gpu-boost) DO_GPU=0 ;;
		--revert) REVERT=1 ;;
		-h | --help) sed -n '2,11p' "$0"; exit 0 ;;
		*) echo "unknown option: $arg (try --help)" >&2; exit 1 ;;
	esac
done

say() { printf '\n==> %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }
run() { if [ "$DRY" -eq 1 ]; then echo "  [dry-run] $*"; else "$@"; fi; }

[ "$(id -u)" -ne 0 ] || die "run this as your normal user, not root (it calls sudo where needed)"

# ---- revert -----------------------------------------------------------------------------------
if [ "$REVERT" -eq 1 ]; then
	say "Removing system-wide tweaks"
	if systemctl list-unit-files igpu-boost.service >/dev/null 2>&1; then
		run sudo systemctl disable --now igpu-boost.service || true
	fi
	run sudo rm -f /etc/sysctl.d/99-gaming.conf /etc/udev/rules.d/60-ioschedulers.rules \
		/etc/modules-load.d/ntsync.conf /etc/X11/xorg.conf.d/90-flat-accel.conf \
		/etc/systemd/system/igpu-boost.service "$BIN_DIR/igpu-boost" "$BIN_DIR/compositor"
	run sudo systemctl daemon-reload
	run sudo udevadm control --reload
	echo "Done. sysctl and scheduler values go back to the distro defaults at the next boot."
	echo "Left alone: $CONF_HOME/picom.conf and $CONF_HOME/gamemode.ini (delete them if you want)."
	exit 0
fi

for f in tweaks/etc/sysctl.d/99-gaming.conf tweaks/etc/udev/rules.d/60-ioschedulers.rules \
	tweaks/etc/modules-load.d/ntsync.conf tweaks/etc/X11/xorg.conf.d/90-flat-accel.conf \
	tweaks/etc/systemd/system/igpu-boost.service tweaks/home/picom.conf tweaks/home/gamemode.ini \
	bin/compositor bin/igpu-boost packages/gaming.txt packages/dev.txt; do
	[ -f "$REPO/$f" ] || die "missing $f in $REPO (is this the complete repo?)"
done

# ---- 1. packages (opt-in) ---------------------------------------------------------------------
if [ "$DO_PKGS" -eq 1 ]; then
	say "Installing gaming and dev packages"
	pkgs=$(cat "$REPO/packages/gaming.txt" "$REPO/packages/dev.txt" | grep -vE '^[[:space:]]*(#|$)')
	# shellcheck disable=SC2086
	run sudo dnf install -y $pkgs
	echo "  Steam itself comes from RPM Fusion nonfree; you already have it."
fi

# ---- 2. kernel/VM tuning ----------------------------------------------------------------------
say "VM and kernel tuning (zram-aware swappiness, HDD-friendly writeback)"
run sudo install -Dm644 "$REPO/tweaks/etc/sysctl.d/99-gaming.conf" /etc/sysctl.d/99-gaming.conf
run sudo sysctl -q -p /etc/sysctl.d/99-gaming.conf

# ---- 3. disk scheduler ------------------------------------------------------------------------
say "BFQ I/O scheduler for spinning disks"
run sudo install -Dm644 "$REPO/tweaks/etc/udev/rules.d/60-ioschedulers.rules" /etc/udev/rules.d/60-ioschedulers.rules
run sudo udevadm control --reload
run sudo udevadm trigger --subsystem-match=block --action=change

# ---- 4. NTSYNC --------------------------------------------------------------------------------
say "NTSYNC (Windows sync primitives for Proton)"
if [ -e /dev/ntsync ] || modinfo ntsync >/dev/null 2>&1; then
	run sudo install -Dm644 "$REPO/tweaks/etc/modules-load.d/ntsync.conf" /etc/modules-load.d/ntsync.conf
	run sudo modprobe ntsync
else
	echo "  this kernel has no ntsync module; skipping (needs Linux 6.14 or newer)"
fi

# ---- 5. iGPU clock pin ------------------------------------------------------------------------
if [ "$DO_GPU" -eq 1 ]; then
	say "Intel iGPU: pin the minimum clock to the maximum (removes ramp-up stutter)"
	run sudo install -Dm755 "$REPO/bin/igpu-boost" "$BIN_DIR/igpu-boost"
	run sudo install -Dm644 "$REPO/tweaks/etc/systemd/system/igpu-boost.service" /etc/systemd/system/igpu-boost.service
	run sudo systemctl daemon-reload
	run sudo systemctl enable --now igpu-boost.service
	echo "  undo with: sudo systemctl disable --now igpu-boost.service"
fi

# ---- 6. mouse (opt-in) ------------------------------------------------------------------------
if [ "$DO_MOUSE" -eq 1 ]; then
	say "Flat pointer acceleration (restart X to apply)"
	run sudo install -Dm644 "$REPO/tweaks/etc/X11/xorg.conf.d/90-flat-accel.conf" /etc/X11/xorg.conf.d/90-flat-accel.conf
fi

# ---- 7. per-user files ------------------------------------------------------------------------
say "Compositor toggle and per-user configs"
run sudo install -Dm755 "$REPO/bin/compositor" "$BIN_DIR/compositor"
run mkdir -p "$CONF_HOME"
for f in picom.conf gamemode.ini; do
	if [ -e "$CONF_HOME/$f" ]; then
		echo "  $CONF_HOME/$f already exists, left alone (compare with tweaks/home/$f)"
	else
		run install -m644 "$REPO/tweaks/home/$f" "$CONF_HOME/$f"
	fi
done

# ---- 8. report --------------------------------------------------------------------------------
say "Report"
for q in /sys/block/*/queue; do
	[ "$(cat "$q/rotational" 2>/dev/null)" = 1 ] && echo "  $(basename "$(dirname "$q")") scheduler: $(cat "$q/scheduler")  (want [bfq])"
done
[ -e /dev/ntsync ] && echo "  /dev/ntsync present" || echo "  /dev/ntsync missing"
echo "  root filesystem: $(findmnt -no FSTYPE,OPTIONS / 2>/dev/null || echo unknown)"
if ! findmnt -no OPTIONS / 2>/dev/null | grep -q noatime; then
	echo "  TODO by hand: add 'noatime' to the options of the / line in /etc/fstab, then reboot"
	echo "  (stops every file read from causing a disk write; the biggest free win on an HDD)"
fi
echo "  test gamemode with: gamemoded -t"
echo
echo "Done. Next: ./install.sh --no-packages  (rebuilds dwm + slstatus and installs the new ~/.xinitrc),"
echo "then Super+Shift+r to restart dwm, and reboot once for the disk and sysctl settings."
