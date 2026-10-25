import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Island.qml — the dynamic island itself.
//
// One layer surface that morphs between four shapes:
//   idle   → the pill (layout, clock, battery)
//   toast  → pill + a notification banner
//   osd    → pill + a volume / brightness strip
//   panel  → the full dashboard, notification centre, wallpaper picker or
//            cheat sheet (expanded on hover, or pinned by a keybind / click)
PanelWindow {
	id: island

	// ── state ──────────────────────────────────────────────────────────────

	property bool hovered: false
	property bool pinned: false
	// Esc asked the island to hide while the pointer is still on it. Hover is
	// ignored until the pointer leaves, so one Esc really does fold it away.
	property bool dismissed: false
	property string mode: "dashboard"
	property bool osdVisible: false
	property string osdKind: "volume"
	property bool panelMounted: false

	readonly property bool expanded: (island.hovered && !island.dismissed) || island.pinned

	onHoveredChanged: {
		// once the pointer is gone, hovering may open it again as usual
		if (!island.hovered) island.dismissed = false;
	}
	readonly property string state: island.expanded
		? "panel"
		: (island.osdVisible ? "osd" : (Notifs.popup !== null ? "toast" : "idle"))

	// Hovering always reveals the dashboard, a keybind pins a specific panel.
	// While the island is folded away the last panel simply stays loaded — that
	// way closing a panel does not instantiate the dashboard (which would start
	// cava for a frame).
	readonly property string activeMode: !island.expanded
		? island.mode
		: (island.pinned ? island.mode : "dashboard")
	readonly property var panelSize: Theme.panelSizes[island.activeMode] ?? Theme.panelSizes.dashboard
	readonly property int pad: Theme.panelPad

	// ── geometry ───────────────────────────────────────────────────────────

	// The collapsed pill hugs its content (IslandHeader.naturalWidth), so with
	// nothing on it but the clock it is a small capsule around the time.
	readonly property int targetWidth: {
		if (island.state === "panel") return island.panelSize.w + island.pad * 2;
		if (island.state === "toast") return Theme.toastW;
		if (island.state === "osd") return Theme.osdW;
		return Math.round(header.naturalWidth);
	}

	readonly property int stripHeight: island.state === "toast"
		? Theme.toastH
		: (island.state === "osd" ? Theme.osdH : 0)

	readonly property int targetHeight: Theme.pillH + island.stripHeight
		+ (island.state === "panel" ? island.pad * 2 + island.panelSize.h : 0)

	// ── window ─────────────────────────────────────────────────────────────

	// The layer surface keeps a constant size. Resizing it every animation frame
	// makes the compositor reallocate the buffer and Qt re-evaluate every
	// binding in the tree, and that is what made the morph stutter. Only the
	// island box inside the surface is animated; the input region follows it.
	readonly property int surfaceWidth: {
		let widest = Math.max(Theme.pillW, Theme.toastW, Theme.osdW);
		for (const key in Theme.panelSizes)
			widest = Math.max(widest, Theme.panelSizes[key].w + island.pad * 2);
		return widest;
	}

	readonly property int surfaceHeight: {
		let tallest = Theme.pillH + Theme.toastH;
		for (const key in Theme.panelSizes)
			tallest = Math.max(tallest, Theme.pillH + island.pad * 2 + Theme.panelSizes[key].h);
		return tallest;
	}

	visible: true
	color: "transparent"
	implicitWidth: island.surfaceWidth
	implicitHeight: island.surfaceHeight

	anchors { top: true }
	// the pill floats a little below the top edge
	margins { top: Theme.edgeMargin }
	exclusiveZone: Theme.reserveTop
	exclusionMode: ExclusionMode.Normal

	WlrLayershell.layer: WlrLayer.Overlay
	WlrLayershell.namespace: "quickshell-island"
	WlrLayershell.keyboardFocus: island.pinned ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

	mask: Region {
		x: box.x
		y: box.y
		width: box.width
		height: box.height
		radius: surface.radius
	}

	// ── public api (also exposed over ipc) ────────────────────────────────

	function openMode(name: string): void {
		if (Theme.panelSizes[name] === undefined) return;

		const wasPinned = island.pinned;

		island.mode = name;
		island.pinned = true;
		island.osdVisible = false;
		if (name === "notifications") Notifs.markRead();

		// Panels are never unloaded, so a genuinely fresh open has to be
		// announced: this is how the launcher clears its search field. Pressing
		// the key again while it is already open must not wipe what is typed.
		if (!wasPinned && panel.item && panel.item.reset !== undefined)
			panel.item.reset();
	}

	function close(): void {
		island.pinned = false;
		// pressing Esc with the pointer resting on the island must actually
		// fold it away — remember that so hover does not open it right back
		island.dismissed = island.hovered;
	}

	function toggle(): void {
		if (island.pinned) island.close();
		else island.openMode(island.mode);
	}

	// the "main panel": what tapping the pill or pressing SUPER+A opens.
	// Unlike toggle() it always lands on the dashboard, whatever was open last.
	function toggleDashboard(): void {
		if (island.pinned && island.mode === "dashboard") island.close();
		else island.openMode("dashboard");
	}

	function showOsd(kind: string): void {
		island.osdKind = kind;
		if (kind === "volume") Sys.refreshVolume();

		if (island.osdVisible) {
			// already on screen: just keep it there, the value updates itself
			osdTimer.restart();
			return;
		}

		osdShowTimer.restart();
	}

	// ── panel visibility ──────────────────────────────────────────────────

	onExpandedChanged: {
		island.panelMounted = island.expanded;

		if (island.expanded) {
			island.pendingFocusAddress = "";
			// remember whose window we take the keyboard from — a plain hover
			// never grabs it, so nothing is remembered and nothing is handed
			// back (refocusing then would yank the cursor into that window)
			if (island.pinned) {
				island.focusReturnAddress = Sys.activeWindowAddress;
				island.keyboardGrabbed = true;
			}
		} else {
			// let the compositor drop our keyboard grab first
			focusReturnTimer.restart();
		}
	}

	Component.onCompleted: island.panelMounted = island.expanded

	// ── giving the focus back ──────────────────────────────────────────────
	// A *pinned* island holds the keyboard exclusively, so it has to hand it
	// back when it closes — otherwise typing goes into nowhere and a window you
	// open afterwards never gets focus. Merely hovering never grabs anything,
	// so nothing is handed back and nothing is refocused (which would otherwise
	// make Hyprland warp the cursor into the focused window).

	property string focusReturnAddress: ""
	property string pendingFocusAddress: ""
	property bool keyboardGrabbed: false

	// the grab begins the moment the island is pinned
	onPinnedChanged: {
		if (island.pinned) {
			island.focusReturnAddress = Sys.activeWindowAddress;
			island.keyboardGrabbed = true;
		}
	}

	Timer {
		id: focusReturnTimer

		interval: 80
		onTriggered: island.returnFocus()
	}

	function returnFocus(): void {
		if (island.expanded) return;
		if (!island.keyboardGrabbed) return;

		island.keyboardGrabbed = false;

		// a window opened while a panel was on screen: it gets the keyboard
		if (island.pendingFocusAddress !== "") {
			const target = island.pendingFocusAddress;
			island.pendingFocusAddress = "";
			island.focusReturnAddress = "";
			Sys.focusWindow(target);
			return;
		}

		Sys.focusWindowOrLast(island.focusReturnAddress);
		island.focusReturnAddress = "";
	}

	// a window opened while a panel is on screen: close up and let it take over
	Connections {
		target: Sys

		function onWindowOpened(address) {
			if (!island.expanded) return;
			island.pendingFocusAddress = address;
			island.close();
		}
	}

	// tells the panels whether they are actually on screen, so that things
	// like cava only run while the island is open
	onPanelMountedChanged: Sys.panelOpen = island.panelMounted

	// only scan for wifi networks while a panel that shows the list is open
	readonly property bool scanning: island.panelMounted
		&& (island.activeMode === "dashboard" || island.activeMode === "info")
	onScanningChanged: Sys.scanWifi = island.scanning

	// the volume OSD follows pipewire (see Sys), the brightness one the sysfs poll
	Connections {
		target: Sys

		function onVolumeAdjusted() {
			if (!island.expanded) island.showOsd("volume");
		}
	}

	Timer {
		id: osdTimer

		interval: 1500
		onTriggered: island.osdVisible = false
	}

	// Pipewire notifies us about a change *before* the new value has reached
	// us, so showing the pill immediately made it flash the previous value
	// (a literal 0% when turning sound up from silence). Showing it one beat
	// later means the first frame already shows the real level.
	Timer {
		id: osdShowTimer

		interval: 80
		onTriggered: {
			island.osdVisible = true;
			osdTimer.restart();
		}
	}

	// the backlight is polled from sysfs, so the OSD follows the F5/F6 keys
	// (or anything else that touches the backlight) without any helper process
	Connections {
		target: Sys

		function onBacklightAdjusted() {
			if (!island.expanded) island.showOsd("brightness");
		}
	}

	// ── the island box (this is what morphs) ───────────────────────────────

	Item {
		id: box

		anchors.top: parent.top
		anchors.horizontalCenter: parent.horizontalCenter
		width: island.targetWidth
		height: island.targetHeight

		Behavior on width {
			NumberAnimation { duration: Theme.dur; easing.type: Theme.easeMorph }
			}

		Behavior on height {
			NumberAnimation { duration: Theme.dur; easing.type: Theme.easeMorph }
			}

		// FocusScope, not Item: an Item with focus:true keeps the focus for
		// itself, which stopped the launcher's search field from ever getting
		// keyboard input.
		FocusScope {
			id: content

			anchors.fill: parent
			focus: island.pinned
			Keys.onEscapePressed: island.close()

			// The island silhouette: one rounded rectangle, drawn as a single
			// path with antialiased curves. The corner radius follows the state
			// (a capsule when collapsed, a card when open). The content lives in
			// the transparent, clipped `surface` drawn on top of it.
			Shape {
				id: islandShape

				// antialiased curves — the default geometry renderer shows the
				// arcs as a visible staircase at 1x scaling
				preferredRendererType: Shape.CurveRenderer

				readonly property real r: Math.max(0, Math.min(surface.cornerRadius, height / 2))

				x: 0
				y: 0
				width: content.width
				height: content.height

				ShapePath {
					fillColor: Theme.island
					strokeColor: "transparent"
					strokeWidth: 0

					startX: islandShape.r
					startY: 0
					PathLine { x: islandShape.width - islandShape.r; y: 0 }
					PathArc {
						x: islandShape.width
						y: islandShape.r
						radiusX: islandShape.r
						radiusY: islandShape.r
						direction: PathArc.Clockwise
					}
					PathLine { x: islandShape.width; y: islandShape.height - islandShape.r }
					PathArc {
						x: islandShape.width - islandShape.r
						y: islandShape.height
						radiusX: islandShape.r
						radiusY: islandShape.r
						direction: PathArc.Clockwise
					}
					PathLine { x: islandShape.r; y: islandShape.height }
					PathArc {
						x: 0
						y: islandShape.height - islandShape.r
						radiusX: islandShape.r
						radiusY: islandShape.r
						direction: PathArc.Clockwise
					}
					PathLine { x: 0; y: islandShape.r }
					PathArc {
						x: islandShape.r
						y: 0
						radiusX: islandShape.r
						radiusY: islandShape.r
						direction: PathArc.Clockwise
					}
				}
			}

			Rectangle {
				id: surface

				anchors.fill: parent
				// the silhouette is drawn by islandShape behind us; this layer
				// only clips the content and feeds the input mask
				color: "transparent"

				property real cornerRadius: island.state === "panel"
					? Theme.radiusPanel
					: (island.state === "idle" ? Theme.radiusPill : Theme.radiusCard + 5)

				radius: surface.cornerRadius
				clip: true

				Behavior on cornerRadius {
					NumberAnimation { duration: Theme.dur; easing.type: Theme.easeMorph }
					}


				HoverHandler {
					id: surfaceHover

					onHoveredChanged: island.hovered = hovered
					}

				IslandHeader {
					id: header

					anchors.top: parent.top
					anchors.left: parent.left
					anchors.right: parent.right
					expanded: island.expanded
					pinned: island.pinned

					onCloseRequested: island.close()
					onActivated: island.toggleDashboard()
					}

				Toast {
					id: toast

					anchors.top: header.bottom
					anchors.left: parent.left
					anchors.right: parent.right
					height: Theme.toastH
					visible: island.state === "toast"
					}

				OsdStrip {
					id: osd

					anchors.top: header.bottom
					anchors.left: parent.left
					anchors.right: parent.right
					height: Theme.osdH
					visible: island.state === "osd"
					kind: island.osdKind
					}

				// The panel keeps its design size and is only revealed by the
				// growing surface: the morph therefore never re-lays out the
				// hundreds of items inside a panel.
				Item {
					id: body

					anchors.top: header.bottom
					anchors.topMargin: island.pad
					anchors.horizontalCenter: parent.horizontalCenter
					width: island.panelSize.w
					height: island.panelSize.h

					opacity: island.panelMounted ? 1 : 0
					scale: island.panelMounted ? 1 : Theme.revealScale
					transformOrigin: Item.Top
					transform: Translate {
						id: revealSlide

						y: island.panelMounted ? 0 : Theme.revealSlide

						Behavior on y {
							NumberAnimation { duration: Theme.durReveal; easing.type: Theme.easeSoft }
							}
						}

					Behavior on opacity {
						NumberAnimation { duration: Theme.durFast; easing.type: Theme.easeOut }
						}

					Behavior on scale {
						NumberAnimation { duration: Theme.durReveal; easing.type: Theme.easeOut }
						}

					Loader {
						id: panel

						anchors.fill: parent
						// deliberately never unmounted: creating ~250 items in the middle
						// of the morph animation drops frames
						active: true

						sourceComponent: {
							if (island.activeMode === "launcher") return launcherPanel;
							if (island.activeMode === "battery") return batteryPanel;
							if (island.activeMode === "info") return infoPanel;
							if (island.activeMode === "notifications") return notifPanel;
							if (island.activeMode === "wallpapers") return wallsPanel;
							if (island.activeMode === "keys") return keysPanel;
							if (island.activeMode === "clipboard") return clipboardPanel;
							return dashPanel;
							}

						onLoaded: {
							// let panels ask the island to fold back up
							if (panel.item && panel.item.requestClose !== undefined)
							panel.item.requestClose.connect(island.close);
							}
						}
					}
				}
			}
	}

	// ── panels ─────────────────────────────────────────────────────────────

	Component { id: dashPanel; PanelDashboard {} }
	Component { id: launcherPanel; PanelLauncher {} }
	Component { id: batteryPanel; PanelBattery {} }
	Component { id: infoPanel; PanelInfo {} }
	Component { id: notifPanel; PanelNotifs {} }
	Component { id: wallsPanel; PanelWalls {} }
	Component { id: keysPanel; PanelKeys {} }
	Component { id: clipboardPanel; PanelClipboard {} }

	// ── ipc: qs ipc call island <method> ───────────────────────────────────

	IpcHandler {
		target: "island"

		function open(mode: string): void {
			island.openMode(mode);
		}

		function toggle(): void {
			island.toggle();
		}

		function dashboard(): void {
			island.toggleDashboard();
		}

		function close(): void {
			island.close();
		}

		function osd(kind: string): void {
			island.showOsd(kind);
		}
	}

}
