import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

StyledRect {
    id: root

    property var optionData
    property int optionIndex
    property bool isSelected
    property int maxIndex

    signal executed
    signal indexModel(int newIndex)
    signal closed

    focus: root.isSelected

    function executeAction() {
        root.forceActiveFocus();
        root.optionData.action();
        root.executed();
    }

    Keys.onPressed: function (event) {
        switch (event.key) {
        case Qt.Key_Return:
        case Qt.Key_Enter:
            root.executeAction();
            GlobalStates.isScreenCapturePanelOpen = false;
            event.accepted = true;
            break;
        case Qt.Key_Escape:
            root.closed();
            event.accepted = true;
            break;
        case Qt.Key_Up:
            if (root.optionIndex > 0)
                root.indexModel(root.optionIndex - 1);
            event.accepted = true;
            break;
        case Qt.Key_Down:
            if (root.optionIndex < root.maxIndex)
                root.indexModel(root.optionIndex + 1);
            event.accepted = true;
            break;
        }
    }

    RowLayout {
        id: content

        anchors {
            fill: parent
            leftMargin: Appearance.spacing.small
            rightMargin: Appearance.spacing.small
        }
        spacing: Appearance.spacing.normal
        transform: Scale {
            origin.x: content.width / 2
            origin.y: content.height / 2
            xScale: root.isSelected ? 1.03 : 1.0
            yScale: root.isSelected ? 1.03 : 1.0

            Behavior on xScale {
                NAnim {
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }
            Behavior on yScale {
                NAnim {
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }
        }

        Icon {
            id: captureIcon
            property color _target: root.isSelected ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3Outline
            property color _cFrom
            property color _cTo
            property bool _cActive: false
            property real _cBlend: 1.0
            on_CBlendChanged: {
                if (!_cActive) return
                if (_cBlend >= 1) {
                    color = _cTo
                    _cActive = false
                } else if (_cBlend > 0) {
                    color = Colours.blendColors(_cFrom, _cTo, _cBlend)
                }
            }
            on_TargetChanged: {
                _cAnim.stop()
                _cFrom = color
                _cTo = _target
                _cActive = true
                _cBlend = 0.0
                _cAnim.start()
            }

            type: Icon.Material
            icon: root.optionData.icon
            font.pixelSize: Appearance.fonts.size.large
            Layout.alignment: Qt.AlignVCenter

            NumberAnimation {
                id: _cAnim
                target: captureIcon
                property: "_cBlend"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }

        StyledText {
            color: root.isSelected ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3Outline
            font.pixelSize: Appearance.fonts.size.normal
            font.weight: Font.DemiBold
            text: root.optionData.name
            Layout.fillWidth: true
        }
    }

    MArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: {
            root.executeAction();
            GlobalStates.isScreenCapturePanelOpen = false;
        }
        onEntered: root.forceActiveFocus()
    }
}
