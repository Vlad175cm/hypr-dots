import QtQuick
import Quickshell.Io

// PanelWalls.qml — the wallpaper picker (SUPER + W).
//
// One horizontal strip (a carousel) rather than a grid: ← → step through the
// wallpapers, ⏎ applies the centred one and folds the island back up, typing
// filters the list. The strip itself is not draggable — navigation is the
// keyboard, which keeps the selection where it belongs: in the middle.
//
// Previews come from scripts/wallpapers.sh and are cached in
// ~/.cache/quickshell/wallthumbs; the matugen palette for whatever the strip
// lands on is warmed up in the background.
Item {
	id: root

	implicitWidth: 1200
	implicitHeight: 260

	readonly property int cardWidth: 260
	// The selection frames are drawn outside the card (the cursor one by 4 px),
	// so the card needs padding at the top: padding on the strip itself would
	// move the viewport and the overhang would still be clipped.
	readonly property int frameOverhang: 4
	readonly property int frameTopPad: 6
	property bool navigated: false

	signal requestClose()

	Component.onCompleted: {
		if (!Walls.ready) Walls.refresh();
		Walls.generateMissing();
		syncSelection(false);
		searchInput.forceActiveFocus();
	}

	// every time the panel comes back on screen, start from what is on the
	// desktop right now
	Connections {
		target: Sys

		function onPanelOpenChanged() {
			if (!Sys.panelOpen) return;
			root.navigated = false;
			root.syncSelection(false);
			searchInput.forceActiveFocus();
		}
	}

	Connections {
		target: Walls

		function onFilteredChanged() {
			if (!root.navigated) root.syncSelection(false);
		}
	}

	// ── selection ──────────────────────────────────────────────────────────

	// the strip is made of equal items, so the scroll offset is plain maths
	function centerOn(index: int, animate: bool): void {
		const step = root.cardWidth + strip.spacing;
		const maxOffset = Math.max(0, strip.contentWidth - strip.width);
		const target = Math.max(0, Math.min(maxOffset, index * step + root.cardWidth / 2 - strip.width / 2));

		if (!animate) {
			slide.stop();
			strip.contentX = target;
			return;
		}

		if (Math.abs(strip.contentX - target) < 1) return;
		slide.to = target;
		slide.restart();
	}

	NumberAnimation {
		id: slide

		target: strip
		property: "contentX"
		duration: 220
		easing.type: Theme.easeOut
	}

	function syncSelection(animate: bool): void {
		const list = Walls.filtered;
		for (let i = 0; i < list.length; i++) {
			if (list[i].path === Walls.current) {
				strip.currentIndex = i;
				centerOn(i, animate);
				return;
			}
		}
		if (strip.currentIndex >= list.length) strip.currentIndex = 0;
		centerOn(strip.currentIndex, animate);
	}

	function moveBy(step: int): void {
		const count = Walls.filtered.length;
		if (count === 0) return;

		root.navigated = true;

		let index = strip.currentIndex + step;
		// wrap around, so a long list never dead ends
		while (index < 0) index += count;
		while (index >= count) index -= count;

		strip.currentIndex = index;
		centerOn(index, true);
	}

	function applyCurrent(): void {
		const item = Walls.filtered[strip.currentIndex];
		if (!item) return;

		Walls.apply(item.path);
		root.requestClose();
	}

	// ── warming the palette of whatever the strip lands on ─────────────────
	// Extracting a palette decodes the whole image (~340 ms for a 2560×1440
	// png) — that is what used to make the colours lag behind the wallpaper.
	property bool prewarmPending: false

	Process {
		id: prewarmProc

		// the item the strip stopped on may have arrived while a previous warm
		// up was still running — give it its turn instead of dropping it
		onExited: if (root.prewarmPending) prewarmTimer.restart()
	}

	Timer {
		id: prewarmTimer

		interval: 400
		onTriggered: root.requestPrewarm()
	}

	function requestPrewarm(): void {
		const item = Walls.filtered[strip.currentIndex];
		if (!item || item.path === Walls.current) return;

		if (prewarmProc.running) {
			root.prewarmPending = true;
			return;
		}

		root.prewarmPending = false;
		prewarmProc.command = ["bash", Walls.script, "prewarm", item.path];
		prewarmProc.running = true;
	}

	// ── toolbar ────────────────────────────────────────────────────────────

	Item {
		id: toolbar

		anchors.top: parent.top
		anchors.left: parent.left
		anchors.right: parent.right
		height: 30

		Rectangle {
			id: searchBox

			anchors.left: parent.left
			anchors.leftMargin: 5
			anchors.verticalCenter: parent.verticalCenter
			width: 232
			height: 30
			radius: 15
			color: Theme.chip
			border.width: 1
			border.color: searchInput.activeFocus ? Theme.alpha(Theme.accent, 0.5) : "transparent"

			Behavior on border.color {
				ColorAnimation { duration: Theme.durFast; easing.type: Theme.easeOut }
			}

			Glyph {
				id: searchGlyph

				anchors.left: parent.left
				anchors.leftMargin: 12
				anchors.verticalCenter: parent.verticalCenter
				text: Icons.search
				size: 10
				tint: Theme.textFaint
			}

			TextInput {
				id: searchInput

				anchors.left: searchGlyph.right
				anchors.leftMargin: 8
				anchors.right: parent.right
				anchors.rightMargin: 12
				anchors.verticalCenter: parent.verticalCenter

				color: Theme.text
				font.family: Theme.fontUi
				font.pixelSize: 11
				selectByMouse: true
				clip: true
				selectionColor: Theme.accentSoft

				onTextChanged: {
					Walls.filter = text;
					if (text !== "") root.navigated = true;
				}

				// the search field keeps the keyboard, so the strip keys are
				// forwarded from here
				Keys.onLeftPressed: event => {
					root.moveBy(-1);
					event.accepted = true;
				}
				Keys.onRightPressed: event => {
					root.moveBy(1);
					event.accepted = true;
				}
				Keys.onReturnPressed: event => {
					root.applyCurrent();
					event.accepted = true;
				}
				Keys.onEnterPressed: event => {
					root.applyCurrent();
					event.accepted = true;
				}

				Text {
					anchors.fill: parent
					verticalAlignment: Text.AlignVCenter
					visible: searchInput.text === ""
					text: "Search " + (Walls.list.length > 0 ? Walls.list.length : "") + " wallpapers…"
					color: Theme.textFaint
					font: parent.font
				}
			}
		}

		Text {
			id: status

			anchors.left: searchBox.right
			anchors.leftMargin: 12
			anchors.verticalCenter: parent.verticalCenter

			text: Walls.error !== ""
				? Walls.error
				: (Walls.generating ? "building previews…" : Walls.filtered.length + " / " + Walls.list.length)
			color: Walls.error !== "" ? Theme.bad : Theme.textFaint
			font.family: Theme.fontUi
			font.pixelSize: 10
		}

		Row {
			anchors.right: parent.right
			anchors.rightMargin: 5
			anchors.verticalCenter: parent.verticalCenter
			spacing: 6

			Repeater {
				model: [
					{ label: "Refresh", action: "refresh" },
					{ label: "Open folder", action: "folder" }
				]

				delegate: Chip {
					id: actionChip

					required property var modelData

					label: actionChip.modelData.label
					size: 10
					hPad: 10
					vPad: 5
					tint: chipHover.hovered ? Theme.text : Theme.textDim
					fill: chipHover.hovered ? Theme.chipHover : Theme.chip

					HoverHandler { id: chipHover }

					MouseArea {
						anchors.fill: parent
						anchors.margins: -2
						cursorShape: Qt.PointingHandCursor
						onClicked: {
							if (actionChip.modelData.action === "refresh") Walls.refresh();
							else Walls.openDir();
						}
					}
				}
			}
		}
	}

	// ── the strip ──────────────────────────────────────────────────────────

	ListView {
		id: strip

		anchors.top: toolbar.bottom
		anchors.topMargin: 10
		anchors.left: parent.left
		anchors.leftMargin: 5
		anchors.right: parent.right
		anchors.rightMargin: 5
		anchors.bottom: hint.top
		anchors.bottomMargin: 8

		orientation: ListView.Horizontal
		clip: true
		spacing: 12
		model: Walls.filtered
		// navigation is the keyboard, deliberately: dragging would fight with
		// "the selection stays centred"
		interactive: false
		flickableDirection: Flickable.HorizontalFlick
		boundsBehavior: Flickable.StopAtBounds
		cacheBuffer: 1400

		// warm the palette of whatever the strip lands on
		onCurrentIndexChanged: prewarmTimer.restart()

		delegate: Item {
			id: card

			required property var modelData
			required property int index

			width: root.cardWidth
			height: strip.height

			readonly property bool isCurrent: Walls.current === card.modelData.path
			// the keyboard cursor, kept visually apart from "this is applied"
			readonly property bool isCursor: strip.currentIndex === card.index

			scale: card.isCursor ? 1.01 : (cardHover.hovered ? 1.02 : 1)
			transformOrigin: Item.Center

			Behavior on scale {
				NumberAnimation { duration: Theme.dur; easing.type: Theme.easeOut }
			}

			// The selection frames are square on purpose (90°), while the preview
			// itself stays rounded: a square marker reads as a marker, and the
			// rounded thumbnail still looks like a photo.
			Rectangle {
				id: appliedFrame

				anchors.fill: frame
				anchors.margins: -1
				color: "transparent"
				border.width: 2
				border.color: Theme.accent
				visible: card.isCurrent
			}

			Rectangle {
				id: cursorFrame

				anchors.fill: frame
				anchors.margins: -4
				color: "transparent"
				border.width: 2
				border.color: Theme.alpha(Theme.text, 0.9)
				visible: card.isCursor
			}

			Rectangle {
				id: frame

				anchors.top: parent.top
				anchors.topMargin: root.frameTopPad
				anchors.left: parent.left
				anchors.right: parent.right
				height: Math.max(80, card.height - root.frameTopPad
					- root.frameOverhang - nameLabel.implicitHeight)
				radius: 14
				color: Theme.chip
				clip: true
				border.width: card.isCursor || card.isCurrent ? 0 : 1
				border.color: cardHover.hovered
					? Theme.alpha(Theme.accent, 0.45)
					: Theme.alpha(Theme.outline, 0.12)

				Behavior on border.color {
					ColorAnimation { duration: Theme.durFast; easing.type: Theme.easeOut }
				}

				Image {
					id: preview

					anchors.fill: parent
					source: card.modelData.thumb ? "file://" + card.modelData.thumb : ""
					fillMode: Image.PreserveAspectCrop
					asynchronous: true
					cache: true
					sourceSize.width: 440
					sourceSize.height: 248
					visible: card.modelData.thumb !== undefined && card.modelData.thumb !== null
				}

				// placeholder while previews are still being built
				Column {
					anchors.centerIn: parent
					spacing: 4
					visible: !preview.visible

					Glyph {
						anchors.horizontalCenter: parent.horizontalCenter
						text: Icons.image
						size: 18
						tint: Theme.alpha(Theme.textFaint, 0.5)
					}

					Text {
						anchors.horizontalCenter: parent.horizontalCenter
						text: "no preview"
						color: Theme.textFaint
						font.family: Theme.fontUi
						font.pixelSize: 9
					}
				}

				// hover overlay with the name
				Rectangle {
					anchors.fill: parent
					opacity: cardHover.hovered || card.isCurrent ? 1 : 0
					color: Theme.alpha(Theme.surface, 0.35)

					Behavior on opacity {
						NumberAnimation { duration: Theme.durFast; easing.type: Theme.easeOut }
					}
				}

				Rectangle {
					id: badge

					anchors.top: parent.top
					anchors.right: parent.right
					anchors.margins: 8
					width: 20
					height: 20
					radius: 10
					visible: card.isCurrent
					color: Theme.accent

					Glyph {
						anchors.centerIn: parent
						text: Icons.check
						size: 9
						tint: Theme.onPrimary
					}
				}

				HoverHandler { id: cardHover }

				MouseArea {
					anchors.fill: parent
					cursorShape: Qt.PointingHandCursor
					onClicked: {
						strip.currentIndex = card.index;
						root.navigated = true;
						Walls.apply(card.modelData.path);
					}
				}
			}

			Text {
				id: nameLabel

				// the caption sits in the overhang slot, right under the card
				anchors.top: frame.bottom
				anchors.topMargin: root.frameOverhang
				anchors.left: frame.left
				anchors.right: frame.right

				text: card.modelData.name
				color: card.isCurrent ? Theme.accent : (card.isCursor || cardHover.hovered ? Theme.text : Theme.textFaint)
				font.family: Theme.fontUi
				font.pixelSize: 10
				elide: Text.ElideMiddle
				horizontalAlignment: Text.AlignHCenter
				textFormat: Text.PlainText
			}
		}
	}

	// ── key hint ───────────────────────────────────────────────────────────

	Row {
		id: hint

		anchors.left: parent.left
		anchors.leftMargin: 5
		anchors.bottom: parent.bottom
		height: 14
		spacing: 14

		Repeater {
			model: [
				{ keys: "← →", desc: "select" },
				{ keys: "⏎", desc: "apply" },
				{ keys: "esc", desc: "close" },
				{ keys: "type", desc: "search" }
			]

			delegate: Row {
				required property var modelData

				spacing: 5

				Text {
					anchors.verticalCenter: parent.verticalCenter
					text: parent.modelData.keys
					color: Theme.textDim
					font.family: Theme.fontUi
					font.pixelSize: 10
					font.weight: Font.Medium
				}

				Text {
					anchors.verticalCenter: parent.verticalCenter
					text: parent.modelData.desc
					color: Theme.textFaint
					font.family: Theme.fontUi
					font.pixelSize: 10
				}
			}
		}
	}
}
