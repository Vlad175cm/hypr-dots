import QtQuick

// KeyGroup.qml — one category of the cheat sheet.
Card {
	id: root

	property var group: null
	property int rowHeight: 16

	readonly property int count: root.group?.items?.length ?? 0

	implicitHeight: 26 + root.count * (root.rowHeight + 2)

	SectionTitle {
		id: title

		anchors.top: parent.top
		anchors.topMargin: 8
		anchors.left: parent.left
		anchors.leftMargin: 10
		anchors.right: parent.right
		anchors.rightMargin: 10

		label: root.group?.title ?? ""
		icon: Icons.keyboard
	}

	Column {
		id: rows

		anchors.top: title.bottom
		anchors.topMargin: 4
		anchors.left: parent.left
		anchors.leftMargin: 10
		anchors.right: parent.right
		anchors.rightMargin: 10
		spacing: 2

		Repeater {
			model: root.group?.items ?? []

			delegate: Item {
				id: entry

				required property var modelData

				width: rows.width
				height: root.rowHeight

				Row {
					id: keys

					anchors.left: parent.left
					anchors.verticalCenter: parent.verticalCenter
					spacing: 3

					Repeater {
						model: entry.modelData.keys

						delegate: Chip {
							required property var modelData

							label: modelData
							size: 8.5
							hPad: 5
							vPad: 2
							tint: Theme.textDim
							fill: Theme.chip
						}
					}
				}

				Text {
					anchors.left: keys.right
					anchors.leftMargin: 8
					anchors.right: parent.right
					anchors.verticalCenter: parent.verticalCenter

					text: entry.modelData.desc
					color: Theme.textDim
					font.family: Theme.fontUi
					font.pixelSize: 10
					elide: Text.ElideRight
					textFormat: Text.PlainText
				}
			}
		}
	}
}
