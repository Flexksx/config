import QtQuick
import Quickshell.Wayland
import qs.libs

BottomSheet {
    id: window

    widthPercent: 40
    minimumWidth: 960
    implicitHeight: layout.implicitHeight + Theme.spacing5 * 2 + Theme.spacing6
    WlrLayershell.namespace: "launcher"
    onVisibleChanged: {
        if (!visible)
            return;
        launcher.query = "";
        search.focusInput();
    }

    LauncherViewModel {
        id: launcher

        onCloseRequested: window.close()
    }

    Column {
        id: layout

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.spacing5
        spacing: Theme.spacing4

        SearchBar {
            id: search

            width: parent.width
            text: launcher.query
            placeholder: "Search apps"
            trailingText: launcher.query.trim().length > 0 ? launcher.matches.length + " / " + launcher.total : ""
            onEdited: text => launcher.query = text
            onAccepted: launcher.open(launcher.top)
            onEscaped: launcher.back()
        }

        KeyboardMap {
            width: parent.width
            rows: launcher.rows
            keymap: launcher.keymap
            selected: launcher.top
            onActivated: app => launcher.open(app)
        }

        Item {
            width: parent.width
            height: Theme.spacing6

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacing2

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: launcher.top !== null
                    text: Icons.enter
                    color: Theme.surface.on
                }

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: launcher.top ? (launcher.top.open ? "switch to " : "open ") + launcher.top.name : launcher.query.length > 0 ? "no match" : "most used per letter  " + Icons.dot + "  outlined tools are out"
                    color: launcher.top ? Theme.surface.on : Theme.surface.variant.on
                }
            }

            Label {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: launcher.top !== null
                text: launcher.top?.open ? "in use" : (launcher.top?.uses ?? 0) + " uses"
            }
        }
    }
}
