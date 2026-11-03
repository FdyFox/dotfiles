-- Eigene Window- und Workspace-Rules (zusätzlich zu Dux)
-- Dux-eigene Rules: Settings -> Applications -> Window rules (dms/windowrules.lua)
-- Monitor-Zuordnungen (z. B. DP-1) stehen in user/hosts/<host>.lua.
-- Hinweis: Hyprland-RegEx unterstützt keine Lookaheads (?!...).

local function rule(match, effects)
    effects.match = match
    return hl.window_rule(effects)
end

----------------
---- BASICS ----
----------------

-- Maximize-Requests von Apps ignorieren
rule({ class = ".*" }, { suppress_event = "maximize" })

-- XWayland Drag-Fix
rule({ class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false }, { no_focus = true })

-- Kein Idle/Lock bei Vollbild
rule({ class = ".*" }, { idle_inhibit = "fullscreen" })

--------------
---- TAGS ----
--------------

rule({ class = "^([Dd]iscord|[Ww]ebCord|[Vv]esktop)$" }, { tag = "+chat" })
rule({ class = "^([Ss]team)$" },                        { tag = "+gaming" })

----------------
---- GAMING ----
----------------

rule({ tag = "gaming" },                 { workspace = "5" })
rule({ class = "^steam_app_\\d+$" },     { fullscreen = true, workspace = "8" })
rule({ class = "^(Minecraft)$" },        { fullscreen = true, workspace = "8" })
rule({ class = "^(gamescope)$" },        { fullscreen = true })

-- Steam-Nebenfenster floaten (Hauptfenster "Steam" bleibt getiled)
rule({ class = "^([Ss]team)$", title = "^([Ss]team [Ss]ettings|Friends List|Steam - News.*|Special Offers)$" }, { float = true })
rule({ class = "^()$", title = "^(Steam - Self Updater)$" }, { float = true })

hl.workspace_rule({ workspace = "8", no_border = true, no_rounding = true })

--------------------------
---- APP -> WORKSPACE ----
--------------------------

rule({ tag = "chat" },                    { workspace = "9" })
rule({ class = "^(code)$" },              { workspace = "2" })
rule({ class = "^(obsidian)$" },          { workspace = "3" })
rule({ class = "^(crealityprint.exe)$" }, { workspace = "6", maximize = true })

---------------
---- FLOAT ----
---------------

local floating_classes = {
    "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$",
    "^(nm-applet|nm-connection-editor|blueman-manager)$",
    "^(nwg-look|qt5ct|qt6ct)$",
    "^(1Password)$",
    "^(xdg-desktop-portal-gtk|xdg-desktop-portal-kde|xdg-desktop-portal-hyprland)(.*)$",
    "^(polkit-gnome-authentication-agent-1|hyprpolkitagent|org.kde.polkit-kde-authentication-agent-1)(.*)$",
    "^(CachyOSHello)$",
    "^(zenity)$",
}
for _, c in ipairs(floating_classes) do
    rule({ class = c }, { float = true })
end

rule({ title = "^(.*Network Manager.*)$" },                    { float = true })
rule({ class = "^()$", title = "^(Picture in picture)$" },     { float = true })
rule({ class = "^()$", title = "^(Save File|Open File)$" },    { float = true })
rule({ class = "^(LibreWolf)$", title = "^(Picture-in-Picture)$" }, { float = true })

-----------------
---- OPACITY ----
-----------------

rule({ class = "^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr)$" }, { opacity = "1.0 0.8" })
rule({ class = "^([Dd]iscord|[Vv]esktop)$" },                         { opacity = "1.0 0.86" })
