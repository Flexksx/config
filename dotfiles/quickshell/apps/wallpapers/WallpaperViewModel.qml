import QtQuick
import qs.libs
import qs.libs.services
import "wallpapers.js" as Wallpapers

QtObject {
    readonly property var modes: [
        {
            value: "all",
            label: "All",
            icon: Icons.images
        },
        {
            value: "dark",
            label: "Dark",
            icon: Icons.moon
        },
        {
            value: "light",
            label: "Light",
            icon: Icons.sun
        }
    ]

    property string query: ""
    property string mode: "all"
    property var tags: []

    readonly property var items: WallpaperService.wallpapers.map(Wallpapers.decorate)
    readonly property var shown: Wallpapers.filter(items, query, mode, tags, WallpaperService.currentMode)
    readonly property var tagOptions: Wallpapers.tagOptions(items)
    readonly property string summary: shown.length + " / " + items.length
    readonly property int startIndex: Math.max(0, shown.findIndex(item => item.current))

    signal closeRequested

    function reset() {
        query = "";
        mode = "all";
        tags = [];
    }

    function toggleTag(tag) {
        tags = tags.includes(tag) ? tags.filter(item => item !== tag) : tags.concat([tag]);
    }

    function cycleMode(step) {
        const index = modes.findIndex(item => item.value === mode);
        mode = modes[(index + step + modes.length) % modes.length].value;
    }

    function back() {
        if (query.length > 0 || tags.length > 0 || mode !== "all")
            reset();
        else
            closeRequested();
    }

    function apply(wallpaper) {
        if (!wallpaper)
            return;
        WallpaperService.apply(wallpaper.path);
        closeRequested();
    }
}
