-- Disable gaps by default
hl.config({ general = { gaps_in = 0, gaps_out = 0 } })

-- Larger default floating window (btop compatibility). Overrides Omarchy's
-- { size = { 875, 600 } } in /usr/share/omarchy/default/hypr/apps/system.lua;
-- this file loads after the defaults and later window rules win.
o.window({ tag = "floating-window" }, { size = { 1200, 800 } })
