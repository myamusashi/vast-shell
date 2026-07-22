import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Services

RowLayout {
    spacing: Appearance.spacing.normal

    StyledSlide {
        id: brightnessSlider

        Layout.fillWidth: true
        Layout.preferredHeight: 48

        icon: "brightness_5"
        iconSize: Appearance.fonts.size.large * 1.5
        to: Brightness.maxValue || 1

        value: brightnessSlider.pressed ? brightnessSlider.value : Brightness.value
        onMoved: Brightness.setBrightnessAll(brightnessSlider.value)
    }

    StyledButton {
        readonly property color inactiveTextColor: Qt.alpha(Colours.m3Colors.m3OnSurface, 0.38)
        readonly property color inactiveButtonColor: Qt.alpha(Colours.m3Colors.m3OnSurface, 0.1)

        icon.name: "bedtime"
        icon.color: Hyprsunset.isNightModeOn ? Colours.m3Colors.m3OnPrimary : inactiveTextColor
        textColor: Hyprsunset.isNightModeOn ? Colours.m3Colors.m3OnPrimary : inactiveTextColor
        color: Hyprsunset.isNightModeOn ? Colours.m3Colors.m3Primary : inactiveButtonColor
        text: qsTr("Night mode")

        onClicked: Hyprsunset.isNightModeOn ? Hyprsunset.down() : Hyprsunset.up()
    }
}
