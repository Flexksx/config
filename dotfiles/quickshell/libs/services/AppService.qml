pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland

Singleton {
    readonly property string fallbackIcon: Quickshell.iconPath("application-x-executable", true)
    readonly property string lastId: history.last

    readonly property var windows: ToplevelManager.toplevels.values.reduce((map, toplevel) => {
        const id = DesktopEntries.heuristicLookup(toplevel.appId)?.id;
        if (id && !(id in map))
            map[id] = toplevel;
        return map;
    }, {})

    readonly property var apps: DesktopEntries.applications.values.map(entry => ({
                id: entry.id,
                name: entry.name,
                icon: Quickshell.iconPath(entry.icon, true) || fallbackIcon,
                text: [entry.name, entry.genericName, entry.comment, entry.keywords.join(" "), entry.id].join(" ").toLowerCase(),
                categories: entry.categories,
                uses: history.counts[entry.id] || 0,
                open: entry.id in windows
            }))

    function find(name) {
        const id = DesktopEntries.heuristicLookup(name)?.id;
        return apps.find(app => app.id === id) ?? null;
    }

    function iconFor(name) {
        return find(name)?.icon ?? fallbackIcon;
    }

    function open(id) {
        const entry = DesktopEntries.byId(id);
        if (id in ScratchpadService.owners)
            ScratchpadService.toggle(ScratchpadService.owners[id]);
        else if (id in windows)
            windows[id].activate();
        else if (entry.runInTerminal)
            Quickshell.execDetached(["ghostty", "-e"].concat(entry.command));
        else
            entry.execute();
        history.record(id);
    }

    History {
        id: history

        path: Quickshell.env("HOME") + "/.local/state/launcher-history"
    }
}
