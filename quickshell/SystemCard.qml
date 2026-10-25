import QtQuick

// SystemCard.qml — radios, sound, brightness and battery in one card.
Card {
	id: root

	readonly property bool charging: Sys.charging

	SectionTitle {
		id: heading

		anchors.top: parent.top
		anchors.topMargin: 10
		anchors.left: parent.left
		anchors.leftMargin: 12
		anchors.right: parent.right
		anchors.rightMargin: 12

		label: "System"
		icon: Icons.microchip
		trailing: Sys.capsLock ? "CAPS" : ""
	}

	Column {
		id: rows

		anchors.top: heading.bottom
		anchors.topMargin: 4
		anchors.left: parent.left
		anchors.leftMargin: 20
		anchors.right: parent.right
		anchors.rightMargin: 20
		spacing: 0

		SystemRow {
			width: parent.width
			icon: Icons.wifi
			label: Sys.wifiName !== "" ? Sys.wifiName : "Wi-Fi"
			value: Sys.wifiOn ? (Sys.activeWifi !== null ? Sys.wifiSignal + "%" : "on") : "off"
			active: Sys.wifiOn
			interactive: true
			barValue: Sys.activeWifi !== null ? Sys.wifiSignal / 100 : -1
			barColor: Theme.accent
			onClicked: Sys.toggleWifi()
		}

		SystemRow {
			width: parent.width
			icon: Icons.bluetooth
			label: Sys.btName !== "" ? Sys.btName : "Bluetooth"
			value: !Sys.btOn ? "off" : (Sys.btConnected.length > 0 ? (Sys.btBattery >= 0 ? Sys.btBattery + "%" : "on") : "on")
			active: Sys.btOn
			interactive: true
			barValue: Sys.btOn && Sys.btBattery >= 0 ? Sys.btBattery / 100 : -1
			barColor: Theme.secondary
			onClicked: Sys.toggleBt()
		}

		SystemRow {
			width: parent.width
			icon: Sys.muted || Sys.volume <= 0.001 ? Icons.volumeOff : (Sys.volume < 0.5 ? Icons.volumeLow : Icons.volumeHigh)
			label: Sys.muted ? "Muted" : "Volume"
			value: Math.round((Sys.muted ? 0 : Sys.volume) * 100) + "%"
			active: !Sys.muted
			interactive: true
			iconClickable: true
			barValue: Sys.muted ? 0 : Sys.volume
			barColor: Theme.accent
			onMoved: value => Sys.setVolume(value)
			onIconClicked: Sys.toggleMute()
		}

		SystemRow {
			width: parent.width
			icon: Icons.sun
			label: "Brightness"
			value: Sys.brightnessKnown ? Math.round(Sys.brightness) + "%" : "—"
			active: true
			interactive: Sys.brightnessKnown
			barValue: Sys.brightnessKnown ? Sys.brightness / 100 : -1
			barColor: Theme.tertiary
			onMoved: value => Sys.setBrightness(value * 100)
		}

		Item {
			width: parent.width
			height: 30

			BatteryGlyph {
				id: batteryIcon

				anchors.left: parent.left
				anchors.verticalCenter: parent.verticalCenter
				level: Sys.batteryPct / 100
				charging: Sys.charging
			}

			Text {
				id: valueText

				anchors.right: parent.right
				anchors.verticalCenter: parent.verticalCenter
				text: Sys.batteryPct + "%"
				color: Theme.text
				font.family: Theme.fontUi
				font.pixelSize: 11
			}

			Bar {
				anchors.right: valueText.left
				anchors.rightMargin: 10
				anchors.verticalCenter: parent.verticalCenter
				width: 118
				interactive: false
				value: Sys.batteryPct / 100
				fillColor: Sys.charging ? Theme.good : (Sys.batteryPct <= 15 ? Theme.bad : Theme.accent)
				thickness: 5
			}

			Text {
				anchors.left: batteryIcon.right
				anchors.leftMargin: 8
				anchors.right: valueText.left
				anchors.rightMargin: 8
				anchors.verticalCenter: parent.verticalCenter
				text: Sys.charging ? "Battery · charging" : "Battery"
				color: Theme.text
				font.family: Theme.fontUi
				font.pixelSize: 11
			}
		}
	}

	Text {
		anchors.left: rows.left
		anchors.right: rows.right
		anchors.bottom: parent.bottom
		anchors.bottomMargin: 11

		text: {
			// the percentage row above already carries the time left, so this
			// line only adds the numbers that do not fit up there
			const bits = [];
			if (Sys.batteryWatts > 0.1) bits.push(Sys.batteryWatts.toFixed(1) + " W");
			if (Sys.batteryHealth > 0) bits.push("health " + Sys.batteryHealth + "%");
			if (bits.length === 0) bits.push(Sys.batteryDetail);
			return bits.join("  ·  ");
		}
		color: Theme.textFaint
		font.family: Theme.fontUi
		font.pixelSize: 10
		elide: Text.ElideRight
	}
}
