import QtQuick
import Quickshell.Services.Notifications

// PanelNotifs.qml — the notification centre (SUPER + N).
Item {
	id: root

	implicitWidth: 428
	implicitHeight: 406

	Component.onCompleted: Notifs.markRead()

	// ── toolbar ────────────────────────────────────────────────────────────

	Item {
		id: toolbar

		anchors.top: parent.top
		anchors.left: parent.left
		anchors.right: parent.right
		height: 28

		Text {
			anchors.left: parent.left
			anchors.verticalCenter: parent.verticalCenter

			text: "NOTIFICATIONS"
			color: Theme.textFaint
			font.family: Theme.fontUi
			font.pixelSize: 10
			font.weight: Font.DemiBold
			font.letterSpacing: 1.1
		}

		Chip {
			anchors.left: parent.left
			anchors.leftMargin: 118
			anchors.verticalCenter: parent.verticalCenter
			visible: Notifs.count > 0

			label: "" + Notifs.count
			size: 9
			hPad: 6
			vPad: 2
			tint: Theme.accent
			fill: Theme.accentGhost
		}

		Row {
			anchors.right: parent.right
			anchors.verticalCenter: parent.verticalCenter
			spacing: 6

			Chip {
				label: Notifs.dnd ? "Silent" : "Alerts"
				size: 9.5
				hPad: 8
				vPad: 4
				tint: Notifs.dnd ? Theme.accent : Theme.textDim
				fill: Notifs.dnd ? Theme.accentGhost : Theme.chip
				stroke: Notifs.dnd ? Theme.alpha(Theme.accent, 0.35) : "transparent"

				MouseArea {
					anchors.fill: parent
					anchors.margins: -2
					cursorShape: Qt.PointingHandCursor
					onClicked: Notifs.toggleDnd()
				}
			}

			Chip {
				label: "Clear"
				size: 9.5
				hPad: 8
				vPad: 4
				tint: Theme.textDim
				fill: Theme.chip

				MouseArea {
					anchors.fill: parent
					anchors.margins: -2
					cursorShape: Qt.PointingHandCursor
					onClicked: Notifs.clear()
				}
			}
		}
	}

	// ── empty state ────────────────────────────────────────────────────────

	Column {
		anchors.centerIn: parent
		spacing: 8
		visible: Notifs.count === 0

		Glyph {
			anchors.horizontalCenter: parent.horizontalCenter
			text: Notifs.dnd ? Icons.bellOff : Icons.bell
			size: 26
			tint: Theme.alpha(Theme.textFaint, 0.7)
		}

		Text {
			anchors.horizontalCenter: parent.horizontalCenter
			text: Notifs.dnd ? "silent mode" : "no notifications"
			color: Theme.textFaint
			font.family: Theme.fontUi
			font.pixelSize: 11
		}
	}

	// ── list ───────────────────────────────────────────────────────────────

	ListView {
		id: list

		anchors.top: toolbar.bottom
		anchors.topMargin: 8
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.bottom: parent.bottom

		clip: true
		spacing: 8
		model: Notifs.items
		visible: Notifs.count > 0
		boundsBehavior: Flickable.StopAtBounds

		delegate: Rectangle {
			id: card

			required property var modelData

			width: list.width
			height: content.implicitHeight + 24
			radius: 14
			color: cardHover.hovered ? Theme.cardHover : Theme.card
			border.width: 1
			border.color: card.modelData.urgency === NotificationUrgency.Critical
				? Theme.alpha(Theme.bad, 0.45)
				: Theme.alpha(Theme.outline, 0.08)

			Behavior on color {
				ColorAnimation { duration: Theme.durFast; easing.type: Theme.easeOut }
			}

			MouseArea {
				anchors.fill: parent
				anchors.rightMargin: 28
				onClicked: {
					const actions = card.modelData.actions;
					for (let i = 0; i < actions.length; i++)
						if (actions[i].identifier === "default") {
							actions[i].invoke();
							return;
						}
				}
			}

			Column {
				id: content

				anchors.left: parent.left
				anchors.right: parent.right
				anchors.top: parent.top
				anchors.leftMargin: 12
				anchors.rightMargin: 12
				anchors.topMargin: 12
				spacing: 4

				Row {
					width: parent.width
					spacing: 6

					Glyph {
						anchors.verticalCenter: parent.verticalCenter
						text: Icons.bell
						size: 9
						tint: Theme.accent
					}

					Text {
						anchors.verticalCenter: parent.verticalCenter
						width: parent.width - 34
						text: card.modelData.appName
						color: Theme.textFaint
						font.family: Theme.fontUi
						font.pixelSize: 10
						font.weight: Font.DemiBold
						font.letterSpacing: 0.6
						elide: Text.ElideRight
					}
				}

				Text {
					width: parent.width
					text: card.modelData.summary
					color: Theme.text
					font.family: Theme.fontUi
					font.pixelSize: 12
					font.weight: Font.DemiBold
					wrapMode: Text.Wrap
					maximumLineCount: 2
					elide: Text.ElideRight
					textFormat: Text.PlainText
				}

				Text {
					width: parent.width
					visible: card.modelData.body !== ""
					text: card.modelData.body
					color: Theme.textDim
					font.family: Theme.fontUi
					font.pixelSize: 11
					wrapMode: Text.Wrap
					maximumLineCount: 3
					elide: Text.ElideRight
					textFormat: Text.StyledText
				}

				Row {
					width: parent.width
					spacing: 6
					visible: card.modelData.actions.length > 0
					height: visible ? 20 : 0

					Repeater {
						model: card.modelData.actions

						delegate: Chip {
							required property var modelData

							label: modelData.text
							size: 9.5
							hPad: 8
							vPad: 4
							tint: Theme.accent
							fill: Theme.accentGhost

							MouseArea {
								anchors.fill: parent
								anchors.margins: -2
								cursorShape: Qt.PointingHandCursor
								onClicked: modelData.invoke()
							}
						}
					}
				}
			}

			// dismiss
			Rectangle {
				id: closeButton

				anchors.top: parent.top
				anchors.right: parent.right
				anchors.margins: 8
				width: 20
				height: 20
				radius: 10
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
					onClicked: Notifs.dismiss(card.modelData)
				}
			}

			HoverHandler { id: cardHover }
		}
	}
}
