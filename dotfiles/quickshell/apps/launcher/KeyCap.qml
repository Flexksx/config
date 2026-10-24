import QtQuick
import QtQuick.Effects
import qs.libs

Rectangle {
    id: keyCap

    property string letter: ""
    property var app: null
    property bool selected: false
    property int order: 0
    readonly property int rippleDelay: 12
    readonly property bool hanging: app !== null && !app.open
    readonly property color ink: selected ? Theme.primary.on : mouse.containsMouse ? Theme.secondaryContainer.on : Theme.surface.on

    signal clicked

    radius: Theme.radiusMd
    color: selected ? Theme.primary.base : mouse.containsMouse ? Theme.secondaryContainer.base : hanging ? Theme.surface.container.high : "transparent"
    border.width: hanging || selected ? 0 : 1
    border.color: Theme.outlineVariant
    scale: mouse.pressed ? 0.96 : 1
    transform: Rotation {
        id: flap

        origin.x: keyCap.width / 2
        origin.y: keyCap.height / 2
        axis.x: 1
        axis.y: 0
        axis.z: 0
    }
    onAppChanged: flip.restart()

    SequentialAnimation {
        id: flip

        PropertyAction {
            target: flap
            property: "angle"
            value: -90
        }
        PauseAnimation {
            duration: keyCap.order * keyCap.rippleDelay
        }
        SpatialAnimation {
            target: flap
            property: "angle"
            to: 0
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: Theme.durationFast
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Theme.durationFast
        }
    }

    Label {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: Theme.spacing2
        text: keyCap.letter
        color: keyCap.selected || mouse.containsMouse ? keyCap.ink : keyCap.app ? Theme.primary.base : Theme.outline
        font.weight: Theme.weightBold
    }

    Label {
        visible: keyCap.app?.open ?? false
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Theme.spacing2
        text: "out"
        color: keyCap.selected || mouse.containsMouse ? keyCap.ink : Theme.outline
    }

    Image {
        id: icon

        visible: keyCap.app !== null
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -Theme.spacing1
        width: Math.min(parent.width, parent.height) * 0.4
        height: width
        source: keyCap.app?.icon ?? ""
        sourceSize.width: 96
        sourceSize.height: 96
        asynchronous: true
        layer.enabled: keyCap.app?.open ?? false
        layer.effect: MultiEffect {
            brightness: 1
            colorization: 1
            colorizationColor: keyCap.selected || mouse.containsMouse ? keyCap.ink : Theme.outlineVariant
        }
    }

    Text {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.spacing2
        text: keyCap.app?.name ?? ""
        elide: Text.ElideRight
        color: keyCap.hanging || keyCap.selected || mouse.containsMouse ? keyCap.ink : Theme.outline
        font.family: Theme.fontFamily
        font.pixelSize: Theme.labelMedium
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        enabled: keyCap.app !== null
        hoverEnabled: true
        onClicked: keyCap.clicked()
    }
}
