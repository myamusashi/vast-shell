import QtQuick

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base

StyledRect {
    id: root

    required property real value

    property alias         circleColor: indicatorEffect.activeColor
    property alias         text: styledText.text
    property real          textPadding: 20
    property alias         textSize: styledText.font.pixelSize

    implicitHeight: 100
    implicitWidth: 100

    ShaderEffect {
        id: indicatorEffect

        property color    activeColor: Colours.m3Colors.m3Primary
        property real     maxSweepDeg: 360
        property real     progress: Math.max(0, Math.min(1, root.value / 100))
        property real     radius: Math.max(0, Math.min(width, height) / 2 - 10)
        property vector2d resolution: Qt.vector2d(width, height)
        property real     startAngleDeg: -90
        property real     strokeWidth: 8
        property color    trackColor: Colours.m3Colors.m3OutlineVariant

        anchors.fill: parent
        blending: true
        fragmentShader: Paths.projectRoot + "/Assets/shaders/arcGauge.frag.qsb"
    }

    StyledText {
        id: styledText

        anchors.centerIn: parent
        color: Colours.m3Colors.m3OnSurface
        font.pixelSize: Appearance.fonts.size.medium
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        width: parent.width - root.textPadding * 2
        wrapMode: Text.WordWrap
    }
}
