pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Services

Item {
    id: root

    required property bool active

    implicitHeight: 44
    implicitWidth: draggingRowLayout.implicitWidth + 32

    RowLayout {
        id: draggingRowLayout

        anchors.centerIn: parent
        spacing: Appearance.spacing.normal
        visible: root.active

        Row {
            spacing: 5

            Repeater {
                model: 3

                delegate: Rectangle {
                    id: dot

                    required property int index
                    property int stagger: index * 90

                    color: Colours.m3Colors.m3Green
                    height: 8
                    radius: width / 2
                    width: 8

                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        running: root.active

                        PauseAnimation {
                            duration: dot.stagger
                        }
                        NAnim {
                            to: 0.55
                        }
                        NAnim {
                            to: 1
                        }
                    }
                }
            }
        }
        StyledText {
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.normal
            text: qsTr("Drop files here")
        }
    }
}
