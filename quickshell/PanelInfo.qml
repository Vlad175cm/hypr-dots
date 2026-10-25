import QtQuick
import Quickshell.Networking

// PanelInfo.qml — the full system panel (SUPER + C).
//
// Wi-Fi access points, paired bluetooth devices, audio, power and machine
// load, all in one place and all actionable.
Item {
	id: root

	implicitWidth: 780
	implicitHeight: 496

	readonly property int columnWidth: (width - 12) / 2

	// network waiting for a password
	property var pendingNetwork: null
	property string psk: ""

	signal requestClose()

	function activateNetwork(network): void {
		if (!network) return;

		if (network.connected) {
			network.disconnect();
			return;
		}

		if (network.known
			|| network.security === WifiSecurityType.Open
			|| network.security === WifiSecurityType.Owe) {
			network.connect();
			return;
		}

		root.pendingNetwork = network;
		root.psk = "";
		pskField.forceActiveFocus();
	}

	function submitPsk(): void {
		if (root.pendingNetwork && root.psk !== "") root.pendingNetwork.connectWithPsk(root.psk);
		root.pendingNetwork = null;
		root.psk = "";
	}

	function securityIcon(network): string {
		if (network.security === WifiSecurityType.Open) return "";
		return Icons.lock;
	}

	Row {
		anchors.fill: parent
		spacing: 12

		// ══ left column ═══════════════════════════════════════════════════

		Column {
			width: root.columnWidth
			spacing: 12

			// ── wi-fi ───────────────────────────────────────────────────────
			Card {
				id: wifiCard

				width: parent.width
				height: 268

				SectionTitle {
					id: wifiHeading

					anchors.top: parent.top
					anchors.topMargin: 12
					anchors.left: parent.left
					anchors.leftMargin: 14
					anchors.right: parent.right
					anchors.rightMargin: 14

					label: "Wi-Fi"
					icon: Icons.wifi
					trailing: Sys.wifiOn ? (Sys.wifiName !== "" ? "connected" : "searching") : "off"
				}

				Item {
					id: currentRow

					anchors.top: wifiHeading.bottom
					anchors.topMargin: 6
					anchors.left: parent.left
					anchors.leftMargin: 14
					anchors.right: parent.right
					anchors.rightMargin: 14
					height: 26

					SignalGlyph {
						id: currentSignal

						anchors.left: parent.left
						anchors.verticalCenter: parent.verticalCenter
						strength: Sys.wifiSignal / 100
						tint: Sys.wifiOn ? Theme.accent : Theme.textFaint
					}

					Text {
						anchors.left: currentSignal.right
						anchors.leftMargin: 10
						anchors.right: wifiToggle.left
						anchors.rightMargin: 8
						anchors.verticalCenter: parent.verticalCenter

						text: Sys.wifiOn ? (Sys.wifiName !== "" ? Sys.wifiName : "not connected") : "Wi-Fi is off"
						color: Sys.wifiOn ? Theme.text : Theme.textFaint
						font.family: Theme.fontUi
						font.pixelSize: 12
						font.weight: Font.Medium
						elide: Text.ElideRight
					}

					Chip {
						id: wifiToggle

						anchors.right: parent.right
						anchors.verticalCenter: parent.verticalCenter
						label: Sys.wifiOn ? "Turn off" : "Turn on"
						size: 9.5
						hPad: 9
						vPad: 4
						tint: Sys.wifiOn ? Theme.textDim : Theme.accent
						fill: Sys.wifiOn ? Theme.chip : Theme.accentGhost
						stroke: Sys.wifiOn ? "transparent" : Theme.alpha(Theme.accent, 0.35)

						MouseArea {
							anchors.fill: parent
							anchors.margins: -2
							cursorShape: Qt.PointingHandCursor
							onClicked: Sys.toggleWifi()
						}
					}
				}

				// ── access points ──────────────────────────────────────────
				ListView {
					id: apList

					anchors.top: currentRow.bottom
					anchors.topMargin: 6
					anchors.left: parent.left
					anchors.leftMargin: 8
					anchors.right: parent.right
					anchors.rightMargin: 8
					anchors.bottom: pskRow.visible ? pskRow.top : parent.bottom
					anchors.bottomMargin: 10

					clip: true
					spacing: 1
					model: Sys.wifiAvailable
					boundsBehavior: Flickable.StopAtBounds
					cacheBuffer: 400

					delegate: Rectangle {
						id: apRow

						required property var modelData

						width: apList.width
						height: 30
						radius: 9
						color: apHover.hovered ? Theme.chip : "transparent"

						Behavior on color {
							ColorAnimation { duration: Theme.durFast; easing.type: Theme.easeOut }
						}

						SignalGlyph {
							id: apSignal

							anchors.left: parent.left
							anchors.leftMargin: 6
							anchors.verticalCenter: parent.verticalCenter
							strength: (apRow.modelData.signalStrength ?? 0)
							tint: apRow.modelData.connected ? Theme.accent : Theme.textDim
						}

						Glyph {
							id: apLock

							anchors.left: apSignal.right
							anchors.leftMargin: 8
							anchors.verticalCenter: parent.verticalCenter
							text: root.securityIcon(apRow.modelData)
							size: 8
							tint: Theme.textFaint
						}

						Text {
							anchors.left: apLock.right
							anchors.leftMargin: apLock.text === "" ? 0 : 7
							anchors.right: apPercent.left
							anchors.rightMargin: 8
							anchors.verticalCenter: parent.verticalCenter

							text: apRow.modelData.name
							color: apRow.modelData.connected ? Theme.text : Theme.textDim
							font.family: Theme.fontUi
							font.pixelSize: 11
							font.weight: apRow.modelData.connected ? Font.Medium : Font.Normal
							elide: Text.ElideRight
							textFormat: Text.PlainText
						}

						Text {
							id: apPercent

							anchors.right: parent.right
							anchors.rightMargin: 10
							anchors.verticalCenter: parent.verticalCenter

							text: Math.round((apRow.modelData.signalStrength ?? 0) * 100) + "%"
							color: Theme.textFaint
							font.family: Theme.fontUi
							font.pixelSize: 10
						}

						HoverHandler { id: apHover }

						MouseArea {
							anchors.fill: parent
							cursorShape: Qt.PointingHandCursor
							onClicked: root.activateNetwork(apRow.modelData)
						}
					}
				}

				// ── password prompt ────────────────────────────────────────
				Rectangle {
					id: pskRow

					anchors.left: parent.left
					anchors.leftMargin: 14
					anchors.right: parent.right
					anchors.rightMargin: 14
					anchors.bottom: parent.bottom
					anchors.bottomMargin: 12
					height: 34
					radius: 12
					color: Theme.chip
					visible: root.pendingNetwork !== null

					Glyph {
						id: pskIcon

						anchors.left: parent.left
						anchors.leftMargin: 10
						anchors.verticalCenter: parent.verticalCenter
						text: Icons.lock
						size: 10
						tint: Theme.accent
					}

					TextInput {
						id: pskField

						anchors.left: pskIcon.right
						anchors.leftMargin: 8
						anchors.right: pskConnect.left
						anchors.rightMargin: 8
						anchors.verticalCenter: parent.verticalCenter

						color: Theme.text
						font.family: Theme.fontUi
						font.pixelSize: 11
						echoMode: TextInput.Password
						clip: true
						selectionColor: Theme.accentSoft

						onTextChanged: root.psk = text

						Keys.onReturnPressed: root.submitPsk()
						Keys.onEnterPressed: root.submitPsk()

						Text {
							anchors.fill: parent
							verticalAlignment: Text.AlignVCenter
							visible: pskField.text === ""
							text: "password for " + (root.pendingNetwork ? root.pendingNetwork.name : "") + "…"
							color: Theme.textFaint
							font: parent.font
							elide: Text.ElideRight
						}
					}

					Chip {
						id: pskConnect

						anchors.right: pskCancel.left
						anchors.rightMargin: 6
						anchors.verticalCenter: parent.verticalCenter
						label: "Connect"
						size: 9
						hPad: 8
						vPad: 3
						tint: Theme.accent
						fill: Theme.accentGhost

						MouseArea {
							anchors.fill: parent
							anchors.margins: -2
							cursorShape: Qt.PointingHandCursor
							onClicked: root.submitPsk()
						}
					}

					Chip {
						id: pskCancel

						anchors.right: parent.right
						anchors.rightMargin: 8
						anchors.verticalCenter: parent.verticalCenter
						label: Icons.close
						size: 9
						hPad: 6
						vPad: 3
						monospace: true
						tint: Theme.textFaint
						fill: Theme.chip

						MouseArea {
							anchors.fill: parent
							anchors.margins: -2
							cursorShape: Qt.PointingHandCursor
							onClicked: root.pendingNetwork = null
						}
					}
				}
			}

			// ── audio ───────────────────────────────────────────────────────
			Card {
				id: audioCard

				width: parent.width
				height: 104

				SectionTitle {
					id: audioHeading

					anchors.top: parent.top
					anchors.topMargin: 12
					anchors.left: parent.left
					anchors.leftMargin: 14
					anchors.right: parent.right
					anchors.rightMargin: 14

					label: "Audio"
					icon: Sys.muted ? Icons.volumeOff : Icons.volumeHigh
					trailing: Sys.muted ? "muted" : Math.round(Sys.volume * 100) + "%"
				}

				Text {
					id: sinkName

					anchors.top: audioHeading.bottom
					anchors.topMargin: 6
					anchors.left: parent.left
					anchors.leftMargin: 14
					anchors.right: muteButton.left
					anchors.rightMargin: 10

					text: Sys.sink ? (Sys.sink.description || Sys.sink.nickname || Sys.sink.name) : "no output device"
					color: Theme.textDim
					font.family: Theme.fontUi
					font.pixelSize: 11
					elide: Text.ElideRight
				}

				Chip {
					id: muteButton

					anchors.right: parent.right
					anchors.rightMargin: 14
					anchors.top: audioHeading.bottom
					anchors.topMargin: 4
					label: Sys.muted ? "Unmute" : "Mute"
					size: 9
					hPad: 8
					vPad: 3
					tint: Sys.muted ? Theme.warn : Theme.textDim
					fill: Theme.chip

					MouseArea {
						anchors.fill: parent
						anchors.margins: -2
						cursorShape: Qt.PointingHandCursor
						onClicked: Sys.toggleMute()
					}
				}

				Bar {
					anchors.left: parent.left
					anchors.leftMargin: 14
					anchors.right: parent.right
					anchors.rightMargin: 14
					anchors.bottom: parent.bottom
					anchors.bottomMargin: 16
					interactive: true
					value: Sys.muted ? 0 : Sys.volume
					thickness: 6
					fillColor: Theme.accent
					onMoved: value => Sys.setVolume(value)
				}
			}

			// ── network ─────────────────────────────────────────────────────
			Card {
				id: netCard

				width: parent.width
				height: 96

				SectionTitle {
					id: netHeading

					anchors.top: parent.top
					anchors.topMargin: 12
					anchors.left: parent.left
					anchors.leftMargin: 14
					anchors.right: parent.right
					anchors.rightMargin: 14

					label: "Network"
					icon: Icons.signal
					trailing: Sys.loadAvg
				}

				Column {
					anchors.top: netHeading.bottom
					anchors.topMargin: 8
					anchors.left: parent.left
					anchors.leftMargin: 14
					anchors.right: parent.right
					anchors.rightMargin: 14
					spacing: 5

					Repeater {
						model: [
							{ label: "IPv4", value: Sys.ipAddress !== "" ? Sys.ipAddress : "—" },
							{ label: "Interface", value: Sys.wifiDevice ? Sys.wifiDevice.name : "—" },
							{ label: "Internet", value: "" + Sys.connectivityLabel }
						]

						delegate: Row {
							required property var modelData

							width: netCard.width - 28

							Text {
								anchors.verticalCenter: parent.verticalCenter
								width: 74
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
								font.pixelSize: 11
								elide: Text.ElideRight
							}
						}
					}
				}
			}
		}

		// ══ right column ══════════════════════════════════════════════════

		Column {
			width: root.columnWidth
			spacing: 12

			// ── bluetooth ───────────────────────────────────────────────────
			Card {
				id: btCard

				width: parent.width
				height: 208

				SectionTitle {
					id: btHeading

					anchors.top: parent.top
					anchors.topMargin: 12
					anchors.left: parent.left
					anchors.leftMargin: 14
					anchors.right: parent.right
					anchors.rightMargin: 14

					label: "Bluetooth"
					icon: Icons.bluetooth
					trailing: Sys.btOn ? (Sys.btConnected.length + " connected") : "off"
				}

				Chip {
					id: btToggle

					anchors.right: parent.right
					anchors.rightMargin: 14
					anchors.top: btHeading.bottom
					anchors.topMargin: 2
					label: Sys.btOn ? "Turn off" : "Turn on"
					size: 9
					hPad: 8
					vPad: 3
					tint: Sys.btOn ? Theme.textDim : Theme.accent
					fill: Sys.btOn ? Theme.chip : Theme.accentGhost

					MouseArea {
						anchors.fill: parent
						anchors.margins: -2
						cursorShape: Qt.PointingHandCursor
						onClicked: Sys.toggleBt()
					}
				}

				Text {
					anchors.left: parent.left
					anchors.leftMargin: 14
					anchors.top: btHeading.bottom
					anchors.topMargin: 6
					anchors.right: btToggle.left
					anchors.rightMargin: 8

					text: Sys.btAdapter ? Sys.btAdapter.name : "no adapter"
					color: Theme.textFaint
					font.family: Theme.fontUi
					font.pixelSize: 10
					elide: Text.ElideRight
				}

				ListView {
					id: btList

					anchors.top: btToggle.bottom
					anchors.topMargin: 8
					anchors.left: parent.left
					anchors.leftMargin: 8
					anchors.right: parent.right
					anchors.rightMargin: 8
					anchors.bottom: parent.bottom
					anchors.bottomMargin: 10

					clip: true
					spacing: 1
					model: Sys.btDevices
					boundsBehavior: Flickable.StopAtBounds
					cacheBuffer: 400

					delegate: Rectangle {
						id: btRow

						required property var modelData

						width: btList.width
						height: 32
						radius: 9
						color: btHover.hovered ? Theme.chip : "transparent"

						Behavior on color {
							ColorAnimation { duration: Theme.durFast; easing.type: Theme.easeOut }
						}

						Glyph {
							id: btGlyph

							anchors.left: parent.left
							anchors.leftMargin: 6
							anchors.verticalCenter: parent.verticalCenter
							text: Icons.bluetooth
							size: 10
							tint: btRow.modelData.connected ? Theme.accent : Theme.textFaint
						}

						Text {
							anchors.left: btGlyph.right
							anchors.leftMargin: 8
							anchors.right: btState.left
							anchors.rightMargin: 8
							anchors.verticalCenter: parent.verticalCenter

							text: btRow.modelData.name || btRow.modelData.deviceName || btRow.modelData.address
							color: btRow.modelData.connected ? Theme.text : Theme.textDim
							font.family: Theme.fontUi
							font.pixelSize: 11
							elide: Text.ElideRight
							textFormat: Text.PlainText
						}

						Text {
							id: btState

							anchors.right: parent.right
							anchors.rightMargin: 10
							anchors.verticalCenter: parent.verticalCenter

							text: {
								if (btRow.modelData.connected)
									return btRow.modelData.batteryAvailable
										? Math.round(btRow.modelData.battery * 100) + "%"
										: "connected";
								return btRow.modelData.paired ? "paired" : "available";
							}
							color: btRow.modelData.connected ? Theme.accent : Theme.textFaint
							font.family: Theme.fontUi
							font.pixelSize: 10
						}

						HoverHandler { id: btHover }

						MouseArea {
							anchors.fill: parent
							cursorShape: Qt.PointingHandCursor
							onClicked: {
								if (btRow.modelData.connected) btRow.modelData.disconnect();
								else if (btRow.modelData.paired) btRow.modelData.connect();
								else btRow.modelData.pair();
							}
						}
					}

					Text {
						anchors.centerIn: parent
						visible: btList.count === 0
						text: Sys.btOn ? "no devices" : "bluetooth off"
						color: Theme.textFaint
						font.family: Theme.fontUi
						font.pixelSize: 11
					}
				}
			}

			// ── power ───────────────────────────────────────────────────────
			Card {
				id: powerCard

				width: parent.width
				height: 92

				SectionTitle {
					id: powerHeading

					anchors.top: parent.top
					anchors.topMargin: 12
					anchors.left: parent.left
					anchors.leftMargin: 14
					anchors.right: parent.right
					anchors.rightMargin: 14

					label: "Power"
					icon: Icons.bolt
					trailing: Sys.batteryWatts.toFixed(1) + " W"
				}

				BatteryGlyph {
					id: powerBattery

					anchors.left: parent.left
					anchors.leftMargin: 14
					anchors.top: powerHeading.bottom
					anchors.topMargin: 8
					level: Sys.livePct / 100
					charging: Sys.charging
				}

				Text {
					anchors.left: powerBattery.right
					anchors.leftMargin: 10
					anchors.verticalCenter: powerBattery.verticalCenter
					text: Sys.livePct.toFixed(1) + "%"
						+ (Sys.batteryTimeLeft !== "" ? "  ·  " + Sys.batteryTimeLeft : "")
					color: Theme.text
					font.family: Theme.fontUi
					font.pixelSize: 13
					font.weight: Font.Medium
				}

				Text {
					anchors.right: parent.right
					anchors.rightMargin: 14
					anchors.verticalCenter: powerBattery.verticalCenter
					text: Sys.batteryStatus
					color: Sys.charging ? Theme.good : Theme.textFaint
					font.family: Theme.fontUi
					font.pixelSize: 10
				}

				Bar {
					anchors.left: parent.left
					anchors.leftMargin: 14
					anchors.right: parent.right
					anchors.rightMargin: 14
					anchors.bottom: parent.bottom
					anchors.bottomMargin: 16
					interactive: false
					value: Sys.livePct / 100
					thickness: 6
					fillColor: Sys.charging ? Theme.good : (Sys.batteryPct <= 15 ? Theme.bad : Theme.accent)
				}
			}

			// ── machine load ────────────────────────────────────────────────
			Card {
				id: sysCard

				width: parent.width
				height: 172

				SectionTitle {
					id: sysHeading

					anchors.top: parent.top
					anchors.topMargin: 12
					anchors.left: parent.left
					anchors.leftMargin: 14
					anchors.right: parent.right
					anchors.rightMargin: 14

					label: "Machine"
					icon: Icons.microchip
					trailing: Sys.uptimeLabel
				}

				Column {
					id: sysRows

					anchors.top: sysHeading.bottom
					anchors.topMargin: 6
					anchors.left: parent.left
					anchors.leftMargin: 20
					anchors.right: parent.right
					anchors.rightMargin: 20
					spacing: 0

					SystemRow {
						width: parent.width
						icon: Icons.microchip
						label: "CPU"
						value: Sys.cpuPercent.toFixed(0) + "%"
						active: true
						barValue: Sys.cpuPercent / 100
						barColor: Sys.cpuPercent > 80 ? Theme.bad : Theme.accent
					}

					SystemRow {
						width: parent.width
						icon: Icons.fire
						label: "CPU temp"
						value: Sys.cpuTemp > 0 ? Sys.cpuTemp.toFixed(0) + " °C" : "—"
						active: Sys.cpuTemp > 0
						barValue: Sys.cpuTemp > 0 ? Math.min(1, (Sys.cpuTemp - 30) / 70) : -1
						barColor: Sys.cpuTemp > 85 ? Theme.bad : (Sys.cpuTemp > 70 ? Theme.warn : Theme.tertiary)
					}

					SystemRow {
						width: parent.width
						icon: Icons.list
						label: "Memory"
						value: Sys.memUsedGb.toFixed(1) + " / " + Sys.memTotalGb.toFixed(1) + " GB"
						active: true
						barValue: Sys.memPercent / 100
						barColor: Sys.memPercent > 85 ? Theme.bad : Theme.secondary
					}

					SystemRow {
						width: parent.width
						icon: Icons.image
						label: "Disk /"
						value: Sys.diskPercent + "%"
						active: true
						barValue: Sys.diskPercent / 100
						barColor: Sys.diskPercent > 90 ? Theme.bad : Theme.accent
					}
				}

				Text {
					anchors.left: sysRows.left
					anchors.right: sysRows.right
					anchors.bottom: parent.bottom
					anchors.bottomMargin: 10

					text: Sys.cpuCores + " threads  ·  " + Sys.cpuMhz + " MHz  ·  load " + Sys.loadAvg
					color: Theme.textFaint
					font.family: Theme.fontUi
					font.pixelSize: 10
					elide: Text.ElideRight
				}
			}
		}
	}
}
