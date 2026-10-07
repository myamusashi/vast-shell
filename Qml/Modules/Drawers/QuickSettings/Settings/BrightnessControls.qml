pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Button
import qs.Components.Base
import qs.Core.Configs
import qs.Services

RowLayout {
    id: root

    readonly property bool multiDisplay: Brightness.displays.length > 1
    readonly property var  selectedDisplay: Brightness.displays.find(d => d.id === targetId) ?? null
    readonly property int  selectedIndex: targets.findIndex(t => t.value === targetId)
    readonly property var  targets: multiDisplay ? [
        {
            display: qsTr("All"),
            value: ""
        },
        ...Brightness.displays.map(d => ({
                    display: d.isInternal ? qsTr("Internal") : String(d.name).split(" ")[0],
                    value: d.id
                }))] : []

    property string        targetId: ""

    spacing: Appearance.spacing.normal

    Connections {
        function onDisplaysChanged() {
            if (root.targetId !== "" && !root.selectedDisplay)
                root.targetId = "";
        }

        target: Brightness
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 55
        color: "transparent"
        radius: Appearance.rounding.small

        border {
            color: Colours.m3Colors.m3Outline
            width: 2
        }

        RowLayout {

            anchors {
                fill: parent
                leftMargin: Appearance.margin.small
                rightMargin: Appearance.margin.small
            }

            StyledSlide {
                id: brightnessSlider

                Layout.fillWidth: true
                Layout.preferredHeight: 45
                icon: "brightness_5"
                iconSize: Appearance.fonts.size.large * 1.5
                to: Brightness.maxValue || 1
                value: brightnessSlider.pressed ? brightnessSlider.value : (root.selectedDisplay?.brightness ?? Brightness.value)
                onMoved: {
                    if (root.targetId === "")
                        Brightness.setBrightnessAll(brightnessSlider.value);
                    else
                        Brightness.setBrightnessForDisplay(root.targetId, brightnessSlider.value);
                }
            }

            SplitButton {
                id: splitButton

                Layout.alignment: Qt.AlignVCenter
                currentIndex: root.selectedIndex
                icon.name: "tv_displays"
                model: root.targets
                text: root.targets[root.selectedIndex]?.display ?? qsTr("All")
                textRole: "display"
                onMenuItemActivated: index => root.targetId = root.targets[index].value
            }
        }
    }

    FloatingButton {
        color: Hyprsunset.isNightModeOn ? Colours.m3Colors.m3Primary : Qt.alpha(Colours.m3Colors.m3Primary, 0.3)
        icon.color: Hyprsunset.isNightModeOn ? Colours.m3Colors.m3OnPrimary : Qt.alpha(Colours.m3Colors.m3OnSurface, 0.38)
        icon.name: "bedtime"
        onClicked: Hyprsunset.isNightModeOn ? Hyprsunset.down() : Hyprsunset.up()
    }
}
