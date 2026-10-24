import QtQuick
import Quickshell.Wayland
import Quickshell.Widgets
import qs.libs

Item {
    id: preview

    required property var source
    required property string title
    required property string icon
    required property real decorationOpacity
    readonly property real borderWidth: 2
    readonly property real iconSize: 16
    readonly property real placeholderIconSize: 48
    readonly property bool hovered: pointer.containsMouse
    readonly property bool ready: capture.hasContent

    signal clicked

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusMd
        color: Theme.surface.container.base
        visible: !capture.hasContent

        AppIcon {
            anchors.centerIn: parent
            width: preview.placeholderIconSize
            height: preview.placeholderIconSize
            source: preview.icon
        }
    }

    ClippingRectangle {
        anchors.fill: parent
        radius: Theme.radiusMd
        color: "transparent"
        opacity: capture.hasContent ? 1 : 0

        ScreencopyView {
            id: capture

            readonly property real reduction: hasContent ? width / sourceSize.width : 1
            readonly property real mipLevel: Math.max(0, Math.floor(Math.log2(1 / reduction)))

            anchors.fill: parent
            captureSource: preview.source
            live: true
            layer.enabled: hasContent
            layer.textureSize: sourceSize
            layer.mipmap: true
            layer.smooth: true
            layer.effect: ShaderEffect {
                property vector2d sourcePixels: Qt.vector2d(capture.sourceSize.width, capture.sourceSize.height)
                property real level: capture.mipLevel

                fragmentShader: "shaders/downscale.frag.qsb"
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusMd
        color: "transparent"
        opacity: preview.decorationOpacity
        border.width: preview.borderWidth
        border.color: preview.hovered ? Theme.primary.base : Theme.outlineVariant

        Behavior on border.color {
            EffectColorAnimation {}
        }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: Theme.spacing2
        width: Math.min(preview.width, caption.implicitWidth + Theme.spacing3 * 2)
        height: Theme.spacing6
        radius: height / 2
        opacity: preview.decorationOpacity
        color: preview.hovered ? Theme.primary.base : Theme.surface.inverse.base

        Behavior on color {
            EffectColorAnimation {}
        }

        Row {
            id: caption

            anchors.centerIn: parent
            spacing: Theme.spacing2

            AppIcon {
                anchors.verticalCenter: parent.verticalCenter
                width: preview.iconSize
                height: preview.iconSize
                source: preview.icon
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, preview.width - Theme.spacing3 * 2 - preview.iconSize - caption.spacing)
                text: preview.title
                elide: Text.ElideRight
                color: preview.hovered ? Theme.primary.on : Theme.surface.inverse.on
                font.family: Theme.fontFamily
                font.pixelSize: Theme.bodySmall
            }
        }
    }

    MouseArea {
        id: pointer

        anchors.fill: parent
        hoverEnabled: true
        onClicked: preview.clicked()
    }
}
