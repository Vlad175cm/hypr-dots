import QtQuick

// MiniBars.qml — the tiny "now playing" equaliser in the collapsed pill.
// Driven by the real pipewire peak level of the default sink.
Item {
	id: root

	property color tint: Theme.accent
	property bool active: true
	property var factors: [0.5, 1.0, 0.72]

	implicitWidth: root.factors.length * 3 + (root.factors.length - 1) * 2
	implicitHeight: 12

	readonly property real level: {
		const peak = Sys.audioPeak;
		if (!root.active || !isFinite(peak)) return 0;
		return Math.min(1, Math.max(0, peak * 2.4));
	}

	Row {
		anchors.fill: parent
		spacing: 2

		Repeater {
			model: root.factors.length

			delegate: Rectangle {
				required property int index

				anchors.verticalCenter: parent.verticalCenter
				width: 3
				height: Math.max(3, parent.height * Math.min(1, 0.18 + root.level * root.factors[index]))
				radius: 1.5
				color: root.active ? root.tint : Theme.textFaint

				Behavior on height {
					NumberAnimation { duration: 110; easing.type: Easing.OutQuad }
				}
			}
		}
	}
}
