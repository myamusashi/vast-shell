import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Vast.Clipboard

import qs.Components.Button
import qs.Components.Base
import qs.Core.States
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

ItemDelegate {
    id: root

    required property var    entryId
    required property string fileName
    required property int    index
    required property bool   isSelected
    required property bool   pinned
    required property string preview
    required property string sourceApp
    required property var    timestamp
    required property string type

    readonly property string formattedTime: {
        const d    = new Date(timestamp);
        const now  = new Date();
        const diff = now - d;

        if (diff < 60000)
            return qsTr("just now");
        if (diff < 3600000)
            return qsTr("%1m ago").arg(Math.floor(diff / 60000));
        if (diff < 86400000)
            return qsTr("%1h ago").arg(Math.floor(diff / 3600000));
        return d.toLocaleDateString(Qt.locale(), Locale.ShortFormat);
    }
    readonly property bool   isFiles: type === "files"
    readonly property bool   isImage: type === "image"

    property bool            inVisual: false

    signal                   activated
    signal                   pinToggled(var id, bool pinned)
    signal                   removeRequested(var id)

    height: 64
    highlighted: isSelected
    hoverEnabled: true
    width: ListView.view?.width ?? parent?.width ?? 320
    background: Rectangle {
        color: root.inVisual && !root.isImage && !root.isFiles ? Qt.alpha(Colours.m3Colors.m3Primary, 0.15) : "transparent"
        radius: Appearance.rounding.small

        Rectangle {
            color: Colours.m3Colors.m3Primary
            implicitHeight: parent.height - Appearance.margin.large
            implicitWidth: 3
            radius: 2
            visible: root.pinned

            anchors {
                left: parent.left
                leftMargin: 2
                verticalCenter: parent.verticalCenter
            }
        }
    }
    contentItem: RowLayout {
        spacing: Appearance.spacing.smaller

        Item {
            Layout.preferredWidth: root.pinned ? Appearance.margin.large - Appearance.margin.normal : 0
        }

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            color: {
                switch (root.type) {
                case "image":
                    return Qt.alpha(Colours.m3Colors.m3Blue, 0.2);
                case "html":
                    return Qt.alpha(Colours.m3Colors.m3Tertiary, 0.2);
                case "files":
                    return Qt.alpha(Colours.m3Colors.m3Green, 0.2);
                default:
                    return Qt.alpha(Colours.m3Colors.m3OnSurface, 0.06);
                }
            }
            implicitHeight: 32
            implicitWidth: 32
            radius: Appearance.rounding.small

            Icon {
                anchors.centerIn: parent
                color: {
                    switch (root.type) {
                    case "image":
                        return Colours.m3Colors.m3Blue;
                    case "html":
                        return Colours.m3Colors.m3Tertiary;
                    case "files":
                        return Colours.m3Colors.m3Green;
                    default:
                        return Colours.m3Colors.m3OnSurface;
                    }
                }
                font.pixelSize: Appearance.fonts.size.large
                icon: {
                    switch (root.type) {
                    case "image":
                        return "image";
                    case "html":
                        return "code";
                    case "files":
                        return "folder";
                    default:
                        return "notes";
                    }
                }
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                readonly property int fileCount: root.isFiles ? root.preview.split("\n").length : 0

                Layout.fillWidth: true
                color: Colours.m3Colors.m3OnSurface
                elide: Text.ElideRight
                font.pixelSize: Appearance.fonts.size.medium
                maximumLineCount: 2
                text: root.isImage ? (root.fileName || qsTr("Image")) : root.isFiles ? qsTr("Files (%1)").arg(fileCount) : root.preview || qsTr("(empty)")
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            RowLayout {
                spacing: Appearance.spacing.small
                visible: root.sourceApp !== ""

                StyledText {
                    Layout.maximumWidth: 120
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.fonts.size.small
                    text: root.sourceApp
                }

                StyledText {
                    color: Colours.m3Colors.m3OutlineVariant
                    font.pixelSize: Appearance.fonts.size.small
                    text: "·"
                }

                StyledText {
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.small
                    text: root.formattedTime
                }
            }
        }

        FloatingButton {
            id: pinButton

            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 28
            Layout.preferredWidth: 28
            backgroundRadius: Appearance.rounding.normal
            color: "transparent"
            icon.color: root.pinned ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant
            icon.name: root.pinned ? "keep" : "keep_off"
            icon.size: Appearance.fonts.size.large
            opacity: pinButton.hovered ? 1.0 : 0.6
            visible: root.hovered || root.pinned
            Behavior on opacity {
                NAnim {}
            }
            onClicked: root.pinToggled(root.entryId, !root.pinned)
        }
    }
    onClicked: activated()

    TapHandler {
        onDoubleTapped: {
            ClipboardManager.copyToClipboard(root.entryId);
            if (!Configs.clipboard.keepOpenAfterCopy)
                GlobalStates.isClipboardOpen = false;
        }
    }
}
