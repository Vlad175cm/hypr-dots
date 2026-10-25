import QtQuick

// Chip.qml — a small rounded label (keyboard keys, badges, status pills).
Rectangle {
	id: chip

	property string label: ""
	property color tint: Theme.textDim
	property color fill: Theme.chip
	property color stroke: "transparent"
	property bool monospace: false
	property bool bold: false
	property real size: 11
	property real hPad: 8
	property real vPad: 4

	implicitWidth: text.implicitWidth + hPad * 2
	implicitHeight: text.implicitHeight + vPad * 2
	radius: Math.min(height / 2, 8)
	color: fill
	border.width: chip.stroke === "transparent" ? 0 : 1
	border.color: chip.stroke

	Text {
		id: text

		anchors.centerIn: parent
		text: chip.label
		color: chip.tint
		font.family: chip.monospace ? Theme.fontIcon : Theme.fontUi
		font.pixelSize: Math.round(chip.size)
		font.weight: chip.bold ? Font.DemiBold : Font.Normal
		font.letterSpacing: 0.3
		textFormat: Text.PlainText
	}
}
