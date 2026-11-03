-- Host: Otto (Desktop, NVIDIA, 3 Monitore)
-- Monitore (Auflösung, Position, HDR) werden in Dux eingestellt:
-- Settings -> Displays (dms/outputs.lua). Alte Werte zum Nachtragen:
--   HDMI-A-2  1920x1200@60   pos 3887x2876  (links)
--   DP-1      2560x1440@165  pos 5807x2771  (mitte, HDR + wide color)
--   HDMI-A-1  1920x1200@60   pos 8367x2533  transform 1 (rechts, hochkant)

require("user.nvidia")

--------------------
---- WORKSPACES ----
--------------------

hl.workspace_rule({ workspace = "1",  monitor = "DP-1",     default = true }) -- Main
hl.workspace_rule({ workspace = "9",  monitor = "HDMI-A-1", default = true }) -- Social
hl.workspace_rule({ workspace = "10", monitor = "HDMI-A-2", default = true }) -- Auslagern

-------------------------------
---- APPS AUF HAUPTMONITOR ----
-------------------------------

for _, c in ipairs({ "^steam_app_\\d+$", "^(Minecraft)$", "^(gamescope)$", "^(crealityprint.exe)$" }) do
    hl.window_rule({ match = { class = c }, monitor = "DP-1" })
end

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("flatpak run --command=/app/bin/launch.sh com.core447.StreamController -b")
end)
