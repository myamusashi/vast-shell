import QtQuick
import QtQuick.Layouts
import Vast

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base

Item {
    id: root

    required property int index
    required property var entryId
    required property string type
    required property string preview
    required property bool pinned
    required property string sourceApp
    required property var timestamp
    required property bool isSelected

    readonly property bool isImage: root.type === "image"
    readonly property bool isFiles: root.type === "files"

    signal activated
    signal pinToggled(var id, bool pinned)
    signal removeRequested(var id)

    implicitWidth: parent?.width ?? 0
    implicitHeight: 64

    StyledRect {
        id: bg

        anchors {
            fill: parent
            margins: 2
        }
        radius: Appearance.rounding.small
        color: root.isSelected ? Qt.alpha(Colours.m3Colors.m3OnSurface, 0.08) : hoverHandler.hovered ? Qt.alpha(Colours.m3Colors.m3OnSurface, 0.04) : "transparent"

        Rectangle {
			anchors {
				left: parent.left
				leftMargin: 2
				verticalCenter: parent.verticalCenter
			}
			implicitWidth: 3
			implicitHeight: parent.height - Appearance.margin.large
			radius: 2
			color: Colours.m3Colors.m3Primary
            visible: root.pinned
        }

        RowLayout {
            anchors {
                fill: parent
                leftMargin: root.pinned ? Appearance.margin.large : Appearance.margin.normal
                rightMargin: Appearance.margin.smaller
                topMargin: Appearance.margin.small
                bottomMargin: Appearance.margin.small
            }
            spacing: Appearance.spacing.smaller

			StyledRect {
				Layout.alignment: Qt.AlignVCenter
				implicitWidth: 32
				implicitHeight: implicitWidth
                radius: Appearance.rounding.small
                color: typeColor()

                function typeColor(): color {
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

                Icon {
                    anchors.centerIn: parent
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
                    font.pixelSize: Appearance.fonts.size.large
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
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                StyledText {
                    Layout.fillWidth: true
                    text: root.isImage ? qsTr("Image") : root.isFiles ? qsTr("Files (%1)").arg(root.preview.split("\n").length) : root.preview || qsTr("(empty)")
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.medium
                    maximumLineCount: 2
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    elide: Text.ElideRight
                }

                RowLayout {
                    spacing: Appearance.spacing.small
                    visible: root.sourceApp !== ""

                    StyledText {
                        text: root.sourceApp
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.small
                        elide: Text.ElideRight
                        Layout.maximumWidth: 120
                    }

                    StyledText {
                        text: "·"
                        color: Colours.m3Colors.m3OutlineVariant
                        font.pixelSize: Appearance.fonts.size.small
                    }

                    StyledText {
                        text: formatTimestamp(root.timestamp)
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.small

                        function formatTimestamp(ms: var): string {
                            const d = new Date(ms);
                            const now = new Date();
                            const diff = now - d;

                            if (diff < 60000)
                                return qsTr("just now");
                            if (diff < 3600000)
                                return qsTr("%1m ago").arg(Math.floor(diff / 60000));
                            if (diff < 86400000)
                                return qsTr("%1h ago").arg(Math.floor(diff / 3600000));
                            return d.toLocaleDateString(Qt.locale(), Locale.ShortFormat);
                        }
                    }
                }
            }

            Item {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                Layout.alignment: Qt.AlignVCenter
                visible: hoverHandler.hovered || root.pinned
                opacity: pinHover.containsMouse ? 1.0 : 0.6

                Behavior on opacity {
                    NAnim {}
                }

                Icon {
                    anchors.centerIn: parent
                    icon: root.pinned ? "keep" : "keep_off"
                    font.pixelSize: Appearance.fonts.size.large
                    color: root.pinned ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant
                }

                MouseArea {
                    id: pinHover
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.pinToggled(root.entryId, !root.pinned)
                }
            }
        }
    }

    HoverHandler {
        id: hoverHandler
    }

    TapHandler {
        onTapped: root.activated()
        onDoubleTapped: ClipboardManager.copyToClipboard(root.entryId)
    }
}
