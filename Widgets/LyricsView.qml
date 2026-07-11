pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Vast

import qs.Core.Configs
import qs.Services
import "../Components/Base"

Item {
    id: root

    property alias listView: listView
    property color activeColor: Colours.m3Colors.m3Primary
    property color inactiveColor: Colours.m3Colors.m3Secondary
    property real activeFontSize: 22
    property real inactiveFontSize: 20

    ListView {
        id: listView

        anchors.fill: parent
        model: LyricsProvider.lines
        spacing: 16
        clip: true
        cacheBuffer: 0
        onCurrentIndexChanged: {
            if (currentIndex < 0)
                positionViewAtBeginning();
            else
                positionViewAtIndex(currentIndex, ListView.Center);
        }

        Binding {
            target: listView
            property: "currentIndex"
            value: LyricsProvider.currentLineIndex
        }

        Connections {
            target: Lyrics

            function onLinesChanged() {
                listView.positionViewAtBeginning();
            }
        }

        delegate: Column {
            id: lineDelegate

            required property var modelData
            required property int index
            readonly property bool isActiveLine: index === LyricsProvider.currentLineIndex

            width: listView.width
            spacing: 4

            scale: isActiveLine ? 1.0 : 0.9
            opacity: {
                if (!Lyrics.synced)
                    return 1.0;
                return isActiveLine ? 1.0 : 0.45;
            }

            Behavior on scale {
                NAnim {
                    duration: Math.max(200, LyricsProvider.currentWordDuration)
                    easing.bezierCurve: Appearance.animations.curves.emphasized
                }
            }
            Behavior on opacity {
                NAnim {
                    duration: Math.max(150, LyricsProvider.currentWordDuration)
                    easing.bezierCurve: Appearance.animations.curves.emphasized
                }
            }

            Flow {
                width: parent.width
                spacing: 0

                Repeater {
                    model: lineDelegate.modelData.text

                    delegate: StyledText {
                        required property var modelData
                        property color _c0From
                        property color _c0To
                        property bool _c0Active: false
                        property real _c0Blend: 1.0

                        on_C0BlendChanged: {
                            if (!_c0Active) return
                            if (_c0Blend >= 1) {
                                color = _c0To
                                _c0Active = false
                            } else if (_c0Blend > 0) {
                                color = Colours.blendColors(_c0From, _c0To, _c0Blend)
                            }
                        }

                        NumberAnimation {
                            id: _c0Anim
                            target: parent
                            property: "_c0Blend"
                            from: 0.0
                            to: 1.0
                            duration: Math.max(150, LyricsProvider.currentWordDuration)
                            easing.bezierCurve: Appearance.animations.curves.emphasized
                        }

                        text: modelData
                        font {
                            pixelSize: Appearance.fonts.size.large
                            weight: Font.DemiBold
                            family: "Noto Sans"
                            hintingPreference: Font.PreferNoHinting
                            kerning: true
                            preferShaping: true
                        }
                        property color _lyricTarget: lineDelegate.isActiveLine ? root.activeColor : root.inactiveColor
                        renderType: Text.QtRendering
                        style: Text.Raised
                        styleColor: "#80000000"

                        on_LyricTargetChanged: {
                            _c0Anim.stop()
                            _c0From = parent.color
                            _c0To = _lyricTarget
                            _c0Active = true
                            _c0Blend = 0.0
                            _c0Anim.start()
                        }
                    }
                }
            }

            StyledText {
                id: translationText
                property color _c1From
                property color _c1To
                property bool _c1Active: false
                property real _c1Blend: 1.0

                on_C1BlendChanged: {
                    if (!_c1Active) return
                    if (_c1Blend >= 1) {
                        color = _c1To
                        _c1Active = false
                    } else if (_c1Blend > 0) {
                        color = Colours.blendColors(_c1From, _c1To, _c1Blend)
                    }
                }

                NumberAnimation {
                    id: _c1Anim
                    target: translationText
                    property: "_c1Blend"
                    from: 0.0
                    to: 1.0
                    duration: Math.max(150, LyricsProvider.currentWordDuration)
                    easing.bezierCurve: Appearance.animations.curves.emphasized
                }

                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: `(${lineDelegate.modelData.translation})`
                visible: lineDelegate.modelData.translation !== ""
                font {
                    pixelSize: Appearance.fonts.size.normal
                    weight: Font.DemiBold
                    family: "Noto Sans"
                    hintingPreference: Font.PreferNoHinting
                    kerning: true
                    preferShaping: true
                }
                property color _transTarget: lineDelegate.isActiveLine ? root.activeColor : root.inactiveColor
                style: Text.Raised
                styleColor: "#80000000"
                opacity: 0.7

                on_TransTargetChanged: {
                    _c1Anim.stop()
                    _c1From = translationText.color
                    _c1To = _transTarget
                    _c1Active = true
                    _c1Blend = 0.0
                    _c1Anim.start()
                }
            }
        }
    }
}
