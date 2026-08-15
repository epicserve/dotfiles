-- Displays: DP-1 = Dell AW2725QF (left), DP-2 = Dell U2720Q (right).
-- List monitors and supported modes with: hyprctl monitors all
hl.env("GDK_SCALE", "2")
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1.6 })

-- Scale SourceGit (Avalonia/XWayland) to match the HiDPI monitor scale.
-- Avalonia has no GDK_SCALE equivalent, and Omarchy's defaults set
-- xwayland force_zero_scaling, so on a scaled monitor the app renders tiny.
-- AVALONIA_GLOBAL_SCALE_FACTOR scales the whole app, context menus included.
hl.env("AVALONIA_GLOBAL_SCALE_FACTOR", "1.5")

-- Bind workspaces to specific monitors (dual-monitor desktop setup):
-- 1-5 on the left monitor, 6-10 on the right. Pinning to an absent monitor
-- is inert, so no monitor-count guard is needed.
for ws = 1, 5 do
  hl.workspace_rule({ workspace = tostring(ws), monitor = "DP-1", persistent = true })
end
for ws = 6, 10 do
  hl.workspace_rule({ workspace = tostring(ws), monitor = "DP-2", persistent = true })
end
