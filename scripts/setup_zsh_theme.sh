#!/usr/bin/env sh

set -e +x

# Install powerlevel10k theme for Oh My Zsh
THEME_DIR="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
if [ ! -d $THEME_DIR ]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $THEME_DIR
fi

# Install the recommended terminal font
# Fonts to install
FONT_BASE_URL="https://github.com/romkatv/powerlevel10k-media/raw/master"
FONTS="MesloLGS%20NF%20Regular.ttf MesloLGS%20NF%20Bold.ttf MesloLGS%20NF%20Italic.ttf MesloLGS%20NF%20Bold%20Italic.ttf"

if [ "$IS_WSL" = true ]; then
  # Install fonts for WINDOWS
  WINDOWS_FONT_DIR="/mnt/c/Windows/Fonts"
  if [ -d "$WINDOWS_FONT_DIR" ]; then
    NEEDS_INSTALL=false
    for font in $FONTS; do
      font_name=$(echo "$font" | sed 's/%20/ /g')
      if [ ! -f "$WINDOWS_FONT_DIR/$font_name" ]; then
        NEEDS_INSTALL=true
        break
      fi
    done
    
    if [ "$NEEDS_INSTALL" = true ]; then
      echo "Installing MesloLGS NF fonts to Windows..."
      for font in $FONTS; do
        font_name=$(echo "$font" | sed 's/%20/ /g')
        if [ ! -f "$WINDOWS_FONT_DIR/$font_name" ]; then
          echo "  Downloading $font_name..."
          curl -L -o "/tmp/$font_name" "$FONT_BASE_URL/$font"
          if [ -f "/tmp/$font_name" ]; then
            sudo cp "/tmp/$font_name" "$WINDOWS_FONT_DIR/"
            rm "/tmp/$font_name"
            echo "  Installed $font_name"
          fi
        fi
      done
      echo "Fonts installed. You may need to restart your terminal for changes to take effect."
    fi
  fi
elif [ "$OS_TYPE" = "Darwin" ]; then
  # Install fonts for macOS
  MACOS_FONT_DIR="$HOME/Library/Fonts"
  mkdir -p "$MACOS_FONT_DIR"
  
  NEEDS_INSTALL=false
  for font in $FONTS; do
    font_name=$(echo "$font" | sed 's/%20/ /g')
    if [ ! -f "$MACOS_FONT_DIR/$font_name" ]; then
      NEEDS_INSTALL=true
      break
    fi
  done
  
  if [ "$NEEDS_INSTALL" = true ]; then
    echo "Installing MesloLGS NF fonts to macOS..."
    for font in $FONTS; do
      font_name=$(echo "$font" | sed 's/%20/ /g')
      if [ ! -f "$MACOS_FONT_DIR/$font_name" ]; then
        echo "  Downloading $font_name..."
        curl -L -o "$MACOS_FONT_DIR/$font_name" "$FONT_BASE_URL/$font"
        echo "  Installed $font_name"
      fi
    done
    echo "Fonts installed. You may need to restart your terminal for changes to take effect."
  fi
else
  # Install fonts for Linux
  LINUX_FONT_DIR="$HOME/.local/share/fonts"
  mkdir -p "$LINUX_FONT_DIR"
  
  NEEDS_INSTALL=false
  for font in $FONTS; do
    font_name=$(echo "$font" | sed 's/%20/ /g')
    if [ ! -f "$LINUX_FONT_DIR/$font_name" ]; then
      NEEDS_INSTALL=true
      break
    fi
  done
  
  if [ "$NEEDS_INSTALL" = true ]; then
    echo "Installing MesloLGS NF fonts to Linux..."
    for font in $FONTS; do
      font_name=$(echo "$font" | sed 's/%20/ /g')
      if [ ! -f "$LINUX_FONT_DIR/$font_name" ]; then
        echo "  Downloading $font_name..."
        curl -L -o "$LINUX_FONT_DIR/$font_name" "$FONT_BASE_URL/$font"
        echo "  Installed $font_name"
      fi
    done
    fc-cache -f -v >/dev/null 2>&1 || true
    echo "Fonts installed. You may need to restart your terminal for changes to take effect."
  fi
  # Note: fc-cache only runs when fonts are actually installed, not when they're already present
fi
