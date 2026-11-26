import QtQuick
import Quickshell
import qs.libs.services
import "dock.js" as Dock

QtObject {
    property var pointed: null

    readonly property var windows: WorkspaceService.windows
    readonly property var bays: Dock.bays(windows.map(window => WorkspaceService.workspaceOf(window)), ScratchpadService.scratchpads)
    readonly property var entries: [].concat(...bays.map(bay => windowsIn(bay)))
    readonly property var groups: entries.map(window => WorkspaceService.workspaceOf(window))
    readonly property string focusedBay: WorkspaceService.focusedWorkspace
    readonly property int pointedSlot: entries.indexOf(pointed)
    readonly property string pointedName: pointed ? appOf(pointed)?.name ?? "" : ""
    readonly property string pointedPlace: pointed ? labelOf(WorkspaceService.workspaceOf(pointed)) : ""
    readonly property string pointedTitle: pointed?.title ?? ""
    readonly property var pointedPlayer: pointed ? playerOf(pointed) : null
    readonly property var pointedMedia: Dock.mediaOf(pointedPlayer)
    readonly property var pointedTargets: pointed ? moveTargetsOf(pointed) : []

    function point(window) {
        pointed = window;
    }

    function release() {
        pointed = null;
    }

    function layout(slot, divider, center, focus, gain, radius) {
        return Dock.arrange(groups, slot, divider, center, focus, gain, radius);
    }

    function slotAt(items, x) {
        return Dock.at(items, x);
    }

    function spanOf(items, bay) {
        return Dock.span(items, bay);
    }

    function windowsIn(bay) {
        return windows.filter(window => WorkspaceService.workspaceOf(window) === bay);
    }

    function labelOf(bay) {
        return Dock.scratchpadAt(ScratchpadService.scratchpads, bay)?.label ?? WorkspaceService.displayName(bay);
    }

    function appOf(window) {
        return AppService.find(WorkspaceService.appIdOf(window));
    }

    function iconOf(window) {
        return AppService.iconFor(WorkspaceService.appIdOf(window));
    }

    function unreadIn(window) {
        return Dock.unreadIn(window.title);
    }

    function playerOf(window) {
        return Dock.playerFor(window.title, WorkspaceService.appIdOf(window), windows.map(other => other.title), MediaService.players);
    }

    function playingIn(window) {
        return playerOf(window)?.isPlaying ?? false;
    }

    function focus(window) {
        const scratchpad = Dock.scratchpadAt(ScratchpadService.scratchpads, WorkspaceService.workspaceOf(window));
        if (scratchpad)
            ScratchpadService.pull(WorkspaceService.clientAddress(window));
        else {
            const address = WorkspaceService.clientAddress(window);
            if (!address) {
                WorkspaceService.focus(window);
                return;
            }
            const selector = JSON.stringify("address:" + address);
            Quickshell.execDetached(["hyprctl", "eval", "local w = hl.get_window(" + selector + "); if w and w.workspace and w.workspace.name == 'special:minimized' then scratchpad_pull(" + JSON.stringify(address) + ") else hl.dispatch(hl.dsp.focus({ window = " + selector + " })) end"]);
        }
    }

    function moveTargetsOf(window) {
        const current = WorkspaceService.workspaceOf(window);
        const bays = WorkspaceService.workspacesOn(window.monitor).map(workspace => workspace.name).concat(ScratchpadService.scratchpads.map(scratchpad => scratchpad.workspace));
        return bays.filter(bay => bay !== current).map(bay => ({
                    bay: bay,
                    label: labelOf(bay)
                }));
    }

    function closeWindow(window) {
        Quickshell.execDetached(["hyprctl", "eval", "hl.dispatch(hl.dsp.window.close({ window = " + selectorOf(window) + " }))"]);
    }

    function moveTo(window, bay) {
        const workspace = /^[0-9]+$/.test(bay) ? bay : JSON.stringify(bay);
        Quickshell.execDetached(["hyprctl", "eval", "hl.dispatch(hl.dsp.window.move({ workspace = " + workspace + ", window = " + selectorOf(window) + ", follow = false }))"]);
    }

    function selectorOf(window) {
        return '"address:' + WorkspaceService.clientAddress(window) + '"';
    }

    function toggleScratchpad(window) {
        const scratchpad = Dock.scratchpadAt(ScratchpadService.scratchpads, WorkspaceService.workspaceOf(window));
        if (scratchpad)
            ScratchpadService.toggle(scratchpad.name);
    }

    function previous() {
        MediaService.previous(pointedPlayer);
    }

    function toggle() {
        MediaService.toggle(pointedPlayer);
    }

    function next() {
        MediaService.next(pointedPlayer);
    }
}
