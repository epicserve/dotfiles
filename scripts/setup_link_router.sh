#!/usr/bin/sh
# Install or update omarchy-link-router: a Chromium extension + native messaging
# host that sends links clicked inside Omarchy web apps (Chromium --app windows)
# to xdg-open, so they open in the default browser (Zen) instead of a Chromium
# tab. The web app window itself and OAuth popups stay in Chromium.
#
# Upstream: https://github.com/Samat220/omarchy-link-router
#
# Idempotent. Without --update it clones only on first run and never touches the
# network afterwards. Upstream install.sh is itself safe to re-run: it copies the
# extension + host to ~/.local/share/chromium-link-router, regenerates
# ~/.config/chromium/NativeMessagingHosts/com.omarchy.link_router.json, and adds
# its path to the existing --load-extension= line in ~/.config/chromium-flags.conf
# only if missing (Chromium honors only the last --load-extension flag, and
# Omarchy already uses one for its own extensions).
#
#   sh ~/.dotfiles/scripts/setup_link_router.sh            # install / re-apply
#   sh ~/.dotfiles/scripts/setup_link_router.sh --update   # git pull first
#
# Run by setup_omarchy.sh, and with --update by the Omarchy post-update hook
# (config/omarchy/hooks/post-update.d/link-router.hook), which also restores the
# chromium-flags.conf entry if an Omarchy migration ever rewrites that file.

LINK_ROUTER_REPO="https://github.com/Samat220/omarchy-link-router.git"
LINK_ROUTER_SRC="$HOME/.local/share/omarchy-link-router"
LINK_ROUTER_DEST="$HOME/.local/share/chromium-link-router"

# Web apps only run in Chromium; nothing to do without it.
if ! command -v chromium >/dev/null 2>&1 || [ ! -d "$HOME/.config/chromium" ]; then
  echo "link-router: chromium not installed or never launched; skipping"
  exit 0
fi

if [ ! -d "$LINK_ROUTER_SRC/.git" ]; then
  git clone --quiet "$LINK_ROUTER_REPO" "$LINK_ROUTER_SRC"
elif [ "$1" = "--update" ]; then
  git -C "$LINK_ROUTER_SRC" pull --quiet --ff-only ||
    echo "link-router: git pull failed; keeping the current version"
fi

# Fingerprint what Chromium actually loads so we only ask for a restart when
# something changed.
link_router_state() {
  {
    cat "$HOME/.config/chromium-flags.conf" 2>/dev/null
    cat "$LINK_ROUTER_DEST"/extension/* "$LINK_ROUTER_DEST/host.py" 2>/dev/null
  } | md5sum
}

before=$(link_router_state)
"$LINK_ROUTER_SRC/install.sh" >/dev/null
if [ "$before" != "$(link_router_state)" ]; then
  echo "link-router: installed/updated; restart Chromium (pkill chromium) to activate"
fi
