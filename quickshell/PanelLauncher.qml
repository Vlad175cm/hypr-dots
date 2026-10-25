import QtQuick
import Quickshell
import Quickshell.Widgets

// PanelLauncher.qml — the application launcher (SUPER + D).
//
// Searches every .desktop entry via Quickshell's DesktopEntries model. Type to
// filter, arrows to move, Enter (or a click) to launch, Escape to close.
Item {
	id: root

	implicitWidth: 596
	implicitHeight: 432

	property var entries: DesktopEntries.applications.values ?? []
	property int selected: 0
	property string query: ""

	// bound, not imperatively built: the desktop entry index is filled in
	// asynchronously, so this has to keep up with it on its own
	readonly property var matches: root.computeMatches()

	signal requestClose()

	Component.onCompleted: searchInput.forceActiveFocus()

	onMatchesChanged: {
		root.selected = 0;
		if (appList.count > 0) appList.positionViewAtBeginning();
	}

	function move(step: int): void {
		if (root.matches.length === 0) return;
		root.selected = Math.max(0, Math.min(root.matches.length - 1, root.selected + step));
		appList.positionViewAtIndex(root.selected, ListView.Contain);
	}

	// ── search ─────────────────────────────────────────────────────────────

	function computeMatches(): var {
		const needle = root.query.trim().toLowerCase();
		const tokens = needle === "" ? [] : needle.split(/\s+/).filter(t => t !== "");
		const found = [];

		for (let i = 0; i < root.entries.length; i++) {
			const app = root.entries[i];
			if (!app || app.noDisplay) continue;

			const name = app.name ?? "";
			if (name === "") continue;

			let score = 1;
			if (tokens.length > 0) {
				const haystack = (name + " " + (app.genericName ?? "") + " "
					+ (app.keywords ?? []).join(" ") + " " + (app.comment ?? "")).toLowerCase();

				let all = true;
				for (let t = 0; t < tokens.length; t++) {
					if (haystack.indexOf(tokens[t]) < 0) {
						all = false;
						break;
					}
				}
				if (!all) continue;

				const lower = name.toLowerCase();
				if (lower === needle) score = 400;
				else if (lower.startsWith(needle)) score = 300;
				else if (lower.indexOf(" " + needle) >= 0) score = 200;
				else if ((app.genericName ?? "").toLowerCase().startsWith(needle)) score = 120;
				else score = 60;

				// shorter names win ties, matches near the start are better
				score -= Math.min(40, name.length);
				score -= Math.min(40, Math.max(0, lower.indexOf(tokens[0])));
			}

			found.push({ entry: app, name: name, generic: app.genericName ?? "", icon: app.icon ?? "", score: score });
		}

		found.sort((a, b) => b.score - a.score || a.name.localeCompare(b.name));
		return found;
	}

	function launch(): void {
		const item = root.matches[root.selected];
		if (!item) return;
		root.requestClose();
		item.entry.execute();
	}

	// The panel is never unloaded (recreating it mid-morph drops frames), so a
	// query typed last time would still be sitting in the field. Island calls
	// this whenever the launcher is really opened, so every open starts clean.
	function reset(): void {
		searchInput.text = "";
		searchInput.forceActiveFocus();
	}

	// ── search field ───────────────────────────────────────────────────────

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
			anchors.right: counter.left
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
			Keys.onReturnPressed: root.launch()
			Keys.onEnterPressed: root.launch()
			Keys.onPressed: event => {
				if (event.key === Qt.Key_PageDown) {
					root.move(6);
					event.accepted = true;
				} else if (event.key === Qt.Key_PageUp) {
					root.move(-6);
					event.accepted = true;
				}
			}

			Text {
				anchors.fill: parent
				verticalAlignment: Text.AlignVCenter
				visible: searchInput.text === ""
				text: "Search applications…"
				color: Theme.textFaint
				font: parent.font
			}
		}

		Text {
			id: counter

			anchors.right: parent.right
			anchors.rightMargin: 16
			anchors.verticalCenter: parent.verticalCenter

			text: root.matches.length + " apps"
			color: Theme.textFaint
			font.family: Theme.fontUi
			font.pixelSize: 10
		}
	}

	// ── results ────────────────────────────────────────────────────────────

	ListView {
		id: appList

		anchors.top: searchBox.bottom
		anchors.topMargin: 10
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.bottom: parent.bottom

		clip: true
		spacing: 2
		model: root.matches
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

			AppIcon {
				id: appIcon

				anchors.left: parent.left
				anchors.leftMargin: 10
				anchors.verticalCenter: parent.verticalCenter
				size: 28
				iconName: item.modelData.icon
				fallbackText: item.modelData.name
			}

			Column {
				anchors.left: appIcon.right
				anchors.leftMargin: 12
				anchors.right: enterHint.left
				anchors.rightMargin: 10
				anchors.verticalCenter: parent.verticalCenter
				spacing: 1

				Text {
					width: parent.width
					text: item.modelData.name
					color: Theme.text
					font.family: Theme.fontUi
					font.pixelSize: 13
					font.weight: Font.Medium
					elide: Text.ElideRight
					textFormat: Text.PlainText
				}

				Text {
					width: parent.width
					visible: item.modelData.generic !== ""
					text: item.modelData.generic
					color: Theme.textFaint
					font.family: Theme.fontUi
					font.pixelSize: 11
					elide: Text.ElideRight
					textFormat: Text.PlainText
				}
			}

			Chip {
				id: enterHint

				anchors.right: parent.right
				anchors.rightMargin: 10
				anchors.verticalCenter: parent.verticalCenter
				visible: root.selected === item.index
				label: "ENTER"
				size: 8.5
				hPad: 7
				vPad: 3
				tint: Theme.accent
				fill: Theme.accentGhost
			}

			HoverHandler {
				id: itemHover

				onHoveredChanged: {
					if (hovered) root.selected = item.index;
				}
			}

			MouseArea {
				anchors.fill: parent
				onClicked: root.launch()
			}
		}
	}

	// nothing matches
	Text {
		anchors.centerIn: parent
		visible: root.matches.length === 0
		text: "no application matches “" + root.query + "”"
		color: Theme.textFaint
		font.family: Theme.fontUi
		font.pixelSize: 12
	}
}
