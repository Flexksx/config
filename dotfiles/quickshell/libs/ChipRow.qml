import QtQuick

ListView {
    id: row

    property var selected: []

    signal toggled(string value)

    implicitHeight: 40
    orientation: ListView.Horizontal
    spacing: Theme.spacing2
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    delegate: Rectangle {
        id: chip

        required property var modelData
        readonly property bool active: row.selected.includes(modelData.value)

        y: (row.height - height) / 2
        width: label.implicitWidth + Theme.spacing4 * 2
        height: 32
        radius: Theme.radiusSm
        color: active ? Theme.secondaryContainer.base : "transparent"
        border.width: active ? 0 : 1
        border.color: Theme.outlineVariant

        Row {
            id: label

            anchors.centerIn: parent
            spacing: Theme.spacing2

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                visible: chip.active
                text: Icons.check
                color: caption.color
            }

            Text {
                id: caption

                anchors.verticalCenter: parent.verticalCenter
                text: chip.modelData.label
                color: chip.active ? Theme.secondaryContainer.on : Theme.surface.variant.on
                font.family: Theme.fontFamily
                font.pixelSize: Theme.labelLarge
                font.weight: Theme.weightMedium
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: row.toggled(chip.modelData.value)
        }
    }
}
