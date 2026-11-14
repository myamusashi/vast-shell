pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    required property QsMenuEntry modelData

    readonly property bool        hasLeadingIcon: (modelData?.icon ?? "") !== ""
    readonly property bool        isEnabled: modelData?.enabled ?? false
    readonly property bool        isSeparator: modelData?.isSeparator ?? false
    readonly property color       trailingIconColor: {
        if (!modelData)
            return "transparent";
        if (modelData.hasChildren)
            return Colours.m3Colors.m3OnSurfaceVariant;
        return modelData.checkState === Qt.Checked ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant;
    }
    readonly property string      trailingIconName: {
        if (!modelData)
            return "";
        if (modelData.hasChildren)
            return "chevron_right";
        if (modelData.buttonType === QsMenuButtonType.CheckBox)
            return modelData.checkState === Qt.Checked ? "check_box" : "check_box_outline_blank";
        if (modelData.buttonType === QsMenuButtonType.RadioButton)
            return modelData.checkState === Qt.Checked ? "radio_button_checked" : "radio_button_unchecked";
        return "";
    }

    signal                        clicked

    implicitHeight: isSeparator ? 1 : 44
    opacity: isSeparator || isEnabled ? 1 : 0.4

    Loader {
        anchors.fill: parent
        sourceComponent: root.isSeparator ? separatorComponent : entryComponent
    }

    Component {
        id: separatorComponent

        StyledRect {

            anchors {
                left: parent.left
                leftMargin: Appearance.margin.large
                right: parent.right
                rightMargin: Appearance.margin.large
                verticalCenter: parent.verticalCenter
            }

            color: Colours.m3Colors.m3OutlineVariant
            height: 1
            radius: 0
        }
    }

    Component {
        id: entryComponent

        Item {
            anchors.fill: parent

            RowLayout {

                anchors {
                    fill: parent
                    leftMargin: Appearance.margin.larger
                    rightMargin: Appearance.margin.larger
                }

                spacing: Appearance.spacing.normal

                Loader {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredHeight: 20
                    Layout.preferredWidth: 20
                    active: root.hasLeadingIcon
                    visible: active
                    sourceComponent: IconImage {
                        backer.cache: true
                        height: 20
                        source: root.modelData ? root.modelData.icon : ""
                        width: 20
                    }
                }

                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: true
                    color: Colours.m3Colors.m3OnSurface
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.Medium
                    text: root.modelData ? root.modelData.text : ""
                    verticalAlignment: Text.AlignVCenter
                }

                Loader {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredHeight: 20
                    Layout.preferredWidth: 20
                    active: root.trailingIconName !== ""
                    visible: active
                    sourceComponent: Icon {
                        color: root.trailingIconColor
                        font.pixelSize: Appearance.fonts.size.large
                        height: 20
                        icon: root.trailingIconName
                        width: 20
                    }
                }
            }

            MArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: root.isEnabled
                layerRadius: Appearance.rounding.small
                onClicked: root.clicked()
            }
        }
    }
}
