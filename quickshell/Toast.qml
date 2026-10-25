import QtQuick

// Toast.qml — the notification banner that grows out of the collapsed island.
Item {
	id: root

	readonly property var notification: Notifs.popup
	readonly property bool has: notification !== null

	opacity: root.visible ? 1 : 0
	transform: Translate {
		y: root.visible ? 0 : 10

		Behavior on y {
			NumberAnimation { duration: Theme.durReveal; easing.type: Theme.easeSoft }
		}
	}

	Behavior on opacity {
		NumberAnimation { duration: Theme.durFast; easing.type: Theme.easeOut }
	}

	Card {
		id: card

		anchors.top: parent.top
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.topMargin: 4
		anchors.bottomMargin: 12
		anchors.bottom: parent.bottom

		interactive: true
		bordered: true

		// accent rail
		Rectangle {
			anchors.left: parent.left
			anchors.top: parent.top
			anchors.bottom: parent.bottom
			anchors.topMargin: 12
			anchors.bottomMargin: 12
			width: 3
			radius: 1.5
			color: Theme.accent
		}

		Column {
			id: content

			anchors.left: parent.left
			anchors.leftMargin: 16
			anchors.right: noticeIcon.left
			anchors.rightMargin: 10
			anchors.top: parent.top
			anchors.topMargin: 12
			spacing: 3

			Text {
				width: parent.width
				text: root.has ? root.notification.appName : ""
				color: Theme.textFaint
				font.family: Theme.fontUi
				font.pixelSize: 10
				font.weight: Font.DemiBold
				font.letterSpacing: 0.5
				elide: Text.ElideRight
			}

			Text {
				width: parent.width
				text: root.has ? root.notification.summary : ""
				color: Theme.text
				font.family: Theme.fontUi
				font.pixelSize: 12
				font.weight: Font.DemiBold
				elide: Text.ElideRight
				textFormat: Text.PlainText
			}

			Text {
				width: parent.width
				visible: root.has && root.notification.body !== ""
				text: root.has ? root.notification.body : ""
				color: Theme.textDim
				font.family: Theme.fontUi
				font.pixelSize: 11
				elide: Text.ElideRight
				textFormat: Text.StyledText
			}
		}

		Glyph {
			id: noticeIcon

			anchors.right: closeButton.left
			anchors.rightMargin: 8
			anchors.verticalCenter: parent.verticalCenter
			visible: !accentDot.visible
			text: Icons.bell
			size: 13
			tint: Theme.alpha(Theme.accent, 0.85)
		}

		// a colour chip when the notice carries one (wallpaper changes)
		Rectangle {
			id: accentDot

			anchors.horizontalCenter: noticeIcon.horizontalCenter
			anchors.verticalCenter: parent.verticalCenter
			visible: root.has && root.notification.accent !== undefined && root.notification.accent !== ""
			width: 13
			height: 13
			radius: 7
			color: visible ? root.notification.accent : "transparent"
			border.width: 1
			border.color: Theme.alpha(Theme.text, 0.3)
		}

		Rectangle {
			id: closeButton

			anchors.right: parent.right
			anchors.rightMargin: 10
			anchors.verticalCenter: parent.verticalCenter
			width: 22
			height: 22
			radius: 11
			color: closeHover.hovered ? Theme.chipHover : "transparent"

			Glyph {
				anchors.centerIn: parent
				text: Icons.close
				size: 9
				tint: Theme.textFaint
			}

			HoverHandler { id: closeHover }

			MouseArea {
				anchors.fill: parent
				anchors.margins: -3
				cursorShape: Qt.PointingHandCursor
				onClicked: Notifs.dismiss(root.notification)
			}
		}

		MouseArea {
			anchors.fill: parent
			anchors.rightMargin: 40
			onClicked: Notifs.dismiss(root.notification)
		}
	}
}
