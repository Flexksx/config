pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property var scratchpads: definitions.map(definition => Object.assign({
                workspace: WorkspaceService.specialPrefix + definition.name
            }, definition))

    readonly property var definitions: [
        {
            name: "comms",
            label: "comms",
            classes: ["slack", "org.telegram.desktop"]
        },
        {
            name: "spotify-scratchpad",
            label: "music",
            classes: ["spotify"],
            media: true
        }
    ]

    readonly property var owners: ownersOf(DesktopEntries.applications.values)

    function ownersOf(entries) {
        const map = {};
        if (entries.length === 0)
            return map;
        for (const scratchpad of scratchpads)
            for (const windowClass of scratchpad.classes) {
                const id = DesktopEntries.heuristicLookup(windowClass)?.id;
                if (id)
                    map[id] = scratchpad.name;
            }
        return map;
    }

    function toggle(name) {
        Quickshell.execDetached(["hyprctl", "eval", "scratchpads[\"" + name + "\"]()"]);
    }
}
