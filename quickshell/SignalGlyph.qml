import QtQuick

// SignalGlyph.qml — the four bar wi-fi strength indicator.
Item {
	id: root

	property real strength: 0
	property color tint: Theme.textDim
	property color offTint: Theme.alpha(Theme.outline, 0.35)

	implicitWidth: 4 * 2 + 3 * 2
	implicitHeight: 12

	Row {
		anchors.fill: parent
		spacing: 2

		Repeater {
			model: 4

			delegate: Rectangle {
				required property int index

				anchors.bottom: parent.bottom
				width: 2
				height: 3 + index * 3
				radius: 1
				color: (index + 1) / 4 <= root.strength ? root.tint : root.offTint

				Behavior on color {
					ColorAnimation { duration: Theme.durFast; easing.type: Theme.easeOut }
				}
			}
		}
	}
}
