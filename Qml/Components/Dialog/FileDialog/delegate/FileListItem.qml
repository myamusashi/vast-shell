import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base
import Vast.Utils

import "../../../Base"

Rectangle {
    id: root

    property var fileModified
    property alias fileName: fileName.text
    property string filePath: ""
    property int fileSize: 0
    property bool isFolder: false
    property bool isSelected: false
    property int itemIndex: 0
    property bool keyboardFocusable: true
    property real rowColorBlendProgress: 1.0
    property bool rowColorBlending: false
    property color rowColorFrom
    property color rowColorTo
    property color target: root.isSelected ? Qt.alpha(Colours.m3Colors.m3Primary, 0.3) : "transparent"

    signal clicked
    signal doubleClicked

    function getFileExtension(name, folder) {
        if (folder)
            return qsTr("Folder");
        var dot = name.lastIndexOf(".");
        return dot >= 0 ? name.substring(dot + 1).toUpperCase() + " " + qsTr("file") : qsTr("File");
    }
    function requestKeyboardFocus() {
        root.forceActiveFocus();
    }

    clip: true
    implicitHeight: 48

    Keys.onReturnPressed: event => {
        root.clicked();
        event.accepted = true;
    }
    Keys.onSpacePressed: event => {
        root.clicked();
        event.accepted = true;
    }
    onRowColorBlendProgressChanged: {
        if (!rowColorBlending)
            return;
        if (rowColorBlendProgress >= 1) {
            color = rowColorTo;
            rowColorBlending = false;
        } else if (rowColorBlendProgress > 0) {
            color = ColorUtils.blendColors(rowColorFrom, rowColorTo, rowColorBlendProgress);
        }
    }
    onTargetChanged: {
        rowColorAnim.stop();
        rowColorFrom = root.color;
        rowColorTo = target;
        rowColorBlending = true;
        rowColorBlendProgress = 0.0;
        rowColorAnim.start();
    }

    NAnim {
        id: rowColorAnim

        duration: Appearance.animations.durations.small
        from: 0.0
        property: "rowColorBlendProgress"
        target: root
        to: 1.0
    }
    Rectangle {
        anchors.fill: parent
        color: Colours.m3Colors.m3OnSurface
        opacity: !root.isSelected && (root.itemIndex % 2 !== 0) ? 0.03 : 0

        Behavior on opacity {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }
    }
    Rectangle {
        anchors.fill: parent
        border.color: Colours.m3Colors.m3Primary
        border.width: 2
        color: "transparent"
        visible: root.activeFocus

        Behavior on opacity {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }
    }
    RowLayout {
        spacing: Appearance.spacing.small

        anchors {
            fill: parent
            leftMargin: Appearance.margin.small
            rightMargin: Appearance.margin.normal
        }
        Icon {
            id: iconItem

            property real iconColorBlendProgress: 1.0
            property bool iconColorBlending: false
            property color iconColorFrom
            property color iconColorTo
            property color target: root.isSelected ? Colours.m3Colors.m3OnPrimaryContainer : (root.isFolder ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant)

            Layout.preferredWidth: 32
            font.pixelSize: Appearance.fonts.size.large
            icon: root.isFolder ? "folder" : "description"

            onIconColorBlendProgressChanged: {
                if (!iconColorBlending)
                    return;
                if (iconColorBlendProgress >= 1) {
                    color = iconColorTo;
                    iconColorBlending = false;
                } else if (iconColorBlendProgress > 0) {
                    color = ColorUtils.blendColors(iconColorFrom, iconColorTo, iconColorBlendProgress);
                }
            }
            onTargetChanged: {
                iconColorAnim.stop();
                iconColorFrom = iconItem.color;
                iconColorTo = target;
                iconColorBlending = true;
                iconColorBlendProgress = 0.0;
                iconColorAnim.start();
            }

            NAnim {
                id: iconColorAnim

                duration: Appearance.animations.durations.small
                from: 0.0
                property: "iconColorBlendProgress"
                target: iconItem
                to: 1.0
            }
        }
        StyledText {
            id: fileName

            property real nameColorBlendProgress: 1.0
            property bool nameColorBlending: false
            property color nameColorFrom
            property color nameColorTo
            property color target: root.isSelected ? Colours.m3Colors.m3OnPrimaryContainer : root.fileName.startsWith(".") ? Colours.m3Colors.m3OnSurfaceVariant : Colours.m3Colors.m3OnSurface

            Layout.fillWidth: true
            elide: Text.ElideRight
            font.pixelSize: Appearance.fonts.size.normal
            leftPadding: 2
            text: ""

            onNameColorBlendProgressChanged: {
                if (!nameColorBlending)
                    return;
                if (nameColorBlendProgress >= 1) {
                    color = nameColorTo;
                    nameColorBlending = false;
                } else if (nameColorBlendProgress > 0) {
                    color = ColorUtils.blendColors(nameColorFrom, nameColorTo, nameColorBlendProgress);
                }
            }
            onTargetChanged: {
                nameColorAnim.stop();
                nameColorFrom = fileName.color;
                nameColorTo = target;
                nameColorBlending = true;
                nameColorBlendProgress = 0.0;
                nameColorAnim.start();
            }

            NAnim {
                id: nameColorAnim

                duration: Appearance.animations.durations.small
                from: 0.0
                property: "nameColorBlendProgress"
                target: fileName
                to: 1.0
            }
        }
        StyledText {
            id: sizeText

            property real sizeColorBlendProgress: 1.0
            property bool sizeColorBlending: false
            property color sizeColorFrom
            property color sizeColorTo
            property color target: root.isSelected ? Colours.m3Colors.m3OnPrimaryContainer : Colours.m3Colors.m3OnSurfaceVariant

            Layout.preferredWidth: 76
            font.pixelSize: Appearance.fonts.size.small
            horizontalAlignment: Text.AlignRight
            text: root.isFolder ? "" : FormatTimeUtils.formatSize(root.fileSize)

            onSizeColorBlendProgressChanged: {
                if (!sizeColorBlending)
                    return;
                if (sizeColorBlendProgress >= 1) {
                    color = sizeColorTo;
                    sizeColorBlending = false;
                } else if (sizeColorBlendProgress > 0) {
                    color = ColorUtils.blendColors(sizeColorFrom, sizeColorTo, sizeColorBlendProgress);
                }
            }
            onTargetChanged: {
                sizeColorAnim.stop();
                sizeColorFrom = sizeText.color;
                sizeColorTo = target;
                sizeColorBlending = true;
                sizeColorBlendProgress = 0.0;
                sizeColorAnim.start();
            }

            NAnim {
                id: sizeColorAnim

                duration: Appearance.animations.durations.small
                from: 0.0
                property: "sizeColorBlendProgress"
                target: sizeText
                to: 1.0
            }
        }
        StyledText {
            id: extensionText

            property real extensionColorBlendProgress: 1.0
            property bool extensionColorBlending: false
            property color extensionColorFrom
            property color extensionColorTo
            property color target: root.isSelected ? Colours.m3Colors.m3OnPrimaryContainer : Colours.m3Colors.m3OnSurfaceVariant

            Layout.preferredWidth: 90
            elide: Text.ElideRight
            font.pixelSize: Appearance.fonts.size.small
            leftPadding: 10
            text: root.getFileExtension(root.fileName, root.isFolder)

            onExtensionColorBlendProgressChanged: {
                if (!extensionColorBlending)
                    return;
                if (extensionColorBlendProgress >= 1) {
                    color = extensionColorTo;
                    extensionColorBlending = false;
                } else if (extensionColorBlendProgress > 0) {
                    color = ColorUtils.blendColors(extensionColorFrom, extensionColorTo, extensionColorBlendProgress);
                }
            }
            onTargetChanged: {
                extensionColorAnim.stop();
                extensionColorFrom = extensionText.color;
                extensionColorTo = target;
                extensionColorBlending = true;
                extensionColorBlendProgress = 0.0;
                extensionColorAnim.start();
            }

            NAnim {
                id: extensionColorAnim

                duration: Appearance.animations.durations.small
                from: 0.0
                property: "extensionColorBlendProgress"
                target: extensionText
                to: 1.0
            }
        }
        StyledText {
            id: dateText

            property real dateColorBlendProgress: 1.0
            property bool dateColorBlending: false
            property color dateColorFrom
            property color dateColorTo
            property color target: root.isSelected ? Colours.m3Colors.m3OnPrimaryContainer : Colours.m3Colors.m3OnSurfaceVariant

            Layout.preferredWidth: 110
            font.pixelSize: Appearance.fonts.size.small
            leftPadding: 6
            text: Qt.formatDateTime(root.fileModified, "yyyy-MM-dd hh:mm")

            onDateColorBlendProgressChanged: {
                if (!dateColorBlending)
                    return;
                if (dateColorBlendProgress >= 1) {
                    color = dateColorTo;
                    dateColorBlending = false;
                } else if (dateColorBlendProgress > 0) {
                    color = ColorUtils.blendColors(dateColorFrom, dateColorTo, dateColorBlendProgress);
                }
            }
            onTargetChanged: {
                dateColorAnim.stop();
                dateColorFrom = dateText.color;
                dateColorTo = target;
                dateColorBlending = true;
                dateColorBlendProgress = 0.0;
                dateColorAnim.start();
            }

            NAnim {
                id: dateColorAnim

                duration: Appearance.animations.durations.small
                from: 0.0
                property: "dateColorBlendProgress"
                target: dateText
                to: 1.0
            }
        }
    }
    MArea {
        layerRadius: root.radius

        onClicked: root.clicked()
        onDoubleClicked: root.doubleClicked()
    }
}
