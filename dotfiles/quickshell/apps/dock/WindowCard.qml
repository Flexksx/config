import QtQuick
import qs.libs

Rectangle {
    id: card

    property string name: ""
    property string place: ""
    property string title: ""
    property var media: null
    readonly property real secondaryOpacity: 0.7

    signal clicked
    signal previous
    signal toggle
    signal next

    implicitHeight: lines.implicitHeight + Theme.spacing3 * 2
    radius: Theme.radiusLg
    color: Theme.surface.inverse.base

    MouseArea {
        anchors.fill: parent
        onClicked: card.clicked()
    }

    Column {
        id: lines

        x: Theme.spacing3
        y: Theme.spacing3
        width: parent.width - Theme.spacing3 * 2
        spacing: Theme.spacing1

        Label {
            width: parent.width
            text: [card.name, card.place].filter(part => part).join(" · ")
            color: Theme.surface.inverse.on
            opacity: card.secondaryOpacity
        }

        Text {
            width: parent.width
            text: card.title
            elide: Text.ElideRight
            color: Theme.surface.inverse.on
            font.family: Theme.fontFamily
            font.pixelSize: Theme.bodyMedium
        }

        Item {
            visible: card.media !== null
            width: parent.width
            height: controls.implicitHeight + Theme.spacing1

            Text {
                anchors.left: parent.left
                anchors.right: controls.left
                anchors.rightMargin: Theme.spacing2
                anchors.verticalCenter: controls.verticalCenter
                text: card.media?.track ?? ""
                elide: Text.ElideRight
                color: Theme.surface.inverse.on
                opacity: card.secondaryOpacity
                font.family: Theme.fontFamily
                font.pixelSize: Theme.bodySmall
            }

            Row {
                id: controls

                anchors.right: parent.right
                anchors.bottom: parent.bottom

                IconButton {
                    glyph: Icons.skipPrevious
                    enabled: card.media?.canPrevious ?? false
                    onClicked: card.previous()
                }

                IconButton {
                    glyph: card.media?.playing ? Icons.pause : Icons.play
                    enabled: card.media?.canToggle ?? false
                    onClicked: card.toggle()
                }

                IconButton {
                    glyph: Icons.skipNext
                    enabled: card.media?.canNext ?? false
                    onClicked: card.next()
                }
            }
        }
    }
}
