import QtQuick
import Quickshell
import Quickshell.Io

// Spectrum.qml — a real FFT spectrum, fed by cava over stdout.
//
// cava only runs while this widget is on screen, so the island costs nothing
// when it is collapsed.
Item {
	id: root

	property int bars: 24
	property real maxRange: 100
	property color barColor: Theme.accent
	property color barColorTop: Theme.onSurface
	property real gap: 2
	property bool active: true

	// smoothed 0..1 levels
	property var levels: []
	property real decay: 0.76

	readonly property var shown: {
		const out = [];
		for (let i = 0; i < root.bars; i++) out.push(root.levels[i] ?? 0);
		return out;
	}

	Process {
		id: cava

		command: ["cava", "-p", Quickshell.shellPath("cava.conf")]
		running: root.active

		stdout: SplitParser {
			onRead: line => root.pushFrame(line)
		}
	}

	function pushFrame(line: string): void {
		if (line === "") return;

		const parts = line.split(";");
		const next = [];

		for (let i = 0; i < root.bars; i++) {
			const raw = (parseFloat(parts[i] ?? "0") || 0) / root.maxRange;
			const clamped = raw < 0 ? 0 : (raw > 1 ? 1 : raw);
			const previous = root.levels[i] ?? 0;
			// instant attack, soft release — looks like a real analyser
			next.push(clamped > previous ? clamped : previous * root.decay);
		}

		root.levels = next;
	}

	Row {
		id: row

		anchors.fill: parent
		spacing: root.gap

		Repeater {
			model: root.bars

			delegate: Item {
				required property int index

				width: (row.width - (root.bars - 1) * root.gap) / root.bars
				height: row.height

				Rectangle {
					id: capsule

					anchors.bottom: parent.bottom
					anchors.horizontalCenter: parent.horizontalCenter
					width: parent.width
					height: Math.max(2, parent.height * (root.shown[index] ?? 0))
					radius: width / 2

					gradient: Gradient {
						GradientStop {
							position: 0
							color: Theme.mix(root.barColor, root.barColorTop, 0.45)
						}
						GradientStop {
							position: 1
							color: Theme.alpha(root.barColor, 0.35)
						}
					}

					Behavior on height {
						NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
					}
				}
			}
		}
	}
}
