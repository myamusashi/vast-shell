pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Components.Button
import qs.Components.Menu
import qs.Components.Tooltip
import qs.Core.Configs
import qs.Services

RowLayout {
    id: root

    required property var    currentValue
    required property var    descriptor

    readonly property bool   hasDynamicInfo: root.showBadge && root.descriptor !== null && root.descriptor !== undefined && root.descriptor.dynamic !== undefined
    readonly property string resolvedDescription: root.descriptionText()

    property string          label: ""
    property var             pickValues: []
    property bool            showBadge: false

    signal                   pickRequested
    signal                   removed
    signal                   valueChanged(var value)

    function                 descriptionText(): string {
        const currentDescriptor = root.descriptor;
        if (!currentDescriptor)
            return "";
        const parts = [];
        if (currentDescriptor.description !== undefined && currentDescriptor.description !== "")
            parts.push(currentDescriptor.description);
        if (currentDescriptor.hint !== undefined && currentDescriptor.hint !== "")
            parts.push(currentDescriptor.hint);
        return parts.join(" · ");
    }

    Layout.fillWidth: true
    spacing: Appearance.spacing.normal

    Item {
        id: labelArea

        Layout.alignment: Qt.AlignVCenter
        Layout.fillWidth: true
        Layout.minimumWidth: 140
        implicitHeight: labelColumn.implicitHeight

        ColumnLayout {
            id: labelColumn

            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
            }

            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                StyledText {
                    color: Colours.m3Colors.m3OnSurface
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.Medium
                    maximumLineCount: 1
                    text: root.label
                }

                RuleSummaryChip {
                    Layout.alignment: Qt.AlignVCenter
                    backgroundColor: Colours.m3Colors.m3SurfaceContainerHighest
                    contentColor: Colours.m3Colors.m3OnSurfaceVariant
                    text: root.descriptor?.dynamic ? qsTr("dynamic") : qsTr("static")
                    tooltipText: {
                        if (root.descriptor?.dynamic)
                            return qsTr("Dynamic — re-applied when matched properties change");
                        return qsTr("Static — applied once when the window opens");
                    }
                    visible: root.hasDynamicInfo
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            StyledText {
                Layout.fillWidth: true
                color: Qt.alpha(Colours.m3Colors.m3OnSurface, 0.58)
                elide: Text.ElideRight
                font.pixelSize: Appearance.fonts.size.small
                maximumLineCount: 1
                text: root.resolvedDescription
                visible: root.resolvedDescription !== ""
            }
        }

        Tooltip {
            anchorItem: labelArea
            enabled: root.resolvedDescription !== ""
            text: root.resolvedDescription
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
        spacing: Appearance.spacing.small

        Item {
            id: pickAnchor

            Layout.alignment: Qt.AlignVCenter
            implicitHeight: pickButton.implicitHeight
            implicitWidth: pickButton.implicitWidth
            visible: root.pickValues.length > 0

            FloatingButton {
                id: pickButton

                anchors.centerIn: parent
                color: Colours.m3Colors.m3SecondaryContainer
                icon.color: Colours.m3Colors.m3OnSecondaryContainer
                icon.name: "list_alt"
                size: "small"
                tooltipText: qsTr("Pick from running")
                onClicked: {
                    root.pickRequested();
                    pickMenu.open();
                }
            }

            DropdownMenu {
                id: pickMenu

                anchorItem: pickButton
                maxWidth: 280
                model: root.pickValues
                popupParent: pickAnchor
                showScrollBar: true
                width: 240
                onActivated: index => {
                    if (index >= 0 && index < root.pickValues.length)
                        root.valueChanged(root.pickValues[index]);
                }
            }
        }

        RuleValueEditor {
            descriptor: root.descriptor
            value: root.currentValue
            onValueCommitted: value => root.valueChanged(value)
        }

        FloatingButton {
            Layout.alignment: Qt.AlignVCenter
            color: "transparent"
            icon.color: Colours.m3Colors.m3OnSurfaceVariant
            icon.name: "close"
            size: "small"
            tooltipText: qsTr("Remove %1").arg(root.label)
            onClicked: root.removed()
        }
    }
}
