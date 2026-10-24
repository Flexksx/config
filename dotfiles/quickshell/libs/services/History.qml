import QtQuick
import Quickshell.Io

FileView {
    property var counts: ({})
    property string last: ""

    function parse() {
        const lines = text().split("\n").filter(line => line.length > 0);
        const tally = {};
        for (const line of lines)
            tally[line] = (tally[line] || 0) + 1;
        counts = tally;
        last = lines[lines.length - 1] ?? "";
    }

    function record(value) {
        setText(text() + value + "\n");
        parse();
    }

    blockLoading: true
    printErrors: false
    Component.onCompleted: parse()
}
