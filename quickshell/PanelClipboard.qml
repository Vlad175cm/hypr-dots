import QtQuick
import Quickshell
import Quickshell.Io

// PanelClipboard.qml — the clipboard history (SUPER + SHIFT + V).
//
// Every copy on the system is recorded by scripts/clipboard.sh. This panel
// lists it, filters it, puts an entry back on the clipboard (click or Enter)
// and forgets single entries. Styled like the other panels: no cards, one
// accent colour, thin hairlines.
Item {
	id: root

	implicitWidth: 596
	implicitHeight: 432

	property var entries: []
	property int selected: 0
	property string query: ""

	readonly property string script: Quickshell.shellPath("scripts/clipboard.sh")

	// filtered view, newest first (the backend already sorts it that way)
	readonly property var shown: {
		const q = root.query.trim().toLowerCase();
		if (q === "") return root.entries;
		return root.entries.filter(e => (e.preview ?? "").toLowerCase().indexOf(q) >= 0);
	}

	signal requestClose()

	Component.onCompleted: {
		root.refresh();
		searchInput.forceActiveFocus();
	}

	function refresh(): void {
		if (!listProc.running) listProc.running = true;
	}

	// called by the island every time the panel is really opened, so a stale
	// search never sticks around
	function reset(): void {
		root.query = "";
		searchInput.text = "";
		root.selected = 0;
		root.refresh();
		searchInput.forceActiveFocus();
	}

	Process {
		id: listProc

		command: ["bash", root.script, "list"]

		stdout: StdioCollector {
			onStreamFinished: {
				try {
					root.entries = JSON.parse(text).entries ?? [];
				} catch (e) {
					root.entries = [];
				}
			}
		}
	}

	// The backend touches .changed on every copy, so watching that file makes
	// the list refresh the moment something is copied — polling every 2 s felt
	// like an eternity. The timer is only a slow safety net.
	FileView {
		path: Quickshell.env("HOME") + "/.cache/quickshell/clipboard/.changed"
		watchChanges: true
		onFileChanged: if (Sys.panelOpen) root.refresh()
	}

	Timer {
		interval: 15000
		running: Sys.panelOpen
		repeat: true
		onTriggered: root.refresh()
	}

	onShownChanged: {
		root.selected = 0;
		if (appList.count > 0) appList.positionViewAtBeginning();
	}

	function move(step: int): void {
		if (root.shown.length === 0) return;
		root.selected = Math.max(0, Math.min(root.shown.length - 1, root.selected + step));
		appList.positionViewAtIndex(root.selected, ListView.Contain);
	}

	function copyEntry(entry): void {
		if (!entry) return;
		root.requestClose();
		Quickshell.execDetached(["bash", root.script, "copy", entry.id]);
	}

	function removeEntry(entry): void {
		if (!entry) return;
		root.entries = root.entries.filter(e => e.id !== entry.id);
		Quickshell.execDetached(["bash", root.script, "remove", entry.id]);
	}

	function clearAll(): void {
		root.entries = [];
		Quickshell.execDetached(["bash", root.script, "clear"]);
	}

	function ageLabel(secs): string {
		if (secs < 60) return "now";
		if (secs < 3600) return Math.floor(secs / 60) + "m";
		if (secs < 86400) return Math.floor(secs / 3600) + "h";
		return Math.floor(secs / 86400) + "d";
	}

	// ── toolbar: search + count + clear ────────────────────────────────────

	Rectangle {
		id: searchBox

		anchors.top: parent.top
		anchors.left: parent.left
		anchors.right: parent.right
		height: 46
		radius: 16
		color: Theme.chip

		Glyph {
			id: searchGlyph

			anchors.left: parent.left
			anchors.leftMargin: 16
			anchors.verticalCenter: parent.verticalCenter
			text: Icons.search
			size: 13
			tint: Theme.textFaint
		}

		TextInput {
			id: searchInput

			anchors.left: searchGlyph.right
			anchors.leftMargin: 12
			anchors.right: clearChip.left
			anchors.rightMargin: 12
			anchors.verticalCenter: parent.verticalCenter

			color: Theme.text
			font.family: Theme.fontUi
			font.pixelSize: 14
			selectByMouse: true
			clip: true
			selectionColor: Theme.accentSoft

			onTextChanged: root.query = text

			Keys.onDownPressed: root.move(1)
			Keys.onUpPressed: root.move(-1)
			Keys.onReturnPressed: root.copyEntry(root.shown[root.selected])
			Keys.onEnterPressed: root.copyEntry(root.shown[root.selected])

			Text {
				anchors.fill: parent
				verticalAlignment: Text.AlignVCenter
				visible: searchInput.text === ""
				text: "Search clipboard…"
				color: Theme.textFaint
				font: parent.font
			}
		}

		Chip {
			id: clearChip

			anchors.right: parent.right
			anchors.rightMargin: 12
			anchors.verticalCenter: parent.verticalCenter
			visible: root.entries.length > 0
			label: "CLEAR"
			size: 8.5
			hPad: 8
			vPad: 4
			tint: Theme.warn
			fill: Theme.alpha(Theme.warn, 0.12)

			MouseArea {
				anchors.fill: parent
				anchors.margins: -4
				cursorShape: Qt.PointingHandCursor
				onClicked: root.clearAll()
			}
		}
	}

	// ── the entries ────────────────────────────────────────────────────────

	ListView {
		id: appList

		anchors.top: searchBox.bottom
		anchors.topMargin: 10
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.bottom: parent.bottom

		clip: true
		spacing: 2
		model: root.shown
		visible: root.shown.length > 0
		boundsBehavior: Flickable.StopAtBounds
		cacheBuffer: 400

		delegate: Rectangle {
			id: item

			required property var modelData
			required property int index

			width: appList.width
			height: 46
			radius: 13
			color: root.selected === item.index
				? Theme.accentGhost
				: (itemHover.hovered ? Theme.chip : "transparent")

			Behavior on color {
				ColorAnimation { duration: Theme.durFast; easing.type: Theme.easeOut }
			}

			// kind: a glyph for text, a thumbnail for an image
			Item {
				id: kindBox

				anchors.left: parent.left
				anchors.leftMargin: 10
				anchors.verticalCenter: parent.verticalCenter
				width: 28
				height: 28

				Rectangle {
					anchors.fill: parent
					radius: 9
					color: Theme.chip
					visible: item.modelData.kind !== "image"
				}

				Glyph {
					anchors.centerIn: parent
					visible: item.modelData.kind !== "image"
					text: Icons.copy
					size: 13
					tint: Theme.accent
				}

				Image {
					anchors.fill: parent
					visible: item.modelData.kind === "image"
					source: item.modelData.kind === "image" ? "file://" + item.modelData.thumb : ""
					sourceSize.width: 56
					sourceSize.height: 56
					fillMode: Image.PreserveAspectCrop
					asynchronous: true
					clip: true

					Rectangle {
						anchors.fill: parent
						radius: 9
						color: "transparent"
						border.width: 1
						border.color: Theme.alpha(Theme.text, 0.14)
					}
				}
			}

			Text {
				anchors.left: kindBox.right
				anchors.leftMargin: 12
				anchors.right: ageText.left
				anchors.rightMargin: 10
				anchors.verticalCenter: parent.verticalCenter
				text: item.modelData.kind === "image"
					? "Image"
					: item.modelData.preview
				color: Theme.text
				font.family: Theme.fontUi
				font.pixelSize: 12
				elide: Text.ElideRight
				textFormat: Text.PlainText
			}

			Text {
				id: ageText

				anchors.right: delBtn.left
				anchors.rightMargin: 10
				anchors.verticalCenter: parent.verticalCenter
				text: root.ageLabel(item.modelData.age)
				color: Theme.textFaint
				font.family: Theme.fontUi
				font.pixelSize: 10
			}

			Rectangle {
				id: delBtn

				anchors.right: parent.right
				anchors.rightMargin: 8
				anchors.verticalCenter: parent.verticalCenter
				width: 22
				height: 22
				radius: 11
				color: delHover.hovered ? Theme.chipHover : "transparent"

				Glyph {
					anchors.centerIn: parent
					text: Icons.close
					size: 9
					tint: Theme.textFaint
				}

				HoverHandler { id: delHover }

				MouseArea {
					anchors.fill: parent
					anchors.margins: -3
					cursorShape: Qt.PointingHandCursor
					onClicked: root.removeEntry(item.modelData)
				}
			}

			HoverHandler {
				id: itemHover

				onHoveredChanged: {
					if (hovered) root.selected = item.index;
				}
			}

			MouseArea {
				anchors.fill: parent
				anchors.rightMargin: 34
				onClicked: root.copyEntry(item.modelData)
			}
		}
	}

	// nothing here yet
	Text {
		anchors.centerIn: parent
		visible: root.shown.length === 0
		text: root.entries.length === 0
			? "clipboard is empty"
			: "nothing matches “" + root.query + "”"
		color: Theme.textFaint
		font.family: Theme.fontUi
		font.pixelSize: 12
	}
}
