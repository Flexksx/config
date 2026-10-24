import QtQuick
import Quickshell.Widgets

ClippingRectangle {
    id: segmented

    property var options: []
    property string current: ""

    signal selected(string value)

    implicitWidth: segments.width
    implicitHeight: 40
    radius: height / 2
    color: "transparent"
    border.width: 1
    border.color: Theme.outline

    Row {
        id: segments

        height: parent.height

        Repeater {
            model: segmented.options

            Rectangle {
                id: segment

                required property var modelData
                required property int index
                readonly property bool active: segmented.current === modelData.value

                width: label.implicitWidth + Theme.spacing6 * 2
                height: segments.height
                color: active ? Theme.secondaryContainer.base : "transparent"

                Rectangle {
                    visible: segment.index > 0
                    width: 1
                    height: parent.height
                    color: Theme.outline
                }

                Row {
                    id: label

                    anchors.centerIn: parent
                    spacing: Theme.spacing2

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: segment.active ? Icons.check : segment.modelData.icon
                        color: caption.color
                    }

                    Text {
                        id: caption

                        anchors.verticalCenter: parent.verticalCenter
                        text: segment.modelData.label
                        color: segment.active ? Theme.secondaryContainer.on : Theme.surface.on
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.labelLarge
                        font.weight: Theme.weightMedium
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: segmented.selected(segment.modelData.value)
                }
            }
        }
    }
}
