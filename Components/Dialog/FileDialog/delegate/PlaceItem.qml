import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Core.Utils
import qs.Services

import "../../../Base"

StyledRect {
    id: root

    required property string icon
    required property string label
    required property bool isSelected

    signal clicked

    implicitHeight: 48
    radius: Appearance.rounding.small
    clip: true
    color: isSelected ? Colours.m3Colors.m3SecondaryContainer : "transparent"

    RowLayout {
        anchors {
            fill: parent
            leftMargin: Appearance.margin.normal
            rightMargin: Appearance.margin.small
        }
        spacing: Appearance.spacing.normal

        Icon {
            id: iconItem
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
                target: iconItem
                property: "_c0Blend"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.small
            }

            property color _target: root.isSelected ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant
            on_TargetChanged: {
                _c0Anim.stop()
                _c0From = iconItem.color
                _c0To = _target
                _c0Active = true
                _c0Blend = 0.0
                _c0Anim.start()
            }

            icon: root.icon
            font.pixelSize: Appearance.fonts.size.large
        }

        StyledText {
            id: label
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
                target: label
                property: "_c1Blend"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.small
            }

            property color _target: root.isSelected ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant
            on_TargetChanged: {
                _c1Anim.stop()
                _c1From = label.color
                _c1To = _target
                _c1Active = true
                _c1Blend = 0.0
                _c1Anim.start()
            }

            text: root.label
            font.pixelSize: Appearance.fonts.size.normal
            font.bold: root.isSelected
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
    }

    MArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
