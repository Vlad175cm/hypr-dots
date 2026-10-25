import QtQuick

// Card.qml — a rounded surface used inside the expanded island.
// It is only a background: put your own content in it and position it with
// anchors. Use SectionTitle for the small heading.
Rectangle {
	id: card

	property color tint: Theme.card
	property bool interactive: false
	property bool bordered: false
	readonly property alias hovered: hover.hovered

	color: card.interactive && hover.hovered ? Theme.cardHover : card.tint
	radius: Theme.radiusCard
	border.width: card.bordered ? 1 : 0
	border.color: Theme.hairline
	clip: true

	Behavior on color {
		ColorAnimation { duration: Theme.durFast; easing.type: Theme.easeOut }
	}

	HoverHandler {
		id: hover
		enabled: card.interactive
	}
}
