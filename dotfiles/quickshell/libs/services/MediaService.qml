pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    readonly property string proxySuffix: ".playerctld"
    readonly property var players: Mpris.players.values.filter(player => !player.dbusName.endsWith(proxySuffix))

    function previous(player) {
        player.previous();
    }

    function toggle(player) {
        player.togglePlaying();
    }

    function next(player) {
        player.next();
    }
}
