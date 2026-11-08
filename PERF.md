# Performance pack for the dwm setup

Built for the i5-7400 / HD 630 / 8 GB / HDD box on Fedora 45 with the CachyOS kernel.
Tested: your three patches apply to dwm 6.8 and the new `dwm/config.h` compiles cleanly; the scripts pass
shellcheck; `igpu-boost` was run against a fake sysfs (both i915 file layouts); the installer was dry-run.
Not tested on real hardware: the sysctl/udev/systemd parts and the Steam/Proton bits. Everything is reversible.

## Apply (from your repo root, `~/Documents/dwm`)

1. Copy this pack over the repo (same layout): `cp -r dwm-perf/. ~/Documents/dwm/`
2. `./install.sh --no-packages`   rebuilds dwm and slstatus and installs the new `~/.xinitrc`
3. `tweaks/install-tweaks.sh --dry-run`   read what it will do, then run it without `--dry-run`
   Add `--packages` (gamemode, gamescope, mangohud, picom, ccache, mold...) and `--flat-mouse` if you want them.
4. Edit `/etc/fstab` by hand: add `noatime` to the options of the `/` line. The script never touches fstab.
5. `Super+Shift+r` to restart dwm, then reboot once.
6. Paste Steam launch options from `tweaks/steam-launch-options.txt`.

## What changed

| File | Change |
|---|---|
| `dwm/config.h` | Steam client on tag 8, Friends List / Settings float; `Super+F10` toggles the compositor |
| `slstatus/config.h` | new `[ gpu 1050MHz ]` item, so you can see when the HD 630 throttles |
| `config/xinitrc` | 10G Mesa shader cache for everything you launch; `powerprofilesctl set performance` if present; links the iGPU clock for the bar |
| `bin/compositor` | picom on/off/toggle (off by default, so no overhead) |
| `bin/igpu-boost` + systemd unit | pins the iGPU minimum clock to its maximum; removes the ramp-up stutter. The card still idles fully (RC6) |
| `tweaks/etc/sysctl.d/99-gaming.conf` | zram-aware swappiness, fixed-size dirty-page limits (no long HDD flush stalls), less cache eviction |
| `tweaks/etc/udev/rules.d/60-ioschedulers.rules` | BFQ on spinning disks |
| `tweaks/etc/modules-load.d/ntsync.conf` | loads NTSYNC at boot (skipped if the kernel lacks it) |
| `tweaks/home/gamemode.ini` | nice -10 and top I/O priority for games; `softrealtime` off on purpose (needs SCHED_ISO, which your kernel lacks) |
| `tweaks/home/picom.conf` | glx + vsync, no shadows/fading, and picom steps aside for fullscreen games |
| `tweaks/etc/X11/xorg.conf.d/90-flat-accel.conf` | opt-in: flat mouse acceleration |

## Check that it worked

    cat /sys/block/sda/queue/scheduler     # [bfq]
    ls /dev/ntsync                         # exists
    sudo igpu-boost status                 # min == max
    sysctl vm.swappiness                   # 150
    gamemoded -t                           # self-test; if renice fails it prints why

## Undo

`tweaks/install-tweaks.sh --revert`, then remove `noatime` from fstab if you added it. `git checkout` restores the other files.

## Not included, and why

- Bigger levers than any of this: an SSD for the Steam library/`/home`, and 16 GB RAM (the iGPU borrows system RAM).
- `mitigations=off`: a few percent on Kaby Lake, but it drops Spectre-class protection while you browse.
- dwm patches (scratchpad, pertag, actualfullscreen, swallow): features rather than performance, and they need
  hand-merging with your three custom patches, so they're better as a separate step.
- Your launcher still passes `--term=st` to j4-dmenu-desktop while `termcmd` is ghostty. Terminal apps launched
  from the menu may open the wrong terminal (or none).
