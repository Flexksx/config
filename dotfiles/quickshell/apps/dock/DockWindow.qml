import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.libs

PanelWindow {
    id: window

    readonly property real restIcon: 18
    readonly property real baseIcon: 40
    readonly property real peakIcon: 72
    readonly property real reach: 3
    readonly property real cardWidth: 320
    readonly property real cardRoom: 140
    readonly property real dividerRatio: 0.6
    readonly property real detailThreshold: 0.5
    readonly property real grow: Math.min(1, motion.progress)
    readonly property real iconSize: restIcon + (baseIcon - restIcon) * grow
    readonly property real gap: Theme.spacing1 * (1 + grow)
    readonly property real pad: Theme.spacing1 * (1 + grow)
    readonly property real divider: Theme.spacing2 * (1 + grow)
    readonly property real lift: (peakIcon - baseIcon) * grow
    readonly property bool pointing: strip.containsMouse || cardHover.hovered || linger.running
    property real focusX: 0
    property real magnify: pointing ? 1 : 0
    readonly property var items: viewModel.layout(iconSize + gap, divider, width / 2, focusX, (peakIcon - baseIcon) * magnify * grow, (baseIcon + Theme.spacing2) * reach)
    readonly property int pointedIndex: pointing ? viewModel.slotAt(items, focusX) : -1

    onPointedIndexChanged: {
        if (pointedIndex >= 0)
            viewModel.point(viewModel.entries[pointedIndex]);
    }

    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    implicitHeight: peakIcon + Theme.spacing2 * 2 + Theme.spacing1 + cardRoom
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "dock"
    mask: Region {
        item: strip

        Region {
            item: cardZone
        }
    }

    Behavior on magnify {
        NumberAnimation {
            duration: Theme.durationDefault
            easing.type: Easing.OutCubic
        }
    }

    DockViewModel {
        id: viewModel
    }

    Reveal {
        id: motion

        onHidden: viewModel.release()
    }

    Timer {
        id: collapse

        interval: Theme.durationSpatialDefault
        onTriggered: motion.hide()
    }

    Timer {
        id: linger

        interval: Theme.durationDefault
    }

    HoverHandler {
        id: hover

        onHoveredChanged: {
            if (hovered) {
                collapse.stop();
                motion.show();
            } else {
                collapse.restart();
            }
        }
    }

    Rectangle {
        id: shelf

        readonly property var first: window.items[0] ?? null
        readonly property var last: window.items[window.items.length - 1] ?? null

        visible: first !== null
        x: (first?.x ?? 0) - window.pad
        y: window.height - Theme.spacing1 - height
        width: (last ? last.x + last.size - first.x : 0) + window.pad * 2
        height: window.iconSize + window.pad * 2
        radius: height / 2
        color: Theme.surface.container.base
        border.width: 1
        border.color: Theme.outlineVariant
    }

    Rectangle {
        readonly property var span: viewModel.spanOf(window.items, viewModel.focusedBay)

        visible: span !== null
        x: span?.x ?? 0
        y: shelf.y + window.pad / 2
        width: span?.width ?? 0
        height: shelf.height - window.pad
        radius: height / 2
        color: Theme.surface.container.highest
    }

    Repeater {
        model: ScriptModel {
            values: viewModel.bays.slice(1)
        }

        Rectangle {
            required property string modelData
            readonly property var span: viewModel.spanOf(window.items, modelData)

            x: (span?.x ?? 0) - window.divider / 2
            y: shelf.y + (shelf.height - height) / 2
            width: 1
            height: window.iconSize * window.dividerRatio
            color: Theme.outlineVariant
        }
    }

    Repeater {
        model: ScriptModel {
            values: viewModel.entries
        }

        DockIcon {
            required property var modelData
            required property int index
            readonly property var place: window.items[index] ?? null

            x: (place?.x ?? 0) + window.gap / 2
            y: shelf.y + shelf.height - window.pad - height
            width: (place?.size ?? window.gap) - window.gap
            height: width
            resolution: window.peakIcon
            source: viewModel.iconOf(modelData)
            active: modelData.activated
            urgent: modelData.urgent
            unread: viewModel.unreadIn(modelData)
            playing: viewModel.playingIn(modelData)
            detailed: window.grow > window.detailThreshold
        }
    }

    MouseArea {
        id: strip

        x: shelf.x
        y: shelf.y - window.lift
        width: shelf.width
        height: window.height - y
        hoverEnabled: true
        onEntered: window.focusX = mouseX + x
        onPositionChanged: mouse => window.focusX = mouse.x + x
        onContainsMouseChanged: {
            if (!containsMouse)
                linger.restart();
        }
        onClicked: mouse => {
            if (window.pointedIndex >= 0) {
                if (mouse.button === Qt.MiddleButton)
                    viewModel.toggleScratchpad(viewModel.pointed);
                else
                    viewModel.focus(viewModel.pointed);
            }
        }
    }

    Item {
        id: cardZone

        readonly property bool shown: window.pointedIndex >= 0 && window.grow === 1 && !motion.hiding
        readonly property var place: window.items[viewModel.pointedSlot] ?? null

        x: Math.max(Theme.spacing2, Math.min(window.width - card.width - Theme.spacing2, (place ? place.x + place.size / 2 : window.width / 2) - card.width / 2))
        y: strip.y - height
        width: shown ? card.width : 0
        height: card.height + Theme.spacing2

        Behavior on x {
            enabled: card.opacity > 0
            SpatialAnimation {}
        }

        HoverHandler {
            id: cardHover
        }

        WindowCard {
            id: card

            width: window.cardWidth
            opacity: cardZone.shown ? 1 : 0
            name: viewModel.pointedName
            place: viewModel.pointedPlace
            title: viewModel.pointedTitle
            media: viewModel.pointedMedia
            onClicked: viewModel.focus(viewModel.pointed)
            onPrevious: viewModel.previous()
            onToggle: viewModel.toggle()
            onNext: viewModel.next()

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.durationFast
                }
            }
        }
    }
}
