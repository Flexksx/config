import QtQuick
import qs.libs.services
import "overview.js" as Overview

QtObject {
    property var monitor: null
    property var shown: null
    property var previous: null
    property var shownSpecial: null
    property var previousSelection: null

    readonly property string monitorName: monitor?.name ?? ""
    readonly property string wallpaperSource: WallpaperService.displayedPath ? "file://" + WallpaperService.displayedPath : ""
    readonly property var workspaces: monitor ? WorkspaceService.workspacesOn(monitor) : []
    readonly property var specialWorkspaces: ScratchpadService.scratchpads.map(s => ({
            name: s.label,
            workspace: s.workspace,
            id: 1000 + ScratchpadService.scratchpads.indexOf(s)
        }))
    readonly property var windows: ordered(windowsIn(shown, shownSpecial))
    readonly property var leaving: ordered(windowsIn(previous, null))
    readonly property var displayed: leaving.concat(windows)
    readonly property int direction: previousSelection && (shown || shownSpecial) ? Math.sign((shown || shownSpecial).id - previousSelection.id) : 0

    signal closeRequested
    signal switched

    function begin() {
        WorkspaceService.refreshWindows();
        monitor = WorkspaceService.focusedMonitor;
        shown = monitor.activeWorkspace;
        WallpaperService.refreshDisplayed(monitor.name);
    }

    function release() {
        previous = null;
        shown = null;
        shownSpecial = null;
        previousSelection = null;
        monitor = null;
    }

    function show(workspace) {
        if (workspace === shown)
            return;
        previousSelection = shownSpecial || shown;
        previous = shownSpecial ? null : shown;
        shown = workspace;
        shownSpecial = null;
        switched();
    }

    function showSpecial(scratchpad) {
        if (scratchpad === shownSpecial)
            return;
        previousSelection = shown || shownSpecial;
        previous = shown;
        shown = null;
        shownSpecial = scratchpad;
        switched();
    }

    function settle() {
        previous = null;
    }

    function pick(window) {
        if (shownSpecial) {
            ScratchpadService.pull(WorkspaceService.clientAddress(window));
            closeRequested();
            return;
        }
        WorkspaceService.focus(window);
        closeRequested();
    }

    function dismiss() {
        if (shown && shown !== monitor.activeWorkspace)
            WorkspaceService.activate(shown);
        closeRequested();
    }

    function windowsIn(workspace, special) {
        if (special)
            return WorkspaceService.windows.filter(window => WorkspaceService.workspaceOf(window) === special.workspace && Overview.placed(WorkspaceService.clientOf(window)));
        if (workspace)
            return WorkspaceService.windows.filter(window => window.workspace === workspace && Overview.placed(WorkspaceService.clientOf(window)));
        return [];
    }

    function ordered(list) {
        return list.sort((first, second) => Overview.leftToRight(frameOf(first), frameOf(second)));
    }

    function frameOf(window) {
        const client = WorkspaceService.clientOf(window);
        if (!client || !monitor)
            return { x: 0, y: 0, width: 0, height: 0 };
        return Overview.frameOf(client, monitor);
    }

    function slotOf(window, area, gaps, maxScale) {
        const group = leaving.includes(window) ? leaving : windows;
        const index = group.indexOf(window);
        if (index < 0)
            return frameOf(window);
        return Overview.arrange(group.map(member => frameOf(member)), area, gaps, maxScale)[index];
    }

    function frameAt(window, slot, progress) {
        return Overview.between(frameOf(window), slot, progress);
    }

    function offsetOf(window, slide, distance) {
        return (leaving.includes(window) ? -slide : 1 - slide) * direction * distance;
    }

    function presenceOf(window, slide) {
        return leaving.includes(window) ? 1 - slide : slide;
    }

    function iconOf(window) {
        return AppService.iconFor(WorkspaceService.appIdOf(window));
    }

    function miniaturesIn(workspace) {
        return windowsIn(workspace, null).map(window => ({
                    source: window.wayland,
                    frame: frameOf(window)
                }));
    }

    function specialMiniaturesIn(scratchpad) {
        return windowsIn(null, scratchpad).map(window => ({
                    source: window.wayland,
                    frame: frameOf(window)
                }));
    }

    function strip(area, aspect, gap) {
        return Overview.strip(workspaces.length, area, aspect, gap);
    }

    function specialStrip(area, aspect, gap) {
        return Overview.strip(specialWorkspaces.length, area, aspect, gap);
    }
}
