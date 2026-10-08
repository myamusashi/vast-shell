pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

WrapperItem {
    id: root

    signal goBack
    signal openFile(string path)

    clip: true

    ColumnLayout {
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
                    text: qsTr("Captures")
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

        GridView {
            id: gridView

            Layout.fillHeight: true
            Layout.fillWidth: true
            boundsBehavior: Flickable.StopAtBounds
            cellHeight: 96 + Appearance.spacing.small
            cellWidth: 104 + Appearance.spacing.small
            clip: true
            focus: true
            keyNavigationEnabled: true
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }
            delegate: StyledRect {
                id: delegateRoot

                required property int index
                required property var modelData

                color: gridView.currentIndex === index ? Qt.alpha(Colours.m3Colors.m3Primary, 0.15) : (delegateMouse.containsMouse ? Qt.alpha(Colours.m3Colors.m3Primary, 0.08) : "transparent")
                height: 96
                radius: Appearance.rounding.small
                width: 104

                Image {
                    id: thumbnail

                    anchors.centerIn: parent
                    asynchronous: true
                    cache: true
                    clip: true
                    fillMode: Image.PreserveAspectCrop
                    height: 80
                    source: delegateRoot.modelData.path ? "file://" + delegateRoot.modelData.path : ""
                    sourceSize: Qt.size(160, 160)
                    width: 88
                }

                Icon {
                    anchors.centerIn: parent
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.large
                    icon: "image"
                    type: Icon.Material
                    visible: thumbnail.status !== Image.Ready && thumbnail.status !== Image.Loading
                }

                MArea {
                    id: delegateMouse

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        gridView.currentIndex = delegateRoot.index;
                        root.openFile(delegateRoot.modelData.path);
                    }
                }
            }
            model: ScriptModel {
                values: [...ScreenCaptureHistory.screenshotFiles]
            }
            Keys.onDownPressed: {
                if (gridView.currentIndex < gridView.count - 1)
                    gridView.currentIndex++;
            }
            Keys.onLeftPressed: {
                if (gridView.currentIndex > 0)
                    gridView.currentIndex--;
            }
            Keys.onRightPressed: {
                if (gridView.currentIndex < gridView.count - 1)
                    gridView.currentIndex++;
            }
            Keys.onUpPressed: {
                if (gridView.currentIndex > 0)
                    gridView.currentIndex--;
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.normal
            text: qsTr("No captures yet")
            visible: gridView.count === 0
        }
    }
}
