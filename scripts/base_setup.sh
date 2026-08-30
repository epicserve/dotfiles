#!/usr/bin/sh
set +x

# Install mise (skip when already present, including Omarchy's mise-bin package)
if ! command -v mise >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/mise" ]; then
  echo "Installing mise..."
  curl https://mise.run | sh
fi

# Symlink global mise config from this repo
mkdir -p "$HOME/.config"
if [ -e "$HOME/.config/mise" ] && [ ! -L "$HOME/.config/mise" ]; then
  mv "$HOME/.config/mise" "$HOME/.config/mise.pre-dotfiles.bak"
  echo "Backed up existing ~/.config/mise to ~/.config/mise.pre-dotfiles.bak"
fi
ln -snf "$HOME/.dotfiles/config/mise" "$HOME/.config/mise"

# Shims + ~/.local/bin so tools are on PATH for the rest of this setup session
export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH"

if command -v mise >/dev/null 2>&1; then
  MISE_BIN="$(command -v mise)"
else
  MISE_BIN="$HOME/.local/bin/mise"
fi

echo "Installing mise tools..."
"$MISE_BIN" install
