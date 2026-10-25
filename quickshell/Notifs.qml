pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Notifs.qml — the notification daemon and its history.
//
// Quickshell takes over org.freedesktop.Notifications, so mako has to be gone
// (it is removed from the hyprland autostart by this setup).
Singleton {
	id: notifs

	property bool dnd: false
	property var items: []
	property var popup: null
	property int unread: 0

	readonly property int count: items.length

	NotificationServer {
		id: server

		keepOnReload: true
		persistenceSupported: true
		bodySupported: true
		bodyMarkupSupported: true
		bodyHyperlinksSupported: true
		imageSupported: true
		actionsSupported: true
		actionIconsSupported: true
		inlineReplySupported: true

		onNotification: notification => notifs.receive(notification)
	}

	function receive(notification): void {
		// tracked notifications stay alive so we can keep them in history
		notification.tracked = true;

		const list = notifs.items.slice();
		list.unshift(notification);
		while (list.length > 80) {
			const dropped = list.pop();
			dropped.tracked = false;
		}

		notifs.items = list;
		notifs.unread += 1;

		if (!notifs.dnd && !notification.transient) {
			notifs.popup = notification;
			popupTimer.restart();
		}
	}

	Timer {
		id: popupTimer
		interval: 5400
		onTriggered: notifs.popup = null
	}

	function dismiss(notification): void {
		if (!notification) return;

		notifs.items = notifs.items.filter(n => n !== notification);
		if (notifs.popup === notification) notifs.popup = null;

		notification.dismiss();
		notification.tracked = false;
	}

	function clear(): void {
		const list = notifs.items;
		notifs.items = [];
		notifs.unread = 0;
		notifs.popup = null;

		for (let i = 0; i < list.length; i++) {
			list[i].dismiss();
			list[i].tracked = false;
		}
	}

	function markRead(): void {
		notifs.unread = 0;
	}

	function toggleDnd(): void {
		notifs.dnd = !notifs.dnd;
	}

	// ── local notices ─────────────────────────────────────────────────────
	// Things the island reports about itself (battery, charger, wallpaper, …).
	// They ride the same history and toast as real notifications.

	function notify(appName: string, summary: string, body: string, accent: var): void {
		const note = {
			appName: appName,
			summary: summary,
			body: body,
			urgency: NotificationUrgency.Normal,
			actions: [],
			accent: accent === undefined ? "" : accent,
			dismiss: function (): void {}
		};

		const list = notifs.items.slice();
		list.unshift(note);
		while (list.length > 80) list.pop();

		notifs.items = list;
		notifs.unread += 1;
		notifs.popup = note;
		popupTimer.restart();
	}

	// ── system notices ────────────────────────────────────────────────────
	// `armed` flips a few seconds after start, so the first reading of every
	// value does not fire a notification.

	property bool armed: false
	property int lastPct: 0
	property bool toldFull: false

	function announce(appName: string, summary: string, body: string, accent: var): void {
		if (notifs.armed) notifs.notify(appName, summary, body, accent);
	}

	Timer {
		interval: 3000
		running: true
		onTriggered: {
			notifs.lastPct = Sys.batteryPct;
			notifs.armed = true;
		}
	}

	Connections {
		target: Sys

		function onChargingChanged() {
			const left = Sys.batteryTimeLeft !== "" ? "  ·  " + Sys.batteryTimeLeft : "";
			if (Sys.charging)
				notifs.announce("Power", "Charger connected", Sys.batteryPct + "%" + left + " to full");
			else
				notifs.announce("Power", "Charger disconnected", Sys.batteryPct + "%" + left + " left");
		}

		function onBatteryPctChanged() {
			if (!notifs.armed) { notifs.lastPct = Sys.batteryPct; return; }

			const pct = Sys.batteryPct;
			const left = Sys.batteryTimeLeft !== "" ? "  ·  " + Sys.batteryTimeLeft + " left" : "";

			if (Sys.charging && pct >= 99 && !notifs.toldFull) {
				notifs.toldFull = true;
				notifs.notify("Power", "Battery full", "Fully charged — you can unplug");
			}
			if (!Sys.charging && pct < 95) notifs.toldFull = false;

			const steps = [20, 10, 5];
			for (let i = 0; i < steps.length; i++)
				if (notifs.lastPct > steps[i] && pct <= steps[i])
					notifs.notify("Power", "Battery low", pct + "%" + left);

			notifs.lastPct = pct;
		}

		function onWifiNameChanged() {
			if (Sys.wifiName !== "") notifs.announce("Wi-Fi", "Connected", Sys.wifiName);
			else notifs.announce("Wi-Fi", "Disconnected", "");
		}

		function onBtNameChanged() {
			if (Sys.btName !== "") notifs.announce("Bluetooth", "Connected", Sys.btName);
			else notifs.announce("Bluetooth", "Disconnected", "");
		}

		function onTrackTitleChanged() {
			if (Sys.playing && Sys.trackTitle !== "")
				notifs.announce(Sys.trackArtist !== "" ? Sys.trackArtist : "Now playing", Sys.trackTitle, "");
		}
	}

	onDndChanged: notifs.announce("Island", notifs.dnd ? "Silent mode on" : "Silent mode off", "")

	// wallpaper: wait a beat so the freshly written palette has landed
	Connections {
		target: Walls
		function onCurrentChanged() { if (Walls.current !== "") wallpaperNotice.restart(); }
	}

	Timer {
		id: wallpaperNotice
		interval: 450
		onTriggered: {
			const name = Walls.current.split("/").pop().replace(/\.[^.]+$/, "");
			notifs.notify("Wallpaper", name, "Accent " + Theme.accent, Theme.accent);
		}
	}
}
