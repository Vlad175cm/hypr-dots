hl.config({
	general = {
		border_size = 0,
		gaps_in = 8,
		gaps_out = 10,
		layout = "dwindle",
	},
	decoration = {
		rounding = 15,
		rounding_power = 2,
		inactive_opacity = 0.96,
		active_opacity = 0.97,
		fullscreen_opacity = 1.0,
		blur = { enabled = false },
		shadow = {
			enabled = false,
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
		disable_autoreload = true,
		animate_manual_resizes = false,
		animate_mouse_windowdragging = false,
	},
	render = {
		new_render_scheduling = true,
		direct_scanout = 2,
	},
})
