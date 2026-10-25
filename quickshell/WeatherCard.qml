import QtQuick

// WeatherCard.qml — current conditions from wttr.in's one line format,
// plus a small sun track between sunrise and sunset.
// See Sys.weatherCity to pin a location instead of guessing from the ip.
Card {
	id: root

	readonly property var w: Sys.weather

	// wttr.in answers with text, so the icon is picked by keyword
	function glyphFor(text): string {
		const t = (text ?? "").toLowerCase();
		if (t.indexOf("thunder") >= 0) return Icons.bolt;
		if (t.indexOf("snow") >= 0 || t.indexOf("sleet") >= 0 || t.indexOf("ice") >= 0 || t.indexOf("blizzard") >= 0) return Icons.snow;
		if (t.indexOf("rain") >= 0 || t.indexOf("drizzle") >= 0 || t.indexOf("shower") >= 0) return Icons.rain;
		if (t.indexOf("fog") >= 0 || t.indexOf("mist") >= 0 || t.indexOf("haze") >= 0 || t.indexOf("smog") >= 0) return Icons.cloud;
		if (t.indexOf("cloud") >= 0 || t.indexOf("overcast") >= 0) return Icons.cloud;
		return Icons.sun;
	}

	readonly property var metrics: root.w === null ? [] : [
		{ icon: Icons.rain, label: "humidity", value: root.w.humidity + "%" },
		{ icon: Icons.wind, label: "wind", value: root.w.wind },
		{ icon: Icons.moon, label: "moon", value: root.w.moon },
		{ icon: Icons.sun, label: "sunrise", value: (root.w?.sunrise ?? "").substring(0, 5) },
		{ icon: Icons.moon, label: "sunset", value: (root.w?.sunset ?? "").substring(0, 5) }
	]

	SectionTitle {
		id: heading

		anchors.top: parent.top
		anchors.topMargin: 12
		anchors.left: parent.left
		anchors.leftMargin: 14
		anchors.right: parent.right
		anchors.rightMargin: 14

		label: "Weather"
		icon: Icons.compass
		trailing: root.w === null
			? (Sys.weatherFailed ? "unavailable" : "loading…")
			: root.w.place
	}

	// ── placeholder while there is nothing to show ─────────────────────────

	Text {
		anchors.centerIn: parent
		visible: root.w === null

		text: Sys.weatherFailed ? "no weather data — retrying" : "loading weather…"
		color: Theme.textFaint
		font.family: Theme.fontUi
		font.pixelSize: 11
	}

	// ── current conditions ─────────────────────────────────────────────────

	Row {
		id: current

		anchors.top: heading.bottom
		anchors.topMargin: 10
		anchors.left: parent.left
		anchors.leftMargin: 14
		spacing: 12
		visible: root.w !== null

		Glyph {
			anchors.verticalCenter: parent.verticalCenter
			text: root.glyphFor(root.w?.desc ?? "")
			size: 32
			tint: Theme.accent
		}

		Column {
			anchors.verticalCenter: parent.verticalCenter
			spacing: 0

			Text {
				text: (root.w?.temp ?? 0) + "°C"
				color: Theme.text
				font.family: Theme.fontUi
				font.pixelSize: 28
				font.weight: Font.Light
			}

			Text {
				text: "feels like " + (root.w?.feels ?? 0) + "°"
				color: Theme.textFaint
				font.family: Theme.fontUi
				font.pixelSize: 10
			}
		}

		Text {
			anchors.verticalCenter: parent.verticalCenter
			width: 132
			text: root.w?.desc ?? ""
			color: Theme.textDim
			font.family: Theme.fontUi
			font.pixelSize: 12
			wrapMode: Text.WordWrap
			maximumLineCount: 3
			elide: Text.ElideRight
			textFormat: Text.PlainText
		}
	}

	// ── signature ──────────────────────────────────────────────────────────

	Text {
		id: motto

		anchors.left: parent.left
		anchors.leftMargin: 14
		anchors.right: parent.right
		anchors.rightMargin: 14
		anchors.bottom: parent.bottom
		anchors.bottomMargin: 10

		text: "ブロンドやアジア系の女性とヤるのが大好きだ。"
		color: Theme.textFaint
		font.family: "Noto Sans CJK JP"
		font.pixelSize: 10
		elide: Text.ElideRight
	}

	// ── metrics ────────────────────────────────────────────────────────────

	Grid {
		id: metrics

		anchors.top: current.bottom
		anchors.topMargin: 12
		anchors.left: parent.left
		anchors.leftMargin: 14
		anchors.right: parent.right
		anchors.rightMargin: 14
		columns: 3
		rowSpacing: 6
		columnSpacing: 4
		visible: root.w !== null

		Repeater {
			model: root.metrics

			delegate: Row {
				required property var modelData

				width: (metrics.width - 8) / 3
				spacing: 5

				Glyph {
					anchors.verticalCenter: parent.verticalCenter
					text: parent.modelData.icon
					size: 9
					tint: Theme.textFaint
				}

				Column {
					anchors.verticalCenter: parent.verticalCenter
					spacing: -1

					Text {
						text: parent.parent.modelData.value
						color: Theme.textDim
						font.family: Theme.fontUi
						font.pixelSize: 11
						elide: Text.ElideRight
						width: parent.parent.width - 16
						textFormat: Text.PlainText
					}

					Text {
						text: parent.parent.modelData.label
						color: Theme.textFaint
						font.family: Theme.fontUi
						font.pixelSize: 9
					}
				}
			}
		}
	}

}
