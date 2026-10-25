import QtQuick

// PanelDashboard.qml — the island's default expanded view.
Item {
	id: root

	implicitWidth: 720
	implicitHeight: 424

	property int columnWidth: (width - 12) / 2

	Row {
		anchors.fill: parent
		spacing: 12

		Column {
			width: root.columnWidth
			spacing: 12

			MediaCard {
				width: parent.width
				height: 222
			}

			WeatherCard {
				width: parent.width
				height: 190
			}
		}

		Column {
			width: root.columnWidth
			spacing: 12

			QuickActions {
				width: parent.width
				height: 48
			}

			SystemCard {
				width: parent.width
				height: 188
			}

			Card {
				width: parent.width
				height: 156

				SectionTitle {
					id: calHeading

					anchors.top: parent.top
					anchors.topMargin: 10
					anchors.left: parent.left
					anchors.leftMargin: 12
					anchors.right: parent.right
					anchors.rightMargin: 12

					label: "Calendar"
					icon: Icons.compass
				}

				CalGrid {
					anchors.top: calHeading.bottom
					anchors.topMargin: 4
					anchors.left: parent.left
					anchors.leftMargin: 12
					anchors.right: parent.right
					anchors.rightMargin: 12
					cellHeight: 15
				}
			}
		}
	}
}
