## Installation

1. [Install Omarchy](https://learn.omacom.io/2/the-omarchy-manual/50/getting-started)
2. Clone this project.
   ```
    git clone https://github.com/epicserve/dotfiles.git ~/.dotfiles
    cd ~/.dotfiles
    ```
3. Run the setup script.
   ```
   ./setup_omarchy.sh
   ```

### ChatGPT Desktop App

The Omarchy setup installs OpenAI's official Linux app as a native Arch package. Because OpenAI does not publish an
Arch repository, `scripts/setup_chatgpt.sh` verifies OpenAI's signed RPM repository metadata and repackages the current
RPM for `pacman`.

Run the updater directly at any time:

```
./scripts/setup_chatgpt.sh
```

Repeat runs are idempotent and do not download or rebuild the app when the installed version is current. To check
without installing, run `./scripts/setup_chatgpt.sh --check`. Quit ChatGPT before installing an available update.

## Manual Changes after Setup

### Monitors

Monitor layout lives in [config/hypr/monitors.lua](../config/hypr/monitors.lua) (symlinked to
`~/.config/hypr/monitors.lua` by setup), together with the workspace-to-monitor pinning and
`GDK_SCALE`. Use `hyprctl monitors all` to see monitor names and modes, then adjust, e.g.:

```lua
hl.monitor({ output = "DP-2", mode = "preferred", position = "0x0", scale = "auto" })
hl.monitor({ output = "DP-1", mode = "preferred", position = "3840x0", scale = "auto" })
```

On a machine with a different layout, edit that file — or skip the symlink to keep a
machine-local copy.

### Install PyCharm

1. Install PyCharm using JetBrains Toolbox App that was installed with `setup_omarchy.sh`.
2. Re-run `setup_omarchy.sh` to automatically configure:
   - Wayland support (`-Dawt.toolkit.name=WLToolkit` in VM options)
   - Docker iptables rules for remote debugging
3. Install the [macOS For All](https://plugins.jetbrains.com/plugin/13968-macos-for-all) keymap plugin.

### Zen Browser Setup

1. Settings \> Look and Feel \> Sidebar and Top Toolbar  
2. Signin with your Firefox account  
3. Open `about:config` in a new tab and search for `zen.urlbar.replace-newtab`, change it to false.  
4. Settings \> Bookmarks \> Show bookmarks toolbar, then right-click on the bookmarks toolbar \> Bookmarks Tookbar \> Only Show on New Tab
5. Create the Work and Personal spaces, assign each to its corresponding profile, and give each an icon.

### 1Password

1. Turn on the SSH Agent under Settings \> Developer

### AWS-Vault

1. Follow the AWS Vault setup [instructions](https://canopyllc.atlassian.net/wiki/spaces/CE/pages/739999785/How-to+Set+up+a+Engineer+s+MacBook+Pro) to finish this setup.

## Upgrading from Omarchy 3.x to Quattro (4.0)

The Quattro upgrade is opt-in: `omarchy-update` alone only installs 3.8.5 and shows the
invitation notification. Before running the real upgrade:

1. Commit and push `~/.dotfiles`.
2. Replace the theme symlink with a real copy — the upgrade deletes symlinked themes and then
   re-applies the current theme by name, which fails if it's missing:
   ```
   rm ~/.config/omarchy/themes/digital-nature
   cp -rL ~/.dotfiles/config/omarchy/themes/digital-nature ~/.config/omarchy/themes/digital-nature
   ```
3. If on Wi-Fi: the upgrade switches iwd → NetworkManager without converting credentials.
   Check `sudo ls /var/lib/iwd` and back up any `*.psk` files (ethernet is unaffected).
4. Expect it to uninstall packages replaced by the new shell, including **claude-code**, dust,
   lazydocker-bin, localsend, opencode, vlc, zoom, pavucontrol, playerctl, waybar, walker,
   swayosd, hypridle, hyprlock, and elephant-*.

Run it from a local terminal (Omarchy menu > Update > **Omarchy To Quattro**), read the final
WARNING output, then reboot.

After the reboot:

1. `yay -S --needed claude-code`
2. `cd ~/.dotfiles && git status` — the upgrade rewrites `config/ghostty/config` through the
   symlink; keep a single `config-file` line pointing at `~/.local/state/omarchy/current/...`.
3. `./setup_omarchy.sh`
4. `hyprctl configerrors`, test the keybindings, then remove the leftovers:
   `~/.config/{waybar,swayosd,mako,walker}.omarchy-upgrade-to-quattro.*.bak`, stale
   `~/.config/hypr/*.conf` (keep `hyprsunset.conf` and `xdph.conf`), and any
   `*.pre-dotfiles.bak` files.

## Current Gripes

1. There isn’t an official Google Drive or OneDrive client  
2. LibreOffice looks really ugly compared to Microsoft Office  
3. Sleep mode doesn't work on my desktop
4. Grammarly Desktop doesn’t exist for Linux  
5. No office application for controlling my Insta 360 camera
