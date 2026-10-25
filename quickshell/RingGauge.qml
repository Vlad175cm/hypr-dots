import QtQuick
import QtQuick.Shapes

// RingGauge.qml — an animated circular gauge.
// The sweep is animated separately from `value` so the ring glides instead of
// jumping when a new sample arrives.
Item {
	id: root

	property real value: 0
	property color ringColor: Theme.accent
	property color ringTrack: Theme.track
	property real thickness: 9

	implicitWidth: 118
	implicitHeight: 118

	property real shown: root.value

	onValueChanged: root.shown = root.value
	Component.onCompleted: root.shown = root.value

	Behavior on shown {
		NumberAnimation { duration: Theme.dur; easing.type: Theme.easeSoft }
	}

	readonly property real radius: width / 2 - root.thickness / 2

	Shape {
		anchors.fill: parent
		layer.enabled: true
		layer.samples: 4

		ShapePath {
			strokeColor: root.ringTrack
			strokeWidth: root.thickness
			fillColor: "transparent"
			capStyle: ShapePath.RoundCap

			PathAngleArc {
				centerX: root.width / 2
				centerY: root.height / 2
				radiusX: root.radius
				radiusY: root.radius
				startAngle: -90
				sweepAngle: 359.99
			}
		}

		ShapePath {
			strokeColor: root.ringColor
			strokeWidth: root.thickness
			fillColor: "transparent"
			capStyle: ShapePath.RoundCap

			PathAngleArc {
				centerX: root.width / 2
				centerY: root.height / 2
				radiusX: root.radius
				radiusY: root.radius
				startAngle: -90
				sweepAngle: 359.99 * Math.max(0.002, Math.min(1, root.shown))
			}
		}
	}
}
