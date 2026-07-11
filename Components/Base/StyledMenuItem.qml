import AnotherRipple
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base

MenuItem {
    id: root

    property alias trailingIcon: trailingIconItem.icon

    implicitWidth: 200
    implicitHeight: 48

    background: Rectangle {
        id: bgRect
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
            target: bgRect
            property: "_c0Blend"
            from: 0.0
            to: 1.0
            duration: Appearance.animations.durations.small
            easing.bezierCurve: Appearance.animations.curves.standard
        }

        anchors {
            fill: parent
            leftMargin: Appearance.margin.small
            rightMargin: Appearance.margin.small
        }
        radius: Appearance.rounding.normal
        property color _bgTarget: root.highlighted ? Colours.m3Colors.m3SecondaryContainer : "transparent"

        on_BgTargetChanged: {
            _c0Anim.stop()
            _c0From = bgRect.color
            _c0To = _bgTarget
            _c0Active = true
            _c0Blend = 0.0
            _c0Anim.start()
        }

        Rectangle {
            id: innerRect
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
                target: innerRect
                property: "_c1Blend"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.small
            }

            anchors.fill: parent
            radius: parent.radius

            property color _innerTarget: trailingIconItem.icon === "" ? "transparent" : Colours.m3Colors.m3SurfaceContainerHighest

            on_InnerTargetChanged: {
                _c1Anim.stop()
                _c1From = innerRect.color
                _c1To = _innerTarget
                _c1Active = true
                _c1Blend = 0.0
                _c1Anim.start()
            }
        }
    }

    contentItem: RowLayout {
        implicitWidth: root.implicitWidth
        implicitHeight: root.implicitHeight

        StyledText {
            id: labelText
            property color _c2From
            property color _c2To
            property bool _c2Active: false
            property real _c2Blend: 1.0

            on_C2BlendChanged: {
                if (!_c2Active) return
                if (_c2Blend >= 1) {
                    color = _c2To
                    _c2Active = false
                } else if (_c2Blend > 0) {
                    color = Colours.blendColors(_c2From, _c2To, _c2Blend)
                }
            }

            NumberAnimation {
                id: _c2Anim
                target: labelText
                property: "_c2Blend"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.small
                easing.bezierCurve: Appearance.animations.curves.standard
            }

            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: Appearance.margin.normal

            text: root.text
            font.pixelSize: Appearance.fonts.size.normal
            font.weight: Font.Medium
            font.letterSpacing: 0.15
            elide: StyledText.ElideRight
            verticalAlignment: StyledText.AlignVCenter

            property color _labelTarget: root.highlighted ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurface

            on_LabelTargetChanged: {
                _c2Anim.stop()
                _c2From = labelText.color
                _c2To = _labelTarget
                _c2Active = true
                _c2Blend = 0.0
                _c2Anim.start()
            }
        }

        Item {
            Layout.alignment: Qt.AlignCenter
            implicitWidth: 30
            implicitHeight: 30

            Icon {
                id: checkIcon
                property color _c3From
                property color _c3To
                property bool _c3Active: false
                property real _c3Blend: 1.0

                on_C3BlendChanged: {
                    if (!_c3Active) return
                    if (_c3Blend >= 1) {
                        color = _c3To
                        _c3Active = false
                    } else if (_c3Blend > 0) {
                        color = Colours.blendColors(_c3From, _c3To, _c3Blend)
                    }
                }

                NumberAnimation {
                    id: _c3Anim
                    target: checkIcon
                    property: "_c3Blend"
                    from: 0.0
                    to: 1.0
                    duration: Appearance.animations.durations.small
                    easing.bezierCurve: Appearance.animations.curves.standard
                }

                anchors.centerIn: parent
                icon: "check_box_outline_blank"
                font.pixelSize: Appearance.fonts.size.large

                property color _checkTarget: root.highlighted ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant

                on_CheckTargetChanged: {
                    _c3Anim.stop()
                    _c3From = checkIcon.color
                    _c3To = _checkTarget
                    _c3Active = true
                    _c3Blend = 0.0
                    _c3Anim.start()
                }
            }

            Icon {
                id: trailingIconItem
                property color _c4From
                property color _c4To
                property bool _c4Active: false
                property real _c4Blend: 1.0

                on_C4BlendChanged: {
                    if (!_c4Active) return
                    if (_c4Blend >= 1) {
                        color = _c4To
                        _c4Active = false
                    } else if (_c4Blend > 0) {
                        color = Colours.blendColors(_c4From, _c4To, _c4Blend)
                    }
                }

                NumberAnimation {
                    id: _c4Anim
                    target: trailingIconItem
                    property: "_c4Blend"
                    from: 0.0
                    to: 1.0
                    duration: Appearance.animations.durations.small
                    easing.bezierCurve: Appearance.animations.curves.standard
                }

                anchors.centerIn: parent
                icon: ""
                font.pixelSize: Appearance.fonts.size.large

                property color _trailTarget: root.highlighted ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant
                visible: root.trailingIcon !== ""

                on_TrailTargetChanged: {
                    _c4Anim.stop()
                    _c4From = trailingIconItem.color
                    _c4To = _trailTarget
                    _c4Active = true
                    _c4Blend = 0.0
                    _c4Anim.start()
                }
            }
        }
    }

    SimpleRipple {
        anchors {
            fill: parent
            leftMargin: Appearance.margin.small
            rightMargin: Appearance.margin.small
        }
        color: Colours.m3Colors.m3OnSurface
        xClipRadius: Appearance.rounding.normal
        yClipRadius: Appearance.rounding.normal
    }
}
