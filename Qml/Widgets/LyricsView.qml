pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Vast.Lyrics
import Vast.Utils

import qs.Components.Base
import qs.Core.Configs
import qs.Services

Item {
    id: root

    property color activeColor: Colours.m3Colors.m3Primary
    property real  activeFontSize: 22
    property color inactiveColor: Colours.m3Colors.m3Secondary
    property real  inactiveFontSize: 20
    property alias listView: listView

    ListView {
        id: listView

        anchors.fill: parent
        cacheBuffer: 0
        clip: true
        model: LyricsProvider.lines
        spacing: 16
        delegate: Column {
            id: lineDelegate

            required property int  index
            required property var  modelData

            readonly property bool isActiveLine: index === LyricsProvider.currentLineIndex

            opacity: {
                if (!Lyrics.synced)
                    return 1.0;
                return isActiveLine ? 1.0 : 0.45;
            }
            scale: isActiveLine ? 1.0 : 0.9
            spacing: 4
            width: listView.width
            Behavior on opacity {
                NAnim {
                    duration: Math.max(150, LyricsProvider.currentWordDuration)
                    easing.bezierCurve: Appearance.animations.curves.emphasized
                }
            }
            Behavior on scale {
                NAnim {
                    duration: Math.max(200, LyricsProvider.currentWordDuration)
                    easing.bezierCurve: Appearance.animations.curves.emphasized
                }
            }

            Flow {
                spacing: 0
                width: parent.width

                Repeater {
                    model: lineDelegate.modelData.text
                    delegate: StyledText {
                        id: flowText

                        required property var modelData

                        property bool         flashInActive: false
                        property real         flashInBlend: 1.0
                        property color        flashInFrom
                        property color        flashInTo
                        property color        lyricTarget: lineDelegate.isActiveLine ? root.activeColor : root.inactiveColor

                        renderType: Text.QtRendering
                        style: Text.Raised
                        styleColor: Qt.alpha(Colours.m3Colors.m3Scrim, 0.5)
                        text: modelData
                        onFlashInBlendChanged: {
                            if (!flashInActive)
                                return;
                            if (flashInBlend >= 1) {
                                color         = flashInTo;
                                flashInActive = false;
                            } else if (flashInBlend > 0) {
                                color = ColorUtils.blendColors(flashInFrom, flashInTo, flashInBlend);
                            }
                        }
                        onLyricTargetChanged: {
                            flashInAnim.stop();
                            flashInFrom   = flowText.color;
                            flashInTo     = lyricTarget;
                            flashInActive = true;
                            flashInBlend  = 0.0;
                            flashInAnim.start();
                        }

                        NAnim {
                            id: flashInAnim

                            duration: Math.max(150, LyricsProvider.currentWordDuration)
                            easing.bezierCurve: Appearance.animations.curves.emphasized
                            from: 0.0
                            property: "flashInBlend"
                            target: flowText
                            to: 1.0
                        }

                        font {
                            family: "Noto Sans"
                            hintingPreference: Font.PreferNoHinting
                            kerning: true
                            pixelSize: Appearance.fonts.size.large
                            preferShaping: true
                            weight: Font.DemiBold
                        }
                    }
                }
            }

            StyledText {
                id: translationText

                property bool  flashOutActive: false
                property real  flashOutBlend: 1.0
                property color flashOutFrom
                property color flashOutTo
                property color translationTarget: lineDelegate.isActiveLine ? root.activeColor : root.inactiveColor

                Layout.fillWidth: true
                opacity: 0.7
                style: Text.Raised
                styleColor: Qt.alpha(Colours.m3Colors.m3Scrim, 0.5)
                text: `(${lineDelegate.modelData.translation})`
                visible: lineDelegate.modelData.translation !== ""
                wrapMode: Text.Wrap
                onFlashOutBlendChanged: {
                    if (!flashOutActive)
                        return;
                    if (flashOutBlend >= 1) {
                        color          = flashOutTo;
                        flashOutActive = false;
                    } else if (flashOutBlend > 0) {
                        color = ColorUtils.blendColors(flashOutFrom, flashOutTo, flashOutBlend);
                    }
                }
                onTranslationTargetChanged: {
                    flashOutAnim.stop();
                    flashOutFrom   = translationText.color;
                    flashOutTo     = translationTarget;
                    flashOutActive = true;
                    flashOutBlend  = 0.0;
                    flashOutAnim.start();
                }

                NAnim {
                    id: flashOutAnim

                    duration: Math.max(150, LyricsProvider.currentWordDuration)
                    easing.bezierCurve: Appearance.animations.curves.emphasized
                    from: 0.0
                    property: "flashOutBlend"
                    target: translationText
                    to: 1.0
                }

                font {
                    family: "Noto Sans"
                    hintingPreference: Font.PreferNoHinting
                    kerning: true
                    pixelSize: Appearance.fonts.size.normal
                    preferShaping: true
                    weight: Font.DemiBold
                }
            }
        }
        onCurrentIndexChanged: {
            if (currentIndex < 0)
                positionViewAtBeginning();
            else
                positionViewAtIndex(currentIndex, ListView.Center);
        }

        Binding {
            property: "currentIndex"
            target: listView
            value: LyricsProvider.currentLineIndex
        }

        Connections {
            function onLinesChanged() {
                listView.positionViewAtBeginning();
            }

            target: Lyrics
        }
    }
}
