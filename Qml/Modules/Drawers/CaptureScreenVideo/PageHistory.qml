pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

StyledRect {
    id: root

    signal goBack
    signal openFile(string path)

    clip: true
    color: "transparent"
    radius: 0

    ColumnLayout {
        anchors.fill: parent
        spacing: Appearance.spacing.small

        StyledRect {
            Layout.fillWidth: true
            Layout.preferredHeight: Appearance.margin.normal + Appearance.fonts.size.normal
            color: "transparent"
            radius: Appearance.rounding.small

            RowLayout {
                spacing: Appearance.spacing.small

                anchors {
                    fill: parent
                    leftMargin: Appearance.spacing.small
                }
                Icon {
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.large
                    icon: "arrow_back"
                    type: Icon.Material
                }
                StyledText {
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.DemiBold
                    text: qsTr("Recordings")
                }
                Item {
                    Layout.fillWidth: true
                }
            }
            MArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                onClicked: root.goBack()
            }
        }
        ListView {
            id: listView

            Layout.fillHeight: true
            Layout.fillWidth: true
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            focus: true
            keyNavigationEnabled: true
            spacing: Appearance.spacing.small

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }
            delegate: StyledRect {
                id: delegateRoot

                required property int index
                required property var modelData
                property alias thumbLoader: thumbLoader

                color: listView.currentIndex === index ? Qt.alpha(Colours.m3Colors.m3Primary, 0.15) : (delegateMouse.containsMouse ? Qt.alpha(Colours.m3Colors.m3Primary, 0.08) : "transparent")
                height: 56
                radius: Appearance.rounding.small
                width: listView.width

                Component.onCompleted: ThumbnailQueue.generate(modelData.path, ThumbnailQueue.pathFor(modelData.path, Paths.cacheDir + "/video-thumbnails"), null)

                Connections {
                    function onThumbnailReady(videoPath, thumbnailPath) {
                        if (videoPath !== delegateRoot.modelData.path)
                            return;
                        thumbLoader.thumbPath = thumbnailPath ? "file://" + thumbnailPath : "";
                    }

                    target: ThumbnailQueue
                }
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Appearance.margin.small
                    spacing: Appearance.spacing.small

                    Loader {
                        id: thumbLoader

                        property string thumbPath: ""

                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredHeight: 40
                        Layout.preferredWidth: 40

                        sourceComponent: StyledRect {
                            color: Colours.m3Colors.m3PrimaryContainer
                            implicitHeight: 40
                            implicitWidth: 40
                            radius: Appearance.rounding.small

                            Image {
                                id: thumbImage

                                anchors.centerIn: parent
                                asynchronous: true
                                cache: true
                                fillMode: Image.PreserveAspectCrop
                                height: 40
                                source: thumbLoader.thumbPath
                                sourceSize: Qt.size(40, 40)
                                width: 40
                            }
                            Icon {
                                anchors.centerIn: parent
                                color: Colours.m3Colors.m3OnPrimaryContainer
                                font.pixelSize: 20
                                icon: "play_circle"
                                type: Icon.Material
                                visible: thumbImage.status !== Image.Ready && thumbImage.status !== Image.Loading
                            }
                        }
                    }
                    ColumnLayout {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillWidth: true
                        spacing: 2

                        StyledText {
                            Layout.fillWidth: true
                            color: listView.currentIndex === delegateRoot.index ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurface
                            elide: Text.ElideRight
                            font.pixelSize: Appearance.fonts.size.normal
                            font.weight: Font.Medium
                            text: delegateRoot.modelData.name
                        }
                        StyledText {
                            color: Colours.m3Colors.m3OnSurfaceVariant
                            font.pixelSize: Appearance.fonts.size.small
                            text: {
                                const ts = delegateRoot.modelData.created;
                                const d = new Date(ts * 1000);
                                return d.toLocaleString("en-US", {
                                    month: "short",
                                    day: "numeric",
                                    hour: "numeric",
                                    minute: "2-digit"
                                });
                            }
                        }
                    }
                    Icon {
                        Layout.alignment: Qt.AlignVCenter
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.medium
                        icon: "open_in_new"
                        type: Icon.Material

                        MArea {
                            anchors.fill: parent
                            anchors.margins: -5
                            cursorShape: Qt.PointingHandCursor

                            onClicked: root.openFile(delegateRoot.modelData.path)
                        }
                    }
                }
                MArea {
                    id: delegateMouse

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onClicked: {
                        listView.currentIndex = delegateRoot.index;
                        root.openFile(delegateRoot.modelData.path);
                    }
                }
            }
            model: ScriptModel {
                values: [...ScreenCaptureHistory.screenrecordFiles]
            }

            Keys.onDownPressed: {
                if (listView.currentIndex < listView.count - 1)
                    listView.currentIndex++;
            }
            Keys.onReturnPressed: {
                const item = listView.model.get ? listView.model.get(listView.currentIndex) : listView.model[listView.currentIndex];
                if (item)
                    root.openFile(item.path);
            }
            Keys.onUpPressed: {
                if (listView.currentIndex > 0)
                    listView.currentIndex--;
            }
        }
    }
}
