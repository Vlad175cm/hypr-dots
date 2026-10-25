import QtQuick

// CalGrid.qml — a compact month calendar, monday first.
Item {
	id: root

	property int monthOffset: 0
	property int cellWidth: Math.floor(width / 7)
	property int cellHeight: 15

	readonly property date today: new Date()
	readonly property var months: ["January", "February", "March", "April", "May", "June",
		"July", "August", "September", "October", "November", "December"]
	readonly property var weekdays: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

	readonly property date shown: new Date(root.today.getFullYear(), root.today.getMonth() + root.monthOffset, 1)
	readonly property string title: root.months[shown.getMonth()] + " " + shown.getFullYear()

	readonly property int lead: (new Date(root.shown.getFullYear(), root.shown.getMonth(), 1).getDay() + 6) % 7
	readonly property int dayCount: new Date(root.shown.getFullYear(), root.shown.getMonth() + 1, 0).getDate()

	readonly property var cells: {
		const out = [];
		for (let i = 0; i < 42; i++) {
			const day = i - root.lead + 1;
			out.push(day >= 1 && day <= root.dayCount ? day : 0);
		}
		return out;
	}

	// ── heading ────────────────────────────────────────────────────────────

	Item {
		id: heading

		anchors.top: parent.top
		anchors.left: parent.left
		anchors.right: parent.right
		height: 18

		Text {
			anchors.left: parent.left
			anchors.verticalCenter: parent.verticalCenter

			text: root.title
			color: Theme.textDim
			font.family: Theme.fontUi
			font.pixelSize: 11
			font.weight: Font.Medium
		}

		Text {
			anchors.right: parent.right
			anchors.verticalCenter: parent.verticalCenter
			visible: root.monthOffset !== 0

			text: "today"
			color: Theme.accent
			font.family: Theme.fontUi
			font.pixelSize: 10

			MouseArea {
				anchors.fill: parent
				anchors.margins: -4
				cursorShape: Qt.PointingHandCursor
				onClicked: root.monthOffset = 0
			}
		}

		Row {
			anchors.right: parent.right
			anchors.rightMargin: root.monthOffset !== 0 ? 40 : 0
			anchors.verticalCenter: parent.verticalCenter
			spacing: 2

			Repeater {
				model: [
					{ glyph: Icons.chevronLeft, step: -1 },
					{ glyph: Icons.chevronRight, step: 1 }
				]

				delegate: Rectangle {
					id: navButton

					required property var modelData

					width: 18
					height: 18
					radius: 9
					color: navHover.hovered ? Theme.chipHover : "transparent"

					Glyph {
						anchors.centerIn: parent
						text: navButton.modelData.glyph
						size: 9
						tint: Theme.textFaint
					}

					HoverHandler { id: navHover }

					MouseArea {
						anchors.fill: parent
						cursorShape: Qt.PointingHandCursor
						onClicked: root.monthOffset += navButton.modelData.step
					}
				}
			}
		}
	}

	// ── grid ───────────────────────────────────────────────────────────────

	Row {
		id: weekdayRow

		anchors.top: heading.bottom
		anchors.topMargin: 4
		anchors.left: parent.left

		Repeater {
			model: root.weekdays

			delegate: Text {
				required property string modelData

				width: root.cellWidth
				horizontalAlignment: Text.AlignHCenter
				text: modelData
				color: Theme.textFaint
				font.family: Theme.fontUi
				font.pixelSize: 9
			}
		}
	}

	Grid {
		id: grid

		anchors.top: weekdayRow.bottom
		anchors.topMargin: 2
		anchors.left: parent.left
		columns: 7

		Repeater {
			model: root.cells

			delegate: Item {
				required property int index
				required property var modelData

				width: root.cellWidth
				height: root.cellHeight

				readonly property bool isToday: modelData !== 0
					&& root.monthOffset === 0
					&& modelData === root.today.getDate()

				Rectangle {
					anchors.centerIn: parent
					width: 20
					height: 15
					radius: 7.5
					color: parent.isToday ? Theme.accent : "transparent"
				}

				Text {
					anchors.centerIn: parent
					visible: parent.modelData !== 0

					text: parent.modelData === 0 ? "" : parent.modelData
					color: parent.isToday ? Theme.onPrimary : Theme.textDim
					font.family: Theme.fontUi
					font.pixelSize: 10
					font.weight: parent.isToday ? Font.Bold : Font.Normal
				}
			}
		}
	}
}
