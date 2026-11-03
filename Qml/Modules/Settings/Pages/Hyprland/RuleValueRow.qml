pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Components.Button
import qs.Core.Configs
import qs.Services

import "../../Components"

SettingRow {
    id: root

    required property var descriptor
    required property var currentValue

    property var          pickValues: []
    property bool         showBadge: false

    signal                pickRequested
    signal                removed
    signal                valueChanged(var value)

    function              descriptionText(): string {
        const descriptor = root.descriptor;
        if (!descriptor)
            return "";
        const parts = [];
        if (descriptor.description !== undefined && descriptor.description !== "")
            parts.push(descriptor.description);
        if (descriptor.hint !== undefined && descriptor.hint !== "")
            parts.push(descriptor.hint);
        return parts.join(" · ");
    }

    description: descriptionText()

    Rectangle {
        Layout.alignment: Qt.AlignVCenter
        implicitHeight: badgeText.implicitHeight + 8
        implicitWidth: badgeText.implicitWidth + 12
        color: Colours.m3Colors.m3SurfaceContainerHighest
        radius: height / 2
        visible: root.showBadge && root.descriptor !== null

        StyledText {
            id: badgeText

            anchors.centerIn: parent
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.small
            text: root.descriptor?.dynamic ? qsTr("dynamic") : qsTr("static")
        }
    }

    SplitButton {
        id: pickButton

        visible: root.pickValues.length > 0
        text: qsTr("Pick from running")
        icon.name: "list_alt"
        model: root.pickValues.map(value => {
            return {
                text: value
            };
        })
        showScrollBar: true
        onClicked: {
            root.pickRequested();
            pickButton.openMenu();
        }
        onMenuItemActivated: index => root.valueChanged(root.pickValues[index])
    }

    RuleValueEditor {
        descriptor: root.descriptor
        value: root.currentValue
        onValueCommitted: value => root.valueChanged(value)
    }

    FloatingButton {
        size: "small"
        icon.name: "close"
        icon.color: Colours.m3Colors.m3OnSurfaceVariant
        onClicked: root.removed()
    }
}
