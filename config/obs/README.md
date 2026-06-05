# OBS Studio config

Backup of the OBS Studio setup so it survives a reinstall.

## What's here

- `scenes/` — **scene collections**: your layout/canvas, sources, transforms, and
  all filters (facecam crop/mask, background removal, etc.)
- `profiles/` — **profiles**: video resolution/FPS, encoder, audio devices,
  hotkeys, and output paths

`global.ini` (window geometry, app-level prefs, absolute config paths) is
intentionally **not** tracked — OBS regenerates it.

## Restore (fresh machine)

Handled automatically by `setup_omarchy.sh`, which:

1. installs `obs-studio`, `obs-advanced-masks`, `obs-backgroundremoval`, and
   `onnxruntime-cpu` (the background-removal inference backend), then
2. sources `scripts/setup_obs.sh`, which copies the scenes/profiles into
   `~/.config/obs-studio/basic/` (only if not already present).

> Tip: run `setup_omarchy.sh` **before** launching OBS for the first time. If
> OBS runs first it auto-creates a default `Untitled` collection, and the
> restore won't overwrite an existing one. (Another reason to rename your
> collection off `Untitled` — see below.)

On first launch, pick the restored collection/profile from OBS's
**Scene Collection** and **Profile** menus if they aren't already active.

## Update the snapshot

After changing your OBS layout or settings, re-run:

```sh
~/.dotfiles/scripts/backup_obs.sh
```

(Quit OBS first for a guaranteed-current snapshot — OBS only writes to disk on
exit/collection-switch/autosave.)

## Caveats (same-machine restore)

The scene JSON contains **hardware-specific references** that won't transfer
cleanly to different hardware:

- the camera device (e.g. `/dev/video0` — the Insta360 Link 2)
- PipeWire audio source IDs (the Elgato Wave:3 mic)
- **absolute paths** to any image used by a mask filter

If you add a mask PNG for a circular facecam, store it in `assets/` here and
point the filter at that in-repo path so it resolves after a restore.

It's recommended to rename your scene collection and profile off the default
`Untitled` (OBS: **Scene Collection → Rename**, **Profile → Rename**) to
something distinctive, then re-run `backup_obs.sh`. This makes the backup
self-describing and avoids colliding with OBS's auto-created `Untitled`.
