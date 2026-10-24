import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets

PanelWindow {
    property real widthPercent: 50
    property real heightPercent: 60
    property int minimumWidth: 0
    property alias surface: surface
    default property alias content: surface.data

    function toggle() {
        visible = !visible;
    }

    visible: false
    screen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    implicitWidth: Math.max(minimumWidth, Math.round(screen.width * widthPercent / 100))
    implicitHeight: Math.round(screen.height * heightPercent / 100)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    ClippingRectangle {
        id: surface

        anchors.fill: parent
        radius: Theme.radiusXl
        color: Theme.surface.container.base
    }
}
