import QtQuick
import qs.libs

Rectangle {
    id: menu

    readonly property real secondaryOpacity: 0.7
    readonly property real dividerOpacity: 0.16
    property string name: ""
    property var targets: []
    property var media: null

    signal closeRequested
    signal moved(string bay)
    signal previous
    signal toggle
    signal next

    component Entry: Rectangle {
        id: entry

        property string text: ""

        signal activated

        width: parent.width
        height: Theme.spacing8
        radius: Theme.radiusSm
        color: "transparent"

        StateLayer {
            anchors.fill: parent
            radius: entry.radius
            tone: Theme.surface.inverse.on
            hovered: pointer.containsMouse
            pressed: pointer.pressed
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: Theme.spacing2
            anchors.verticalCenter: parent.verticalCenter
            text: entry.text
            color: Theme.surface.inverse.on
            font.family: Theme.fontFamily
            font.pixelSize: Theme.bodySmall
        }

        MouseArea {
            id: pointer

            anchors.fill: parent
            hoverEnabled: true
            onClicked: entry.activated()
        }
    }

    implicitWidth: 200
    implicitHeight: rows.implicitHeight + Theme.spacing2 * 2
    radius: Theme.radiusMd
    color: Theme.surface.inverse.base

    Column {
        id: rows

        x: Theme.spacing2
        y: Theme.spacing2
        width: menu.width - Theme.spacing2 * 2
        spacing: Theme.spacing1

        Label {
            width: parent.width
            text: menu.name
            color: Theme.surface.inverse.on
            opacity: menu.secondaryOpacity
        }

        Entry {
            text: "Close"
            onActivated: menu.closeRequested()
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.surface.inverse.on
            opacity: menu.dividerOpacity
        }

        Label {
            width: parent.width
            text: "Move to"
            color: Theme.surface.inverse.on
            opacity: menu.secondaryOpacity
        }

        Repeater {
            model: menu.targets

            Entry {
                required property var modelData

                text: modelData.label
                onActivated: menu.moved(modelData.bay)
            }
        }

        Rectangle {
            visible: menu.media !== null
            width: parent.width
            height: 1
            color: Theme.surface.inverse.on
            opacity: menu.dividerOpacity
        }

        Text {
            visible: menu.media !== null
            width: parent.width
            text: menu.media?.track ?? ""
            elide: Text.ElideRight
            color: Theme.surface.inverse.on
            opacity: menu.secondaryOpacity
            font.family: Theme.fontFamily
            font.pixelSize: Theme.bodySmall
        }

        Row {
            visible: menu.media !== null

            IconButton {
                glyph: Icons.skipPrevious
                enabled: menu.media?.canPrevious ?? false
                onClicked: menu.previous()
            }

            IconButton {
                glyph: menu.media?.playing ? Icons.pause : Icons.play
                enabled: menu.media?.canToggle ?? false
                onClicked: menu.toggle()
            }

            IconButton {
                glyph: Icons.skipNext
                enabled: menu.media?.canNext ?? false
                onClicked: menu.next()
            }
        }
    }
}
