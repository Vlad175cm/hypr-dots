import QtQuick
import Quickshell

// QuickActions.qml — the four tiles at the top right of the dashboard.
Row {
	id: root

	property real tileWidth: (width - spacing * 3) / 4
	spacing: 8

	Repeater {
		model: [
			{
				key: "wifi",
				icon: Icons.wifi,
				label: "Wi-Fi",
				active: Sys.wifiOn,
				enabled: Sys.wifiHardware
			},
			{
				key: "bt",
				icon: Icons.bluetooth,
				label: "Bluetooth",
				active: Sys.btOn,
				enabled: true
			},
			{
				key: "dnd",
				icon: Notifs.dnd ? Icons.bellOff : Icons.bell,
				label: Notifs.dnd ? "Silent" : "Alerts",
				active: Notifs.dnd,
				enabled: true
			},
			{
				key: "shot",
				icon: Icons.camera,
				label: "Shot",
				active: false,
				enabled: true
			}
		]

		delegate: Rectangle {
			id: tile

			required property var modelData

			width: root.tileWidth
			height: root.height
			radius: 14
			opacity: tile.modelData.enabled ? 1 : 0.45
			scale: tileHover.hovered ? 1.03 : 1

			color: tile.modelData.active
				? Theme.accentGhost
				: (tileHover.hovered ? Theme.cardHover : Theme.card)
			border.width: 1
			border.color: tile.modelData.active ? Theme.alpha(Theme.accent, 0.35) : Theme.alpha(Theme.outline, 0.10)

			Behavior on color {
				ColorAnimation { duration: Theme.durFast; easing.type: Theme.easeOut }
			}

			Behavior on scale {
				NumberAnimation { duration: Theme.durFast; easing.type: Theme.easeOut }
			}

			Column {
				anchors.centerIn: parent
				spacing: 3

				Glyph {
					anchors.horizontalCenter: parent.horizontalCenter
					text: tile.modelData.icon
					size: 14
					tint: tile.modelData.active ? Theme.accent : Theme.textDim
				}

				Text {
					anchors.horizontalCenter: parent.horizontalCenter
					text: tile.modelData.label
					color: tile.modelData.active ? Theme.text : Theme.textFaint
					font.family: Theme.fontUi
					font.pixelSize: 10
				}
			}

			HoverHandler {
				id: tileHover
				enabled: tile.modelData.enabled
			}

			MouseArea {
				anchors.fill: parent
				enabled: tile.modelData.enabled
				cursorShape: Qt.PointingHandCursor
				onClicked: {
					if (tile.modelData.key === "wifi") Sys.toggleWifi();
					else if (tile.modelData.key === "bt") Sys.toggleBt();
					else if (tile.modelData.key === "dnd") Notifs.toggleDnd();
					else if (tile.modelData.key === "shot") Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/screenshot.sh", "area"]);
				}
			}
		}
	}
}
