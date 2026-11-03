-- Einstiegspunkt für eigene Ergänzungen zur Dux-Config.
--
-- ~/.config/hypr/hyprland.lua und dms/*.lua gehören Dux (`dms setup`).
-- Das Install-Script hängt dort nur `require("user.main")` ans Ende.
-- Alles hier wird also NACH den Dux-Defaults geladen und gewinnt.
--
-- Bewusst Dux überlassen: Keybinds (Ausnahmen in user/keybinds.lua), Monitore, Cursor, Gaps/Rahmen/Farben,
-- Animationen, Lockscreen/Idle, Bar, Notifications, Startup (systemd).
-- Anpassungen dafür: Dux Settings (SUPER + comma) oder dms/binds-user.lua.

require("user.settings")
require("user.autostart")
require("user.keybinds")
require("user.windowrules")
require("user.layout")

-- Host-spezifisches: user/hosts/<hostname>.lua (optional)
local function hostname()
    local f = io.open("/proc/sys/kernel/hostname", "r")
    if not f then return nil end
    local name = f:read("*l")
    f:close()
    return name
end

local host    = hostname()
local confdir = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/hypr"
if host then
    local f = io.open(confdir .. "/user/hosts/" .. host .. ".lua", "r")
    if f then
        f:close()
        require("user.hosts." .. host)
    end
end
