import QtQuick
import qs.libs

Item {
    id: icon

    property string source: ""
    property real resolution: 0
    property bool active: false
    property bool urgent: false
    property bool playing: false
    property bool detailed: false
    property int unread: 0
    readonly property real restDotSize: 3
    readonly property real dotSize: detailed ? Theme.spacing1 : restDotSize

    AppIcon {
        anchors.fill: parent
        sourceSize.width: icon.resolution
        sourceSize.height: icon.resolution
        source: icon.source
        mipmap: true
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height + 1
        width: icon.dotSize
        height: icon.dotSize
        radius: width / 2
        visible: icon.active
        color: Theme.primary.base
    }

    Badge {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: counted ? -Theme.spacing1 : 0
        count: icon.detailed ? icon.unread : 0
        dot: icon.urgent || icon.unread > 0
    }

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: -Theme.spacing1
        width: Theme.spacing5
        height: Theme.spacing5
        radius: width / 2
        visible: icon.playing && icon.detailed
        color: Theme.tertiary.base

        Icon {
            anchors.centerIn: parent
            text: Icons.volume
            color: Theme.tertiary.on
            font.pixelSize: Theme.labelMedium
        }
    }
}
