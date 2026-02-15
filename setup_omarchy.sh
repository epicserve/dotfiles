#!/usr/bin/sh

. scripts/clone_dotfiles.sh

# install apps
xargs yay -S --noconfirm --needed <<EOF
bind-tools
cursor-bin
dms-shell-bin
guvcview
jetbrains-toolbox
obs-advanced-masks
solaar
sourcegit-bin
terraform-bin
visual-studio-code-bin
zen-browser-bin
EOF

# uninstall packages we don't want
for pkg in alacritty; do
    yay -Qi "$pkg" &> /dev/null && yay --noconfirm -Rns "$pkg"
done

# remove web apps
omarchy-webapp-remove Basecamp Fizzy Discord GitHub HEY WhatsApp X YouTube Figma > /dev/null

# install web apps
omarchy-webapp-install "Slack" "https://app.slack.com/client/T07NZL2HG/C07NZPX4H" "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/slack.png"

. scripts/base_setup.sh
. scripts/base_linux_setup.sh

# Link configs
if [ -d ~/.config/git ]; then
  rm -rf ~/.config/git
fi

ln -sf ~/.dotfiles/config/aliases ~/.config/
. "$HOME/.dotfiles/scripts/setup_git.sh"

# Customize the Zoom level for SourceGit
if [ ! -f ~/.local/share/applications/sourcegit.desktop ]; then
  cp /usr/share/applications/sourcegit.desktop ~/.local/share/applications/
fi
EXEC_LINE='Exec=env AVALONIA_GLOBAL_SCALE_FACTOR=1.5 sourcegit'
sed -i "/^Exec=/c$EXEC_LINE" ~/.local/share/applications/sourcegit.desktop

# Fix JetBrains Toolbox scaling (prevent double scaling on Wayland)
if [ -f /opt/jetbrains-toolbox/jetbrains-toolbox ]; then
  cat > ~/.local/share/applications/jetbrains-toolbox.desktop << 'EOF'
[Desktop Entry]
Icon=/opt/jetbrains-toolbox/toolbox.svg
Exec=env GDK_SCALE=1 /opt/jetbrains-toolbox/jetbrains-toolbox %u
Version=1.0
Type=Application
Categories=Development
Name=JetBrains Toolbox
StartupWMClass=jetbrains-toolbox
Terminal=false
MimeType=x-scheme-handler/jetbrains;
EOF
fi

# Fix guvcview desktop file (upstream uses _Name instead of Name)
if [ ! -f ~/.local/share/applications/guvcview.desktop ]; then
  cp /usr/share/applications/guvcview.desktop ~/.local/share/applications/
  sed -i 's/^_Name=/Name=/' ~/.local/share/applications/guvcview.desktop
  sed -i 's/^_GenericName=/GenericName=/' ~/.local/share/applications/guvcview.desktop
  sed -i 's/^_Comment=/Comment=/' ~/.local/share/applications/guvcview.desktop
fi

OMARCHY_BASH_ADDITIONS='. "$HOME/.dotfiles/config/omarchy/bashrc_additions.sh"'
BASHRC_FILE="$HOME/.bashrc"
if ! grep -qFx "$OMARCHY_BASH_ADDITIONS" "$BASHRC_FILE"; then
  echo -e "\n# Source Omarchy Bash Additions" >> "$BASHRC_FILE" 
  echo "$OMARCHY_BASH_ADDITIONS" >> "$BASHRC_FILE"
fi

HYPR_MAIN_CONFIG="$HOME/.config/hypr/hyprland.conf"
HYPR_OMARCHY_OVERRIDES='source = ~/.dotfiles/config/hypr/omarchy_hyprland_overrides.conf'
if ! grep -qFx "$HYPR_OMARCHY_OVERRIDES" "$HYPR_MAIN_CONFIG"; then
  echo -e "\n# Omarchy Hyprland Overrides" >> "$HYPR_MAIN_CONFIG"
  echo "$HYPR_OMARCHY_OVERRIDES" >> "$HYPR_MAIN_CONFIG"
fi

# Setup 1Password to use Zen Browser
sudo mkdir -p /etc/1password
sudo touch /etc/1password/custom_allowed_browsers
if ! grep -qFx "zen-bin" /etc/1password/custom_allowed_browsers; then
  echo "zen-bin" | sudo tee -a /etc/1password/custom_allowed_browsers
fi

# Setup Ghostty config
if [ -d ~/.config/ghostty ] && [ ! -L ~/.config/ghostty ]; then
  rm -rf ~/.config/ghostty
  ln -s ~/.dotfiles/config/ghostty ~/.config/ghostty
fi

# Setup VS Code config (fixes keyring detection on Hyprland)
ln -sf ~/.dotfiles/config/vscode/code-flags.conf ~/.config/code-flags.conf

# Install tailscale
if ! command -v tailscale >/dev/null 2>&1; then
    echo "Configuring Tailscale to accept routes persistently..."
    sudo yay -S --noconfirm --needed tailscale
    sudo tailscale set --accept-routes=true
fi

# Backup configs before DMS migration
echo "Backing up existing configs before DMS migration..."
for file in ~/.config/waybar/config.jsonc ~/.config/hypr/hyprlock.conf; do
  if [ -f "$file" ] && [ ! -f "$file.pre-dms-backup" ]; then
    cp "$file" "$file.pre-dms-backup"
    echo "  Backed up: $file"
  fi
done

# Install theme
if [ ! -L ~/.config/omarchy/themes/digital-nature ]; then
  ln -s ~/.dotfiles/config/omarchy/themes/digital-nature ~/.config/omarchy/themes/
fi

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

# DISABLED: Hyprlock now managed by DMS
# # Customize hyprlock input-field (sed replaces in main config since hyprlock doesn't merge blocks)
# HYPRLOCK_CONFIG="$HOME/.config/hypr/hyprlock.conf"
# sed -i 's/size = [0-9]*, [0-9]*/size = 400, 60/' "$HYPRLOCK_CONFIG"
# sed -i 's/rounding = [0-9]*/rounding = 8/' "$HYPRLOCK_CONFIG"

# Apply multi-monitor workspace config only if multiple monitors detected
MONITOR_COUNT=$(hyprctl monitors -j 2>/dev/null | grep -c '"name"' || echo "1")
if [ "$MONITOR_COUNT" -gt 1 ]; then
  echo "Multiple monitors detected ($MONITOR_COUNT), applying multi-monitor workspace config..."

  # Add workspace source to main override file
  HYPR_OMARCHY_CONFIG="$HOME/.dotfiles/config/hypr/omarchy_hyprland_overrides.conf"
  HYPR_WORKSPACE_SOURCE='source = ~/.dotfiles/config/hypr/_workspaces_multimonitor.conf'
  if ! grep -qFx "$HYPR_WORKSPACE_SOURCE" "$HYPR_OMARCHY_CONFIG"; then
    echo -e "\n# Multi-monitor Workspace Bindings" >> "$HYPR_OMARCHY_CONFIG"
    echo "$HYPR_WORKSPACE_SOURCE" >> "$HYPR_OMARCHY_CONFIG"
  fi

  # REMOVED: Waybar config - DMS handles panel now
  # cp ~/.dotfiles/config/waybar/config_multimonitor.jsonc ~/.config/waybar/config.jsonc
  # omarchy-restart-waybar

  echo "  DMS will auto-detect multi-monitor setup"
fi

# Link Pipewire config
if [ -d ~/.config/pipewire ] && [ ! -L ~/.config/pipewire ]; then
  mv ~/.config/pipewire ~/.config/pipewire.backup
  ln -s ~/.dotfiles/config/pipewire ~/.config/pipewire
fi

# Configure PyCharm for Wayland (add WLToolkit to any existing PyCharm configs)
for pycharm_dir in ~/.config/JetBrains/PyCharm*; do
  if [ -d "$pycharm_dir" ]; then
    vmoptions_file="$pycharm_dir/pycharm64.vmoptions"
    if [ -f "$vmoptions_file" ]; then
      if ! grep -q "Dawt.toolkit.name=WLToolkit" "$vmoptions_file"; then
        echo "-Dawt.toolkit.name=WLToolkit" >> "$vmoptions_file"
      fi
    fi
  fi
done

# Setup iptables rules for PyCharm Docker debugger
if ! sudo iptables -C INPUT -s 172.16.0.0/12 -j ACCEPT 2>/dev/null; then
  echo "Adding iptables rule for Docker networks (PyCharm debugger)..."
  sudo iptables -I INPUT -s 172.16.0.0/12 -j ACCEPT
  sudo iptables-save | sudo tee /etc/iptables/iptables.rules > /dev/null
  sudo systemctl enable iptables.service
  sudo systemctl start iptables.service
fi

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
