# dwm

A lightweight, black-and-red dwm (X11) desktop for Fedora, inspired by Watch Dogs 2 / DedSec.
No compositor, no daemons, one command to rebuild it on a fresh install.

- **dwm** with a centered status bar, black theme, red accent, restart-in-place (`Super+Shift+r`)
- **slstatus**: `[ cpu 28% ] [ ram 34% ] [ 40C ] [ vol 45% ] [ Sun 25 Oct  01:19 ]`
- **st** terminal with the "Holy Lulz" palette (every colour readable on the background)
- **Launcher**: `j4-dmenu-desktop` + dmenu (every installed app, most-used first)
- **Screenshots** (`scrot` + `xclip`), **wallpaper** (`feh`), **volume/media keys** (`wpctl`, `playerctl`)
- **Keyboard tools**: LED toggle and a timed keyboard lock
- **Font**: 0xProto Nerd Font Mono, downloaded by the installer

## Install on a new Fedora system

```bash
sudo dnf install git
git clone https://github.com/somniasum/dwm.git
cd dwm
./install.sh        # 'permission denied'? run: chmod +x install.sh   (or: sh install.sh)
```

Log out and choose **dwm** from the gear menu on the login screen. Prefer a TTY login? Run
`./install.sh --no-gdm`, then `startx` from a TTY.

Options: `--no-packages` (skip dnf), `--no-fonts` (skip the font download), `--no-gdm` (skip the
login-screen entry). Re-running is safe; update with `git pull && ./install.sh`.
Already inside dwm? After a re-run press **Super+Shift+r** and the new build loads without logging out.

## Repo layout

```
install.sh                  installer (run from the repo root)
packages/fedora.txt         dnf packages
dwm/config.h                dwm config: colors, font, keys, launcher
dwm/patches/                *.diff, every patch here is applied in order:
                              centered-status.diff  status text centered in the bar
                              restart.diff          Super+Shift+r restarts dwm in place
slstatus/config.h           status bar items (temperature + volume paths filled in by the installer)
st/colors.h                 the st colour table (palette + cursor + default colours)
st/apply-theme.sh           builds st's config.h from the pristine config.def.h + colors.h + font
bin/                        shot, kbd-led, kbd-lock, volume  -> /usr/local/bin
config/xinitrc              -> ~/.xinitrc
session/dwm.desktop         GDM session entry
wallpapers/                 default wallpaper(s), copied to ~/.config/wallpapers
```

The suckless sources are cloned to `~/suckless` (dwm is pinned to tag 6.8, which the patches target).
The font is set once, in the `FONT` line of `dwm/config.h`; dmenu and st use the same one.

## Keys (Super = Windows key)

| Keys                           | Action                                 |
|--------------------------------|----------------------------------------|
| Super+Return                   | terminal                               |
| Super+d                        | app launcher                           |
| Super+Shift+d                  | run any command from `$PATH`           |
| Print / Super+s                | screenshot: select an area             |
| Shift+Print / Super+Shift+s    | screenshot: full screen                |
| Super+Print                    | screenshot: focused window             |
| Super+F1 / F2 / F3             | mute / volume down / volume up         |
| Super+F4                       | mute microphone                        |
| Super+F5 / F6 / F7             | previous / play-pause / next track     |
| Super+F8                       | toggle keyboard LEDs (`xset led`)      |
| Super+F9                       | lock (disable) the keyboard, see below |
| Super+q                        | close window                           |
| Super+Shift+q                  | quit dwm                               |
| Super+Shift+r                  | restart dwm (keeps your windows)       |
| Super+j / k                    | focus next / previous                  |
| Super+h / l                    | shrink / grow master area              |
| Super+i / o                    | more / fewer windows in master         |
| Super+Space                    | promote window to master               |
| Super+Shift+Space              | toggle floating                        |
| Super+t / m                    | tile / monocle                         |
| Super+b                        | hide/show bar                          |
| Super+1-9, Super+Shift+1-9     | go to / move window to workspace       |
| Super+Tab, Super+0             | previous workspace, show all           |
| Super+drag                     | left = move, right = resize            |
| Middle-click workspace numbers | unlock the keyboard                    |

Media keys on your keyboard (volume, mic, play/next/prev) work too.

### Volume in the bar

`bin/volume` changes the volume with `wpctl`, then writes the result (`45%` or `mute`) to
`/run/user/<uid>/volume`. slstatus just reads that file, so the bar never polls PipeWire and never
forks a process. Because the file is only updated by the volume keys, changes made elsewhere
(pavucontrol, an app's slider) do not show up. To track those too, uncomment the
`volume watch` line in `config/xinitrc` (needs `pulseaudio-utils` for `pactl`; one idle process).

### Keyboard lock

`Super+F9` disables every keyboard device (cleaning, cat on the desk). A disabled keyboard cannot
send its own unlock key, so it unlocks by itself after 120 seconds (`KBD_LOCK_SECONDS=300 kbd-lock lock`
changes that), or immediately when you **middle-click the workspace numbers** in the bar.

## Terminal theme (st, "Holy Lulz")

The palette in `st/colors.h` is sampled from the DedSec "Holy Lulz" wallpaper (red `#ff2a2a`,
greys, whites) and follows three rules so no text can disappear:

- colour 0 ("black") is a visible grey, never the same as the background
- every other colour has at least 4.5:1 contrast against the background (colour 0: 3:1)
- colours keep their usual meaning: red = error, green = success, yellow = warning, blue = directories

The table must keep exactly 260 entries (16 colours, then the cursor, reverse cursor, default
foreground and default background at 256-259). `st/apply-theme.sh` rebuilds `config.h` from st's pristine
`config.def.h` every time, and the build fails loudly if the table is the wrong size.
To tweak a colour, edit `st/colors.h` and re-run `./install.sh --no-packages --no-fonts --no-gdm`.

## Customising

- Colors and keys: `dwm/config.h` (`C_ACC` is the red accent), then re-run the installer and press Super+Shift+r.
- Status bar items: `slstatus/config.h`.
- Wallpaper: `cp ~/.config/wallpapers/<name>.png ~/.config/wallpaper.png`, then
  `feh --bg-fill ~/.config/wallpaper.png`. An image at your exact screen resolution loads fastest.
- Tearing in video or games: uncomment the `picom` line in `config/xinitrc`.

## Troubleshooting

- **dwm missing on the login screen**: `ls /usr/share/xsessions/dwm.desktop`, check that
  `/etc/gdm/custom.conf` has `XorgEnable=true` under `[daemon]`, then `sudo systemctl restart gdm`.
  Or use a TTY and `startx`.
- **`[ vol -- ]`**: `wpctl get-volume @DEFAULT_AUDIO_SINK@` must work (package `wireplumber`); then run `volume sync`.
- **`[ --C ]`**: find the right file with `grep . /sys/class/thermal/thermal_zone*/type`, edit
  `~/suckless/slstatus/config.h`, then `make && sudo make install` in that folder.
- **Patch does not apply**: `git -C ~/suckless/dwm checkout 6.8`, then re-run the installer.
- **Icons or letters look wrong in the bar**: the Nerd Font download failed; re-run `./install.sh --no-packages`.

The DedSec wallpapers are Watch Dogs artwork.
