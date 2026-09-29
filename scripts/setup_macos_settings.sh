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
macos_set com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking int 1
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

# iTerm2: Left Option sends Esc+ so Alt shortcuts reach terminal apps (Claude Code's
# Alt+P model picker, herdr's alt bindings); Right Option still types characters like π.
# iTerm2 writes its in-memory profiles back over the prefs, so only change them while it is quit.
iterm2_left_option_esc() (
  pb=/usr/libexec/PlistBuddy
  plist=$(mktemp)
  trap 'rm -f "$plist"' EXIT
  defaults export com.googlecode.iterm2 "$plist" 2>/dev/null || true

  # The default profile, or the first one if no default was ever chosen
  default=$("$pb" -c "Print :'Default Bookmark Guid'" "$plist" 2>/dev/null || true)
  i=0 entry=""
  while guid=$("$pb" -c "Print :'New Bookmarks':$i:Guid" "$plist" 2>/dev/null); do
    if [[ -z "$default" || "$guid" == "$default" ]]; then
      entry=":'New Bookmarks':$i:'Option Key Sends'"
      break
    fi
    i=$((i + 1))
  done
  if [[ -z "$entry" ]]; then
    echo "iTerm2 has no profile yet: open and quit it once, then re-run to set Left Option to Esc+"
    exit 0
  fi

  current=$("$pb" -c "Print $entry" "$plist" 2>/dev/null || echo unset)
  if [[ "$current" == 2 ]]; then
    exit 0
  fi
  if pgrep -xq iTerm2; then
    echo "Quit iTerm2 and re-run (from Terminal.app) to set its Left Option key to Esc+"
    exit 0
  fi
  if [[ "$current" == unset ]]; then
    "$pb" -c "Add $entry integer 2" "$plist"
  else
    "$pb" -c "Set $entry 2" "$plist"
  fi
  defaults import com.googlecode.iterm2 "$plist"
)
iterm2_left_option_esc

# Restart affected apps (always silent)
killall Finder Dock &>/dev/null || true
