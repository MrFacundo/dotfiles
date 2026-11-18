# Walker as KRunner replacement

Typing on an empty Plasma desktop, or pressing the KRunner shortcut, opens
[walker](https://github.com/abenz1267/walker) with the typed text.

Setup (Arch + KDE Plasma, Wayland, `yay` available):

```sh
scripts/setup-walker-krunner.sh             # install / repair, safe to re-run
scripts/setup-walker-krunner.sh --uninstall # restore KRunner, then re-login
```

## What gets set up

| Item | Location / unit |
|---|---|
| Packages | `walker-bin`, `elephant` + providers (desktopapplications, calc, symbols, files, runner, providerlist), `wl-clipboard`, `ydotool` |
| Walker config + `leaf` theme | `home/.config/walker` → `~/.config/walker` |
| Walker background service | `walker.service` → `~/.config/systemd/user/` |
| KRunner stand-in | `scripts/walker-krunner.py`, started via `home/.local/share/dbus-1/services/org.kde.krunner.service` |
| User services enabled | `elephant`, `walker`, `ydotool` |
| KRunner | `plasma-krunner.service` masked |

## How it works

1. Plasma sends typed text to `org.kde.krunner` (`ActivateAction("Query", [text])`).
2. The user D-Bus service file takes priority over the system one, so
   `walker-krunner.py` owns that name and opens walker.
3. Walker starts with an empty input, so the script pastes the collected text
   (`wl-copy` + `ydotool` Ctrl+V) and restores the previous clipboard text.

## Requirements

- Desktop setting *Desktop and Wallpaper → Icons → Typing on the desktop* =
  **Activates KRunner** (Plasma default).
- Write access to `/dev/uinput` for `ydotool` (the script warns when it is missing).
- `elephant` and its providers built with the same Go version. The setup
  script rebuilds them on mismatch; re-run it after a Go update if walker shows no results.

## Tuning

`scripts/walker-krunner.py`: `INJECT_DELAY_MS` (wait before pasting, default 180).
