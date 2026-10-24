pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: service

    readonly property string home: Quickshell.env("HOME")
    readonly property string directory: home + "/config/backgrounds"
    readonly property string thumbnails: home + "/.cache/wallpaper-thumbs"
    readonly property var modeTags: ["dark", "light"]

    property var paths: []
    property string currentMode: "dark"

    property var tagsByName: ({})
    property string displayedPath: ""

    readonly property var wallpapers: paths.map(path => {
        const name = path.split("/").pop();
        const tags = tagsByName[name] || [];
        return {
            path: path,
            name: name,
            thumbnail: thumbnails + "/" + name + ".jpg",
            mode: tags.includes("light") ? "light" : "dark",
            tags: tags.filter(tag => !modeTags.includes(tag)),
            uses: history.counts[path] || 0,
            current: path === history.last
        };
    })

    function refresh() {
        modeProcess.running = true;
        listProcess.running = true;
    }

    function refreshDisplayed(output) {
        displayedProcess.command = ["noctalia", "msg", "wallpaper-get", output];
        displayedProcess.running = true;
    }

    function parseTags() {
        const map = {};
        for (const line of tagsFile.text().split("\n")) {
            const [name, list] = line.split("\t");
            if (name)
                map[name] = (list || "").split(",").filter(tag => tag.length > 0);
        }
        tagsByName = map;
    }

    function apply(path) {
        history.record(path);
        Quickshell.execDetached(["theme", currentMode, path]);
    }

    Component.onCompleted: {
        parseTags();
        refresh();
    }

    History {
        id: history

        path: service.home + "/.local/state/wallpaper-history"
    }

    FileView {
        id: tagsFile

        path: service.directory + "/tags.tsv"
        blockLoading: true
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: service.parseTags()
    }

    Process {
        id: modeProcess

        command: ["darkman", "get"]
        stdout: StdioCollector {
            onStreamFinished: service.currentMode = this.text.trim() === "light" ? "light" : "dark"
        }
    }

    Process {
        id: displayedProcess

        stdout: StdioCollector {
            onStreamFinished: service.displayedPath = this.text.trim()
        }
        onExited: exitCode => {
            if (exitCode !== 0)
                console.warn("noctalia wallpaper-get failed with exit code", exitCode);
        }
    }

    Process {
        id: listProcess

        command: ["sh", "-c", "mkdir -p \"$2\" && fd -t f -a -e jpg -e jpeg -e png -e webp -e gif . \"$1\" | while read -r f; do t=\"$2/${f##*/}.jpg\"; [ -e \"$t\" ] || magick \"$f[0]\" -thumbnail 480x270^ -gravity center -extent 480x270 \"$t\"; echo \"$f\"; done", "sh", service.directory, service.thumbnails]
        stdout: StdioCollector {
            onStreamFinished: service.paths = this.text.split("\n").filter(line => line.length > 0)
        }
    }
}
