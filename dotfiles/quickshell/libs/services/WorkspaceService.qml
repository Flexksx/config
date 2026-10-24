pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    readonly property string specialPrefix: "special:"
    readonly property var windows: Hyprland.toplevels.values.filter(toplevel => toplevel.workspace !== null)
    readonly property string focusedWorkspace: Hyprland.focusedWorkspace?.name ?? ""
    readonly property var focusedMonitor: Hyprland.focusedMonitor

    function workspaceOf(window) {
        return window.workspace.name;
    }

    function displayName(workspace) {
        return workspace.replace(specialPrefix, "");
    }

    function isSpecial(workspace) {
        return workspace.startsWith(specialPrefix);
    }

    function workspacesOn(monitor) {
        return Hyprland.workspaces.values.filter(workspace => workspace.monitor === monitor && !isSpecial(workspace.name)).sort((first, second) => first.id - second.id);
    }

    function appIdOf(window) {
        return window.wayland?.appId ?? window.lastIpcObject.class ?? "";
    }

    function clientOf(window) {
        return window.lastIpcObject;
    }

    function refreshWindows() {
        Hyprland.refreshToplevels();
    }

    function focus(window) {
        window.wayland?.activate();
    }

    function activate(workspace) {
        workspace.activate();
    }
}
