import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.libs

PanelWindow {
    id: window

    readonly property real stripTop: Theme.spacing4
    readonly property real stripHeight: 96
    readonly property real stripGap: Theme.spacing4
    readonly property real sidePadding: Theme.spacing8
    readonly property real captionRoom: Theme.spacing10
    readonly property real bottomPadding: Theme.spacing6
    readonly property real stripTravel: Theme.spacing8
    readonly property real switchTravel: Theme.spacing16
    readonly property real maxScale: 1
    readonly property real backdropOpacity: 0.2
    readonly property real progress: motion.progress
    readonly property real previewTop: stripTop + stripHeight + captionRoom
    readonly property var previewArea: ({
            x: sidePadding,
            y: previewTop,
            width: width - sidePadding * 2,
            height: height - previewTop - bottomPadding
        })
    readonly property var previewGaps: ({
            column: Theme.spacing8,
            row: Theme.spacing12
        })
    readonly property var stripSlots: viewModel.strip({
        x: sidePadding,
        y: stripTop,
        width: width - sidePadding * 2,
        height: stripHeight
    }, width / height, stripGap)
    readonly property bool capturesReady: Array.from({
        length: previews.count
    }, (unused, index) => previews.itemAt(index)).every(item => item !== null && item.ready)
    property real slide: 1
    property bool awaitingCaptures: false

    function toggle() {
        if (visible && !motion.hiding)
            viewModel.dismiss();
        else
            open();
    }

    function open() {
        viewModel.begin();
        screen = Quickshell.screens.find(candidate => candidate.name === viewModel.monitorName) ?? Quickshell.screens[0];
        motion.progress = 0;
        awaitingCaptures = true;
        visible = true;
        revealDeadline.restart();
        if (capturesReady)
            reveal();
    }

    function reveal() {
        if (!awaitingCaptures)
            return;
        awaitingCaptures = false;
        revealDeadline.stop();
        motion.show();
    }

    onCapturesReadyChanged: {
        if (capturesReady)
            reveal();
    }

    visible: false
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "overview"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    onVisibleChanged: {
        if (visible) {
            keys.forceActiveFocus();
        } else {
            awaitingCaptures = false;
            viewModel.release();
        }
    }

    OverviewViewModel {
        id: viewModel

        onCloseRequested: motion.hide()
        onSwitched: switcher.restart()
    }

    Reveal {
        id: motion

        raise: SpatialAnimation {
            target: motion
            property: "progress"
            to: 1
        }
        lower: SpatialAnimation {
            target: motion
            property: "progress"
            to: 0
        }
        onHidden: window.visible = false
    }

    Timer {
        id: revealDeadline

        interval: Theme.durationFast
        onTriggered: window.reveal()
    }

    SpatialAnimation {
        id: switcher

        target: window
        property: "slide"
        from: 0
        to: 1
        duration: Theme.durationFast
        onFinished: viewModel.settle()
    }

    Item {
        id: keys

        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: viewModel.dismiss()

        Image {
            anchors.fill: parent
            source: viewModel.wallpaperSource
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: window.width
            sourceSize.height: window.height
            opacity: window.progress
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.scrim
            opacity: window.backdropOpacity * window.progress

            MouseArea {
                anchors.fill: parent
                onClicked: viewModel.dismiss()
            }
        }

        Repeater {
            model: ScriptModel {
                values: viewModel.workspaces
            }

            WorkspaceCard {
                required property var modelData
                required property int index
                readonly property var slot: window.stripSlots[index] ?? null

                x: slot?.x ?? 0
                y: (slot?.y ?? 0) - (1 - window.progress) * window.stripTravel
                width: slot?.width ?? 0
                height: slot?.height ?? 0
                opacity: window.progress
                label: modelData.name
                selected: modelData === viewModel.shown
                miniatures: viewModel.miniaturesIn(modelData)
                factor: width / window.width
                onClicked: viewModel.show(modelData)
            }
        }

        Repeater {
            id: previews

            model: ScriptModel {
                values: viewModel.displayed
            }

            WindowPreview {
                required property var modelData
                readonly property var slot: viewModel.slotOf(modelData, window.previewArea, window.previewGaps, window.maxScale)
                readonly property var frame: viewModel.frameAt(modelData, slot, window.progress)

                x: Math.round(frame.x)
                y: Math.round(frame.y)
                width: Math.round(frame.width)
                height: Math.round(frame.height)
                source: modelData.wayland
                title: modelData.title
                icon: viewModel.iconOf(modelData)
                decorationOpacity: window.progress
                opacity: viewModel.presenceOf(modelData, window.slide)
                transform: Translate {
                    x: viewModel.offsetOf(modelData, window.slide, window.switchTravel)
                }
                onClicked: viewModel.pick(modelData)
            }
        }
    }
}
