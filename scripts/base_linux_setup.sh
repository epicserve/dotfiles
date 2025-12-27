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