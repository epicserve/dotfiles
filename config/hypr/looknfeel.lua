-- Disable gaps by default
hl.config({ general = { gaps_in = 0, gaps_out = 0 } })

-- Larger default floating window (btop compatibility). Overrides Omarchy's
-- { size = { 875, 600 } } in /usr/share/omarchy/default/hypr/apps/system.lua;
-- this file loads after the defaults and later window rules win.
o.window({ tag = "floating-window" }, { size = { 1200, 800 } })

-- Red Dead Redemption 2 (XWayland): fullscreen the game window as soon as it
-- maps. RDR2 treats its initial window size as the desktop resolution, so a
-- tiled 2396x1320 window makes it "choose" 3834x2112. The title match skips
-- the tiny helper window the game also creates.
o.window({ class = "^steam_app_1174180$", title = "^Red Dead Redemption 2$" }, { fullscreen = true })
