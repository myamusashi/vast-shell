pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import M3Shapes

import qs.Core.Configs
import qs.Services
import qs.Components.Base

import "Markdown"

Pages {
    id: root

    content: Visibility {
    }

    component Visibility: Column {
        clip: true
        spacing: Appearance.spacing.normal

        anchors {
            fill: parent
            topMargin: 20
        }
        Header {
            icon: "visibility"
            title: qsTr("Visibility")

            onClicked: root.isOpen = false
        }
        ClippingRectangle {
            color: Colours.m3Colors.m3SurfaceContainer
            implicitHeight: parent.height * 0.1
            implicitWidth: parent.width
            radius: Appearance.rounding.normal

            Item {
                implicitHeight: parent.height
                implicitWidth: parent.width

                MaterialShape {
                    anchors.left: parent.left
                    anchors.leftMargin: -20
                    anchors.verticalCenter: parent.verticalCenter
                    color: Qt.lighter(Colours.m3Colors.m3OnPrimary, 1.1)
                    implicitHeight: parent.height * 2
                    implicitWidth: parent.height * 2
                    shape: MaterialShape.Cookie9Sided
                    z: 3
                }
                MaterialShape {
                    anchors.verticalCenter: parent.verticalCenter
                    color: Colours.m3Colors.m3OnPrimary
                    implicitHeight: parent.height * 2
                    implicitWidth: parent.height * 2
                    opacity: 0.8
                    shape: MaterialShape.Cookie9Sided
                    x: 10
                    z: 2
                }
                MaterialShape {
                    anchors.verticalCenter: parent.verticalCenter
                    color: Colours.m3Colors.m3OnPrimary
                    implicitHeight: parent.height * 2
                    implicitWidth: parent.height * 2
                    opacity: 0.6
                    shape: MaterialShape.Cookie9Sided
                    x: 30
                    z: 1
                }
            }
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Appearance.margin.large

                StyledText {
                    Layout.alignment: Qt.AlignCenter | Qt.AlignLeft
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.large
                    font.weight: Font.Bold
                    text: qsTr("Current conditions")
                }
                RowLayout {
                    Layout.alignment: Qt.AlignCenter | Qt.AlignLeft
                    implicitWidth: parent.width
                    spacing: Appearance.spacing.normal

                    StyledText {
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.extraLarge
                        font.weight: Font.Bold
                        text: parseInt(Weather.visibility)
                    }
                    StyledText {
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.extraLarge
                        font.weight: Font.DemiBold
                        text: "Km"
                    }
                }
                Item {
                    implicitHeight: parent.height
                }
            }
        }
        WrapperRectangle {
            color: Colours.m3Colors.m3Surface
            implicitHeight: description.contentHeight + 15
            implicitWidth: parent.width
            margin: 10
            radius: Appearance.rounding.normal

            border {
                color: Colours.m3Colors.m3Outline
                width: 1
            }
            StyledText {
                id: description

                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.normal
                text: DetailText.visibility
                textFormat: Text.MarkdownText
                wrapMode: Text.Wrap
            }
        }
    }
}
