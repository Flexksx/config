import QtQuick
import Quickshell
import Quickshell.Io
import qs.apps.dock
import qs.apps.launcher
import qs.apps.overview
import qs.apps.wallpapers

ShellRoot {
    LauncherWindow {
        id: launcher
    }

    WallpaperWindow {
        id: wallpapers
    }

    OverviewWindow {
        id: overview
    }

    Variants {
        model: Quickshell.screens

        DockWindow {
            required property var modelData

            screen: modelData
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            wallpapers.visible = false;
            launcher.toggle();
        }
    }

    IpcHandler {
        target: "wallpaper"

        function toggle(): void {
            launcher.visible = false;
            wallpapers.toggle();
        }
    }

    IpcHandler {
        target: "overview"

        function toggle(): void {
            launcher.visible = false;
            wallpapers.visible = false;
            overview.toggle();
        }
    }
}
