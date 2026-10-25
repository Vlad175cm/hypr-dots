import QtQuick

// Bar.qml — a slim progress bar that can also be dragged.
//
// `value` is always the external source of truth (volume, brightness, track
// position). Dragging never assigns to it directly: it emits moved() and the
// owner pushes the change back into the system, which re-updates `value`.
Item {
	id: bar

	property real value: 0
	property color fillColor: Theme.accent
	property color trackColor: Theme.track
	property real thickness: 6
	property bool interactive: true
	property real hitSlop: 9
	// how long the fill takes to catch up with `value`. Sliders can be slow and
	// silky; an OSD that follows fast key repeats wants it short.
	property int animDuration: Theme.dur

	signal moved(real value)

	implicitHeight: bar.thickness
	readonly property real shownValue: drag.active ? drag.value : Math.max(0, Math.min(1, bar.value))

	// The fill follows an animated *number*, never the rectangle's width. The
	// bar itself is resized while the island morphs, and a width animation
	// there lags behind the track and then snaps — a visible twitch every time
	// the volume/brightness strip appears. Animating the number keeps the
	// proportion exact while the bar grows, and still eases a value change.
	property real animatedValue: bar.shownValue

	Behavior on animatedValue {
		enabled: !drag.active
		NumberAnimation { duration: bar.animDuration; easing.type: Theme.easeSoft }
	}

	function valueAt(x: real): real {
		return Math.max(0, Math.min(1, x / Math.max(1, bar.width)));
	}

	Rectangle {
		id: track

		width: parent.width
		height: bar.thickness
		radius: bar.thickness / 2
		color: bar.trackColor
	}

	Rectangle {
		id: fillRect

		width: bar.animatedValue * track.width
		height: track.height
		radius: track.radius
		color: bar.fillColor
	}

	MouseArea {
		id: drag

		property real value: 0

		anchors.fill: parent
		anchors.topMargin: -bar.hitSlop
		anchors.bottomMargin: -bar.hitSlop
		enabled: bar.interactive
		preventStealing: true
		cursorShape: bar.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor

		onPressed: mouse => {
			drag.value = bar.valueAt(mouse.x);
			bar.moved(drag.value);
		}

		onPositionChanged: mouse => {
			if (!drag.active) return;
			drag.value = bar.valueAt(mouse.x);
			bar.moved(drag.value);
		}

		onWheel: wheel => {
			if (!bar.interactive) return;
			const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
			drag.value = Math.max(0, Math.min(1, bar.shownValue + step));
			bar.moved(drag.value);
		}
	}
}
