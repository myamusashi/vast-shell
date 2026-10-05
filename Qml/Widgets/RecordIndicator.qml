import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Services.CaptureScreenVideo

StyledRect {
    id: root

    Layout.alignment: Qt.AlignCenter
    color: "transparent"
    implicitWidth: row.width
    visible: CaptureScreenVideo.isRecording

    RowLayout {
        id: row

        anchors.centerIn: parent

        Item {
            id: iconStatus

            property bool isHovering: false

            Layout.preferredHeight: 30
            Layout.preferredWidth: 30

            Behavior on scale {
                NAnim {
                    duration: Appearance.animations.durations.small
                }
            }

            Icon {
                id: recordIcon

                anchors.centerIn: parent
                color: Colours.m3Colors.m3OnPrimary
                font.pixelSize: Appearance.fonts.size.large * 1.3
                icon: "screen_record"
                opacity: iconStatus.isHovering ? 0 : 1
                scale: iconStatus.isHovering ? 0.5 : 1.0
                type: Icon.Material

                Behavior on opacity {
                    NAnim {
                        duration: Appearance.animations.durations.small
                    }
                }
                Behavior on scale {
                    NAnim {
                        duration: Appearance.animations.durations.small
                    }
                }
            }
            Icon {
                id: stopIcon

                anchors.centerIn: parent
                color: Colours.m3Colors.m3OnPrimary
                font.pixelSize: Appearance.fonts.size.large * 1.3
                icon: "stop_circle"
                opacity: iconStatus.isHovering ? 1 : 0
                scale: iconStatus.isHovering ? 1.0 : 0.5
                type: Icon.Material

                Behavior on opacity {
                    NAnim {
                        duration: Appearance.animations.durations.small
                    }
                }
                Behavior on scale {
                    NAnim {
                        duration: Appearance.animations.durations.small
                    }
                }
            }
            HoverHandler {
                id: hoverArea

                cursorShape: Qt.PointingHandCursor

                onHoveredChanged: {
                    if (hovered)
                        iconStatus.isHovering = true;
                    else
                        iconStatus.isHovering = false;
                }
            }
            TapHandler {
                id: tapHandler

                onTapped: CaptureScreenVideo.stopRecording()
            }
        }
        StyledText {
            color: Colours.m3Colors.m3OnBackground
            font.bold: true
            text: FormatTimeUtils.formatDuration(CaptureScreenVideo.recordingElapsedSeconds)
        }
    }
}
