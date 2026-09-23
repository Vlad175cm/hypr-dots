hl.config({
    general = {
        border_size = 0,
        gaps_in = 8,
        gaps_out = 14,
        layout = "dwindle",
    },
    decoration = {
        rounding = 15,
        rounding_power = 2.0,
        inactive_opacity = 0.96,
        active_opacity = 0.97,
        fullscreen_opacity = 1.0,
        blur = { enabled = false },
        shadow = {
            enabled = true,
            range = 12,
            render_power = 3,
            color = "0x40000000",
        },
    },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 1,
        background_color = "0x000000",
        focus_on_activate = true,
        font_family = "Inter",
        middle_click_paste = false,
    },
})
