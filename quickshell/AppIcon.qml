import QtQuick
import Quickshell

// AppIcon.qml — a desktop entry icon with a letter tile as a fallback, so a
// missing icon theme entry never leaves a hole in the launcher.
Item {
	id: root

	property string iconName: ""
	property string fallbackText: "?"
	property real size: 26
	property color tint: Theme.accent

	implicitWidth: root.size
	implicitHeight: root.size

	readonly property string iconSource: {
		if (root.iconName === "") return "";
		if (root.iconName.charAt(0) === "/") return "file://" + root.iconName;
		return Quickshell.hasThemeIcon(root.iconName) ? Quickshell.iconPath(root.iconName) : "";
	}

	Image {
		id: image

		anchors.fill: parent
		source: root.iconSource
		fillMode: Image.PreserveAspectFit
		asynchronous: true
		smooth: true
		// an explicit rasterisation size keeps Qt's svg renderer happy
		sourceSize.width: Math.max(8, Math.round(root.size))
		sourceSize.height: Math.max(8, Math.round(root.size))
	}

	Rectangle {
		anchors.fill: parent
		visible: image.status !== Image.Ready
		radius: root.size * 0.3
		color: Theme.accentGhost

		Text {
			anchors.centerIn: parent
			text: root.fallbackText.substring(0, 1).toUpperCase()
			color: root.tint
			font.family: Theme.fontUi
			font.pixelSize: Math.round(root.size * 0.52)
			font.weight: Font.DemiBold
		}
	}
}
