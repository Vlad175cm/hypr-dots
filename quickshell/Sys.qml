pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire

// Sys.qml — everything the island knows about the machine.
Singleton {
	id: sys

	function fmtDur(seconds: real): string {
		if (!seconds || seconds <= 0 || !isFinite(seconds)) return "";
		const h = Math.floor(seconds / 3600);
		const m = Math.round((seconds % 3600) / 60);
		if (h <= 0) return m + "m";
		return h + "h " + (m < 10 ? "0" + m : m) + "m";
	}

	// ══ applications ═══════════════════════════════════════════════════════
	// The desktop-entry index is built lazily and trickles in as a stream of
	// incremental updates. Touching it once here warms it up at startup, so the
	// launcher does not have to sit through that stream (each update resets its
	// list and re-creates every delegate) the first time it is opened.

	readonly property var appEntries: DesktopEntries.applications.values

	// ══ clipboard ══════════════════════════════════════════════════════════
	// One watcher records every copy through scripts/clipboard.sh. It lives
	// here, tied to the shell: no login hook to keep in sync, no chance of two
	// watchers stepping on each other.

	Process {
		id: clipboardWatch

		command: ["bash", Quickshell.shellPath("scripts/clipboard.sh"), "watch"]

		Component.onCompleted: running = true
	}

	// ══ battery ════════════════════════════════════════════════════════════
	// UPower only refreshes every ~30s, so the raw numbers are re-read from
	// sysfs once a second and the percentage ticks live.

	readonly property var battery: UPower.displayDevice
	readonly property bool hasBattery: battery?.isLaptopBattery ?? false
	readonly property string batteryPath: "/sys/class/power_supply/BAT0"

	property real chargeNow: 0        // µAh
	property real chargeFull: 0       // µAh
	property real chargeFullDesign: 0 // µAh
	property real currentNow: 0       // µA
	property real voltageNow: 0       // µV
	property real voltageDesign: 0    // µV
	property real batteryTemp: 0      // °C
	property int cycleCount: 0
	property string batteryStatus: ""

	FileView {
		id: fChargeNow
		path: sys.batteryPath + "/charge_now"
		preload: true
		onLoaded: sys.chargeNow = parseFloat(fChargeNow.text()) || 0
	}

	FileView {
		id: fCurrentNow
		path: sys.batteryPath + "/current_now"
		preload: true
		onLoaded: sys.currentNow = parseFloat(fCurrentNow.text()) || 0
	}

	FileView {
		id: fVoltageNow
		path: sys.batteryPath + "/voltage_now"
		preload: true
		onLoaded: sys.voltageNow = parseFloat(fVoltageNow.text()) || 0
	}

	FileView {
		id: fStatus
		path: sys.batteryPath + "/status"
		preload: true
		onLoaded: sys.batteryStatus = fStatus.text().trim()
	}

	FileView {
		id: fChargeFull
		path: sys.batteryPath + "/charge_full"
		preload: true
		onLoaded: sys.chargeFull = parseFloat(fChargeFull.text()) || 0
	}

	FileView {
		id: fChargeDesign
		path: sys.batteryPath + "/charge_full_design"
		preload: true
		onLoaded: sys.chargeFullDesign = parseFloat(fChargeDesign.text()) || 0
	}

	FileView {
		id: fVoltageDesign
		path: sys.batteryPath + "/voltage_min_design"
		preload: true
		onLoaded: sys.voltageDesign = parseFloat(fVoltageDesign.text()) || 0
	}

	FileView {
		id: fTemp
		path: sys.batteryPath + "/temp"
		preload: true
		onLoaded: sys.batteryTemp = (parseFloat(fTemp.text()) || 0) / 10
	}

	FileView {
		id: fCycles
		path: sys.batteryPath + "/cycle_count"
		preload: true
		onLoaded: sys.cycleCount = parseInt(fCycles.text()) || 0
	}

	property int batteryTick: 0

	Timer {
		interval: 1000
		running: true
		repeat: true
		onTriggered: {
			fChargeNow.reload();
			fCurrentNow.reload();
			fVoltageNow.reload();
			fStatus.reload();

			// the slow moving values only need a refresh now and then
			sys.batteryTick += 1;
			if (sys.batteryTick % 30 === 0) {
				fChargeFull.reload();
				fChargeDesign.reload();
				fVoltageDesign.reload();
				fTemp.reload();
				fCycles.reload();
			}
		}
	}

	readonly property bool charging: sys.batteryStatus === "Charging"
		|| sys.batteryStatus === "Full"
		|| battery?.state === UPowerDeviceState.Charging
		|| battery?.state === UPowerDeviceState.FullyCharged
	readonly property bool full: sys.batteryStatus === "Full"
		|| battery?.state === UPowerDeviceState.FullyCharged
	readonly property bool onAc: !UPower.onBattery

	// live percentage straight out of the fuel gauge
	readonly property real livePct: {
		if (sys.chargeNow > 0 && sys.chargeFull > 0) return sys.chargeNow / sys.chargeFull * 100;
		const p = sys.battery?.percentage ?? 0;
		return p <= 1 ? p * 100 : p;
	}
	readonly property int batteryPct: Math.round(sys.livePct)

	// the pack is 2S, so Wh are computed against the nominal voltage to match
	// what upower reports
	readonly property real nominalVolts: (sys.voltageDesign > 0 ? sys.voltageDesign : 7600000) / 1000000
	readonly property real batteryVolts: sys.voltageNow / 1000000
	readonly property real batteryAmps: Math.abs(sys.currentNow) / 1000000
	readonly property real batteryWatts: {
		if (sys.batteryAmps > 0.001 && sys.batteryVolts > 0.1) return sys.batteryAmps * sys.batteryVolts;
		return Math.abs(sys.battery?.changeRate ?? 0);
	}
	readonly property real batteryEnergyWh: sys.chargeNow / 1000000 * sys.nominalVolts
	readonly property real batteryFullWh: sys.chargeFull / 1000000 * sys.nominalVolts
	readonly property real batteryCapacityAh: sys.chargeFull / 1000000
	readonly property real batteryDesignAh: sys.chargeFullDesign / 1000000

	readonly property int batteryHealth: {
		if (sys.chargeFull > 0 && sys.chargeFullDesign > 0)
			return Math.round(sys.chargeFull / sys.chargeFullDesign * 100);
		const h = sys.battery?.healthPercentage ?? 0;
		return h <= 0 ? -1 : Math.round(h <= 1 ? h * 100 : h);
	}

	// "1h 32m" style label that rides along with the percentage
	readonly property string batteryTimeLeft: {
		if (!sys.hasBattery) return "";
		if (sys.full) return "full";
		if (sys.charging) {
			const t = sys.fmtDur(sys.battery?.timeToFull ?? 0);
			return t === "" ? "" : t;
		}
		if (sys.battery?.state === UPowerDeviceState.PendingCharge) return "";
		const t = sys.fmtDur(sys.battery?.timeToEmpty ?? 0);
		return t === "" ? "" : t;
	}

	readonly property string batteryDetail: {
		if (!sys.hasBattery) return "no battery";
		if (sys.full) return "fully charged";
		if (sys.charging) {
			const t = sys.fmtDur(sys.battery?.timeToFull ?? 0);
			return t === "" ? "charging" : t + " until full";
		}
		if (sys.battery?.state === UPowerDeviceState.PendingCharge) return "waiting to charge";
		const t = sys.fmtDur(sys.battery?.timeToEmpty ?? 0);
		return t === "" ? "on battery" : t + " remaining";
	}

	// ── session history (memory only, nothing is written to disk) ──────────

	property var batteryHistory: []

	function sampleHistory(): void {
		if (sys.livePct <= 0) return;

		const list = sys.batteryHistory.slice();
		list.push({ t: Date.now(), pct: sys.livePct, watts: sys.batteryWatts, charging: sys.charging });
		while (list.length > 480) list.shift();
		sys.batteryHistory = list;
	}

	Timer {
		interval: 15000
		running: true
		repeat: true
		triggeredOnStart: true
		onTriggered: sys.sampleHistory()
	}

	readonly property var historyRange: {
		const list = sys.batteryHistory;
		if (list.length === 0) return { min: 0, max: 100, minutes: 0 };
		let min = 100;
		let max = 0;
		for (let i = 0; i < list.length; i++) {
			if (list[i].pct < min) min = list[i].pct;
			if (list[i].pct > max) max = list[i].pct;
		}
		const minutes = (list[list.length - 1].t - list[0].t) / 60000;
		return { min: min, max: max, minutes: minutes };
	}

	// ══ wi-fi ══════════════════════════════════════════════════════════════

	readonly property var devices: Networking.devices.values ?? []
	readonly property var wifiDevice: {
		for (let i = 0; i < devices.length; i++)
			if (devices[i].type === DeviceType.Wifi) return devices[i];
		return null;
	}
	readonly property bool wifiHardware: Networking.wifiHardwareEnabled
	readonly property bool wifiOn: Networking.wifiEnabled
	readonly property var wifiNetworks: wifiDevice?.networks?.values ?? []
	readonly property var activeWifi: {
		for (let i = 0; i < wifiNetworks.length; i++)
			if (wifiNetworks[i].connected) return wifiNetworks[i];
		return null;
	}

	// NetworkManager only fills the access point list while the scanner is on.
	// Scanning costs a little power, so it is only turned on while the island
	// is actually showing the list.
	property bool scanWifi: false

	onScanWifiChanged: applyWifiScanner()
	onWifiDeviceChanged: applyWifiScanner()

	function applyWifiScanner(): void {
		if (wifiDevice) wifiDevice.scannerEnabled = scanWifi;
	}
	readonly property string wifiName: activeWifi?.name ?? ""
	// signalStrength is 0..1 on most backends, but some report 0..100.
	readonly property int wifiSignal: {
		const s = activeWifi?.signalStrength ?? 0;
		return Math.round(s <= 1.0 ? s * 100 : s);
	}
	readonly property var wifiAvailable: {
		const list = wifiNetworks.filter(n => n.name !== "").slice();
		list.sort((a, b) => (b.connected - a.connected) || ((b.signalStrength ?? 0) - (a.signalStrength ?? 0)));
		return list;
	}
	readonly property string connectivityLabel: {
		const c = Networking.connectivity;
		if (c === NetworkConnectivity.Full) return "reachable";
		if (c === NetworkConnectivity.Limited) return "limited";
		if (c === NetworkConnectivity.Portal) return "captive portal";
		if (c === NetworkConnectivity.None) return "no internet";
		return "unknown";
	}

	readonly property string wifiDetail: {
		if (!wifiHardware) return "hardware switch off";
		if (!wifiOn) return "off";
		return wifiName !== "" ? wifiName : "not connected";
	}

	function toggleWifi(): void {
		Networking.wifiEnabled = !Networking.wifiEnabled;
	}

	// ══ bluetooth ══════════════════════════════════════════════════════════

	readonly property var btAdapter: Bluetooth.defaultAdapter
	readonly property bool btOn: btAdapter?.enabled ?? false
	readonly property var btDevices: btAdapter?.devices?.values ?? []
	readonly property var btConnected: btDevices.filter(d => d.connected)
	readonly property string btName: btConnected.length > 0 ? (btConnected[0].name || btConnected[0].deviceName) : ""
	readonly property int btBattery: {
		if (btConnected.length === 0) return -1;
		const d = btConnected[0];
		return d.batteryAvailable ? Math.round(d.battery * 100) : -1;
	}
	readonly property string btDetail: btOn ? (btName !== "" ? btName : "on, nothing connected") : "off"

	function toggleBt(): void {
		if (btAdapter) btAdapter.enabled = !btAdapter.enabled;
	}

	// ══ sound ══════════════════════════════════════════════════════════════

	PwObjectTracker {
		objects: [Pipewire.defaultAudioSink]
	}

	readonly property var sink: Pipewire.defaultAudioSink

	// Pipewire wrappers are created lazily and the very first read can land
	// before the sink's values have arrived, which leaves the volume stuck at
	// zero for the rest of the session. wpctl is used as a safety net: the
	// pipewire value wins whenever it is real, and any volume change pushes it
	// instantly (that is also what drives the volume OSD).
	property var wpctl: ({ volume: -1, muted: false })

	Process {
		id: wpctlRead

		command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]

		stdout: StdioCollector {
			onStreamFinished: sys.parseWpctl(text)
		}
	}

	Timer {
		interval: 5000
		running: true
		repeat: true
		triggeredOnStart: true
		onTriggered: if (!wpctlRead.running) wpctlRead.running = true
	}

	function parseWpctl(raw: string): void {
		const match = /Volume:\s*([0-9.]+)/.exec(raw ?? "");
		sys.wpctl = {
			volume: match ? parseFloat(match[1]) : -1,
			muted: (raw ?? "").indexOf("[MUTED]") >= 0
		};
	}

	property real lastGoodVolume: 0

	readonly property real volume: {
		const live = sys.sink?.audio?.volume ?? 0;
		if (live > 0.0001) return live;

		// Pipewire is authoritative as soon as it has ever handed us a real
		// value: then a zero here is a genuine zero (you turned the sound off),
		// not a value that has not arrived yet. wpctl is only a fallback for a
		// sink whose values never came through at all.
		if (sys.lastGoodVolume > 0.0001) return live;
		return sys.wpctl.volume >= 0 ? sys.wpctl.volume : live;
	}

	readonly property bool muted: {
		if (sys.sink?.audio) return sys.sink.audio.muted;
		return sys.wpctl.muted;
	}

	function setVolume(v: real): void {
		if (!sink?.audio) return;
		sink.audio.volume = clamp01(v);
		if (sink.audio.volume > 0 && v > 0 && sink.audio.muted) sink.audio.muted = false;
	}

	function clamp01(v: real): real {
		return v < 0 ? 0 : (v > 1 ? 1 : v);
	}

	function toggleMute(): void {
		if (sink?.audio) sink.audio.muted = !sink.audio.muted;
	}

	// ── following the volume ───────────────────────────────────────────────
	// Pipewire objects only exist once the service has handed them over, so the
	// connection is created lazily.

	property real previousVolume: 0
	property bool volumeSettled: false

	signal volumeAdjusted()

	Loader {
		active: sys.sink !== null && sys.sink !== undefined
			&& sys.sink.audio !== null && sys.sink.audio !== undefined

		sourceComponent: Connections {
			target: sys.sink?.audio

			function onVolumesChanged() { sys.onVolumeChanged(); }
			function onMutedChanged() { sys.volumeAdjusted(); }
		}
	}

	function onVolumeChanged(): void {
		const audio = sys.sink?.audio;
		if (!audio) return;

		const volume = audio.volume;
		const first = !sys.volumeSettled;

		// turning the volume up on a muted sink unmutes it: every desktop does
		// this, and without it the OSD would keep showing a muted sink
		if (sys.volumeSettled && audio.muted && volume > sys.previousVolume + 0.001)
			audio.muted = false;

		if (volume > 0.0001) sys.lastGoodVolume = volume;

		sys.previousVolume = volume;
		sys.volumeSettled = true;

		// the first read just establishes the value — no OSD for it
		if (!first) sys.volumeAdjusted();
	}

	// the pump for the wpctl safety net, used when the OSD pops up
	function refreshVolume(): void {
		if (!wpctlRead.running) wpctlRead.running = true;
	}

	// Set by the island: true while a panel is actually on screen. Keeps the
	// heavy panels loaded (so opening them costs no frame) without letting
	// cava and friends run in the background.
	property bool panelOpen: false

	// Real audio peaks, only sampled while something is actually playing.
	readonly property bool watchAudio: sys.playing

	PwNodePeakMonitor {
		id: peakMonitor
		node: Pipewire.defaultAudioSink
		enabled: sys.watchAudio
	}

	readonly property real audioPeak: peakMonitor.peak
	readonly property var audioPeaks: peakMonitor.peaks

	// ══ brightness ═════════════════════════════════════════════════════════
	// The backlight is polled straight out of sysfs. Reading a four byte file
	// five times a second costs nothing, and it means the OSD reacts to *any*
	// brightness change — the F5/F6 keys, the slider, some other program —
	// without spawning a process. Spawning `qs ipc call` per key repeat (and a
	// `brightnessctl` per pixel while dragging) was what made changing the
	// brightness stutter.

	property string backlightDir: ""
	property int backlightValue: 0
	property int backlightMax: 0
	property bool brightnessKnown: sys.backlightMax > 0
	property bool backlightSettled: false
	readonly property real brightness: sys.backlightMax > 0
		? sys.backlightValue * 100 / sys.backlightMax
		: 0

	// emitted when the backlight moves (any source), the island shows the OSD
	signal backlightAdjusted()

	// find the device once
	Process {
		id: brightnessProbe

		command: ["brightnessctl", "-m"]

		stdout: StdioCollector {
			onStreamFinished: {
				const parts = text.trim().split(",");
				if (parts.length >= 5 && parts[0] !== "") {
					sys.backlightDir = "/sys/class/backlight/" + parts[0];
					sys.backlightMax = parseInt(parts[4]) || 0;
				}
			}
		}
	}

	FileView {
		id: backlightRead

		path: sys.backlightDir === "" ? "" : sys.backlightDir + "/brightness"
		preload: true

		onLoaded: {
			const value = parseInt(backlightRead.text());
			if (isNaN(value)) return;

			const changed = value !== sys.backlightValue;
			const first = !sys.backlightSettled;

			sys.backlightValue = value;
			sys.backlightSettled = true;

			// the first read just establishes the value — no OSD for it
			if (changed && !first) sys.backlightAdjusted();
		}
	}

	Timer {
		// every frame worth of a four byte file read — free, and it means no
		// key repeat step is ever missed by the brightness OSD
		interval: 16
		running: sys.backlightDir !== ""
		repeat: true
		onTriggered: backlightRead.reload()
	}

	// the slider asks for a value many times a second; the real call is rate
	// limited so dragging does not fork a process per pixel
	property int pendingBrightness: -1

	Timer {
		id: brightnessApply

		interval: 90
		repeat: true
		onTriggered: {
			if (sys.pendingBrightness < 0) {
				brightnessApply.stop();
				return;
			}
			Quickshell.execDetached(["brightnessctl", "-q", "set", sys.pendingBrightness + "%"]);
			sys.pendingBrightness = -1;
		}
	}

	function setBrightness(percent: real): void {
		const value = Math.max(1, Math.min(100, Math.round(percent)));
		sys.pendingBrightness = value;
		if (!brightnessApply.running) brightnessApply.start();
	}

	function toggleBrightnessStep(up: bool): void {
		sys.setBrightness(sys.brightness + (up ? 5 : -5));
	}

	// ══ keyboard layout ════════════════════════════════════════════════════

	property string layoutName: ""
	property bool capsLock: false
	property bool numLock: false

	readonly property string layout: {
		const name = sys.layoutName.toLowerCase();
		if (name.startsWith("english") || name.startsWith("us")) return "EN";
		if (name.startsWith("russian") || name.startsWith("ru")) return "RU";
		if (name === "") return "";
		return sys.layoutName.substring(0, 2).toUpperCase();
	}

	Process {
		id: devicesRead

		command: ["hyprctl", "-j", "devices"]

		stdout: StdioCollector {
			onStreamFinished: {
				try {
					const data = JSON.parse(text);
					const keyboards = data.keyboards ?? [];
					const kb = keyboards.find(k => !/power-button|sleep-button|video-bus/.test(k.name ?? ""));
					if (kb) {
						if (kb.active_keymap) sys.layoutName = kb.active_keymap;
						sys.capsLock = kb.capsLock ?? false;
						sys.numLock = kb.numLock ?? false;
					}
				} catch (e) {
					console.warn("[sys] could not parse hyprctl devices:", e);
				}
			}
		}
	}

	Connections {
		target: Hyprland

		function onRawEvent(event) {
			if (event.name === "activelayout") {
				const comma = event.data.indexOf(",");
				if (comma >= 0) sys.layoutName = event.data.substring(comma + 1);
			} else if (event.name === "openwindow") {
				// data is "address,workspace,class,title"; the address arrives
				// without the 0x prefix that the focus dispatcher expects
				const raw = (event.data ?? "").split(",")[0];
				const address = raw === "" ? "" : (raw.indexOf("0x") === 0 ? raw : "0x" + raw);
				sys.windowOpened(address);
			}
		}
	}

	// ── window focus ───────────────────────────────────────────────────────
	// The island takes the keyboard exclusively while a panel is open (that is
	// what makes Esc and the launcher's search field work). When it closes the
	// keyboard has to be handed back, otherwise typing goes nowhere and newly
	// opened windows never get focus. Hyprland's lua api has a focus dispatcher
	// for exactly this: hl.dsp.focus({ window = "address:0x…" }).

	signal windowOpened(address: string)

	readonly property string activeWindowAddress: Hyprland.activeToplevel?.address ?? ""

	function windowExists(address: string): bool {
		const list = Hyprland.toplevels?.values ?? [];
		for (let i = 0; i < list.length; i++)
			if (list[i].address === address) return true;
		return false;
	}

	function focusWindow(address: string): void {
		if (address === "") return;
		Quickshell.execDetached(["hyprctl", "dispatch",
			'hl.dsp.focus({window="address:' + address + '"})']);
	}

	// the window we remembered may have been closed while the panel was up
	function focusWindowOrLast(address: string): void {
		if (address !== "" && sys.windowExists(address)) sys.focusWindow(address);
		else sys.focusLastWindow();
	}

	function focusLastWindow(): void {
		Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({last=true})"]);
	}

	function refreshLayout(): void {
		if (!devicesRead.running) devicesRead.running = true;
	}

	// ══ workspaces ═════════════════════════════════════════════════════════
	// The island only shows the current workspace number, so clicking it is
	// what moves between them: it steps through 1…9 and wraps back to 1. Empty
	// workspaces are fine — Hyprland just creates them on the way.

	readonly property int workspaceId: Hyprland.focusedWorkspace?.id ?? 0

	function focusNextWorkspace(): void {
		const here = sys.workspaceId;
		const next = (here >= 1 && here < 9) ? here + 1 : 1;

		// hyprctl wraps its argument as lua here, so the dispatcher has to be
		// the hl.dsp form (legacy dispatcher strings do not work)
		Quickshell.execDetached(["hyprctl", "dispatch",
			'hl.dsp.focus({workspace="' + next + '"})']);
	}

	// ══ system stats (cpu, memory, temperature, disks) ═════════════════════

	property var stats: ({})
	property bool statsReady: false

	Process {
		id: statsRead

		command: ["bash", Quickshell.shellPath("scripts/stats.sh")]

		stdout: StdioCollector {
			onStreamFinished: sys.parseStats(text)
		}
	}

	Timer {
		interval: 2500
		running: true
		repeat: true
		triggeredOnStart: true
		onTriggered: sys.refreshStats()
	}

	function refreshStats(): void {
		if (!statsRead.running) statsRead.running = true;
	}

	function parseStats(raw: string): void {
		const out = {};
		const parts = (raw ?? "").trim().split(/\s+/);

		for (let i = 0; i < parts.length; i++) {
			const eq = parts[i].indexOf("=");
			if (eq < 0) continue;
			out[parts[i].substring(0, eq)] = parts[i].substring(eq + 1);
		}

		sys.stats = out;
		sys.statsReady = true;
	}

	readonly property real cpuPercent: (parseFloat(sys.stats.cpu ?? "0") || 0) / 10
	readonly property real memPercent: (parseFloat(sys.stats.mem ?? "0") || 0) / 10
	readonly property real memUsedGb: (parseFloat(sys.stats.memused ?? "0") || 0) / 1048576
	readonly property real memTotalGb: (parseFloat(sys.stats.memtotal ?? "0") || 0) / 1048576
	readonly property real cpuTemp: (parseFloat(sys.stats.temp ?? "0") || 0) / 1000
	readonly property int diskPercent: parseInt(sys.stats.disk ?? "0") || 0
	readonly property int homeDiskPercent: parseInt(sys.stats.homedisk ?? "0") || 0
	readonly property real uptimeSeconds: parseFloat(sys.stats.uptime ?? "0") || 0
	readonly property string loadAvg: (sys.stats.load ?? "").split(",").join("  ")
	readonly property string ipAddress: sys.stats.ip ?? ""
	readonly property int cpuMhz: Math.round((parseFloat(sys.stats.freq ?? "0") || 0) / 1000)
	readonly property int cpuCores: parseInt(sys.stats.cores ?? "0") || 0
	readonly property string uptimeLabel: sys.fmtUptime(sys.uptimeSeconds)

	function fmtUptime(seconds: real): string {
		if (!seconds || seconds <= 0) return "";
		const days = Math.floor(seconds / 86400);
		const hours = Math.floor((seconds % 86400) / 3600);
		const minutes = Math.floor((seconds % 3600) / 60);
		if (days > 0) return days + "d " + hours + "h";
		if (hours > 0) return hours + "h " + minutes + "m";
		return minutes + "m";
	}

	// ══ media (mpris) ══════════════════════════════════════════════════════

	readonly property var players: Mpris.players.values ?? []
	readonly property var player: {
		for (let i = 0; i < players.length; i++)
			if (players[i].isPlaying) return players[i];
		return players.length > 0 ? players[0] : null;
	}
	readonly property bool playing: player?.isPlaying ?? false
	readonly property string trackTitle: player?.trackTitle ?? ""
	readonly property string trackArtist: player?.trackArtist ?? ""
	readonly property string trackAlbum: player?.trackAlbum ?? ""
	readonly property string trackArt: player?.trackArtUrl ?? ""
	readonly property int trackLength: Math.round(player?.length ?? 0)

	// ══ weather ════════════════════════════════════════════════════════════
	// wttr.in's full json is unusable from some networks (the response is cut
	// off mid body), so the tiny one line format is used instead: it answers in
	// ~0.2 s and carries everything the card needs.
	//
	// Pinned location. Left empty the place is guessed from the ip address, in
	// which case wttr.in answers with coordinates instead of a name and the
	// place label is hidden.

	property string weatherCity: "Переславль-Залесский"
	property var weather: null
	property bool weatherFailed: false

	readonly property string weatherFormat: "%l|%C|%t|%f|%h|%w|%p|%P|%u|%S|%s|%m"
	readonly property string weatherUrl: sys.weatherCity === ""
		? "https://wttr.in/?format=" + sys.weatherFormat
		: "https://wttr.in/" + sys.weatherCity + "?format=" + sys.weatherFormat

	Process {
		id: weatherRead

		command: ["curl", "-sS", "--compressed", "--max-time", "12", sys.weatherUrl]

		stdout: StdioCollector {
			onStreamFinished: sys.parseWeather(text)
		}
	}

	Timer {
		interval: 20 * 60 * 1000
		running: true
		repeat: true
		triggeredOnStart: true
		onTriggered: sys.refreshWeather()
	}

	// a failed fetch is retried a minute later instead of waiting 20 minutes
	Timer {
		id: weatherRetry
		interval: 60000
		onTriggered: sys.refreshWeather()
	}

	function refreshWeather(): void {
		if (!weatherRead.running) weatherRead.running = true;
	}

	function parseWeather(raw: string): void {
		const line = (raw ?? "").trim();

		if (line === "" || line.indexOf("|") < 0) {
			sys.weatherFailed = true;
			weatherRetry.restart();
			return;
		}

		const f = line.split("|");
		if (f.length < 12) {
			sys.weatherFailed = true;
			weatherRetry.restart();
			return;
		}

		sys.weather = {
			place: /^[0-9., -]+$/.test(f[0]) ? "" : f[0],
			desc: f[1],
			temp: parseInt(f[2]),
			feels: parseInt(f[3]),
			humidity: parseInt(f[4]),
			wind: f[5],
			precip: f[6],
			pressure: f[7],
			uv: parseInt(f[8]),
			sunrise: f[9].trim(),
			sunset: f[10].trim(),
			moon: f[11]
		};

		sys.weatherFailed = false;
	}

	// ══ session ════════════════════════════════════════════════════════════

	function lock(): void {
		Quickshell.execDetached(["hyprlock"]);
	}

	function suspend(): void {
		Quickshell.execDetached(["systemctl", "suspend"]);
	}

	function powerOff(): void {
		Quickshell.execDetached(["systemctl", "poweroff"]);
	}

	function reboot(): void {
		Quickshell.execDetached(["systemctl", "reboot"]);
	}

	function logout(): void {
		Quickshell.execDetached(["hyprctl", "dispatch", "exit"]);
	}

	// ══ startup ════════════════════════════════════════════════════════════

	Component.onCompleted: {
		refreshLayout();
		// ask brightnessctl once for the backlight device, then sysfs takes over
		if (!brightnessProbe.running) brightnessProbe.running = true;
	}
}
