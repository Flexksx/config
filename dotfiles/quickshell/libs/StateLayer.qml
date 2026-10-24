import QtQuick

Rectangle {
    property bool hovered: false
    property bool pressed: false
    property color tone: Theme.surface.on

    radius: Theme.radiusMd
    color: Theme.getStateLayerColor(tone, pressed ? "pressed" : hovered ? "hover" : "")

    Behavior on color {
        ColorAnimation {
            duration: Theme.durationFast
        }
    }
}
