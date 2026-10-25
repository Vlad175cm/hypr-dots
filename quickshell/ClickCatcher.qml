import QtQuick
import Quickshell
import Quickshell.Wayland

// ClickCatcher.qml — a full screen, invisible layer that closes a pinned
// panel when you click anywhere outside it.
//
// It lives on the Top layer while the island is on the Overlay layer, so the
// island always stays on top and keeps receiving its own clicks.
PanelWindow {
	id: catcher

	visible: false
	color: "transparent"

	anchors {
		top: true
		bottom: true
		left: true
		right: true
	}

	// note: do NOT set exclusiveZone here — quickshell turns that into
	// ExclusionMode.Normal, and the compositor would then push this surface
	// below the island's reserved strip
	exclusionMode: ExclusionMode.Ignore
	WlrLayershell.layer: WlrLayer.Top
	WlrLayershell.namespace: "quickshell-dismiss"
	WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

	signal dismissed()

	MouseArea {
		anchors.fill: parent
		acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
		onClicked: catcher.dismissed()
	}
}
