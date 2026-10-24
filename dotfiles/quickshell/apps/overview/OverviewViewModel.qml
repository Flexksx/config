import QtQuick
import qs.libs.services
import "overview.js" as Overview

QtObject {
    property var monitor: null
    property var shown: null
    property var previous: null

    readonly property string monitorName: monitor?.name ?? ""
    readonly property string wallpaperSource: WallpaperService.displayedPath ? "file://" + WallpaperService.displayedPath : ""
    readonly property var workspaces: monitor ? WorkspaceService.workspacesOn(monitor) : []
    readonly property var windows: ordered(windowsIn(shown))
    readonly property var leaving: ordered(windowsIn(previous))
    readonly property var displayed: leaving.concat(windows)
    readonly property int direction: previous && shown ? Math.sign(shown.id - previous.id) : 0

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
        monitor = null;
    }

    function show(workspace) {
        if (workspace === shown)
            return;
        previous = shown;
        shown = workspace;
        switched();
    }

    function settle() {
        previous = null;
    }

    function pick(window) {
        WorkspaceService.focus(window);
        closeRequested();
    }

    function dismiss() {
        if (shown !== monitor.activeWorkspace)
            WorkspaceService.activate(shown);
        closeRequested();
    }

    function windowsIn(workspace) {
        return WorkspaceService.windows.filter(window => window.workspace === workspace && Overview.placed(WorkspaceService.clientOf(window)));
    }

    function ordered(list) {
        return list.sort((first, second) => Overview.leftToRight(frameOf(first), frameOf(second)));
    }

    function frameOf(window) {
        return Overview.frameOf(WorkspaceService.clientOf(window), monitor);
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
        return windowsIn(workspace).map(window => ({
                    source: window.wayland,
                    frame: frameOf(window)
                }));
    }

    function strip(area, aspect, gap) {
        return Overview.strip(workspaces.length, area, aspect, gap);
    }
}
