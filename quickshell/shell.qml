import QtQuick
import Quickshell

// shell.qml — the entry point.
//
//   Island          the dynamic island (pill, dashboard, notification centre,
//                   wallpaper picker and shortcut cheat sheet)
//   WallpaperLayer  draws the wallpaper behind everything (replaces swaybg)
//   ClickCatcher    closes a pinned panel when you click outside of it
//
// Single monitor setup: the island and the wallpaper layer let the compositor
// pick the focused output. See README.md for how to make this multi-monitor.
ShellRoot {
	WallpaperLayer {}

	Island {
		id: island
	}

	ClickCatcher {
		visible: island.pinned
		onDismissed: island.close()
	}
}
