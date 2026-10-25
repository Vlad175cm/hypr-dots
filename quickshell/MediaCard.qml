import QtQuick

// MediaCard.qml — now playing.
//
//   ┌──────────┐  title
//   │  cover   │  artist · album
//   │   ▶/⏸    │            ← the play button sits on the cover
//   └──────────┘
//   ──────────────────────────────────  ← progress line, full width
//   1:23                          3:45
//              ◀      ▶
//   ▁▃▅▇▅▃▁▃▅▇▅▃▁▃▅▇▅▃▁▃▅▇▅▃▁▃▅      ← cava, full width
Card {
	id: root

	readonly property var player: Sys.player
	readonly property bool hasPlayer: player !== null

	readonly property real basePos: root.player?.position ?? 0
	readonly property int trackLength: Sys.trackLength

	// local interpolation so the progress bar keeps moving on players that
	// do not report their position
	property double baseTime: Date.now()
	property int tick: 0

	onBasePosChanged: root.baseTime = Date.now()

	Connections {
		target: root.player

		function onIsPlayingChanged() {
			root.baseTime = Date.now();
		}
	}

	Timer {
		interval: 500
		running: Sys.playing
		repeat: true
		onTriggered: root.tick += 1
	}

	readonly property real position: {
		const frame = root.tick;
		if (!root.hasPlayer) return 0;

		let value = root.basePos;
		if (Sys.playing) value += (Date.now() - root.baseTime) / 1000;
		if (root.trackLength > 0 && value > root.trackLength) value = root.trackLength;
		return Math.max(0, value);
	}

	readonly property string artSource: {
		const url = Sys.trackArt;
		if (url === "") return "";
		if (url.startsWith("http") || url.startsWith("file:") || url.startsWith("data:")) return url;
		return "file://" + url;
	}

	function fmt(seconds: real): string {
		const total = Math.max(0, Math.floor(seconds));
		const m = Math.floor(total / 60);
		const s = total % 60;
		return m + ":" + (s < 10 ? "0" + s : s);
	}

	// ── cover, with the play/pause button in its centre ────────────────────

	Rectangle {
		id: artFrame

		anchors.left: parent.left
		anchors.top: parent.top
		anchors.margins: 12
		width: 92
		height: 92
		radius: 14
		color: Theme.chip
		clip: true

		gradient: Gradient {
			GradientStop { position: 0; color: Theme.alpha(Theme.accent, 0.30) }
			GradientStop { position: 1; color: Theme.alpha(Theme.accent, 0.06) }
		}

		Image {
			id: art

			anchors.fill: parent
			source: root.artSource
			fillMode: Image.PreserveAspectCrop
			asynchronous: true
			cache: true
			sourceSize.width: 184
			sourceSize.height: 184
		}

		// play / pause, in the middle of the cover. It stays visible even when
		// nothing is playing (just dimmed): hiding it made it impossible to
		// find the control.
		Rectangle {
			id: playButton

			anchors.centerIn: parent
			width: 38
			height: 38
			radius: 19

			// the circle always stays crisp — dimming the whole button made it
			// vanish over a bright album cover. Only the glyph goes quiet.
			color: playHover.hovered && root.hasPlayer
				? Theme.accent
				: Theme.alpha(Theme.surface, 0.72)
			border.width: 1.5
			border.color: Theme.alpha(Theme.accent, playHover.hovered && root.hasPlayer ? 1 : 0.6)

			Behavior on color {
				ColorAnimation { duration: Theme.durFast; easing.type: Theme.easeOut }
			}

			Behavior on opacity {
				NumberAnimation { duration: Theme.durFast; easing.type: Theme.easeOut }
			}

			Glyph {
				anchors.centerIn: parent
				// nerd font glyphs sit a hair high; nudge the triangle down so
				// it looks centred inside the circle
				anchors.verticalCenterOffset: 1
				text: Sys.playing ? Icons.pause : Icons.play
				size: 15
				tint: playHover.hovered && root.hasPlayer ? Theme.surface : Theme.accent
				opacity: root.hasPlayer ? 1 : 0.45

				Behavior on opacity {
					NumberAnimation { duration: Theme.durFast; easing.type: Theme.easeOut }
				}
			}

			HoverHandler {
				id: playHover
				enabled: root.hasPlayer
			}

			MouseArea {
				anchors.fill: parent
				enabled: root.hasPlayer
				cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
				onClicked: if (root.player) root.player.togglePlaying()
			}
		}
	}

	// ── track info ─────────────────────────────────────────────────────────

	Text {
		id: title

		anchors.left: artFrame.right
		anchors.leftMargin: 12
		anchors.right: parent.right
		anchors.rightMargin: 12
		anchors.top: artFrame.top
		anchors.topMargin: 2

		text: root.hasPlayer ? (Sys.trackTitle === "" ? "Unknown track" : Sys.trackTitle) : "Nothing playing"
		color: root.hasPlayer ? Theme.text : Theme.textFaint
		font.family: Theme.fontUi
		font.pixelSize: 14
		font.weight: Font.DemiBold
		elide: Text.ElideRight
		textFormat: Text.PlainText
	}

	Text {
		id: artist

		anchors.left: title.left
		anchors.right: title.right
		anchors.top: title.bottom
		anchors.topMargin: 3

		text: root.hasPlayer ? Sys.trackArtist : "start something in a player"
		color: Theme.textDim
		font.family: Theme.fontUi
		font.pixelSize: 12
		elide: Text.ElideRight
		textFormat: Text.PlainText
	}

	Text {
		id: album

		anchors.left: title.left
		anchors.right: title.right
		anchors.top: artist.bottom
		anchors.topMargin: 2
		visible: root.hasPlayer && Sys.trackAlbum !== ""

		text: Sys.trackAlbum
		color: Theme.textFaint
		font.family: Theme.fontUi
		font.pixelSize: 11
		elide: Text.ElideRight
		textFormat: Text.PlainText
	}

	// ── progress line, edge to edge ────────────────────────────────────────

	Bar {
		id: progress

		anchors.left: parent.left
		anchors.leftMargin: 12
		anchors.right: parent.right
		anchors.rightMargin: 12
		anchors.top: artFrame.bottom
		anchors.topMargin: 14

		interactive: root.hasPlayer && root.trackLength > 0 && (root.player?.canSeek ?? false)
		value: root.trackLength > 0 ? root.position / root.trackLength : 0
		thickness: 4
		fillColor: Theme.accent

		onMoved: value => {
			if (root.player && root.trackLength > 0) root.player.position = value * root.trackLength;
		}
	}

	Text {
		id: elapsed

		anchors.left: progress.left
		anchors.top: progress.bottom
		anchors.topMargin: 6

		visible: root.hasPlayer && root.trackLength > 0
		text: root.fmt(root.position)
		color: Theme.textFaint
		font.family: Theme.fontUi
		font.pixelSize: 10
	}

	Text {
		anchors.right: progress.right
		anchors.top: progress.bottom
		anchors.topMargin: 6

		visible: root.hasPlayer && root.trackLength > 0
		text: root.fmt(root.trackLength)
		color: Theme.textFaint
		font.family: Theme.fontUi
		font.pixelSize: 10
	}

	// ── previous / next, centred under the timeline ────────────────────────

	Row {
		id: controls

		anchors.horizontalCenter: parent.horizontalCenter
		anchors.top: elapsed.bottom
		anchors.topMargin: 6
		visible: root.hasPlayer
		spacing: 26

		Repeater {
			model: [
				{ glyph: Icons.prev, action: "prev", size: 14 },
				{ glyph: Icons.next, action: "next", size: 14 }
			]

			delegate: Rectangle {
				id: control

				required property var modelData

				width: 32
				height: 32
				radius: 16
				color: controlHover.hovered ? Theme.chipHover : "transparent"

				Behavior on color {
					ColorAnimation { duration: Theme.durFast; easing.type: Theme.easeOut }
				}

				Glyph {
					anchors.centerIn: parent
					text: control.modelData.glyph
					size: control.modelData.size
					tint: controlHover.hovered ? Theme.text : Theme.textDim
				}

				HoverHandler { id: controlHover }

				MouseArea {
					anchors.fill: parent
					cursorShape: Qt.PointingHandCursor
					onClicked: {
						if (!root.player) return;
						if (control.modelData.action === "prev") root.player.previous();
						else root.player.next();
					}
				}
			}
		}
	}

	// ── the visualiser spans the whole card ───────────────────────────────

	Spectrum {
		anchors.left: parent.left
		anchors.leftMargin: 12
		anchors.right: parent.right
		anchors.rightMargin: 12
		anchors.bottom: parent.bottom
		anchors.bottomMargin: 12
		height: 26
		active: root.visible && Sys.panelOpen
		barColor: Theme.accent
		opacity: root.hasPlayer ? 1 : 0.25
	}
}
