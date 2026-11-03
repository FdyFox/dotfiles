-- Eigene Abweichungen von den Dux-Keybinds (dms/binds.lua)
-- Wird nach Dux geladen; hl.unbind() entfernt vorher die Dux-Belegung.
-- Achtung: hl.unbind() ist case-sensitive, Schreibweise wie in dms/binds.lua.

local terminal = "kitty"

local function rebind(keys, action, flags)
    hl.unbind(keys)
    return hl.bind(keys, action, flags)
end

-- Terminal auf SUPER + Q (Dux: Fenster schließen)
rebind("SUPER + Q", hl.dsp.exec_cmd(terminal))

-- Fenster schließen auf SUPER + C (wie bisher)
rebind("SUPER + C", hl.dsp.window.close())

-- Manual Sizing
rebind("SUPER + minus", hl.dsp.window.resize({ x = -100, y = 0, relative = true }), { repeating = true })
rebind("SUPER + plus", hl.dsp.window.resize({ x = 100, y = 0, relative = true }), { repeating = true })

rebind("SUPER + SHIFT + minus", hl.dsp.window.resize({ x = 0, y = -100, relative = true }), { repeating = true })
rebind("SUPER + SHIFT + plus", hl.dsp.window.resize({ x = 0, y = 100, relative = true }), { repeating = true })

-- Wallpaper-Karussell auf SUPER + W
rebind("SUPER + W", hl.dsp.exec_cmd("dms ipc call wallpaperCarousel toggle"))

