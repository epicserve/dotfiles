-- Omarchy Quattro keybinding overrides (Lua port of the legacy _bindings.conf).
-- Loaded by ~/.config/hypr/hyprland.lua via require("hypr.bindings"), AFTER
-- Omarchy's defaults, so hl.unbind() removes a default bind before rebinding.
-- API reference: /usr/share/hypr/stubs/hl.meta.lua and /usr/share/omarchy/default/hypr/.

-- Send a key chord to the focused surface. Copied from Omarchy's
-- /usr/share/omarchy/default/hypr/bindings/clipboard.lua: the down/up split
-- works around Hyprland send_shortcut sometimes leaving synthetic key state
-- stuck/repeating (https://github.com/hyprwm/Hyprland/discussions/14099).
-- If a chord misfires, fall back per bind to hl.dsp.send_shortcut or to the
-- exec string "hyprctl dispatch sendshortcut CTRL, X, activewindow".
local function send_shortcut_once(mods, key)
  return function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))

    hl.timer(function()
      hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
    end, { timeout = 50, type = "oneshot" })
  end
end

-- Reassign the scratchpad shortcut (SUPER+S / SUPER+ALT+S become senders below)
hl.unbind("SUPER + S")
hl.unbind("SUPER + ALT + S")
-- TODO: Fix the new scratchpad shortcut
-- o.bind("ALT + SHIFT + S", "Toggle scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))

-- Reassign the Ghostty shortcut
hl.unbind("SUPER + RETURN")
o.bind("SUPER + ALT + T", "Terminal", { launch = "ghostty" })

-- Reassign Keyboard Bindings Shortcut (v4 puts tmux keybindings on SUPER+ALT+K)
hl.unbind("SUPER + K")
hl.unbind("SUPER + ALT + K")
o.bind("SUPER + ALT + K", "Show key bindings", "omarchy-menu-keybindings")

-- Screenshots (v4 puts the Google Maps webapp on SUPER+SHIFT+S)
hl.unbind("SUPER + SHIFT + S")
o.bind("SUPER + SHIFT + S", "Screenshot with editing", "omarchy-capture-screenshot")

-- Reassign Window Management Shortcuts
hl.unbind("SUPER + T") -- v4: toggle floating; SUPER+T becomes a CTRL+T sender
hl.unbind("SUPER + F") -- v4: full screen; SUPER+F becomes a CTRL+F sender
hl.unbind("SUPER + ALT + F") -- v4: full width
o.bind("SUPER + ALT + F", "Full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.unbind("SUPER + SHIFT + LEFT") -- v4: swap window; becomes a selection sender
hl.unbind("SUPER + SHIFT + RIGHT")
o.bind("SUPER + ALT + CTRL + LEFT", "Swap window to the left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + ALT + CTRL + RIGHT", "Swap window to the right", hl.dsp.window.swap({ direction = "r" }))
hl.unbind("SUPER + O") -- v4: pop window out; SUPER+O becomes a CTRL+O sender
o.bind("ALT + O", "Pop window out (float & pin)", "omarchy-hyprland-window-pop")

-- Make SUPER + Letter send CTRL + Letter (SUPER+C/V/X already do this in v4)
hl.unbind("SUPER + L") -- v4: toggle workspace layout
hl.unbind("SUPER + SLASH") -- v4: monitor scaling
o.bind("SUPER + A", "Send CTRL+A", send_shortcut_once("CTRL", "A"))
o.bind("SUPER + D", "Send CTRL+D", send_shortcut_once("CTRL", "D"))
o.bind("SUPER + F", "Send CTRL+F", send_shortcut_once("CTRL", "F"))
o.bind("SUPER + L", "Send CTRL+L", send_shortcut_once("CTRL", "L"))
o.bind("SUPER + O", "Send CTRL+O", send_shortcut_once("CTRL", "O"))
o.bind("SUPER + Q", "Send CTRL+Q", send_shortcut_once("CTRL", "Q"))
o.bind("SUPER + R", "Send CTRL+R", send_shortcut_once("CTRL", "R"))
o.bind("SUPER + S", "Send CTRL+S", send_shortcut_once("CTRL", "S"))
o.bind("SUPER + T", "Send CTRL+T", send_shortcut_once("CTRL", "T"))
o.bind("SUPER + Z", "Send CTRL+Z", send_shortcut_once("CTRL", "Z"))
o.bind("SUPER + SLASH", "Send CTRL+/", send_shortcut_once("CTRL", "slash"))
o.bind("SUPER + RETURN", "Send CTRL+Enter", send_shortcut_once("CTRL", "Return"))

-- Reassign toggling a floating window (nothing binds SUPER+SHIFT+T in v4)
o.bind("SUPER + SHIFT + T", "Toggle window floating/tiling", hl.dsp.window.float({ action = "toggle" }))

-- Mac-like cursor movement bindings; window focus moves to SUPER+ALT+arrows
hl.unbind("SUPER + LEFT") -- v4: focus; SUPER+arrows become cursor-movement senders
hl.unbind("SUPER + RIGHT")
hl.unbind("SUPER + UP")
hl.unbind("SUPER + DOWN")
hl.unbind("SUPER + ALT + LEFT") -- v4: move window into group
hl.unbind("SUPER + ALT + RIGHT")
hl.unbind("SUPER + ALT + UP")
hl.unbind("SUPER + ALT + DOWN")
hl.unbind("SUPER + SHIFT + UP") -- v4: swap window; becomes a selection sender
hl.unbind("SUPER + SHIFT + DOWN")
o.bind("SUPER + ALT + LEFT", "Move window focus left", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + ALT + RIGHT", "Move window focus right", hl.dsp.focus({ direction = "r" }))
o.bind("SUPER + ALT + UP", "Move window focus up", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + ALT + DOWN", "Move window focus down", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + UP", "Move cursor to the top of the page", send_shortcut_once("CTRL", "Home"))
o.bind("SUPER + SHIFT + UP", "Select text to the start of page", send_shortcut_once("CTRL SHIFT", "Home"))
o.bind("SUPER + DOWN", "Move cursor to the bottom of the page", send_shortcut_once("CTRL", "End"))
o.bind("SUPER + SHIFT + DOWN", "Select text to the end of page", send_shortcut_once("CTRL SHIFT", "End"))
o.bind("SUPER + LEFT", "Move the cursor to the start of the line", send_shortcut_once("", "Home"))
o.bind("SUPER + SHIFT + LEFT", "Select text to the start of the line", send_shortcut_once("SHIFT", "Home"))
o.bind("SUPER + RIGHT", "Move cursor to the end of the line", send_shortcut_once("", "End"))
o.bind("SUPER + SHIFT + RIGHT", "Select text to the end of the line", send_shortcut_once("SHIFT", "End"))

-- Override Signal (adds the keyring password-store flag)
hl.unbind("SUPER + SHIFT + G")
o.bind("SUPER + SHIFT + G", "Open Signal", { launch = 'signal-desktop --password-store="gnome-libsecret"' })

-- System Power (v4 puts a calculator on SUPER+CTRL+Q; it stays on XF86Calculator)
hl.unbind("SUPER + CTRL + Q")
o.bind("SUPER + CTRL + Q", "Suspend desktop", "systemctl suspend")
