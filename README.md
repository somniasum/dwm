# dwm-setup

A lightweight, black-and-red dwm (X11) desktop for Fedora. No compositor, no daemons, one
command to rebuild it on a fresh install.

- **dwm** with a centered status bar (patch included), black theme, red accent
- **slstatus**: `[ ctOS ] [ cpu 3% ] [ ram 41% ] [ 52C ] [ rx 12K tx 3K ] [ vpn 10.10.14.7 ] [ up 3h 12m ] [ Sat 24 Oct  21:07 ]`
- **Launcher**: `j4-dmenu-desktop` + dmenu (every installed app, most-used first)
- **Screenshots** (`scrot` + `xclip`), **wallpaper** (`feh`), **volume/media keys** (`wpctl`, `playerctl`)
- **Keyboard tools**: LED toggle and a timed keyboard lock
- **st** terminal

## Install on a new Fedora system

```bash
sudo dnf install git          # if git is not there yet
git clone https://github.com/<you>/dwm-setup.git
cd dwm-setup
./install.sh        # 'permission denied'? run: chmod +x install.sh   (or: sh install.sh)
```

Log out and choose **dwm** from the gear menu on the login screen. Prefer a TTY login? Run
`./install.sh --no-gdm`, then `startx` from a TTY.

Options: `--no-packages` (skip dnf) and `--no-gdm` (skip the login-screen entry). Re-running is
safe; update with `git pull && ./install.sh`.

## Repo layout

```
install.sh                  installer (run from the repo root)
packages/fedora.txt         dnf packages
dwm/config.h                dwm config: colors, keys, launcher
dwm/patches/                centered-status.diff (status text centered in the bar)
slstatus/config.h           status bar items (interface/temp filled in by the installer)
bin/                        shot, kbd-led, kbd-lock  -> /usr/local/bin
config/xinitrc              -> ~/.xinitrc
session/dwm.desktop         GDM session entry
wallpapers/                 dedsec-red (default), dedsec, ctos-red
```

The suckless sources are cloned to `~/suckless` (dwm is pinned to tag 6.8, which the patch targets).

## Keys (Super = Windows key)

| Keys | Action |
|---|---|
| Super+Return | terminal |
| Super+d | app launcher |
| Super+Shift+d | run any command from `$PATH` |
| Print / Super+s | screenshot: select an area |
| Shift+Print / Super+Shift+s | screenshot: full screen |
| Super+Print | screenshot: focused window |
| Super+F1 / F2 / F3 | mute / volume down / volume up |
| Super+F4 | mute microphone |
| Super+F5 / F6 / F7 | previous / play-pause / next track |
| Super+F8 | toggle keyboard LEDs (`xset led`) |
| Super+F9 | lock (disable) the keyboard, see below |
| Super+q | close window |
| Super+Shift+q | quit dwm |
| Super+j / k | focus next / previous |
| Super+h / l | shrink / grow master area |
| Super+i / o | more / fewer windows in master |
| Super+Space | promote window to master |
| Super+Shift+Space | toggle floating |
| Super+t / m | tile / monocle |
| Super+b | hide/show bar |
| Super+1-9, Super+Shift+1-9 | go to / move window to workspace |
| Super+Tab, Super+0 | previous workspace, show all |
| Super+drag | left = move, right = resize |
| Middle-click workspace numbers | unlock the keyboard |

Media keys on your keyboard (volume, mic, play/next/prev) work too.

### Keyboard lock

`Super+F9` disables every keyboard device (cleaning, cat on the desk). A disabled keyboard cannot
send its own unlock key, so it unlocks by itself after 120 seconds (`KBD_LOCK_SECONDS=300 kbd-lock lock`
changes that), or immediately when you **middle-click the workspace numbers** in the bar.

## Customising

- Colors and keys: `dwm/config.h` (`C_ACC` is the red accent), then re-run `./install.sh --no-packages`.
- Status bar items: `slstatus/config.h`. The VPN field watches `tun0`.
- Wallpaper: `cp ~/.config/wallpapers/ctos-red.png ~/.config/wallpaper.png` and log in again,
  or apply instantly with `feh --bg-fill ~/.config/wallpaper.png`. Use an image at your exact screen
  resolution to save memory.
- Tearing in video or games: uncomment the `picom` line in `config/xinitrc`.

## Troubleshooting

- **dwm missing on the login screen**: `ls /usr/share/xsessions/dwm.desktop`, check that
  `/etc/gdm/custom.conf` has `XorgEnable=true` under `[daemon]`, then `sudo systemctl restart gdm`.
  Or use a TTY and `startx`.
- **`temp` or `vpn` shows `--`**: find the right file with `grep . /sys/class/thermal/thermal_zone*/type`
  and the interface with `ip route show default`, edit `~/suckless/slstatus/config.h`, then
  `make && sudo make install` in that folder.
- **Patch does not apply**: `git -C ~/suckless/dwm checkout 6.8`, then re-run the installer.

## Publishing this repo

```bash
cd dwm-setup
git init && git add . && git commit -m "dwm setup"
git branch -M main
git remote add origin git@github.com:<you>/dwm-setup.git
git push -u origin main
```

The DedSec wallpapers are Watch Dogs artwork. If you make the repo public and would rather not
host them, delete the two `dedsec*.png` files and change `dedsec-red.png` to `ctos-red.png` in
`install.sh`.
