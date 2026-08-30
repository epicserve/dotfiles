#!/usr/bin/sh

set -e

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
