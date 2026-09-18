#!/usr/bin/sh
# Open Slack links clicked in Zen in the Omarchy Slack Chromium web app.
#
# Zen handles https itself, so a Zen extension cancels Slack navigations and
# hands the URL to a native host (config/webapp-url-router/host.py), which
# loads it into the open Slack --app window or launches one. A small Chromium
# extension keeps one native-messaging port open so the host can push deep
# links into the open window instead of Chromium starting a second one.
#
# Installs the host, both native-messaging manifests, the Chromium extension
# (appended to the --load-extension line, which Chromium honors only once) and
# Slack.desktop with the host as Exec so the launcher focuses an open Slack
# instead of starting another. Idempotent; a re-run writes nothing and touches
# the network only when Slack.desktop has to be (re)created.
#
# The Zen extension is unsigned. Zen is built without MOZ_REQUIRE_SIGNING, so
# with xpinstall.signatures.required off it installs the XPI this script drops
# into the default profile's extensions/ directory at the next Zen start.
#
# Never create ~/.zen: if that directory exists Zen uses it instead of
# ~/.config/zen and the real profile appears to vanish.
#
#   sh ~/.dotfiles/scripts/setup_webapp_url_router.sh

set -eu

SRC="${DOTFILES:-$HOME/.dotfiles}/config/webapp-url-router"
DEST="$HOME/.local/share/webapp-url-router"
HOST_NAME="com.omarchy.webapp_url_router"
ZEN_EXT_ID="webapp-url-router@dotfiles"
# Stable id derived from the "key" in chromium-extension/manifest.json. Rotated
# once: a profile that had run the old polling worker kept starting it and never
# registered the replacement, while routine edits of the current worker update
# fine on relaunch.
CHROMIUM_EXT_ID="oaieagefogkhhenngcnlhninfpmkebek"
# Keep in sync with SLACK_URL in host.py.
SLACK_URL="https://app.slack.com/client/T07NZL2HG/C07NZPX4H"
SLACK_ICON="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/slack.png"

if ! command -v omarchy-launch-webapp >/dev/null 2>&1; then
  echo "webapp-url-router: omarchy-launch-webapp not found; skipping"
  exit 0
fi

# put FILE CONTENT: write only when different, so re-runs leave mtimes alone.
put() {
  if [ ! -f "$1" ] || [ "$(cat "$1")" != "$2" ]; then
    mkdir -p "$(dirname "$1")"
    printf '%s\n' "$2" >"$1"
  fi
}

mkdir -p "$DEST"
chmod +x "$SRC/host.py"
ln -snf "$SRC/host.py" "$DEST/host.py"
ln -snf "$SRC/chromium-extension" "$DEST/chromium-extension"

# Native-messaging manifests need absolute paths, so they are generated here.
# Zen reads Firefox's ~/.mozilla location (1Password registers there too);
# ~/.config/zen is its XDG config dir.
ZEN_MANIFEST="{
  \"name\": \"$HOST_NAME\",
  \"description\": \"Open Slack links in the Omarchy Slack web app\",
  \"path\": \"$DEST/host.py\",
  \"type\": \"stdio\",
  \"allowed_extensions\": [\"$ZEN_EXT_ID\"]
}"
put "$HOME/.mozilla/native-messaging-hosts/$HOST_NAME.json" "$ZEN_MANIFEST"
put "$HOME/.config/zen/native-messaging-hosts/$HOST_NAME.json" "$ZEN_MANIFEST"

# Zen: build the extension into an XPI and drop it into the default profile's
# extensions/ directory, where Zen installs it at the next start. The signature
# pref lets the unsigned XPI in; autoDisableScopes=14 keeps profile-directory
# installs enabled instead of "sideloaded, disabled". Both live in user.js,
# which Zen reads at startup and never rewrites.
ZEN_PROFILE=$(sed -n '/^\[Install/,/^$/p' "$HOME/.config/zen/profiles.ini" 2>/dev/null | sed -n 's/^Default=//p' | head -1)
if [ -n "$ZEN_PROFILE" ] && [ -d "$HOME/.config/zen/$ZEN_PROFILE" ]; then
  ZEN_PROFILE="$HOME/.config/zen/$ZEN_PROFILE"
  XPI="$DEST/$ZEN_EXT_ID.xpi"
  if [ ! -f "$XPI" ] || [ "$SRC/extension/manifest.json" -nt "$XPI" ] || [ "$SRC/extension/background.js" -nt "$XPI" ]; then
    python3 - "$XPI" "$SRC/extension" <<'PY'
import pathlib, sys, zipfile
xpi, src = sys.argv[1], pathlib.Path(sys.argv[2])
with zipfile.ZipFile(xpi, "w", zipfile.ZIP_DEFLATED) as z:
    for f in sorted(src.iterdir()):
        z.write(f, f.name)
PY
  fi
  for pref in 'user_pref("xpinstall.signatures.required", false);' 'user_pref("extensions.autoDisableScopes", 14);'; do
    grep -qsFx "$pref" "$ZEN_PROFILE/user.js" || printf '%s\n' "$pref" >>"$ZEN_PROFILE/user.js"
  done
  mkdir -p "$ZEN_PROFILE/extensions"
  if ! cmp -s "$XPI" "$ZEN_PROFILE/extensions/$ZEN_EXT_ID.xpi"; then
    cp "$XPI" "$ZEN_PROFILE/extensions/$ZEN_EXT_ID.xpi"
    echo "webapp-url-router: Zen extension installed; restart Zen to load it"
  fi
else
  echo "webapp-url-router: no default Zen profile found; skipping the Zen extension"
fi

# Web apps only run in Chromium; the Chromium half waits until it has a profile.
if [ -d "$HOME/.config/chromium" ]; then
  put "$HOME/.config/chromium/NativeMessagingHosts/$HOST_NAME.json" "{
  \"name\": \"$HOST_NAME\",
  \"description\": \"Open Slack links in the Omarchy Slack web app\",
  \"path\": \"$DEST/host.py\",
  \"type\": \"stdio\",
  \"allowed_origins\": [\"chrome-extension://$CHROMIUM_EXT_ID/\"]
}"

  # Chromium honors only the last --load-extension flag: append to the
  # existing Omarchy + link-router line rather than adding a second one.
  FLAGS="$HOME/.config/chromium-flags.conf"
  if ! grep -qsF "$DEST/chromium-extension" "$FLAGS"; then
    if grep -qs '^--load-extension=' "$FLAGS"; then
      sed -i "s|^--load-extension=.*|&,$DEST/chromium-extension|" "$FLAGS"
    else
      printf '%s\n' "--load-extension=$DEST/chromium-extension" >>"$FLAGS"
    fi
    echo "webapp-url-router: Chromium extension added; fully quit Chromium (every window) to load it"
  fi
fi

# Slack.desktop runs the host, which focuses an open Slack window or launches
# one. omarchy-webapp-install downloads the icon every time, so only run it
# when the Exec line is not already ours.
if ! grep -qsFx "Exec=$DEST/host.py" "$HOME/.local/share/applications/Slack.desktop"; then
  omarchy-webapp-install "Slack" "$SLACK_URL" "$SLACK_ICON" "$DEST/host.py" >/dev/null
fi
