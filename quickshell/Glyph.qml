import QtQuick

// Glyph.qml — a nerd font icon.
Text {
	property real size: 12
	property color tint: Theme.text

	font.family: Theme.fontIcon
	font.pixelSize: Math.round(size)
	color: tint
	textFormat: Text.PlainText
	verticalAlignment: Text.AlignVCenter
	renderType: Text.QtRendering
}
