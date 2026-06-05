#!/usr/bin/sh
# Snapshot the current OBS scene collections + profiles into the dotfiles repo.
# Re-run this whenever you change your OBS layout, filters, or settings.
#
#   ~/.dotfiles/scripts/backup_obs.sh
#
# Captures:
#   - Scene collections (your layout/canvas + all filters) -> config/obs/scenes/
#   - Profiles (resolution, encoder, audio, hotkeys, paths) -> config/obs/profiles/
# Intentionally excludes global.ini (machine-specific paths/window geometry that
# OBS regenerates on its own).

OBS_SRC="$HOME/.config/obs-studio/basic"
REPO_DST="$HOME/.dotfiles/config/obs"

if [ ! -d "$OBS_SRC" ]; then
  echo "OBS config not found at $OBS_SRC -- is OBS installed and has it run at least once?"
  exit 1
fi

# OBS only writes scenes/profiles to disk on exit, on a collection switch, or via
# its periodic autosave. If OBS is running, this snapshot reflects the last save,
# not any unsaved on-screen changes.
if pgrep -x obs >/dev/null 2>&1; then
  echo "WARNING: OBS is running -- snapshot reflects the last autosave/exit, not unsaved changes."
  echo "         For a guaranteed-current backup, quit OBS first, then re-run this script."
fi

# Scene collections (skip OBS's *.bak autosave files). Mirror: drop stale copies first.
mkdir -p "$REPO_DST/scenes"
rm -f "$REPO_DST"/scenes/*.json 2>/dev/null
for f in "$OBS_SRC"/scenes/*.json; do
  [ -e "$f" ] || continue
  cp "$f" "$REPO_DST/scenes/"
  echo "  scene collection: $(basename "$f")"
done

# Profiles (mirror the whole tree).
rm -rf "$REPO_DST/profiles"
mkdir -p "$REPO_DST/profiles"
if [ -d "$OBS_SRC/profiles" ]; then
  cp -r "$OBS_SRC"/profiles/. "$REPO_DST/profiles/"
  for d in "$REPO_DST"/profiles/*/; do
    [ -d "$d" ] || continue
    echo "  profile: $(basename "$d")"
  done
fi

echo "Snapshotted OBS config to $REPO_DST"
echo "Review/commit with: git -C \"$HOME/.dotfiles\" status"
