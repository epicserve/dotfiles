-- Displays: DP-1 = Dell AW2725QF (left), DP-2 = Dell U2720Q (right).
-- List monitors and supported modes with: hyprctl monitors all
hl.env("GDK_SCALE", "2")
-- AW2725QF: its EDID "preferred" mode is 4K@60, so request 4K@165 explicitly.
-- Fullscreen games on Wayland run at the compositor's refresh rate, so the
-- desktop must be at 165 Hz for games to get it. Not "highrr": on the U2720Q
-- that would pick a low-resolution 75 Hz fallback mode.
hl.monitor({ output = "DP-1", mode = "3840x2160@165", position = "auto", scale = 1.6 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1.6 })

-- Scale SourceGit (Avalonia/XWayland) to match the HiDPI monitor scale.
-- Avalonia has no GDK_SCALE equivalent, and Omarchy's defaults set
-- xwayland force_zero_scaling, so on a scaled monitor the app renders tiny.
-- AVALONIA_GLOBAL_SCALE_FACTOR scales the whole app, context menus included.
hl.env("AVALONIA_GLOBAL_SCALE_FACTOR", "1.5")

-- Workspaces: using Hyprland's stock dynamic model -- one global pool of
-- numbers, each workspace created on the focused monitor, whole workspaces
-- thrown between monitors with SUPER+SHIFT+ALT+arrows.
-- To restore the static grid (1-5 pinned to DP-1, 6-10 to DP-2), uncomment:
-- for ws = 1, 5 do
--   hl.workspace_rule({ workspace = tostring(ws), monitor = "DP-1", persistent = true })
-- end
-- for ws = 6, 10 do
--   hl.workspace_rule({ workspace = tostring(ws), monitor = "DP-2", persistent = true })
-- end
