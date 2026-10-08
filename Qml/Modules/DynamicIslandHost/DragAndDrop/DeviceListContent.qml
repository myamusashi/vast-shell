pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.Components.Button
import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    required property bool active
    required property var  island

    readonly property int  deviceCount: KDEConnect.availableDevices.length
    readonly property real maxContentHeight: FileListMetrics.clampHeight(deviceCount, rowHeight, 4, 200)
    readonly property real rowHeight: 36
    readonly property real visibleHeight: maxContentHeight

    function               computeActiveWidth() {
        return FileListMetrics.computeActiveWidth(KDEConnect.availableDevices, device => {
            deviceMetrics.text = device.name;
            return deviceMetrics.width;
        }, 180, 104, 250);
    }

    implicitHeight: Math.max(44, visibleHeight + 40)
    implicitWidth: active ? computeActiveWidth() : 180

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
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.normal
                text: qsTr("No devices available")
            }
        }

        Flickable {
            id: deviceFlickable

            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            Layout.leftMargin: Appearance.margin.large
            Layout.preferredHeight: root.visibleHeight
            Layout.rightMargin: Appearance.margin.large
            Layout.topMargin: Appearance.margin.small
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            contentHeight: deviceColumn.implicitHeight
            contentWidth: width
            flickableDirection: Flickable.VerticalFlick
            visible: root.active
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            ColumnLayout {
                id: deviceColumn

                spacing: 0
                width: deviceFlickable.width

                Repeater {
                    model: KDEConnect.availableDevices

                    ExtendedFloatingButton {
                        required property var modelData

                        Layout.fillWidth: true
                        color: "transparent"
                        icon.color: Colours.m3Colors.m3Primary
                        icon.name: "smartphone"
                        implicitHeight: root.rowHeight - 12   // or keep 24
                        text: modelData.name
                        textColor: Colours.m3Colors.m3Primary
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
            Layout.bottomMargin: Appearance.margin.normal
            Layout.rightMargin: Appearance.margin.normal
            color: Qt.alpha(Colours.m3Colors.m3Primary, 0.12)
            icon.color: Colours.m3Colors.m3Primary
            icon.name: "arrow_back_ios_new"
            implicitHeight: 24
            text: qsTr("Back")
            textColor: Colours.m3Colors.m3OnSurface
            onClicked: root.island.goBack()
        }
    }
}
