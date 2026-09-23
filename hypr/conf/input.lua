hl.config({
    input = {
        kb_layout = "us,ru",
        kb_variant = "",
        kb_options = "grp:win_space_toggle",
        repeat_rate = 40,
        repeat_delay = 250,
        follow_mouse = 1,
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
            clickfinger_behavior = true,
            scroll_factor = 0.4,
            drag_3fg = 1,
            disable_while_typing = true,
        },
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
