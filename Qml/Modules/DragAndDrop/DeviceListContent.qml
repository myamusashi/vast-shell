pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Components.Button
import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    required property var island
    required property bool active

    readonly property int deviceCount: KDEConnect.availableDevices.length
    readonly property real rowHeight: 36
    readonly property real maxContentHeight: FileListMetrics.clampHeight(deviceCount, rowHeight, 4, 200)
    readonly property real visibleHeight: maxContentHeight

    implicitWidth: active ? computeActiveWidth() : 180
    implicitHeight: Math.max(44, visibleHeight + 40)

    function computeActiveWidth() {
        return FileListMetrics.computeActiveWidth(KDEConnect.availableDevices, device => {
            deviceMetrics.text = device.name;
            return deviceMetrics.width;
        }, 180, 104, 250);
    }

    TextMetrics {
        id: deviceMetrics

        font.pixelSize: Appearance.fonts.size.normal
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Loader {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            active: root.active && root.deviceCount === 0
            sourceComponent: StyledText {
                text: qsTr("No devices available")
                font.pixelSize: Appearance.fonts.size.normal
                color: Colours.m3Colors.m3OnSurfaceVariant
            }
        }

        Flickable {
            id: deviceFlickable

            Layout.fillWidth: true
            Layout.leftMargin: Appearance.margin.large
            Layout.rightMargin: Appearance.margin.large
            Layout.topMargin: Appearance.margin.small
            Layout.preferredHeight: root.visibleHeight
            Layout.alignment: Qt.AlignTop

            contentWidth: width
            contentHeight: deviceColumn.implicitHeight
            clip: true
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds
            visible: root.active

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            ColumnLayout {
                id: deviceColumn

                width: deviceFlickable.width
                spacing: 0

                Repeater {
                    model: KDEConnect.availableDevices

                    ExtendedFloatingButton {
                        required property var modelData

                        Layout.fillWidth: true
                        implicitHeight: root.rowHeight - 12   // or keep 24
                        text: modelData.name
                        icon.name: "smartphone"
                        icon.color: Colours.m3Colors.m3Primary
                        textColor: Colours.m3Colors.m3Primary
                        color: "transparent"
                        onClicked: {
                            root.island.selectedDevice = modelData;
                            root.island.goToConfirmation();
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        } // spacer: pushes Back to the bottom

        ExtendedFloatingButton {
            id: backButton

            Layout.alignment: Qt.AlignRight
            Layout.rightMargin: Appearance.margin.normal
            Layout.bottomMargin: Appearance.margin.normal
            implicitHeight: 24
            text: qsTr("Back")
            icon.name: "arrow_back_ios_new"
            icon.color: Colours.m3Colors.m3Primary
            textColor: Colours.m3Colors.m3OnSurface
            color: Qt.alpha(Colours.m3Colors.m3Primary, 0.12)
            onClicked: root.island.goBack()
        }
    }
}
