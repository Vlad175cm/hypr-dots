pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Walls.qml — wallpaper list, previews and the apply/crossfade flow.
//
// The heavy lifting (listing, generating previews, running matugen) lives in
// scripts/wallpapers.sh so that nothing blocks the QML thread.
Singleton {
	id: walls

	readonly property string home: Quickshell.env("HOME")
	readonly property string dir: home + "/.wallpapers"
	readonly property string script: Quickshell.shellPath("scripts/wallpapers.sh")
	readonly property string statePath: home + "/.local/state/hypr/wallpaper"

	property var list: []
	property string current: ""
	property bool ready: false
	property bool busy: false
	property bool generating: false
	property string filter: ""
	property string error: ""

	readonly property var filtered: {
		const query = walls.filter.trim().toLowerCase();
		if (query === "") return walls.list;
		return walls.list.filter(w => w.name.toLowerCase().indexOf(query) >= 0);
	}

	// ── listing ────────────────────────────────────────────────────────────

	Process {
		id: listProc

		command: ["bash", walls.script, "list"]
		onRunningChanged: walls.busy = running

		stdout: StdioCollector {
			onStreamFinished: {
				try {
					const data = JSON.parse(text);
					walls.list = data.wallpapers ?? [];
					walls.current = data.current ?? "";
					walls.ready = true;
					walls.error = "";
				} catch (e) {
					walls.error = "could not read " + walls.dir + " (" + e + ")";
					console.warn("[walls]", walls.error);
				}
			}
		}
	}

	// ── preview generation ─────────────────────────────────────────────────

	Process {
		id: thumbsProc

		command: ["bash", walls.script, "thumbs"]

		stdout: SplitParser {
			onRead: line => {
				if (line.trim() === "done") {
					walls.generating = false;
					walls.refresh();
				}
			}
		}
	}

	function refresh(): void {
		if (!listProc.running) listProc.running = true;
	}

	function generateMissing(): void {
		if (thumbsProc.running) return;
		const missing = walls.list.filter(w => !w.thumb).length;
		if (missing === 0) return;
		walls.generating = true;
		thumbsProc.running = true;
	}

	// ── applying ───────────────────────────────────────────────────────────

	Process {
		id: applyProc
	}

	function apply(path: string): void {
		if (path === "" || path === walls.current) return;

		// instant visual feedback …
		walls.current = path;

		// … then persist it and re-run matugen in the background.
		applyProc.command = ["bash", walls.script, "apply", path];
		applyProc.running = true;
	}

	function openDir(): void {
		Quickshell.execDetached(["xdg-open", walls.dir]);
	}

	// ── startup ────────────────────────────────────────────────────────────

	Component.onCompleted: refresh()

	Timer {
		// pick up wallpapers added while the shell is running
		interval: 30000
		running: true
		repeat: true
		onTriggered: {
			const missing = walls.list.filter(w => !w.thumb).length;
			if (missing > 0) walls.generateMissing();
		}
	}
}
