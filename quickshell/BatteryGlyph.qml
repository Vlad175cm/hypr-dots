import QtQuick

// BatteryGlyph.qml — a small hand drawn battery, crisper than an icon font.
Item {
	id: root

	property real level: 0
	property bool charging: false
	property color tint: Theme.text

	readonly property color levelColor: {
		if (root.charging) return Theme.good;
		if (root.level <= 0.12) return Theme.bad;
		if (root.level <= 0.3) return Theme.warn;
		return "#ffffff";
	}

	implicitWidth: 22
	implicitHeight: 11

	Rectangle {
		id: body

		anchors.left: parent.left
		anchors.verticalCenter: parent.verticalCenter
		width: parent.width - 3
		height: parent.height
		radius: 3.5
		color: "transparent"
		border.width: 1.2
		border.color: root.tint

		Rectangle {
			anchors.left: parent.left
			anchors.top: parent.top
			anchors.bottom: parent.bottom
			anchors.margins: 2
			width: Math.max(0, (parent.width - 4) * Math.max(0, Math.min(1, root.level)))
			radius: 1.8
			color: root.levelColor

			Behavior on width {
				NumberAnimation { duration: Theme.dur; easing.type: Theme.easeOut }
			}
		}
	}

	Rectangle {
		anchors.left: body.right
		anchors.leftMargin: 1.5
		anchors.verticalCenter: parent.verticalCenter
		width: 1.5
		height: 4
		radius: 1
		color: Theme.alpha(root.tint, 0.5)
	}

	Glyph {
		anchors.centerIn: body
		visible: root.charging
		text: Icons.bolt
		size: 8
		tint: Theme.surface
	}
}
