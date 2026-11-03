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
