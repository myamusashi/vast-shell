import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base

Rectangle {
    id: root

    property alias text: textItem.text
    property alias iconName: iconItem.icon
    property int pageIndex: 0
    property bool isActive: pageIndex === settingsLoader.currentPage

    Layout.fillWidth: true
    Layout.preferredHeight: 48
    radius: height / 2
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
        target: root
        property: "_c0Blend"
        from: 0.0
        to: 1.0
    }

    property color _bgTarget: isActive ? Colours.m3Colors.m3SecondaryContainer : "transparent"

    on_BgTargetChanged: {
        _c0Anim.stop()
        _c0From = root.color
        _c0To = _bgTarget
        _c0Active = true
        _c0Blend = 0.0
        _c0Anim.start()
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: Appearance.margin.large
            rightMargin: Appearance.margin.large
        }
        spacing: Appearance.spacing.normal

        Icon {
            id: iconItem
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
                target: iconItem
                property: "_c1Blend"
                from: 0.0
                to: 1.0
            }

            font.pixelSize: Appearance.fonts.size.extraLarge
            layer.enabled: true
            layer.smooth: true

            property color _iconTarget: root.isActive ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant

            on_IconTargetChanged: {
                _c1Anim.stop()
                _c1From = iconItem.color
                _c1To = _iconTarget
                _c1Active = true
                _c1Blend = 0.0
                _c1Anim.start()
            }

            font.variableAxes: {
                "FILL": (area.containsPress || root.isActive) ? 1 : 0
            }

            rotation: area.containsPress ? 25 : area.containsMouse ? 15 : root.isActive ? 20 : 0

            transform: Rotation {
                id: flipRotation

                origin.x: iconItem.width / 2
                origin.y: iconItem.height / 2
                axis {
                    x: 0
                    y: 1
                    z: 0
                }
                angle: 0
            }

            states: State {
                name: "flipped"
                when: area.containsPress
                PropertyChanges {
                    target: flipRotation
                    angle: 180
                }
            }

            transitions: Transition {
                NAnim {
                    target: flipRotation
                    property: "angle"
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }

            Behavior on rotation {
                NAnim {
                    duration: Appearance.animations.durations.normal
                }
            }
        }

        StyledText {
            id: textItem
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
                target: textItem
                property: "_c2Blend"
                from: 0.0
                to: 1.0
            }

            Layout.fillWidth: true
            font.pixelSize: Appearance.fonts.size.normal
            font.bold: root.isActive

            property color _textTarget: root.isActive ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant

            on_TextTargetChanged: {
                _c2Anim.stop()
                _c2From = textItem.color
                _c2To = _textTarget
                _c2Active = true
                _c2Blend = 0.0
                _c2Anim.start()
            }
        }
    }

    MArea {
        id: area

        layerColor: "transparent"
        layerRadius: root.radius
        anchors.fill: parent
        onClicked: settingsLoader.currentPage = root.pageIndex

        Rectangle {
            id: hoverOverlay
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
                target: hoverOverlay
                property: "_c3Blend"
                from: 0.0
                to: 1.0
            }

            anchors.fill: parent
            radius: root.radius
            property color _hoverTarget: area.containsMouse && !root.isActive ? Qt.rgba(Colours.m3Colors.m3OnSurface.r, Colours.m3Colors.m3OnSurface.g, Colours.m3Colors.m3OnSurface.b, 0.08) : "transparent"

            on_HoverTargetChanged: {
                _c3Anim.stop()
                _c3From = hoverOverlay.color
                _c3To = _hoverTarget
                _c3Active = true
                _c3Blend = 0.0
                _c3Anim.start()
            }
        }
    }
}
