import QtQuick

// SystemRow.qml — one line of the system card: icon, label, optional bar, value.
//
// The row-wide click target is declared first so that it sits *under* the bar
// and the icon in stacking order: dragging the bar works, clicking anywhere
// else triggers clicked().
Item {
	id: row

	property string icon: ""
	property string label: ""
	property string value: ""
	property real barValue: -1
	property color barColor: Theme.accent
	property bool interactive: false
	property bool iconClickable: false
	property bool active: false
	property bool dim: false
	property bool showBar: barValue >= 0

	signal clicked()
	signal iconClicked()
	signal moved(real value)

	implicitHeight: 28
	opacity: row.dim ? 0.45 : 1

	Behavior on opacity {
		NumberAnimation { duration: Theme.durFast; easing.type: Theme.easeOut }
	}

	Rectangle {
		anchors.fill: parent
		anchors.leftMargin: -8
		anchors.rightMargin: -8
		radius: 9
		color: hover.hovered && (row.interactive || row.iconClickable) ? Theme.chip : "transparent"

		Behavior on color {
			ColorAnimation { duration: Theme.durFast; easing.type: Theme.easeOut }
		}
	}

	HoverHandler {
		id: hover
		enabled: row.interactive || row.iconClickable
	}

	MouseArea {
		anchors.fill: parent
		enabled: row.interactive
		acceptedButtons: Qt.LeftButton
		cursorShape: Qt.PointingHandCursor
		onClicked: row.clicked()
	}

	Glyph {
		id: glyph

		anchors.left: parent.left
		anchors.verticalCenter: parent.verticalCenter
		text: row.icon
		size: 12
		tint: row.active ? Theme.accent : Theme.textFaint
	}

	MouseArea {
		anchors.fill: glyph
		anchors.margins: -5
		enabled: row.iconClickable
		cursorShape: Qt.PointingHandCursor
		onClicked: row.iconClicked()
	}

	Text {
		id: valueText

		anchors.right: parent.right
		anchors.verticalCenter: parent.verticalCenter

		text: row.value
		color: row.active ? Theme.text : Theme.textDim
		font.family: Theme.fontUi
		font.pixelSize: 11
		horizontalAlignment: Text.AlignRight
	}

	Bar {
		id: bar

		anchors.right: valueText.left
		anchors.rightMargin: 10
		anchors.verticalCenter: parent.verticalCenter
		width: 118
		visible: row.showBar
		interactive: row.interactive && row.showBar
		value: row.showBar ? row.barValue : 0
		fillColor: row.barColor
		thickness: 5

		onMoved: value => row.moved(value)
	}

	Text {
		id: labelText

		anchors.left: glyph.right
		anchors.leftMargin: 8
		anchors.right: row.showBar ? bar.left : valueText.left
		anchors.rightMargin: 8
		anchors.verticalCenter: parent.verticalCenter

		text: row.label
		color: row.active ? Theme.text : Theme.textFaint
		font.family: Theme.fontUi
		font.pixelSize: 11
		elide: Text.ElideRight
		textFormat: Text.PlainText
	}
}
