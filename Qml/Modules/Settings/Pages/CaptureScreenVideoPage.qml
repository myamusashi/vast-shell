import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Components.Base
import qs.Components.Button
import qs.Services.CaptureScreenVideo

import "../Components"

SettingsPageBase {
    pageTitle: qsTr("Screen Recorder")

    SettingsCard {
        title: qsTr("Recording")

        GridLayout {
            columns: 2

            SettingRow {
                description: qsTr("Target frames per second for screen recordings.")
                label: qsTr("Frame Rate")

                SplitButton {
                    readonly property int selectedIndex: model.findIndex(entry => entry.value === Configs.captureScreenVideo.maxFps)

                    currentIndex: selectedIndex
                    icon.name: "autofps_select"
                    model: [
                        {
                            display: "30 FPS",
                            value: 30
                        },
                        {
                            display: "60 FPS",
                            value: 60
                        },
                        {
                            display: "120 FPS",
                            value: 120
                        }
                    ]
                    text: model[selectedIndex]?.display ?? ""
                    textRole: "display"
                    onMenuItemActivated: index => {
                        Configs.captureScreenVideo.maxFps = model[index].value;
                        CaptureScreenVideo.maxFps         = model[index].value;
                    }
                }
            }

            SettingRow {
                description: qsTr("Encoding quality preset for recordings. Higher presets increase sharpness and file size.")
                label: qsTr("Quality")

                SplitButton {
                    readonly property int selectedIndex: model.findIndex(entry => entry.value === Configs.captureScreenVideo.quality)

                    currentIndex: selectedIndex
                    icon.name: "shutter_speed"
                    model: [
                        {
                            display: qsTr("Medium"),
                            value: "medium"
                        },
                        {
                            display: qsTr("High"),
                            value: "high"
                        },
                        {
                            display: qsTr("Very High"),
                            value: "very_high"
                        },
                        {
                            display: qsTr("Ultra"),
                            value: "ultra"
                        }
                    ]
                    text: model[selectedIndex]?.display ?? ""
                    textRole: "display"
                    onMenuItemActivated: index => {
                        Configs.captureScreenVideo.quality = model[index].value;
                        CaptureScreenVideo.quality         = model[index].value;
                    }
                }
            }

            SettingRow {
                description: qsTr("Encoder for the video stream.")
                label: qsTr("Video Codec")

                SplitButton {
                    readonly property int selectedIndex: model.findIndex(entry => entry.value === Configs.captureScreenVideo.videoCodec)

                    currentIndex: selectedIndex
                    icon.name: "hd"
                    model: [
                        {
                            display: "Auto",
                            value: ""
                        },
                        {
                            display: "H.264",
                            value: "h264"
                        },
                        {
                            display: "HEVC",
                            value: "hevc"
                        },
                        {
                            display: "VP8",
                            value: "vp8"
                        },
                        {
                            display: "VP9",
                            value: "vp9"
                        },
                        {
                            display: "AV1",
                            value: "av1"
                        }
                    ]
                    text: model[selectedIndex]?.display ?? ""
                    textRole: "display"
                    onMenuItemActivated: index => {
                        Configs.captureScreenVideo.videoCodec = model[index].value;
                        CaptureScreenVideo.videoCodec         = model[index].value;
                    }
                }
            }

            SettingRow {
                description: qsTr("Encoder for the audio stream.")
                label: qsTr("Audio Codec")

                SplitButton {
                    readonly property int selectedIndex: model.findIndex(entry => entry.value === Configs.captureScreenVideo.audioCodec)

                    currentIndex: selectedIndex
                    icon.name: "hd"
                    model: [
                        {
                            display: "Auto",
                            value: ""
                        },
                        {
                            display: "AAC",
                            value: "aac"
                        },
                        {
                            display: "MP3",
                            value: "mp3"
                        },
                        {
                            display: "Opus",
                            value: "opus"
                        }
                    ]
                    text: model[selectedIndex]?.display ?? ""
                    textRole: "display"
                    onMenuItemActivated: index => {
                        Configs.captureScreenVideo.audioCodec = model[index].value;
                        CaptureScreenVideo.audioCodec         = model[index].value;
                    }
                }
            }
        }

        SettingRow {
            description: qsTr("Include the mouse cursor in the recording.")
            label: qsTr("Show Cursor")

            StyledSwitch {
                checked: Configs.captureScreenVideo.showCursor
                onCheckedChanged: {
                    Configs.captureScreenVideo.showCursor = checked;
                    CaptureScreenVideo.showCursor         = checked;
                }
            }
        }

        SettingRow {
            description: qsTr("Allow the GPU to enter a lower power state while recording (AMD only).")
            label: qsTr("Low Power Mode")

            StyledSwitch {
                checked: Configs.captureScreenVideo.lowPower
                onCheckedChanged: {
                    Configs.captureScreenVideo.lowPower = checked;
                    CaptureScreenVideo.lowPower         = checked;
                }
            }
        }
    }
}
