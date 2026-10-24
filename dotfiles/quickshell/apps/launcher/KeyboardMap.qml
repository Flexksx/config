import QtQuick
import qs.libs

Rectangle {
    id: board

    property var rows: []
    property var keymap: ({})
    property var selected: null
    readonly property real gap: Theme.spacing2
    readonly property real keyWidth: (keys.width - gap * 9) / 10

    signal activated(var app)

    implicitHeight: keys.implicitHeight + Theme.spacing4 * 2
    radius: Theme.radiusLg
    color: Theme.surface.container.lowest

    Canvas {
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const context = getContext("2d");
            const step = Theme.spacing4;
            context.reset();
            context.fillStyle = Theme.outlineVariant;
            for (let x = step / 2; x < width; x += step)
                for (let y = step / 2; y < height; y += step) {
                    context.beginPath();
                    context.arc(x, y, 1.5, 0, Math.PI * 2);
                    context.fill();
                }
        }
    }

    Column {
        id: keys

        anchors.fill: parent
        anchors.margins: Theme.spacing4
        spacing: board.gap

        Repeater {
            model: board.rows

            Row {
                id: row

                required property string modelData
                required property int index

                x: [0, 0.25, 0.75][index] * (board.keyWidth + board.gap)
                spacing: board.gap

                Repeater {
                    model: row.modelData.split("")

                    KeyCap {
                        required property string modelData
                        required property int index

                        width: board.keyWidth
                        height: board.keyWidth * 1.1
                        letter: modelData
                        app: board.keymap[modelData] ?? null
                        selected: app !== null && app === board.selected
                        order: index + row.index
                        onClicked: board.activated(app)
                    }
                }
            }
        }
    }
}
