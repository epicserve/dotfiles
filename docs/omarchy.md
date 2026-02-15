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

## Manual Changes after Setup

### Hyperland Config Changes

1. If you have multiple monitors you'll need to edit `~/.config/hypr/monitors.conf` and change the settings to
   something like the following. You can use `hyprctl monitors` to see the names of your monitors. Also consult the
   [Omarchy documentation](https://learn.omacom.io/2/the-omarchy-manual/86/monitors?search=monitor#monitors).
   ```  
   monitor=DP-2,preferred,0x0,auto  
   monitor=DP-1,preferred,3840x0,auto
   ```

### DMS (DankMaterialShell) Configuration

This setup uses DMS for panel, notifications, lock screen, and polkit instead of the traditional waybar/mako/hyprlock stack.

**What DMS Provides:**
- Integrated panel with workspace indicators, system tray, clock, etc.
- Material Design-inspired notifications
- Modern lock screen
- Polkit authentication agent
- All components themed consistently

**Post-Installation Tasks:**
1. Log out and log back into Hyprland for DMS to start
2. Verify workspace 1-5 appear on DP-1, 6-10 on DP-2
3. Test notifications: `notify-send 'Test' 'DMS Notifications'`
4. Test lock screen with configured binding (likely Super+L)
5. Customize DMS theme if desired (check DMS documentation)

**Service Management:**
```bash
# Check DMS status
systemctl --user status dms

# View logs
journalctl --user -u dms -f

# Restart DMS
systemctl --user restart dms

# Disable DMS
systemctl --user disable --now dms
```

**Configuration Files:**
- `~/.config/hypr/dms/` - DMS-generated configs (colors, layout, outputs)
- `~/.config/dms/` - DMS main configuration (if exists)
- `~/.dotfiles/config/hypr/_dms.conf` - Integration with Hyprland

**Multi-Monitor Support:**
DMS auto-detects monitors and works with existing Hyprland workspace bindings in `_workspaces_multimonitor.conf`.

**Rollback to Waybar/Mako:**
If DMS doesn't work as expected:

1. Disable DMS:
   ```bash
   systemctl --user disable --now dms
   systemctl --user remove-wants hyprland-session.target dms
   ```

2. Restore backups:
   ```bash
   cp ~/.config/waybar/config.jsonc.pre-dms-backup ~/.config/waybar/config.jsonc
   cp ~/.config/hypr/hyprlock.conf.pre-dms-backup ~/.config/hypr/hyprlock.conf
   ```

3. Comment out DMS source in `~/.dotfiles/config/hypr/omarchy_hyprland_overrides.conf`:
   ```
   # source = ~/.dotfiles/config/hypr/_dms.conf
   ```

4. Log out and back in (or restart Hyprland)

5. Optional - uninstall DMS:
   ```bash
   yay -Rns dms-shell-bin
   ```

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

### 1Password

1. Turn on the SSH Agent under Settings \> Developer

### AWS-Vault

1. Follow the AWS Vault setup [instructions](https://canopyllc.atlassian.net/wiki/spaces/CE/pages/739999785/How-to+Set+up+a+Engineer+s+MacBook+Pro) to finish this setup.

## Current Gripes

1. There isn’t an official Google Drive or OneDrive client  
2. LibreOffice looks really ugly compared to Microsoft Office  
3. Sleep mode doesn't work on my desktop
4. Grammarly Desktop doesn’t exist for Linux  
5. No office application for controlling my Insta 360 camera