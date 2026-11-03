-- Ergänzungen zu den Dux-Defaults (nur was Dux nicht selbst setzt)

-- Von Dux empfohlen, aber nicht in der Stock-Config enthalten
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("QT_QPA_PLATFORMTHEME_QT6", "gtk3")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

hl.config({
    input = {
        -- Dux-Default ist leer (= "us"). Überschreibt auch Dux Settings -> Keyboard.
        kb_layout = "de",
    },
    misc = {
        vrr = 2, -- VRR nur im Vollbild (Gaming)
    },
})
