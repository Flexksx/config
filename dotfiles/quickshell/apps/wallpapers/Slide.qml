import QtQuick
import Quickshell.Widgets
import qs.libs

Rectangle {
    id: slide

    property var wallpaper: null
    property int number: 0
    property bool active: false

    signal clicked

    height: width * 9 / 16 + Theme.spacing8
    radius: Theme.radiusSm
    color: active ? Theme.primary.base : mouse.containsMouse ? Theme.secondaryContainer.base : Theme.surface.container.highest

    Behavior on color {
        ColorAnimation {
            duration: Theme.durationFast
        }
    }

    ClippingRectangle {
        id: window

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.spacing1 * 1.5
        height: width * 9 / 16
        radius: Theme.radiusXs
        color: Theme.surface.container.lowest

        Image {
            anchors.fill: parent
            source: slide.wallpaper ? "file://" + slide.wallpaper.thumbnail : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 480
        }
    }

    Label {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: Theme.spacing2
        text: String(slide.number).padStart(3, "0")
        color: slide.active ? Theme.primary.on : Theme.surface.variant.on
        font.weight: Theme.weightBold
    }

    Label {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.spacing2
        visible: slide.wallpaper?.current ?? false
        text: "on wall"
        color: slide.active ? Theme.primary.on : Theme.primary.base
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        onClicked: slide.clicked()
    }
}
