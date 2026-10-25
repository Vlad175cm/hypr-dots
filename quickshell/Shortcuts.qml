pragma Singleton

import QtQuick
import Quickshell

// Shortcuts.qml — the shortcut cheat sheet shown by the island (SUPER + K).
//
// This is a static list: it is not parsed out of ~/.config/hypr/conf/binds.lua,
// so if you add a bind, add it here too.
Singleton {
	readonly property var groups: [
		{
			title: "Island",
			items: [
				{ keys: ["SUPER", "A"], desc: "Main panel (the dashboard)" },
				{ keys: ["SUPER", "D"], desc: "App launcher" },
				{ keys: ["SUPER", "W"], desc: "Wallpaper picker" },
				{ keys: ["SUPER", "N"], desc: "Notification centre" },
				{ keys: ["SUPER", "K"], desc: "This cheat sheet" },
				{ keys: ["SUPER", "C"], desc: "System info" },
				{ keys: ["SUPER", "SHIFT", "B"], desc: "Battery details" },
				{ keys: ["SUPER", "SHIFT", "V"], desc: "Clipboard history" },
				{ keys: ["hover"], desc: "Expand the island" },
				{ keys: ["ESC"], desc: "Close a pinned panel" }
			]
		},
		{
			title: "Launchers",
			items: [
				{ keys: ["SUPER", "Return"], desc: "Terminal — kitty" },
				{ keys: ["SUPER", "B"], desc: "Browser — zen" },
				{ keys: ["SUPER", "E"], desc: "Files — yazi" },
				{ keys: ["SUPER", "T"], desc: "Telegram" },
				{ keys: ["SUPER", "D"], desc: "Anything else" }
			]
		},
		{
			title: "Yazi",
			items: [
				{ keys: ["j", "k"], desc: "Down / up" },
				{ keys: ["h", "l"], desc: "Parent / enter" },
				{ keys: ["gg", "G"], desc: "Top / bottom" },
				{ keys: ["Space"], desc: "Select" },
				{ keys: ["y", "x", "p"], desc: "Copy / cut / paste" },
				{ keys: ["d"], desc: "Trash" },
				{ keys: ["a"], desc: "New file / folder" },
				{ keys: ["r"], desc: "Rename" },
				{ keys: ["v"], desc: "Visual select" },
				{ keys: [".", "f", "/"], desc: "Hidden / filter / search" },
				{ keys: ["z"], desc: "Jump — zoxide" },
				{ keys: ["~"], desc: "Help" },
				{ keys: ["q"], desc: "Quit" }
			]
		},
		{
			title: "Windows",
			items: [
				{ keys: ["SUPER", "Q"], desc: "Close window" },
				{ keys: ["SUPER", "F"], desc: "Fullscreen" },
				{ keys: ["SUPER", "ALT", "F"], desc: "Float / tile" },
				{ keys: ["SUPER", "V"], desc: "Toggle split" },
				{ keys: ["SUPER", "←↑↓→"], desc: "Move focus" },
				{ keys: ["SUPER", "ALT", "←↑↓→"], desc: "Move window" }
			]
		},
		{
			title: "Workspaces",
			items: [
				{ keys: ["SUPER", "1…0"], desc: "Go to workspace" },
				{ keys: ["SUPER", "SHIFT", "1…0"], desc: "Send window there" },
				{ keys: ["3 fingers"], desc: "Swipe workspaces" },
				{ keys: ["SUPER", "Space"], desc: "Switch keyboard layout" }
			]
		},
		{
			title: "Session",
			items: [
				{ keys: ["SUPER", "L"], desc: "Lock — hyprlock" },
				{ keys: ["SUPER", "S"], desc: "Exit hyprland" },
				{ keys: ["SUPER", "SHIFT", "R"], desc: "Reload hyprland" },
				{ keys: ["F1-F3"], desc: "Volume / mute" },
				{ keys: ["F5-F6"], desc: "Brightness" },
				{ keys: ["F7-F8"], desc: "Keyboard backlight" }
			]
		},
		{
			title: "Screenshots",
			items: [
				{ keys: ["SUPER", "SHIFT", "A"], desc: "Region → clipboard" },
				{ keys: ["SUPER", "SHIFT", "W"], desc: "Window → clipboard" },
				{ keys: ["SUPER", "SHIFT", "F"], desc: "Full screen" }
			]
		}
	]
}
