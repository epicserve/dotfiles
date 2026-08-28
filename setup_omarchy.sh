#!/usr/bin/sh

. scripts/clone_dotfiles.sh

# This setup targets Omarchy Quattro (v4+), which configures Hyprland in Lua.
if [ ! -f "$HOME/.config/hypr/hyprland.lua" ]; then
  echo "ERROR: Omarchy Quattro (v4) is not applied -- ~/.config/hypr/hyprland.lua is missing."
  echo "Run the upgrade first (Omarchy menu > Update > Omarchy To Quattro), reboot, then re-run this script."
  exit 1
fi

# install paru (AUR helper)
if ! command -v paru >/dev/null 2>&1; then
  sudo pacman -S --noconfirm --needed base-devel git
  tmp=$(mktemp -d)
  git clone https://aur.archlinux.org/paru.git "$tmp/paru"
  (cd "$tmp/paru" && makepkg -si --noconfirm)
  rm -rf "$tmp"
fi

# install apps
xargs yay -S --noconfirm --needed <<EOF
bind-tools
cursor-bin
guvcview
jetbrains-toolbox
obs-advanced-masks
obs-backgroundremoval
obs-studio
onnxruntime-cpu
solaar
sourcegit-bin
terraform-bin
visual-studio-code-bin
zen-browser-bin
zsh
EOF

# uninstall packages we don't want
for pkg in alacritty; do
    yay -Qi "$pkg" &> /dev/null && yay --noconfirm -Rns "$pkg"
done

# remove web apps (ChatGPT is installed as a native app below).
# omarchy-webapp-remove treats all arguments as one name, so call it once per app.
for app in \
  Basecamp \
  "Google Contacts" \
  "Google Photos" \
  "Google Maps" \
  HEY \
  Discord \
  WhatsApp \
  YouTube \
  Fizzy \
  GitHub \
  X \
  Figma \
  ChatGPT
do
  OMARCHY_REMOVE_NOTIFY=false omarchy-webapp-remove "$app" >/dev/null 2>&1 || true
done

# install web apps
omarchy-webapp-install "Slack" "https://app.slack.com/client/T07NZL2HG/C07NZPX4H" "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/slack.png"

. scripts/base_setup.sh
. scripts/base_linux_setup.sh
. "$HOME/.dotfiles/scripts/setup_zsh.sh"

# Install/update OpenAI's official ChatGPT Linux app as a native Arch package
"$HOME/.dotfiles/scripts/setup_chatgpt.sh"

# Scale SourceGit (Avalonia) on HiDPI displays. Avalonia has no GDK_SCALE equivalent,
# so on a scaled monitor it renders tiny. AVALONIA_GLOBAL_SCALE_FACTOR (the Avalonia
# analog of GDK_SCALE) scales the whole app -- including right-click context menus --
# on every launch method and survives SourceGit upgrades. The env var lives in
# config/hypr/monitors.lua (symlinked to ~/.config/hypr/monitors.lua below), so it is
# version-controlled and always loaded by Hyprland.
# Force SourceGit's internal Zoom to 1 so it doesn't stack on top of the env scale.
SOURCEGIT_PREF=~/.sourcegit/preference.json
if [ -f "$SOURCEGIT_PREF" ] && ! pgrep -x sourcegit >/dev/null 2>&1; then
  tmp=$(mktemp "${SOURCEGIT_PREF}.XXXXXX")
  jq '.Zoom = 1' "$SOURCEGIT_PREF" >"$tmp" && mv "$tmp" "$SOURCEGIT_PREF"
fi

# Install WorkTrunk
if ! command -v wt >/dev/null 2>&1; then
  paru -S --noconfirm worktrunk-bin
  wt config shell install
fi

# Install/update Stripe CLI from Stripe's official release (not the AUR -- see script header)
. "$HOME/.dotfiles/scripts/setup_stripe_cli.sh"

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

# Replace Omarchy-seeded Hyprland user override files with repo symlinks.
# ~/.config/hypr/hyprland.lua stays Omarchy-owned; it already requires
# hypr.{monitors,input,bindings,looknfeel,autostart}.
# WARNING: `omarchy refresh hyprland` / `omarchy refresh shell` copy defaults
# THROUGH these symlinks (cp -f) and will dirty ~/.dotfiles. Recover with:
#   git -C ~/.dotfiles checkout -- config/hypr config/omarchy/shell.json && ./setup_omarchy.sh
for f in bindings input looknfeel monitors autostart; do
  dst="$HOME/.config/hypr/$f.lua"
  if [ -f "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "$dst.pre-dotfiles.bak"
  fi
  ln -sf "$HOME/.dotfiles/config/hypr/$f.lua" "$dst"
done

# Omarchy shell (bar layout + idle/lock timings)
if [ -f "$HOME/.config/omarchy/shell.json" ] && [ ! -L "$HOME/.config/omarchy/shell.json" ]; then
  mv "$HOME/.config/omarchy/shell.json" "$HOME/.config/omarchy/shell.json.pre-dotfiles.bak"
fi
ln -sf "$HOME/.dotfiles/config/omarchy/shell.json" "$HOME/.config/omarchy/shell.json"

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

# Espanso text expander (Wayland build; expansions live in config/espanso).
if ! command -v espanso >/dev/null 2>&1; then
  yay -S --noconfirm --needed espanso-wayland
fi
if [ -d ~/.config/espanso ] && [ ! -L ~/.config/espanso ]; then
  mv ~/.config/espanso ~/.config/espanso.pre-dotfiles.bak
fi
ln -snf ~/.dotfiles/config/espanso ~/.config/espanso
# The Wayland binary reads /dev/input directly and needs cap_dac_override.
# pacman strips the capability when the package upgrades; re-running this
# script restores it.
if ! getcap "$(command -v espanso)" | grep -q cap_dac_override; then
  sudo setcap "cap_dac_override+p" "$(command -v espanso)"
fi
[ -f "$HOME/.config/systemd/user/espanso.service" ] || espanso service register
pgrep -x espanso >/dev/null 2>&1 || espanso start >/dev/null 2>&1 || true

# Solaar rules + user service (MX Mechanical Mini Dictation / F9-without-Fn -> Voxtype)
if command -v solaar >/dev/null 2>&1; then
  mkdir -p "$HOME/.config/solaar" "$HOME/.config/systemd/user"
  ln -sf "$HOME/.dotfiles/config/solaar/rules.yaml" "$HOME/.config/solaar/rules.yaml"
  ln -sf "$HOME/.dotfiles/config/systemd/user/solaar.service" "$HOME/.config/systemd/user/solaar.service"
  systemctl --user daemon-reload
  systemctl --user enable --now solaar.service
fi

# Setup VS Code config (fixes keyring detection on Hyprland)
ln -sf ~/.dotfiles/config/vscode/code-flags.conf ~/.config/code-flags.conf

# Restore OBS scene collections + profiles (layout, filters, settings)
. "$HOME/.dotfiles/scripts/setup_obs.sh"

# Install tailscale
if ! command -v tailscale >/dev/null 2>&1; then
    echo "Configuring Tailscale to accept routes persistently..."
    sudo yay -S --noconfirm --needed tailscale
    sudo tailscale set --accept-routes=true
fi

# Install theme (the Quattro upgrade replaces the symlink with a real copy; re-link)
if [ -d ~/.config/omarchy/themes/digital-nature ] && [ ! -L ~/.config/omarchy/themes/digital-nature ]; then
  rm -rf ~/.config/omarchy/themes/digital-nature
fi
ln -snf ~/.dotfiles/config/omarchy/themes/digital-nature ~/.config/omarchy/themes/digital-nature

# Link Pipewire config
if [ -d ~/.config/pipewire ] && [ ! -L ~/.config/pipewire ]; then
  mv ~/.config/pipewire ~/.config/pipewire.backup
  ln -s ~/.dotfiles/config/pipewire ~/.config/pipewire
fi

# WirePlumber drop-ins (Shimmer headphone icon, etc.). The conf.d directory
# may have been created as root during early Bluetooth setup; take ownership
# so the user can manage it, then symlink files without replacing other drop-ins.
if [ -d ~/.config/wireplumber ] && [ "$(stat -c %U ~/.config/wireplumber 2>/dev/null)" = "root" ]; then
  sudo chown -R "$USER:$USER" ~/.config/wireplumber
fi
mkdir -p ~/.config/wireplumber/wireplumber.conf.d
ln -snf ~/.dotfiles/config/wireplumber/wireplumber.conf.d/51-shimmer-headphones.conf \
  ~/.config/wireplumber/wireplumber.conf.d/51-shimmer-headphones.conf

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

# Setup Claude Code settings (preserve across reformats)
mkdir -p ~/.claude
if [ -f ~/.dotfiles/config/claude/settings.json ] && [ ! -L ~/.claude/settings.json ]; then
  [ -f ~/.claude/settings.json ] && mv ~/.claude/settings.json ~/.claude/settings.json.backup
  ln -s ~/.dotfiles/config/claude/settings.json ~/.claude/settings.json
fi
if [ -d ~/.dotfiles/config/claude/projects ] && [ ! -L ~/.claude/projects ]; then
  [ -d ~/.claude/projects ] && mv ~/.claude/projects ~/.claude/projects.backup
  ln -s ~/.dotfiles/config/claude/projects ~/.claude/projects
fi

# Setup iptables rules for PyCharm Docker debugger
if ! sudo iptables -C INPUT -s 172.16.0.0/12 -j ACCEPT 2>/dev/null; then
  echo "Adding iptables rule for Docker networks (PyCharm debugger)..."
  sudo iptables -I INPUT -s 172.16.0.0/12 -j ACCEPT
  sudo iptables-save | sudo tee /etc/iptables/iptables.rules > /dev/null
  sudo systemctl enable iptables.service
  sudo systemctl start iptables.service
fi

# Apply desktop config (theme colors, quickshell bar, Hyprland Lua overrides)
omarchy-theme-set digital-nature || true
omarchy-restart-shell || true
hyprctl reload || true
