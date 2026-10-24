import QtQuick
import qs.libs.services
import "launcher.js" as Launcher

QtObject {
    readonly property var rows: ["qwertyuiop", "asdfghjkl", "zxcvbnm"]

    property string query: ""

    readonly property var matches: Launcher.rank(AppService.apps, query)
    readonly property var top: matches[0] ?? null
    readonly property var keymap: Launcher.keymap(AppService.apps, query, rows.join(""), top)
    readonly property int total: AppService.apps.length

    signal closeRequested

    function back() {
        if (query.length > 0)
            query = "";
        else
            closeRequested();
    }

    function open(app) {
        if (!app)
            return;
        AppService.open(app.id);
        closeRequested();
    }
}
