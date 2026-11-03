-- Eigene Autostart-Programme
-- Dux selbst startet über systemd (dms.service an hyprland-session.target).

local scripts = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/hypr/scripts"

hl.on("hyprland.start", function()
    -- Clipboard Wayland -> X11 (XWayland-Apps)
    hl.exec_cmd(scripts .. "/clipboard-sync.sh")

    -- OneDrive verzögert starten
    hl.exec_cmd("sleep 20 && OneDriveGUI")
end)
