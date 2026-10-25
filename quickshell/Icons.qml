pragma Singleton

import QtQuick
import Quickshell

// Icons.qml — every glyph used by the island, in one place.
// These are Nerd Font (Font Awesome) codepoints, rendered with the
// "JetBrainsMono Nerd Font" family. Swap the codepoint here if you want a
// different look, everything else picks it up automatically.
Singleton {
	// radios / power
	readonly property string wifi: "\uf1eb"
	readonly property string bluetooth: "\uf293"
	readonly property string signal: "\uf012"
	readonly property string plug: "\uf1e6"
	readonly property string batteryFull: "\uf240"
	readonly property string batteryThree: "\uf241"
	readonly property string batteryHalf: "\uf242"
	readonly property string batteryQuarter: "\uf243"
	readonly property string batteryEmpty: "\uf244"
	readonly property string bolt: "\uf0e7"
	readonly property string microchip: "\uf2db"
	readonly property string power: "\uf011"

	// audio / media
	readonly property string music: "\uf001"
	readonly property string headphones: "\uf025"
	readonly property string volumeHigh: "\uf028"
	readonly property string volumeLow: "\uf027"
	readonly property string volumeOff: "\uf026"
	readonly property string play: "\uf04b"
	readonly property string pause: "\uf04c"
	readonly property string stop: "\uf04d"
	readonly property string next: "\uf051"
	readonly property string prev: "\uf048"

	// ui
	readonly property string search: "\uf002"
	readonly property string close: "\uf00d"
	readonly property string check: "\uf00c"
	readonly property string chevronLeft: "\uf104"
	readonly property string chevronRight: "\uf105"
	readonly property string angleUp: "\uf106"
	readonly property string angleDown: "\uf107"
	readonly property string refresh: "\uf021"
	readonly property string sliders: "\uf1de"
	readonly property string list: "\uf0ca"
	readonly property string keyboard: "\uf11c"
	readonly property string image: "\uf03e"
	readonly property string palette: "\uf53f"
	readonly property string bell: "\uf0f3"
	readonly property string bellOff: "\uf1f6"
	readonly property string moon: "\uf186"
	readonly property string sun: "\uf185"
	readonly property string lock: "\uf023"
	readonly property string camera: "\uf030"
	readonly property string expand: "\uf065"
	readonly property string compass: "\uf14e"
	readonly property string dot: "\uf111"
	readonly property string dotHollow: "\uf10c"
	readonly property string copy: "\uf0c5"

	// weather
	readonly property string cloud: "\uf0c2"
	readonly property string rain: "\uf043"
	readonly property string snow: "\uf2dc"
	readonly property string umbrella: "\uf0e9"
	readonly property string wind: "\uf0b2"
	readonly property string thermometer: "\uf2c7"
	readonly property string fire: "\uf06d"
	readonly property string hardDisk: "\uf0a0"

	// status
	readonly property string info: "\uf05a"
	readonly property string warn: "\uf071"
	readonly property string offline: "\uf127"
}
