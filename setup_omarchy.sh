#!/usr/bin/sh

. scripts/clone_dotfiles.sh

# install apps
xargs yay -S --noconfirm --needed <<EOF
bind-tools
cursor-bin
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

# Install udev rules (e.g. disable Logitech Bolt wake-from-suspend)
sudo cp ~/.dotfiles/config/udev/*.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules

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

# Install theme
if [ ! -L ~/.config/omarchy/themes/digital-nature ]; then
  ln -s ~/.dotfiles/config/omarchy/themes/digital-nature ~/.config/omarchy/themes/
fi

# Customize hyprlock input-field (sed replaces in main config since hyprlock doesn't merge blocks)
HYPRLOCK_CONFIG="$HOME/.config/hypr/hyprlock.conf"
sed -i 's/size = [0-9]*, [0-9]*/size = 400, 60/' "$HYPRLOCK_CONFIG"
sed -i 's/rounding = [0-9]*/rounding = 8/' "$HYPRLOCK_CONFIG"

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

  # Copy multi-monitor waybar config
  cp ~/.dotfiles/config/waybar/config_multimonitor.jsonc ~/.config/waybar/config.jsonc
  omarchy-restart-waybar
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
