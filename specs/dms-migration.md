# DankMaterialShell Migration Plan

## Context

You're currently using Omarchy (Arch Linux) with Hyprland and a traditional waybar/mako/hyprlock stack for panel/notifications/lock screen. DankMaterialShell (DMS) is a modern, integrated desktop shell built with Quickshell and Go that's designed specifically for Wayland compositors like Hyprland. It replaces the fragmented approach of multiple tools with a cohesive shell experience.

**Why this change:** DMS provides a more integrated, polished desktop experience while maintaining compatibility with your existing Hyprland setup. It replaces waybar, mako, hyprlock, and polkit-gnome with a unified system.

**Current architecture:**
- UWSM (Universal Wayland Session Manager) manages Hyprland and services
- Waybar shows workspaces 1-5 on DP-1 (left), 6-10 on DP-2 (right)
- Mako handles notifications
- Hyprlock provides lock screen (customized input field: 400x60, rounding 8)
- Various services auto-started via `exec-once` in Hyprland config

## Implementation Strategy

### Approach: Parallel Systemd Integration

DMS and UWSM will coexist:
- **UWSM continues managing:** Hyprland compositor, fcitx5, swaybg, swayosd-server
- **DMS manages:** Panel, notifications, lock screen, polkit
- **Shared mechanism:** Both use systemd environment and D-Bus activation

This avoids conflicts while allowing each system to handle what it does best.

## Critical Files to Modify

1. **[setup_omarchy.sh](../setup_omarchy.sh)** - Main setup script
2. **[config/hypr/omarchy_hyprland_overrides.conf](../config/hypr/omarchy_hyprland_overrides.conf)** - Hyprland override file
3. **[config/hypr/_dms.conf](../config/hypr/_dms.conf)** - New file for DMS integration
4. **[docs/omarchy.md](../docs/omarchy.md)** - Documentation updates

## Detailed Implementation Steps

### 1. Add DMS Package Installation

**File:** `setup_omarchy.sh`
**Location:** After line 8 in the AUR packages section

```bash
# install apps
xargs yay -S --noconfirm --needed <<EOF
bind-tools
cursor-bin
dms-shell-bin
guvcview
...
```

### 2. Create Backup Section

**File:** `setup_omarchy.sh`
**Location:** After line 109 (before theme installation)

```bash
# Backup configs before DMS migration
echo "Backing up existing configs before DMS migration..."
for file in ~/.config/waybar/config.jsonc ~/.config/hypr/hyprlock.conf; do
  if [ -f "$file" ] && [ ! -f "$file.pre-dms-backup" ]; then
    cp "$file" "$file.pre-dms-backup"
    echo "  Backed up: $file"
  fi
done
```

### 3. Create Systemd Target for DMS

**File:** `setup_omarchy.sh`
**Location:** After backup section

```bash
# Create systemd target for DMS binding
echo "Creating systemd target for DMS..."
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_USER_DIR"

HYPRLAND_SESSION_TARGET="$SYSTEMD_USER_DIR/hyprland-session.target"
if [ ! -f "$HYPRLAND_SESSION_TARGET" ]; then
  cat > "$HYPRLAND_SESSION_TARGET" << 'EOF'
[Unit]
Description=Hyprland compositor session
Documentation=man:systemd.special(7)
BindsTo=graphical-session.target
Wants=graphical-session-pre.target
After=graphical-session-pre.target
EOF
  echo "  Created: $HYPRLAND_SESSION_TARGET"
fi
```

### 4. Create DMS Integration Config

**File:** `setup_omarchy.sh`
**Location:** After systemd target creation

```bash
# Create DMS integration config
DMS_CONFIG="$HOME/.dotfiles/config/hypr/_dms.conf"
if [ ! -f "$DMS_CONFIG" ]; then
  cat > "$DMS_CONFIG" << 'EOF'
# DMS (DankMaterialShell) Integration
# Export environment to systemd for proper service management
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = systemctl --user start hyprland-session.target

# Source DMS-generated configs (created by 'dms setup')
# Note: These files are created by DMS and may not exist initially
source = ~/.config/hypr/dms/colors.conf
source = ~/.config/hypr/dms/layout.conf
source = ~/.config/hypr/dms/outputs.conf
EOF
  echo "  Created: $DMS_CONFIG"
fi

# Ensure DMS config is sourced in main overrides
HYPR_OMARCHY_CONFIG="$HOME/.dotfiles/config/hypr/omarchy_hyprland_overrides.conf"
DMS_SOURCE='source = ~/.dotfiles/config/hypr/_dms.conf'
if ! grep -qFx "$DMS_SOURCE" "$HYPR_OMARCHY_CONFIG"; then
  # Insert after gaps_out line
  sed -i '/gaps_out = 0/a\\n# DMS Integration\nsource = ~/.dotfiles/config/hypr/_dms.conf' "$HYPR_OMARCHY_CONFIG"
  echo "  Added DMS source to omarchy_hyprland_overrides.conf"
fi
```

### 5. Run DMS Setup and Enable Service

**File:** `setup_omarchy.sh`
**Location:** After DMS config creation

```bash
# Run DMS setup and configure systemd integration
if command -v dms >/dev/null 2>&1; then
  echo "Configuring DMS..."

  # Create directory for DMS-generated configs
  mkdir -p ~/.config/hypr/dms

  # Run DMS setup (generates starter configs)
  dms setup

  # Bind DMS to hyprland-session.target
  systemctl --user add-wants hyprland-session.target dms 2>/dev/null || true

  # Enable DMS service for autostart
  systemctl --user enable dms 2>/dev/null || true

  echo "  DMS configured and enabled"
else
  echo "  WARNING: dms command not found. Install may have failed."
fi
```

### 6. Disable Hyprlock Customization

**File:** `setup_omarchy.sh`
**Location:** Lines 114-117 (comment out)

```bash
# DISABLED: Hyprlock now managed by DMS
# # Customize hyprlock input-field
# HYPRLOCK_CONFIG="$HOME/.config/hypr/hyprlock.conf"
# sed -i 's/size = [0-9]*, [0-9]*/size = 400, 60/' "$HYPRLOCK_CONFIG"
# sed -i 's/rounding = [0-9]*/rounding = 8/' "$HYPRLOCK_CONFIG"
```

### 7. Remove Waybar from Multi-Monitor Section

**File:** `setup_omarchy.sh`
**Location:** Lines 132-134 (comment out)

```bash
  # REMOVED: Waybar config - DMS handles panel now
  # cp ~/.dotfiles/config/waybar/config_multimonitor.jsonc ~/.config/waybar/config.jsonc
  # omarchy-restart-waybar

  echo "  DMS will auto-detect multi-monitor setup"
fi
```

**Keep:** Lines 119-130 (multi-monitor workspace config) - DMS will respect these Hyprland workspace bindings

### 8. Add Completion Message

**File:** `setup_omarchy.sh`
**Location:** End of file (after line 162)

```bash
echo ""
echo "============================================"
echo "DMS Migration Complete!"
echo "============================================"
echo ""
echo "Changes:"
echo "  ✓ Installed DankMaterialShell"
echo "  ✓ Replaced waybar, mako, hyprlock, polkit-gnome"
echo "  ✓ Preserved 1Password, keybindings, monitor config"
echo "  ✓ Backups: ~/.config/waybar/config.jsonc.pre-dms-backup"
echo ""
echo "Next steps:"
echo "  1. Log out and log back into Hyprland"
echo "  2. Verify DMS panel appears on both monitors"
echo "  3. Test lock screen: Super+L"
echo "  4. Check status: systemctl --user status dms"
echo "  5. View logs: journalctl --user -u dms -f"
echo ""
echo "Troubleshooting:"
echo "  - If DMS doesn't start: Check ~/.config/hypr/dms/"
echo "  - Rollback: systemctl --user disable --now dms"
echo "  - Restore: cp ~/.config/waybar/config.jsonc.pre-dms-backup ~/.config/waybar/config.jsonc"
echo ""
```

### 9. Update Documentation

**File:** `docs/omarchy.md`
**Location:** Add new section after existing post-setup steps

```markdown
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
```

### 10. Update Autostart Config Comment

**File:** `config/hypr/_autostart.conf`
**Location:** Add comment at top

```conf
# Autostart overrides
# Note: waybar, mako, hyprlock, and polkit-gnome are now handled by DMS
# Only services not provided by DMS should be added here
exec-once = uwsm-app -- 1password --silent
```

## Components Affected

### Replaced by DMS
- ✗ **Waybar** - Status bar/panel
- ✗ **Mako** - Notification daemon
- ✗ **Hyprlock** - Lock screen
- ✗ **Polkit-gnome** - Authentication agent

### Preserved
- ✓ **1Password** - Auto-starts via `_autostart.conf`
- ✓ **Hypridle** - Idle management (may work with DMS lock)
- ✓ **Fcitx5** - Input method framework
- ✓ **Swaybg** - Background/wallpaper
- ✓ **SwayOSD** - Volume/brightness OSD
- ✓ **Custom keybindings** - All preserved in `_bindings.conf`
- ✓ **Monitor config** - Dual 4K at 1.5x scale
- ✓ **Workspace bindings** - Multi-monitor layout (1-5 on DP-1, 6-10 on DP-2)
- ✓ **Input settings** - Alt/Win swap, keyboard layout
- ✓ **Digital-nature theme** - May need theme mapping to DMS

## Potential Issues and Solutions

### Issue 1: Omarchy Default Autostart Conflicts

**Problem:** Omarchy's default `autostart.conf` still tries to launch waybar/mako via UWSM.

**Solution:** These services will start initially but DMS will take precedence. Consider stopping them explicitly:

```bash
# Optional: Add to _autostart.conf
exec-once = sleep 2 && systemctl --user stop app-waybar@autostart.service 2>/dev/null || true
exec-once = sleep 2 && systemctl --user stop app-mako@autostart.service 2>/dev/null || true
```

**Alternative:** Uninstall waybar/mako packages (prevents conflicts but makes rollback harder):
```bash
yay -Rns --noconfirm waybar mako
```

### Issue 2: DMS Config Files Don't Exist

**Problem:** Sourcing `~/.config/hypr/dms/*.conf` files that don't exist yet.

**Solution:** DMS should create these on first run. If errors occur, comment out the source lines temporarily:
```conf
# source = ~/.config/hypr/dms/colors.conf
# source = ~/.config/hypr/dms/layout.conf
# source = ~/.config/hypr/dms/outputs.conf
```

### Issue 3: Theme Incompatibility

**Problem:** DMS has its own theming separate from Omarchy's digital-nature theme.

**Solution:** After installation, investigate DMS theming options and document color mapping. DMS likely provides theme configuration in `~/.config/dms/`.

### Issue 4: Workspace Layout Changes

**Problem:** DMS might have its own workspace management that conflicts with `_workspaces_multimonitor.conf`.

**Solution:** Test after installation. Hyprland workspace bindings should take precedence. If issues occur, check DMS workspace settings.

### Issue 5: 1Password Doesn't Auto-Start

**Problem:** UWSM wrapping might interfere with new startup order.

**Solution:** Change from UWSM wrapper to direct exec in `_autostart.conf`:
```conf
exec-once = 1password --silent
```

## Testing Checklist

After running the modified setup script and logging back in:

### Visual Verification
- [ ] DMS panel visible on both monitors
- [ ] Panel shows workspace indicators (1-5 on left, 6-10 on right)
- [ ] System tray shows with icons
- [ ] Clock displays correctly
- [ ] Workspace switching works (click indicators)

### Functional Tests
- [ ] Test notification: `notify-send 'Test' 'Message'`
- [ ] Test lock screen: Configured binding or `loginctl lock-session`
- [ ] Test polkit: `pkexec ls /root` (should prompt for password)
- [ ] Verify 1Password auto-started (check system tray)
- [ ] Test all custom keybindings (Super+Alt+F, etc.)
- [ ] Window focus moves correctly between monitors
- [ ] Workspaces stay on correct monitors

### Service Health
- [ ] `systemctl --user status dms` shows active/running
- [ ] No errors in `journalctl --user -u dms -f`
- [ ] `systemctl --user status hyprland-session.target` active
- [ ] DMS survives logout/login cycle

### Configuration Verification
- [ ] DMS configs exist: `ls ~/.config/hypr/dms/`
- [ ] Monitor scaling still 1.5x: `hyprctl monitors`
- [ ] Custom window rules work
- [ ] Theme colors acceptable (or document customization needed)

## Rollback Plan

If major issues occur:

1. **Disable DMS immediately:**
   ```bash
   systemctl --user disable --now dms
   systemctl --user remove-wants hyprland-session.target dms
   ```

2. **Restore configs:**
   ```bash
   cp ~/.config/waybar/config.jsonc.pre-dms-backup ~/.config/waybar/config.jsonc
   cp ~/.config/hypr/hyprlock.conf.pre-dms-backup ~/.config/hypr/hyprlock.conf
   ```

3. **Comment out DMS source:**
   Edit `~/.dotfiles/config/hypr/omarchy_hyprland_overrides.conf`:
   ```conf
   # source = ~/.dotfiles/config/hypr/_dms.conf
   ```

4. **Log out and back in** - waybar/mako/hyprlock should work again

5. **Optional - full uninstall:**
   ```bash
   yay -Rns dms-shell-bin
   rm -rf ~/.config/hypr/dms
   rm ~/.config/systemd/user/hyprland-session.target
   ```

## Success Criteria

Migration is successful when:
1. DMS panel visible and functional on both monitors
2. All existing features preserved (1Password, keybindings, monitors)
3. No systemd errors in logs
4. Configuration survives reboot
5. User experience is improved or equivalent to previous setup

## References

- [DankMaterialShell GitHub](https://github.com/AvengeMedia/DankMaterialShell)
- [DMS Installation Docs](https://danklinux.com/docs/dankmaterialshell/installation)
- [DMS Compositor Setup](https://danklinux.com/docs/dankmaterialshell/compositors)
- [Sudo Science: DMS Makes Hyprland Feel Complete](https://sudoscience.blog/2026/01/24/dank-material-shell-makes-hyprland-feel-complete/)

---

**Implementation Time:** ~10-15 minutes for modifications + 5 minutes for DMS installation
**Risk Level:** Medium (good rollback plan available, backups created)
**User Impact:** Visual change to panel/notifications, but functionality preserved
