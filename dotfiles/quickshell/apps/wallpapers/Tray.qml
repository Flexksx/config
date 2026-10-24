import QtQuick
import qs.libs

Item {
    id: tray

    property alias model: view.model
    property alias currentIndex: view.currentIndex
    property real wheel: 0
    readonly property int notch: 120
    readonly property real slideWidth: width * 0.2
    readonly property real ring: width
    readonly property real sweep: 40
    readonly property real frontScale: 1.15
    readonly property real edgeScale: 0.8
    readonly property real frontHeight: (slideWidth * 9 / 16 + Theme.spacing8) * frontScale
    readonly property real arcTop: frontHeight / 2 + Theme.spacing3
    readonly property point center: Qt.point(width / 2, arcTop + ring)

    signal activated(var wallpaper)

    implicitHeight: frontHeight + Theme.spacing8
    clip: true

    function scroll(angleDelta) {
        wheel += Math.abs(angleDelta.y) >= Math.abs(angleDelta.x) ? angleDelta.y : angleDelta.x;
        while (Math.abs(wheel) >= notch) {
            turn(wheel > 0 ? -1 : 1);
            wheel -= Math.sign(wheel) * notch;
        }
    }

    function turn(step) {
        if (step > 0)
            view.incrementCurrentIndex();
        else
            view.decrementCurrentIndex();
    }

    Keys.onLeftPressed: turn(-1)
    Keys.onRightPressed: turn(1)

    Rectangle {
        x: tray.center.x - width / 2
        y: tray.center.y - height / 2
        width: (tray.ring + tray.arcTop) * 2
        height: width
        radius: width / 2
        color: Theme.surface.container.lowest
        border.width: 1
        border.color: Theme.outlineVariant
    }

    PathView {
        id: view

        anchors.fill: parent
        pathItemCount: Math.max(3, Math.floor(tray.ring * tray.sweep * Math.PI / 90 / (tray.slideWidth * 1.1)))
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        highlightRangeMode: PathView.StrictlyEnforceRange
        highlightMoveDuration: Theme.durationDefault
        snapMode: PathView.SnapToItem

        path: Path {
            PathAttribute {
                name: "turn"
                value: -tray.sweep
            }
            PathAttribute {
                name: "size"
                value: tray.edgeScale
            }
            PathAngleArc {
                centerX: tray.center.x
                centerY: tray.center.y
                radiusX: tray.ring
                radiusY: tray.ring
                startAngle: 270 - tray.sweep
                sweepAngle: tray.sweep
            }
            PathAttribute {
                name: "turn"
                value: 0
            }
            PathAttribute {
                name: "size"
                value: tray.frontScale
            }
            PathAngleArc {
                centerX: tray.center.x
                centerY: tray.center.y
                radiusX: tray.ring
                radiusY: tray.ring
                startAngle: 270
                sweepAngle: tray.sweep
                moveToStart: false
            }
            PathAttribute {
                name: "turn"
                value: tray.sweep
            }
            PathAttribute {
                name: "size"
                value: tray.edgeScale
            }
        }

        delegate: Slide {
            required property var modelData
            required property int index

            width: tray.slideWidth
            number: index + 1
            wallpaper: modelData
            active: PathView.isCurrentItem
            rotation: PathView.turn ?? 0
            scale: PathView.size ?? 1
            z: PathView.size ?? 1
            onClicked: active ? tray.activated(modelData) : view.currentIndex = index
        }
    }
}
