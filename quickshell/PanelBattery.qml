import QtQuick

// PanelBattery.qml — deep battery information (SUPER + SHIFT + B).
//
// Everything here updates live: the raw numbers are re-read from sysfs once a
// second (see Sys.qml), the ring glides, and the session chart grows as the
// island keeps running.
Item {
	id: root

	implicitWidth: 620
	implicitHeight: 452

	readonly property var history: Sys.batteryHistory

	readonly property var range: Sys.historyRange
	readonly property real chartMin: Math.max(0, range.min - 1.5)
	readonly property real chartMax: Math.min(100, range.max + 1.5)

	readonly property var liveStats: [
		{ icon: Icons.bolt, label: "Power draw", value: Sys.batteryWatts.toFixed(2) + " W" },
		{ icon: Icons.signal, label: "Current", value: Sys.batteryAmps.toFixed(2) + " A" },
		{ icon: Icons.power, label: "Voltage", value: Sys.batteryVolts.toFixed(2) + " V" },
		{
			icon: Icons.batteryHalf,
			label: "Energy",
			value: Sys.batteryEnergyWh.toFixed(2) + " / " + Sys.batteryFullWh.toFixed(1) + " Wh"
		},
		{
			icon: Icons.refresh,
			label: Sys.charging ? "Until full" : "Remaining",
			value: Sys.fmtDur(Sys.charging ? (Sys.battery?.timeToFull ?? 0) : (Sys.battery?.timeToEmpty ?? 0)) || "—"
		}
	]

	// ── live ───────────────────────────────────────────────────────────────

	Card {
		id: liveCard

		anchors.top: parent.top
		anchors.left: parent.left
		anchors.right: parent.right
		height: 158

		SectionTitle {
			id: liveHeading

			anchors.top: parent.top
			anchors.topMargin: 12
			anchors.left: parent.left
			anchors.leftMargin: 14
			anchors.right: parent.right
			anchors.rightMargin: 14

			label: "Battery"
			icon: Icons.batteryHalf
			trailing: Sys.batteryStatus.toLowerCase()
		}

		RingGauge {
			id: ring

			anchors.left: parent.left
			anchors.leftMargin: 16
			anchors.top: liveHeading.bottom
			anchors.topMargin: 6
			width: 112
			height: 112

			value: Sys.livePct / 100
			ringColor: Sys.charging
				? Theme.good
				: (Sys.batteryPct <= 15 ? Theme.bad : (Sys.batteryPct <= 30 ? Theme.warn : Theme.accent))

			Column {
				anchors.centerIn: parent
				spacing: -2

				Text {
					anchors.horizontalCenter: parent.horizontalCenter
					text: Sys.livePct.toFixed(1)
					color: Theme.text
					font.family: Theme.fontUi
					font.pixelSize: 26
					font.weight: Font.Light
				}

				Text {
					anchors.horizontalCenter: parent.horizontalCenter
					text: "%"
					color: Theme.textFaint
					font.family: Theme.fontUi
					font.pixelSize: 10
				}

				Text {
					anchors.horizontalCenter: parent.horizontalCenter
					visible: Sys.batteryTimeLeft !== ""
					text: Sys.batteryTimeLeft
					color: Theme.textFaint
					font.family: Theme.fontUi
					font.pixelSize: 9
				}
			}
		}

		Column {
			id: liveRows

			anchors.left: ring.right
			anchors.leftMargin: 18
			anchors.right: parent.right
			anchors.rightMargin: 16
			anchors.top: liveHeading.bottom
			anchors.topMargin: 4
			spacing: 0

			Repeater {
				model: root.liveStats

				delegate: Item {
					id: statRow

					required property var modelData

					width: liveRows.width
					height: 25

					Glyph {
						id: statIcon

						anchors.left: parent.left
						anchors.verticalCenter: parent.verticalCenter
						text: statRow.modelData.icon
						size: 10
						tint: Theme.textFaint
					}

					Text {
						anchors.left: statIcon.right
						anchors.leftMargin: 8
						anchors.verticalCenter: parent.verticalCenter
						text: statRow.modelData.label
						color: Theme.textFaint
						font.family: Theme.fontUi
						font.pixelSize: 11
					}

					Text {
						anchors.right: parent.right
						anchors.verticalCenter: parent.verticalCenter
						text: statRow.modelData.value
						color: Theme.textDim
						font.family: Theme.fontUi
						font.pixelSize: 12
						font.weight: Font.Medium
					}
				}
			}
		}
	}

	// ── wear ───────────────────────────────────────────────────────────────

	Card {
		id: wearCard

		anchors.top: liveCard.bottom
		anchors.topMargin: 12
		anchors.left: parent.left
		anchors.right: parent.right
		height: 106

		SectionTitle {
			id: wearHeading

			anchors.top: parent.top
			anchors.topMargin: 12
			anchors.left: parent.left
			anchors.leftMargin: 14
			anchors.right: parent.right
			anchors.rightMargin: 14

			label: "Wear"
			icon: Icons.microchip
		}

		Row {
			id: wearTiles

			anchors.top: wearHeading.bottom
			anchors.topMargin: 8
			anchors.left: parent.left
			anchors.leftMargin: 14
			anchors.right: parent.right
			anchors.rightMargin: 14
			spacing: 10

			Repeater {
				model: [
					{ label: "HEALTH", value: (Sys.batteryHealth > 0 ? Sys.batteryHealth : "—") + (Sys.batteryHealth > 0 ? "%" : "") },
					{ label: "CYCLES", value: Sys.cycleCount > 0 ? "" + Sys.cycleCount : "—" },
					{ label: "DESIGN", value: Sys.batteryDesignAh.toFixed(2) + " Ah" },
					{ label: "TEMP", value: Sys.batteryTemp > 0 ? Sys.batteryTemp.toFixed(1) + " °C" : "—" }
				]

				delegate: Rectangle {
					id: tile

					required property var modelData

					width: (wearTiles.width - 30) / 4
					height: 44
					radius: 12
					color: Theme.alpha(Theme.surfaceHighest, 0.45)

					Column {
						anchors.centerIn: parent
						spacing: 2

						Text {
							anchors.horizontalCenter: parent.horizontalCenter
							text: tile.modelData.value
							color: Theme.text
							font.family: Theme.fontUi
							font.pixelSize: 14
							font.weight: Font.Medium
						}

						Text {
							anchors.horizontalCenter: parent.horizontalCenter
							text: tile.modelData.label
							color: Theme.textFaint
							font.family: Theme.fontUi
							font.pixelSize: 9
							font.letterSpacing: 0.8
						}
					}
				}
			}
		}
	}

	// ── session ────────────────────────────────────────────────────────────

	Card {
		id: sessionCard

		anchors.top: wearCard.bottom
		anchors.topMargin: 12
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.bottom: parent.bottom

		SectionTitle {
			id: sessionHeading

			anchors.top: parent.top
			anchors.topMargin: 12
			anchors.left: parent.left
			anchors.leftMargin: 14
			anchors.right: parent.right
			anchors.rightMargin: 14

			label: "This session"
			icon: Icons.compass
			trailing: Sys.historyRange.minutes >= 1
				? (Sys.historyRange.minutes >= 60
					? (Sys.historyRange.minutes / 60).toFixed(1) + " h recorded"
					: Math.round(Sys.historyRange.minutes) + " min recorded")
				: "collecting…"
		}

		Text {
			anchors.centerIn: chart
			visible: root.history.length < 2
			text: "the graph fills in as the island runs"
			color: Theme.textFaint
			font.family: Theme.fontUi
			font.pixelSize: 11
		}

		Sparkline {
			id: chart

			anchors.top: sessionHeading.bottom
			anchors.topMargin: 6
			anchors.left: parent.left
			anchors.leftMargin: 14
			anchors.right: parent.right
			anchors.rightMargin: 14
			anchors.bottom: legend.top
			anchors.bottomMargin: 6

			points: root.history
			minValue: root.chartMin
			maxValue: root.chartMax
			lineColor: Sys.charging ? Theme.good : Theme.accent
		}

		Row {
			id: legend

			anchors.left: parent.left
			anchors.leftMargin: 14
			anchors.right: parent.right
			anchors.rightMargin: 14
			anchors.bottom: parent.bottom
			anchors.bottomMargin: 12
			spacing: 16

			Repeater {
				model: [
					{ label: "now", value: Sys.livePct.toFixed(1) + "%" },
					{ label: "low", value: root.range.min.toFixed(1) + "%" },
					{ label: "high", value: root.range.max.toFixed(1) + "%" },
					{ label: "draw", value: Sys.batteryWatts.toFixed(1) + " W" }
				]

				delegate: Row {
					required property var modelData

					spacing: 5

					Text {
						anchors.verticalCenter: parent.verticalCenter
						text: parent.modelData.label
						color: Theme.textFaint
						font.family: Theme.fontUi
						font.pixelSize: 10
					}

					Text {
						anchors.verticalCenter: parent.verticalCenter
						text: parent.modelData.value
						color: Theme.textDim
						font.family: Theme.fontUi
						font.pixelSize: 10
						font.weight: Font.Medium
					}
				}
			}
		}
	}
}
