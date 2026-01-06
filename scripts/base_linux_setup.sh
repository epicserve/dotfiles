#!/usr/bin/sh

set -e

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
fi

# Install AppPack
if ! command -v apppack >/dev/null 2>&1; then
  echo "Installing AppPack..."
  # Get latest release tag from GitHub API
  LATEST_TAG=$(curl -s https://api.github.com/repos/apppackio/apppack/releases/latest | grep 'tag_name' | cut -d '"' -f4)
  if [ -z "$LATEST_TAG" ]; then
    echo "Failed to fetch latest apppack release tag. Aborting."
    exit 1
  fi
  # real:   https://github.com/apppackio/apppack/releases/download/v4.6.7/apppack_4.6.7_Linux_x86_64.tar.gz
  # script: https://github.com/apppackio/apppack/releases/download/v4.6.7/apppack_vv4.6.7_Linux_x86_64.tar.gz
  DOWNLOAD_URL="https://github.com/apppackio/apppack/releases/download/${LATEST_TAG}/apppack_${LATEST_TAG#v}_Linux_x86_64.tar.gz"
  mkdir -p /tmp/apppack
  curl -L "$DOWNLOAD_URL" -o /tmp/apppack/apppack.tar.gz
  CWD=$(pwd)
  cd /tmp/apppack/
  tar xzf apppack.tar.gz
  sudo mv apppack /usr/local/bin/
  cd $CWD
  sudo rm -rf /tmp/apppack/
fi

# Install Chamber
if ! command -v chamber >/dev/null 2>&1; then
  version=$(curl -s https://api.github.com/repos/segmentio/chamber/releases/latest | grep 'tag_name' | cut -d '"' -f4)
  if [ -z "$version" ]; then
    echo "Failed to fetch latest chamber release tag. Aborting."
    exit 1
  fi
  sudo curl -Ls https://github.com/segmentio/chamber/releases/download/${version}/chamber-${version}-linux-amd64 -o /usr/local/bin/chamber
  sudo chmod +x /usr/local/bin/chamber
fi
