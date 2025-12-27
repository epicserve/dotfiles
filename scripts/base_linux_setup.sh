set -e  # Exit on error

# Set zsh as your shell if it's not set
if [ "$SHELL" != "/bin/zsh" ]; then
  chsh -s /bin/zsh;
fi

# Install aws-vault
if ! command -v aws-vault >/dev/null 2>&1; then
  echo "Installing aws-vault..."
  # Get latest release tag from GitHub API
  LATEST_TAG=$(curl -s https://api.github.com/repos/99designs/aws-vault/releases/latest | grep 'tag_name' | cut -d '"' -f4)
  if [ -z "$LATEST_TAG" ]; then
    echo "Failed to fetch latest aws-vault release tag. Aborting."
    exit 1
  fi
  DOWNLOAD_URL="https://github.com/99designs/aws-vault/releases/download/${LATEST_TAG}/aws-vault-linux-amd64"
  sudo curl -L "$DOWNLOAD_URL" -o /usr/local/bin/aws-vault
  sudo chmod +x /usr/local/bin/aws-vault
fi

if [ ! -d ~/.oh-my-zsh ]; then
  echo "Installing oh-my-zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  mkdir -p ~/.oh-my-zsh/custom/completions
fi

# Install Just
if ! command -v just >/dev/null 2>&1; then
  echo "Installing just..."
  # Get latest release tag from GitHub API
  LATEST_TAG=$(curl -s https://api.github.com/repos/casey/just/releases/latest | grep 'tag_name' | cut -d '"' -f4)
  if [ -z "$LATEST_TAG" ]; then
    echo "Failed to fetch latest just release tag. Aborting."
    exit 1
  fi
  DOWNLOAD_URL="https://github.com/casey/just/releases/download/${LATEST_TAG}/just-${LATEST_TAG}-x86_64-unknown-linux-musl.tar.gz"
  echo $DOWNLOAD_URL
  sudo curl -L "$DOWNLOAD_URL" -o /tmp/just.tar.gz
  sudo mkdir -p /tmp/just
  sudo tar xzvf /tmp/just.tar.gz -C /tmp/just
  sudo mv /tmp/just/just /usr/local/bin/
  sudo rm -rf /tmp/just-extract /tmp/just.tar.gz
  sudo rm -rf /tmp/just
  just --completions zsh > ~/.oh-my-zsh/custom/completions/just.zsh
fi

# install zoxide
if ! command -v zoxide >/dev/null 2>&1; then
  echo "Installing zoxide..."
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
fi
