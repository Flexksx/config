import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.libs
import qs.libs.services

BottomSheet {
    id: window

    readonly property var slide: picker.shown[tray.currentIndex] ?? null

    widthPercent: 45
    minimumWidth: 720
    implicitHeight: layout.implicitHeight + Theme.spacing6
    WlrLayershell.namespace: "wallpaper-picker"
    onVisibleChanged: {
        if (!visible)
            return;
        WallpaperService.refresh();
        picker.reset();
        tray.currentIndex = picker.startIndex;
        search.focusInput();
    }

    WallpaperViewModel {
        id: picker

        onCloseRequested: window.close()
    }

    Column {
        id: layout

        width: parent.width

        Column {
            width: parent.width
            padding: Theme.spacing5
            spacing: Theme.spacing3

            Item {
                width: parent.width - Theme.spacing5 * 2
                height: search.implicitHeight

                SearchBar {
                    id: search

                    anchors.left: parent.left
                    anchors.right: modes.left
                    anchors.rightMargin: Theme.spacing3
                    text: picker.query
                    placeholder: "Search slides, tags or colors"
                    trailingText: picker.summary
                    forwardTo: [tray]
                    onEdited: text => picker.query = text
                    onAccepted: picker.apply(window.slide)
                    onTabbed: step => picker.cycleMode(step)
                    onEscaped: picker.back()
                }

                SegmentedButton {
                    id: modes

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    options: picker.modes
                    current: picker.mode
                    onSelected: value => picker.mode = value
                }
            }

            ChipRow {
                width: parent.width - Theme.spacing5 * 2
                model: picker.tagOptions
                selected: picker.tags
                onToggled: value => picker.toggleTag(value)
            }
        }

        Tray {
            id: tray

            width: parent.width
            transform: Rotation {
                origin.x: tray.center.x
                origin.y: tray.center.y
                angle: (1 - window.reveal) * -30
            }
            model: ScriptModel {
                values: picker.shown
                objectProp: "path"
                onValuesChanged: tray.currentIndex = picker.startIndex
            }
            onActivated: wallpaper => picker.apply(wallpaper)

            Text {
                anchors.centerIn: parent
                visible: picker.shown.length === 0
                text: "No slides match"
                color: Theme.surface.variant.on
                font.family: Theme.fontFamily
                font.pixelSize: Theme.titleMedium
            }
        }

        Rectangle {
            width: parent.width
            height: details.implicitHeight + Theme.spacing3 * 2
            color: Theme.surface.container.high

            Label {
                anchors.left: parent.left
                anchors.leftMargin: Theme.spacing5
                anchors.verticalCenter: parent.verticalCenter
                text: picker.shown.length > 0 ? (tray.currentIndex + 1) + " of " + picker.shown.length : ""
            }

            Column {
                id: details

                anchors.centerIn: parent
                width: parent.width * 0.6
                spacing: 2

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: window.slide?.title ?? ""
                    color: Theme.surface.on
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.titleMedium
                    font.weight: Theme.weightMedium
                }

                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: (window.slide?.tags ?? []).concat([window.slide?.current ? "on the wall" : (window.slide?.uses ?? 0) + " uses"]).join("  " + Icons.dot + "  ")
                }
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: Theme.spacing5
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacing2

                Repeater {
                    model: [Icons.arrowLeft, Icons.arrowRight, Icons.enter, Icons.escapeKey]

                    Icon {
                        required property string modelData

                        text: modelData
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => tray.scroll(wheel.angleDelta)
    }
}
