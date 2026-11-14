import QtQuick
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
        else
            WorkspaceService.focus(window);
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
