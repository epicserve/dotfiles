#!/usr/bin/env sh
set +x

# Install Homebrew if not installed
if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install Homebrew Formulas
HOMEBREW_NO_INSTALL_UPGRADE=1
brew update -q
xargs brew install -q <<EOF
chamber
git
git-extras
node
eza
EOF

# Add taps
brew tap apppackio/apppack
brew install -q apppack

# Install Homebrew Casks
while read -r pkg; do
    if ! brew list --cask | grep -Fx "$pkg" > /dev/null; then
        brew install --cask --quiet "$pkg"
    fi
done <<EOF
1password
1password-cli
bartender
chatgpt
claude
firefox
fork
iterm2
pycharm
raycast
sequel-ace
slack
tailscale
visual-studio-code
zoom
EOF
