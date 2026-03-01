import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

StyledRect {
    id: root

    Layout.alignment: Qt.AlignCenter

    implicitWidth: row.width
    visible: Record.isRecordingControlOpen
    color: "transparent"

    function formatTime(seconds) {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        const secs = seconds % 60;

        if (hours > 0)
            return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;

        return `${String(minutes).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
    }

    RowLayout {
        id: row

        anchors.centerIn: parent

        Item {
            id: iconStatus

            property bool isHovering: false
            property bool isRecording: false

            Layout.preferredWidth: 30
            Layout.preferredHeight: 30

            Behavior on scale {
                NAnim {
                    duration: Appearance.animations.durations.small
                }
            }

            Icon {
                id: recordIcon

                anchors.centerIn: parent
                type: Icon.Material
                icon: "screen_record"
                font.pixelSize: Appearance.fonts.size.large * 1.3
                color: Colours.m3Colors.m3OnPrimary
                opacity: iconStatus.isHovering ? 0 : 1
                scale: iconStatus.isHovering ? 0.5 : 1.0

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
                type: Icon.Material
                icon: "stop_circle"
                font.pixelSize: Appearance.fonts.size.large * 1.3
                color: Colours.m3Colors.m3OnPrimary
                opacity: iconStatus.isHovering ? 1 : 0
                scale: iconStatus.isHovering ? 1.0 : 0.5

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

                onTapped: {
                    iconStatus.isRecording = !iconStatus.isRecording;
                    ScreenCapture.exec("--stop-recording");
                }
            }
        }

        StyledText {
            text: root.formatTime(Record.recordingSeconds)
            color: Colours.m3Colors.m3OnBackground
            font.bold: true
        }
    }
}
