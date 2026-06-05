#!/usr/bin/sh
# Restore OBS scene collections + profiles from the dotfiles repo.
#
# Sourced by setup_omarchy.sh after the OBS packages are installed.
# Idempotent: only copies a collection/profile if it isn't already present, so
# re-running setup never clobbers a live OBS config. To refresh the snapshot,
# use scripts/backup_obs.sh.

REPO_SRC="$HOME/.dotfiles/config/obs"
OBS_DST="$HOME/.config/obs-studio/basic"

# Nothing to restore yet -- bail cleanly whether sourced or executed directly.
[ -d "$REPO_SRC" ] || return 0 2>/dev/null || exit 0

mkdir -p "$OBS_DST/scenes" "$OBS_DST/profiles"

# Scene collections (layout/canvas + filters)
if [ -d "$REPO_SRC/scenes" ]; then
  for f in "$REPO_SRC"/scenes/*.json; do
    [ -e "$f" ] || continue
    dest="$OBS_DST/scenes/$(basename "$f")"
    if [ ! -e "$dest" ]; then
      cp "$f" "$dest"
      echo "Restored OBS scene collection: $(basename "$f")"
    fi
  done
fi

# Profiles (settings: resolution, encoder, audio, hotkeys, output paths)
if [ -d "$REPO_SRC/profiles" ]; then
  for d in "$REPO_SRC"/profiles/*/; do
    [ -d "$d" ] || continue
    name=$(basename "$d")
    dest="$OBS_DST/profiles/$name"
    if [ ! -e "$dest" ]; then
      cp -r "$d" "$dest"
      echo "Restored OBS profile: $name"
    fi
  done
fi
