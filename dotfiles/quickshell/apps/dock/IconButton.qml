import QtQuick
import qs.libs

Item {
    id: button

    property string glyph: ""
    readonly property real disabledOpacity: 0.38

    signal clicked

    implicitWidth: Theme.spacing8
    implicitHeight: Theme.spacing8
    opacity: enabled ? 1 : disabledOpacity

    StateLayer {
        anchors.fill: parent
        radius: width / 2
        tone: Theme.surface.inverse.on
        hovered: mouse.containsMouse
        pressed: mouse.pressed
    }

    Icon {
        anchors.centerIn: parent
        text: button.glyph
        color: Theme.surface.inverse.on
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        onClicked: button.clicked()
    }
}
