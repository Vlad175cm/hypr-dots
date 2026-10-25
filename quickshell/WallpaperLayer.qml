import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// WallpaperLayer.qml — draws the wallpaper behind everything, so quickshell
// can crossfade between wallpapers instead of restarting a separate program
// (this replaces swaybg).
PanelWindow {
	id: layer

	visible: true
	color: "black"

	anchors {
		top: true
		bottom: true
		left: true
		right: true
	}

	// note: do NOT set exclusiveZone here — quickshell turns that into
	// ExclusionMode.Normal, and the compositor would then push this surface
	// below the island's reserved strip
	exclusionMode: ExclusionMode.Ignore
	WlrLayershell.layer: WlrLayer.Background
	WlrLayershell.namespace: "quickshell-wallpaper"
	WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

	// click-through: an empty input region
	mask: Region {}

	property string backSource: ""
	property string frontSource: ""
	property bool fading: false
	property bool initialised: false

	function display(path: string): void {
		if (path === "") return;

		if (!layer.initialised) {
			layer.initialised = true;
			layer.backSource = path;
			layer.frontSource = path;
			front.opacity = 1;
			return;
		}

		if (path === layer.frontSource) return;

		// the current image stays visible on the back layer while the new one
		// loads and fades in on top of it
		layer.backSource = layer.frontSource;
		layer.frontSource = path;
		layer.fading = true;
		front.opacity = 0;

		// if it is already decoded (cached) no status change will arrive
		if (front.status === Image.Ready) layer.runFade();
	}

	function runFade(): void {
		if (!layer.fading) return;
		layer.fading = false;
		fade.restart();
	}

	// paint the remembered wallpaper immediately, without waiting for the
	// wallpaper index to load
	FileView {
		id: stateFile

		path: Walls.statePath
		preload: true

		onLoaded: {
			const remembered = stateFile.text().trim();
			if (remembered !== "") layer.display(remembered);
		}
	}

	Connections {
		target: Walls

		function onCurrentChanged() {
			layer.display(Walls.current);
		}
	}

	Image {
		id: back

		anchors.fill: parent
		source: layer.backSource
		fillMode: Image.Stretch
		asynchronous: true
		cache: true
		sourceSize.width: Math.max(1, layer.width)
		sourceSize.height: Math.max(1, layer.height)
	}

	Image {
		id: front

		anchors.fill: parent
		source: layer.frontSource
		fillMode: Image.Stretch
		asynchronous: true
		cache: true
		opacity: 0
		sourceSize.width: Math.max(1, layer.width)
		sourceSize.height: Math.max(1, layer.height)

		onStatusChanged: {
			if (status === Image.Ready) layer.runFade();
		}

		NumberAnimation {
			id: fade

			target: front
			property: "opacity"
			from: 0
			to: 1
			duration: Theme.dur
			easing.type: Easing.InOutSine

			onFinished: {
				layer.backSource = layer.frontSource;
				front.opacity = 0;
			}
		}
	}
}
