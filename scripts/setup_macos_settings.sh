#!/usr/bin/env bash

# Silent, idempotent macOS settings configurator
set -euo pipefail

# Prompt for sudo up front if needed
sudo -v 2>/dev/null || true

# Helper to idempotently set a macOS setting
macos_set() {
  local domain="$1" key="$2" type="$3" value="$4" current desired
  if [[ "$type" == "bool" ]]; then
    current=$(defaults read "$domain" "$key" 2>/dev/null || echo "unset")
    if [[ "$value" == "true" || "$value" == "1" ]]; then
      desired="1"
    else
      desired="0"
    fi
    [[ "$current" == "$desired" ]] || defaults write "$domain" "$key" -bool "$value"
  elif [[ "$type" == "int" || "$type" == "integer" ]]; then
    current=$(defaults read "$domain" "$key" 2>/dev/null || echo "unset")
    [[ "$current" == "$value" ]] || defaults write "$domain" "$key" -int "$value"
  elif [[ "$type" == "float" ]]; then
    current=$(defaults read "$domain" "$key" 2>/dev/null || echo "unset")
    [[ "$current" == "$value" ]] || defaults write "$domain" "$key" -float "$value"
  else
    current=$(defaults read "$domain" "$key" 2>/dev/null || echo "unset")
    [[ "$current" == "$value" ]] || defaults write "$domain" "$key" "$value"
  fi
}

# General UI/UX
macos_set com.apple.LaunchServices LSQuarantine int 0
macos_set com.googlecode.iterm2 PromptOnQuit int 0
# Trackpad: tap to click
autoset com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking int 1
# Increase mouse speed to 9
macos_set NSGlobalDomain com.apple.mouse.scaling float 9
macos_set NSGlobalDomain KeyRepeat int 2

# Finder
macos_set NSGlobalDomain AppleShowAllExtensions bool true
macos_set com.apple.finder QLEnableTextSelection bool true
macos_set com.apple.finder FXEnableExtensionChangeWarning bool false
macos_set com.apple.finder EmptyTrashSecurely integer 0

# Show the ~/Library folder (avoid repeating if already visible)
if [[ -d "$HOME/Library" && $(ls -ldO "$HOME/Library" | grep -c nohidden) -eq 0 ]]; then
  sudo chflags nohidden "$HOME/Library"
fi

# Dock & hot corners
macos_set com.apple.dock autohide bool true
macos_set com.apple.dock magnification bool true
macos_set com.apple.dock tilesize float 32
macos_set com.apple.dock largesize float 64
macos_set com.apple.dock wvous-tl-corner int 6
macos_set com.apple.dock wvous-tr-corner int 2
macos_set com.apple.dock wvous-bl-corner int 5
macos_set com.apple.dock wvous-br-corner int 4

# Misc
macos_set com.apple.desktopservices DSDontWriteNetworkStores bool true

# Restart affected apps (always silent)
killall Finder Dock &>/dev/null || true
