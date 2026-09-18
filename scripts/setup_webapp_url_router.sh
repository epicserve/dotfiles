#!/usr/bin/sh
# Route Slack https:// (and slack://) links into the Omarchy Slack Chromium web
# app instead of leaving them in Zen.
#
# Linux has no OS-level "open this hostname in that app" map, so Zen handles
# https itself. This installs:
#   1. ~/.local/bin/webapp-url-router — focuses an existing Slack --app window
#      or launches omarchy-launch-webapp
#   2. Slack.desktop Exec=%u + x-scheme-handler/slack
#   3. A Chromium extension (loaded with the other --load-extension paths)
#      that navigates the existing Slack window instead of opening a second
#      --app window for the deep-link URL
#   4. A native messaging host registered under ~/.mozilla and ~/.config/zen
#      only — never ~/.zen, which would make Zen abandon its XDG profile
#
# Idempotent. Restart Chromium / the Slack web app so it picks up the
# window-reuse extension (same as omarchy-link-router).
#
# Do not create ~/.zen. If that directory exists, Zen uses it instead of
# ~/.config/zen and the real Work/Personal profile looks gone.
#
#   sh ~/.dotfiles/scripts/setup_webapp_url_router.sh

set -eu

REPO="${DOTFILES:-$HOME/.dotfiles}"
SRC="$REPO/config/webapp-url-router"
DEST="$HOME/.local/share/webapp-url-router"
HOST_NAME="com.omarchy.webapp_url_router"
EXT_ID="webapp-url-router@dotfiles"
# Stable Chromium ID from chromium-extension/manifest.json "key".
CHROMIUM_EXT_ID="ieleckodcjeehocebpgonkniopemcjjn"
# Keep in sync with setup_omarchy.sh / host.py
SLACK_URL="https://app.slack.com/client/T07NZL2HG/C07NZPX4H"
SLACK_ICON="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/slack.png"

if [ ! -d "$SRC/extension" ] || [ ! -d "$SRC/chromium-extension" ] || [ ! -f "$SRC/host.py" ]; then
  echo "webapp-url-router: missing sources in $SRC" >&2
  exit 1
fi

mkdir -p "$DEST" "$HOME/.local/bin"
ln -snf "$SRC/host.py" "$DEST/host.py"
chmod +x "$SRC/host.py"
ln -snf "$DEST/host.py" "$HOME/.local/bin/webapp-url-router"
rm -rf "$DEST/chromium-extension"
ln -snf "$SRC/chromium-extension" "$DEST/chromium-extension"

# Native messaging manifest: absolute path required. Zen's app id is Firefox's,
# and 1Password already registers under ~/.mozilla. Also write the XDG config
# dir. Never create ~/.zen — that directory is the legacy profile home, and
# creating it makes Zen ignore ~/.config/zen.
HOST_JSON=$(cat <<EOF
{
  "name": "$HOST_NAME",
  "description": "Open Slack links in the Omarchy Slack web app",
  "path": "$DEST/host.py",
  "type": "stdio",
  "allowed_extensions": ["$EXT_ID"]
}
EOF
)
for dir in \
  "$HOME/.mozilla/native-messaging-hosts" \
  "$HOME/.config/zen/native-messaging-hosts"
do
  mkdir -p "$dir"
  printf '%s\n' "$HOST_JSON" > "$dir/$HOST_NAME.json"
done

# Chromium uses allowed_origins (extension ID) rather than Firefox addon IDs.
# Same host binary; Omarchy web apps only run in Chromium.
if [ -d "$HOME/.config/chromium" ]; then
  mkdir -p "$HOME/.config/chromium/NativeMessagingHosts"
  cat > "$HOME/.config/chromium/NativeMessagingHosts/$HOST_NAME.json" <<EOF
{
  "name": "$HOST_NAME",
  "description": "Open Slack links in the Omarchy Slack web app",
  "path": "$DEST/host.py",
  "type": "stdio",
  "allowed_origins": ["chrome-extension://$CHROMIUM_EXT_ID/"]
}
EOF
fi

# Chromium honors only the last --load-extension flag, so append to the
# existing Omarchy + link-router line instead of adding a second flag.
update_chromium_flags() {
  file="$1"
  marker="webapp-url-router/chromium-extension"
  ext="$DEST/chromium-extension"
  touch "$file"
  if grep -q "$marker" "$file"; then
    return
  fi
  if grep -q '^--load-extension=' "$file"; then
    sed -i "s|^--load-extension=.*|&,$ext|" "$file"
  else
    printf '%s\n' "--load-extension=$ext" >> "$file"
  fi
}
if [ -d "$HOME/.config/chromium" ]; then
  update_chromium_flags "$HOME/.config/chromium-flags.conf"
fi

# Point the Slack launcher at the router so %u deep links and slack:// work.
# omarchy-webapp-install is idempotent besides re-fetching the icon.
if command -v omarchy-webapp-install >/dev/null 2>&1; then
  omarchy-webapp-install "Slack" "$SLACK_URL" "$SLACK_ICON" \
    "$HOME/.local/bin/webapp-url-router %u" \
    "x-scheme-handler/slack;" >/dev/null
fi

MIMEAPPS="$HOME/.config/mimeapps.list"
if [ -f "$MIMEAPPS" ]; then
  if ! grep -qFx "x-scheme-handler/slack=Slack.desktop" "$MIMEAPPS"; then
    python3 - "$MIMEAPPS" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
line = "x-scheme-handler/slack=Slack.desktop"
if "[Default Applications]" in text:
    text = text.replace(
        "[Default Applications]\n",
        "[Default Applications]\n" + line + "\n",
        1,
    )
else:
    text += "\n[Default Applications]\n" + line + "\n"
path.write_text(text)
PY
  fi
fi
xdg-mime default Slack.desktop x-scheme-handler/slack >/dev/null 2>&1 || true

echo "webapp-url-router: installed"
if pgrep -x chromium >/dev/null; then
  echo "webapp-url-router: fully quit Chromium (every Chromium window, not just Slack) so the next launch loads window reuse"
fi
