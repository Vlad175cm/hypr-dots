import QtQuick

// SectionTitle.qml — the tiny uppercase heading inside a Card.
Item {
	id: root

	property string label: ""
	property string icon: ""
	property string trailing: ""

	implicitHeight: 14

	Glyph {
		id: glyph

		anchors.left: parent.left
		anchors.verticalCenter: parent.verticalCenter
		visible: root.icon !== ""
		text: root.icon
		size: 10
		tint: Theme.accent
	}

	Text {
		anchors.left: glyph.visible ? glyph.right : parent.left
		anchors.leftMargin: glyph.visible ? 6 : 0
		anchors.verticalCenter: parent.verticalCenter

		text: root.label.toUpperCase()
		color: Theme.textFaint
		font.family: Theme.fontUi
		font.pixelSize: 10
		font.weight: Font.DemiBold
		font.letterSpacing: 1.1
		textFormat: Text.PlainText
	}

	Text {
		anchors.right: parent.right
		anchors.verticalCenter: parent.verticalCenter

		text: root.trailing
		color: Theme.textFaint
		font.family: Theme.fontUi
		font.pixelSize: 10
		textFormat: Text.PlainText
	}
}
