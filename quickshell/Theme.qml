pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Theme.qml — colours, geometry, typography and motion.
//
// Colours are read from theme/colors.json, which matugen rewrites every time
// the wallpaper changes, so the island always matches the current wallpaper.
// Everything else is a constant you can tweak in the "geometry" / "motion"
// sections below.
Singleton {
	id: theme

	// ══ palette (matugen) ══════════════════════════════════════════════════

	property var palette: ({})

	FileView {
		id: colorsFile

		path: Quickshell.shellPath("theme/colors.json")
		preload: true
		watchChanges: true

		onLoaded: theme.loadColors()
		onFileChanged: reload()
	}

	function loadColors(): void {
		try {
			const parsed = JSON.parse(colorsFile.text());
			if (parsed && typeof parsed === "object") theme.palette = parsed;
		} catch (e) {
			console.warn("[theme] theme/colors.json is not valid json:", e);
		}
	}

	function col(key: string, fallback: color): color {
		const value = theme.palette[key];
		return value === undefined || value === "" ? fallback : value;
	}

	// ── raw palette ────────────────────────────────────────────────────────

	readonly property color primary: col("primary", "#bac3ff")
	readonly property color onPrimary: col("on_primary", "#202c6b")
	readonly property color primaryContainer: col("primary_container", "#38437a")
	readonly property color onPrimaryContainer: col("on_primary_container", "#dee1ff")
	readonly property color secondary: col("secondary", "#c4c6dd")
	readonly property color tertiary: col("tertiary", "#e5bad8")
	readonly property color error: col("error", "#ffb4ab")
	readonly property color surface: col("surface", "#121318")
	readonly property color surfaceLow: col("surface_container_low", "#1a1b21")
	readonly property color surfaceContainer: col("surface_container", "#1e1f25")
	readonly property color surfaceHigh: col("surface_container_high", "#292a2f")
	readonly property color surfaceHighest: col("surface_container_highest", "#34343a")
	readonly property color onSurface: col("on_surface", "#e3e1e9")
	readonly property color onSurfaceVariant: col("on_surface_variant", "#c6c5d0")
	readonly property color outline: col("outline", "#90909a")
	readonly property color outlineVariant: col("outline_variant", "#46464f")

	// ── semantic ───────────────────────────────────────────────────────────

	// The island itself: pure black, like a real notch. No tint, no sheen, no
	// edge — the whole thing is one flat black shape.
	readonly property color island: "#000000"
	readonly property color islandEdge: alpha(outline, 0.16)
	readonly property color islandSheen: alpha(onSurface, 0.05)

	// Cards and chips on top of the island: the same accent, only as a faint
	// wash. No separate "surface" colours anywhere — everything is the one
	// wallpaper colour.
	readonly property color card: "transparent"
	readonly property color cardHover: alpha(accent, 0.14)
	readonly property color chip: alpha(accent, 0.12)
	readonly property color chipHover: alpha(accent, 0.2)

	// Everything on the island is one colour — the wallpaper's accent — and the
	// hierarchy comes purely from opacity: values read at a glance, labels are a
	// little softer, the tiny uppercase section headings are softest.
	readonly property color text: accent
	readonly property color textDim: alpha(accent, 0.8)
	readonly property color textFaint: alpha(accent, 0.58)

	// the clock follows the same single accent colour as everything else
	readonly property color clock: accent

	readonly property color accent: primary
	readonly property color accentSoft: alpha(primary, 0.28)
	readonly property color accentGhost: alpha(primary, 0.13)
	readonly property color track: alpha(accent, 0.18)
	readonly property color hairline: alpha(accent, 0.18)

	readonly property color good: "#a6e3a1"
	readonly property color warn: "#f9e2af"
	readonly property color bad: error

	// ── geometry ───────────────────────────────────────────────────────────

	readonly property int pillW: 224
	readonly property int pillH: 30
	// gap between the top of the screen and the floating pill
	readonly property int edgeMargin: 6
	readonly property int radiusCard: 18
	readonly property int radiusPanel: 26
	// collapsed pill is a capsule
	readonly property int radiusPill: pillH / 2
	readonly property int pad: 12

	// Space reserved at the top of the screen so windows never slide under
	// the floating pill. Set to 0 for a pill you can tuck under windows.
	readonly property int reserveTop: pillH + edgeMargin

	// Padding between the island edge and a panel's content.
	readonly property int panelPad: 12

	// Size of each expanded panel's content, excluding the header and padding.
	readonly property var panelSizes: ({
		dashboard: { w: 720, h: 424 },
		launcher: { w: 596, h: 432 },
		battery: { w: 620, h: 452 },
		info: { w: 780, h: 496 },
		notifications: { w: 428, h: 406 },
		wallpapers: { w: 1200, h: 260 },
		keys: { w: 624, h: 540 },
		clipboard: { w: 596, h: 432 }
	})

	// Collapsed pill and the two transient strips (notification banner, osd).
	readonly property int toastW: 384
	readonly property int toastH: 96
	readonly property int osdW: 272
	readonly property int osdH: 44

	// ── typography ─────────────────────────────────────────────────────────

	readonly property string fontUi: "Inter"
	readonly property string fontIcon: "JetBrainsMono Nerd Font"

	// ── motion ─────────────────────────────────────────────────────────────
	// Everything is deliberately slow and soft: the island should feel like
	// liquid metal, not like a menu popping open.

	// Keep color and hover feedback under the requested 100 ms; geometry keeps
	// its slower timing so the island still feels smooth.
	readonly property int dur: 450
	readonly property int durReveal: 450
	readonly property int durFast: 80

	readonly property int easeOut: Easing.OutCubic
	readonly property int easeSoft: Easing.OutQuart
	readonly property int easeBoth: Easing.InOutQuart

	// smooth deceleration, no bounce
	readonly property int easeMorph: Easing.OutQuint

	// the easing for things that keep moving for a while (wallpaper crossfade)
	readonly property int easeDrift: Easing.InOutSine

	// ── shapes ─────────────────────────────────────────────────────────────

	// how far the panel content slides up while appearing
	readonly property real revealSlide: 12
	readonly property real revealScale: 0.978

	// ── helpers ────────────────────────────────────────────────────────────

	function alpha(c: color, a: real): color {
		return Qt.rgba(c.r, c.g, c.b, a);
	}

	function mix(a: color, b: color, t: real): color {
		return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t);
	}

	function clamp(v: real, lo: real, hi: real): real {
		return v < lo ? lo : (v > hi ? hi : v);
	}
}
