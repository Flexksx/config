import QtQuick
import Quickshell.Wayland
import Quickshell.Widgets
import qs.libs

Item {
    id: card

    required property string label
    required property bool selected
    required property var miniatures
    required property real factor
    readonly property real selectedBorder: 2
    readonly property real restingBorder: 1
    readonly property real faceOpacity: 0.6

    signal clicked

    ClippingRectangle {
        anchors.fill: parent
        radius: Theme.radiusSm
        color: Theme.withOpacity(Theme.surface.container.base, card.faceOpacity)

        Repeater {
            model: card.miniatures

            ScreencopyView {
                required property var modelData

                x: modelData.frame.x * card.factor
                y: modelData.frame.y * card.factor
                width: modelData.frame.width * card.factor
                height: modelData.frame.height * card.factor
                captureSource: modelData.source
                live: false
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSm
        color: "transparent"
        border.width: card.selected ? card.selectedBorder : card.restingBorder
        border.color: card.selected ? Theme.primary.base : Theme.outlineVariant

        Behavior on border.color {
            EffectColorAnimation {}
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: Theme.spacing2
        width: name.implicitWidth + Theme.spacing2 * 2
        height: name.implicitHeight + Theme.spacing1 * 2
        radius: height / 2
        color: Theme.surface.inverse.base

        Label {
            id: name

            anchors.centerIn: parent
            text: card.label
            color: Theme.surface.inverse.on
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: card.clicked()
    }
}
