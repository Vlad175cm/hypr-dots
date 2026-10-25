import QtQuick

// PanelKeys.qml — the shortcut cheat sheet (SUPER + K).
Item {
	id: root

	implicitWidth: 624
	implicitHeight: 394

	// Groups are dealt into two columns so that both end up roughly the same
	// height, whatever you put in Shortcuts.qml.
	readonly property var columns: {
		const left = [];
		const right = [];
		let leftHeight = 0;
		let rightHeight = 0;

		for (let i = 0; i < Shortcuts.groups.length; i++) {
			const group = Shortcuts.groups[i];
			const height = 26 + (group.items?.length ?? 0) * 18 + 8;

			if (leftHeight <= rightHeight) {
				left.push(group);
				leftHeight += height;
			} else {
				right.push(group);
				rightHeight += height;
			}
		}

		return [left, right];
	}

	function tallest(): real {
		return Math.max(leftColumn.height, rightColumn.height);
	}

	Flickable {
		id: flick

		anchors.fill: parent
		contentHeight: root.tallest()
		clip: true
		boundsBehavior: Flickable.StopAtBounds

		Column {
			id: leftColumn

			width: (flick.width - 10) / 2
			spacing: 8

			Repeater {
				model: root.columns[0]

				delegate: KeyGroup {
					width: leftColumn.width
					group: modelData
				}
			}
		}

		Column {
			id: rightColumn

			x: leftColumn.width + 10
			width: leftColumn.width
			spacing: 8

			Repeater {
				model: root.columns[1]

				delegate: KeyGroup {
					width: rightColumn.width
					group: modelData
				}
			}
		}
	}
}
