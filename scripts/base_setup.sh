#!/usr/bin/sh
set +x

OS_TYPE=$(uname)

# Detect if running in WSL
IS_WSL=false
if grep -qiE "(Microsoft|WSL)" /proc/version 2>/dev/null; then
  IS_WSL=true
fi

# Check if 'uv' is installed
if ! command -v uv >/dev/null 2>&1; then
  echo "Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# install the AWS CLI
if ! command -v aws >/dev/null 2>&1 && [ "$OS_TYPE" != "Darwin" ]; then
  echo "Installing aws..."
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
  unzip /tmp/awscliv2.zip -d /tmp
  sudo /tmp/aws/install
  sudo rm /tmp/awscliv2.zip
  sudo rm -rf /tmp/aws
elif ! command -v aws >/dev/null 2>&1 && [ "$OS_TYPE" = "Darwin" ]; then
  echo "Installing aws..."
  curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "/tmp/AWSCLIV2.pkg"
  sudo installer -pkg /tmp/AWSCLIV2.pkg -target /
  sudo rm /tmp/AWSCLIV2.pkg
fi

# Install fzf
if ! command -v fzf >/dev/null 2>&1; then
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  ~/.fzf/install
fi