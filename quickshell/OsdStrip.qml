import QtQuick

// OsdStrip.qml — the short-lived volume / brightness pill.
//
// It appears when the sound or brightness keys are pressed and folds back into
// the island after a moment, exactly like the volume HUD on iOS.
//
// A muted sink still shows its level (with an amber bar and a crossed speaker):
// showing 0% for a muted output made it impossible to tell how loud it was
// going to be when the mute clears.
Item {
	id: root

	property string kind: "volume"

	readonly property bool isVolume: root.kind === "volume"
	readonly property bool muted: root.isVolume && Sys.muted
	readonly property real value: root.isVolume
		? Sys.volume
		: (Sys.brightnessKnown ? Sys.brightness / 100 : 0)

	Row {
		id: row

		anchors.left: parent.left
		anchors.leftMargin: 18
		anchors.right: parent.right
		anchors.rightMargin: 18
		anchors.verticalCenter: parent.verticalCenter
		spacing: 10

		Glyph {
			anchors.verticalCenter: parent.verticalCenter
			text: root.isVolume
				? (root.muted || Sys.volume <= 0.001
					? Icons.volumeOff
					: (Sys.volume < 0.5 ? Icons.volumeLow : Icons.volumeHigh))
				: Icons.sun
			size: 13
			tint: root.muted ? Theme.warn : Theme.accent

			Behavior on tint {
				ColorAnimation { duration: Theme.durFast; easing.type: Theme.easeOut }
			}
		}

		Bar {
			anchors.verticalCenter: parent.verticalCenter
			width: row.width - 13 - 10 - 34 - 20
			interactive: false
			value: root.value
			thickness: 5
			fillColor: root.muted ? Theme.warn : Theme.accent
			// short on purpose: the keys repeat every ~25 ms, a 450 ms fill
			// would trail behind them and look ragged
			animDuration: 150
		}

		Text {
			anchors.verticalCenter: parent.verticalCenter
			width: 34
			horizontalAlignment: Text.AlignRight
			text: Math.round(root.value * 100) + "%"
			color: root.muted ? Theme.warn : Theme.textDim
			font.family: Theme.fontUi
			font.pixelSize: 11

			Behavior on color {
				ColorAnimation { duration: Theme.durFast; easing.type: Theme.easeOut }
			}
		}
	}
}
