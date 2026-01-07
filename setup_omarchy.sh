#!/usr/bin/sh

. scripts/clone_dotfiles.sh

# install apps
xargs yay -S --noconfirm --needed <<EOF
visual-studio-code-bin
zen-browser-bin
sourcegit-bin
bind-tools
cursor-bin
terraform-bin
pass
EOF

# uninstall packages we don't want
for pkg in alacritty; do
    yay -Qi "$pkg" &> /dev/null && yay --noconfirm -Rns "$pkg"
done

# remove web apps
omarchy-webapp-remove Basecamp Fizzy Discord GitHub HEY WhatsApp X YouTube Figma > /dev/null

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
  EXEC_LINE='Exec=env AVALONIA_GLOBAL_SCALE_FACTOR=2.5 sourcegit'
  sed -i "/^Exec=/c$EXEC_LINE" ~/.local/share/applications/sourcegit.desktop
fi

OMARCHY_BASH_ADDITIONS='. "$HOME/.dotfiles/config/omarchy/bashrc_additions.sh"'
BASHRC_FILE="$HOME/.bashrc"
if ! grep -qFx "$OMARCHY_BASH_ADDITIONS" "$BASHRC_FILE"; then
  echo -e "\n# Source Omarchy Bash Additions" >> "$BASHRC_FILE" 
  echo "$OMARCHY_BASH_ADDITIONS" >> "$BASHRC_FILE"
fi

HYPR_MAIN_CONFIG="$HOME/.config/hypr/hyprland.conf"
HYPR_INPUT_OVERRIDES='source = ~/.dotfiles/config/hypr/input_overrides.conf'
if ! grep -qFx "$HYPR_INPUT_OVERRIDES" "$HYPR_MAIN_CONFIG"; then
  echo -e "\n# Hyprland Input Overrides" >> "$HYPR_MAIN_CONFIG" 
  echo "$HYPR_INPUT_OVERRIDES" >> "$HYPR_MAIN_CONFIG"
fi

HYPR_BINDINGS_OVERRIDES='source = ~/.dotfiles/config/hypr/binding_overrides.conf'
if ! grep -qFx "$HYPR_BINDINGS_OVERRIDES" "$HYPR_MAIN_CONFIG"; then
  echo -e "\n# Hyprland Bindings Overrides" >> "$HYPR_MAIN_CONFIG"
  echo "$HYPR_BINDINGS_OVERRIDES" >> "$HYPR_MAIN_CONFIG"
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

# Install tailscale
if ! command -v tailscale >/dev/null 2>&1; then
    echo "Configuring Tailscale to accept routes persistently..."
    sudo yay -S --noconfirm --needed tailscale
    sudo tailscale set --accept-routes=true
fi
