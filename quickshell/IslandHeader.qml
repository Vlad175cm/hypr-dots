import QtQuick

// IslandHeader.qml — the always visible top row of the island.
// Collapsed it is the whole pill; expanded it becomes the panel header.
Item {
	id: header

	property bool expanded: false
	property bool pinned: false
	property date now: new Date()

	signal closeRequested()

	implicitHeight: Theme.pillH

	// The collapsed pill hugs its content: it is exactly as wide as the widest
	// cluster needs, so with nothing on it but the clock it turns into a small
	// capsule around the time.
	readonly property real sideExtent: Math.max(leftCluster.implicitWidth, rightCluster.implicitWidth)
	readonly property real naturalWidth: centre.implicitWidth + 24
		+ (sideExtent > 0 ? 2 * (sideExtent + 8) : 0)

	readonly property string time: Qt.formatTime(header.now, "HH:mm")

	signal activated()

	// a tap on the pill pins the panel open (or closes it again)
	TapHandler {
		onTapped: header.activated()
	}

	// self correcting clock: re-align to the top of every second
	Timer {
		interval: 1000
		running: true
		repeat: true
		triggeredOnStart: true
		onTriggered: {
			header.now = new Date();
			interval = 1000 - (Date.now() % 1000);
		}
	}

	HoverHandler { id: headerHover }

	// ── left: caps warning (workspace number and layout were removed — they
	// are not needed on the panels) ────────────────────────────────────────

	Row {
		id: leftCluster

		anchors.left: parent.left
		anchors.leftMargin: 12
		anchors.verticalCenter: parent.verticalCenter

		spacing: 5

		Chip {
			anchors.verticalCenter: parent.verticalCenter
			visible: Sys.capsLock
			label: "CAPS"
			size: 9
			hPad: 6
			vPad: 2
			tint: Theme.warn
			fill: Theme.alpha(Theme.warn, 0.14)
		}
	}

	// ── centre: the clock ──────────────────────────────────────────────────

	Row {
		id: centre

		anchors.centerIn: parent

		Text {
			anchors.verticalCenter: parent.verticalCenter
			text: header.time
			color: Theme.clock
			font.family: Theme.fontUi
			font.pixelSize: 13
			font.weight: Font.DemiBold
			font.letterSpacing: 0.6
		}
	}

	// ── right: activity, alerts, battery ───────────────────────────────────

	Row {
		id: rightCluster

		anchors.right: parent.right
		anchors.rightMargin: 12
		anchors.verticalCenter: parent.verticalCenter

		spacing: 8

		// no battery glyph — just the number, and only when there is a reason
		// to look at it (on the charger, or running low). Panels never show it;
		// the full battery panel is SUPER + SHIFT + B.
		Text {
			anchors.verticalCenter: parent.verticalCenter
			visible: Sys.charging || Sys.batteryPct <= 20
			text: Sys.batteryPct + "%"
			color: Theme.textDim
			font.family: Theme.fontUi
			font.pixelSize: 13
		}
	}
}
