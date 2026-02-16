#!/usr/bin/env bash
# Reverts the DankMaterialShell (DMS) migration and restores stock Omarchy components.
#
# USAGE (switch from DMS back to stock Omarchy):
#   1. Run this script:        ~/.dotfiles/scripts/stop_using_dms.sh
#   2. Switch to main branch:  cd ~/.dotfiles && git checkout main
#   3. Log out and back in — stock Omarchy services (waybar, mako, hyprlock,
#      polkit-gnome) will start automatically.
#
# TO SWITCH BACK TO DMS later:
#   1. Switch branch:          cd ~/.dotfiles && git checkout feature/dms
#   2. Re-run the setup:       ~/.dotfiles/setup_omarchy.sh
#      (This reinstalls dms-shell-bin, re-creates the systemd target,
#       backs up waybar/hyprlock configs, and re-enables the DMS service.)
#   3. Log out and back in.
#
set -euo pipefail

echo "=== Stopping DMS and restoring stock Omarchy ==="

# 1. Stop and disable DMS service
echo ""
echo "--- Disabling DMS service ---"
if systemctl --user is-enabled dms &>/dev/null; then
    systemctl --user disable --now dms
    echo "DMS service disabled and stopped."
else
    echo "DMS service not enabled, skipping."
fi

# 2. Remove hyprland-session.target (created by DMS setup)
echo ""
echo "--- Removing DMS systemd target ---"
TARGET_FILE="$HOME/.config/systemd/user/hyprland-session.target"
if [[ -f "$TARGET_FILE" ]]; then
    rm "$TARGET_FILE"
    systemctl --user daemon-reload
    echo "Removed $TARGET_FILE"
else
    echo "No hyprland-session.target found, skipping."
fi

# 3. Restore waybar config from backup
echo ""
echo "--- Restoring waybar config ---"
WAYBAR_BACKUP="$HOME/.config/waybar/config.jsonc.pre-dms-backup"
WAYBAR_CONFIG="$HOME/.config/waybar/config.jsonc"
if [[ -f "$WAYBAR_BACKUP" ]]; then
    cp "$WAYBAR_BACKUP" "$WAYBAR_CONFIG"
    echo "Restored $WAYBAR_CONFIG from backup."
else
    echo "WARNING: No waybar backup found at $WAYBAR_BACKUP"
fi

# 4. Restore hyprlock config from backup
echo ""
echo "--- Restoring hyprlock config ---"
HYPRLOCK_BACKUP="$HOME/.config/hypr/hyprlock.conf.pre-dms-backup"
HYPRLOCK_CONFIG="$HOME/.config/hypr/hyprlock.conf"
if [[ -f "$HYPRLOCK_BACKUP" ]]; then
    cp "$HYPRLOCK_BACKUP" "$HYPRLOCK_CONFIG"
    echo "Restored $HYPRLOCK_CONFIG from backup."
else
    echo "WARNING: No hyprlock backup found at $HYPRLOCK_BACKUP"
fi

# 5. Clean up DMS-generated Hyprland configs
echo ""
echo "--- Removing DMS-generated Hyprland configs ---"
DMS_DIR="$HOME/.config/hypr/dms"
if [[ -d "$DMS_DIR" ]]; then
    rm -rf "$DMS_DIR"
    echo "Removed $DMS_DIR"
else
    echo "No DMS config directory found, skipping."
fi

# 6. Uninstall dms-shell-bin package
echo ""
echo "--- Uninstalling dms-shell-bin ---"
if pacman -Q dms-shell-bin &>/dev/null; then
    yay -Rns --noconfirm dms-shell-bin
    echo "Removed dms-shell-bin package."
else
    echo "dms-shell-bin not installed, skipping."
fi

# 7. Clean up backup files
echo ""
echo "--- Cleaning up backup files ---"
[[ -f "$WAYBAR_BACKUP" ]] && rm "$WAYBAR_BACKUP" && echo "Removed $WAYBAR_BACKUP"
[[ -f "$HYPRLOCK_BACKUP" ]] && rm "$HYPRLOCK_BACKUP" && echo "Removed $HYPRLOCK_BACKUP"

echo ""
echo "=== DMS rollback complete ==="
echo ""
echo "Next steps:"
echo "  1. Switch to main branch:  cd ~/.dotfiles && git checkout main"
echo "  2. Log out and back in to restart Hyprland with stock Omarchy"
echo ""
echo "Stock Omarchy services (waybar, mako, hyprlock, polkit-gnome)"
echo "will start automatically on next login."
echo ""
echo "To switch back to DMS later:"
echo "  1. cd ~/.dotfiles && git checkout feature/dms"
echo "  2. ~/.dotfiles/setup_omarchy.sh"
echo "  3. Log out and back in"
