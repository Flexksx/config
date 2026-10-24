import QtQuick

OverlayWindow {
    id: sheet

    readonly property alias reveal: motion.progress

    function toggle() {
        if (visible && !motion.hiding)
            close();
        else
            open();
    }

    function open() {
        if (!visible) {
            motion.progress = 0;
            visible = true;
        }
        motion.show();
    }

    function close() {
        motion.hide();
    }

    anchors.bottom: true
    surface.anchors.bottomMargin: Theme.spacing6
    surface.transform: Translate {
        y: Math.max(0, 1 - sheet.reveal) * sheet.height
    }

    Reveal {
        id: motion

        onHidden: sheet.visible = false
    }
}
