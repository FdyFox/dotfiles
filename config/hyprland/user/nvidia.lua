-- NVIDIA - wird aus user/hosts/<host>.lua geladen
-- https://wiki.hypr.land/nvidia/

hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")

hl.config({
    cursor = {
        no_hardware_cursors = 1,
    },

    -- Flicker-Workaround: https://github.com/hyprwm/Hyprland/issues/7252#issuecomment-2345792172
    -- damage_tracking = 0 und vfr = false kosten deutlich Leistung. Mit aktuellen
    -- Treibern (explicit sync) testweise auskommentieren.
    opengl = {
        nvidia_anti_flicker = false,
    },
    debug = {
        damage_tracking = 0,
        vfr             = false,
    },
})
