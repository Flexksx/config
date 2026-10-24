import QtQuick

Rectangle {
    id: searchBar

    property string text: ""
    property string placeholder: ""
    property string trailingText: ""
    property list<Item> forwardTo

    signal edited(string text)
    signal accepted
    signal escaped
    signal tabbed(int step)

    function focusInput() {
        input.forceActiveFocus();
    }

    implicitHeight: 56
    radius: height / 2
    color: Theme.surface.container.high

    Icon {
        id: icon

        anchors.left: parent.left
        anchors.leftMargin: Theme.spacing5
        anchors.verticalCenter: parent.verticalCenter
        text: Icons.search
        font.pixelSize: 22
    }

    TextInput {
        id: input

        anchors.left: icon.right
        anchors.right: trailing.left
        anchors.leftMargin: Theme.spacing4
        anchors.rightMargin: Theme.spacing4
        anchors.verticalCenter: parent.verticalCenter
        text: searchBar.text
        color: Theme.surface.on
        selectionColor: Theme.primary.base
        selectedTextColor: Theme.primary.on
        font.family: Theme.fontFamily
        font.pixelSize: Theme.bodyLarge
        Keys.forwardTo: searchBar.forwardTo
        Keys.onEscapePressed: searchBar.escaped()
        Keys.onTabPressed: searchBar.tabbed(1)
        Keys.onBacktabPressed: searchBar.tabbed(-1)
        onTextEdited: searchBar.edited(text)
        onAccepted: searchBar.accepted()

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text.length === 0
            text: searchBar.placeholder
            color: Theme.surface.variant.on
            font: input.font
        }
    }

    Text {
        id: trailing

        anchors.right: parent.right
        anchors.rightMargin: Theme.spacing6
        anchors.verticalCenter: parent.verticalCenter
        text: searchBar.trailingText
        color: Theme.surface.variant.on
        font.family: Theme.fontFamily
        font.pixelSize: Theme.labelLarge
    }
}
