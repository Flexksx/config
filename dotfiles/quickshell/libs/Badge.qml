import QtQuick

Rectangle {
    id: badge

    property int count: 0
    property bool dot: false
    readonly property int maximum: 99
    readonly property real dotSize: Theme.spacing2
    readonly property bool counted: count > 0

    visible: counted || dot
    width: counted ? Math.max(height, label.implicitWidth + Theme.spacing2) : dotSize
    height: counted ? Theme.spacing4 : dotSize
    radius: height / 2
    color: Theme.error.base

    Text {
        id: label

        anchors.centerIn: parent
        visible: badge.counted
        text: badge.count > badge.maximum ? badge.maximum + "+" : badge.count
        color: Theme.error.on
        font.family: Theme.fontFamily
        font.pixelSize: Theme.labelSmall
        font.weight: Theme.weightBold
    }
}
