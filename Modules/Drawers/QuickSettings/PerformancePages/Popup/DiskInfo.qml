import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Services
import qs.Components

PopupWidget {
    icon: "storage"
    text: qsTr("Storage")
    content: ColumnLayout {
        RowLayout {
            StyledText {
                text: SystemUsage.diskProp.toFixed(0) + qsTr(" GB used")
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large
                font.weight: Font.DemiBold
            }

            StyledText {
                text: (SystemUsage.diskTotal / 1048576).toFixed(0) + qsTr(" GB total")
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large
                font.weight: Font.DemiBold
            }
        }

        Slider3Values {
            Layout.fillWidth: true
            Layout.topMargin: Appearance.spacing.small
            values1: SystemUsage.storageFree / 1048576
            values2: SystemUsage.storageSystem / 1048576
            values3: SystemUsage.storageAppsData / 1048576
        }

        Repeater {
            model: [
                {
                    color: Colours.m3Colors.m3Green,
                    text: qsTr("Root"),
                    value: SystemUsage.storageAppsFormatted
                },
                {
                    color: Colours.withAlpha(Colours.m3Colors.m3Green, 0.7),
                    text: qsTr("Boot"),
                    value: SystemUsage.storageSystemFormatted
                },
                {
                    color: Colours.withAlpha(Colours.m3Colors.m3Green, 0.3),
                    text: qsTr("Free"),
                    value: SystemUsage.storageFreeFormatted
                }
            ]
            delegate: RowLayout {
                required property var modelData

                StyledRect {
                    color: parent.modelData.color
                    implicitWidth: 15
                    implicitHeight: 15
                }

                StyledText {
                    text: parent.modelData.text
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    text: parent.modelData.value
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                }
            }
        }

        StyledText {
            text: qsTr("Internal storage")
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.large
            font.weight: Font.DemiBold
        }

        Repeater {
            model: SystemUsage.filesystemNames.map(e => ({
                        fs: e.name,
                        fsType: e.type,
                        mountPoint: e.mountpoint,
                        totalMountPointData: e.totalFormatted,
                        totalUsed: e.usedFormatted,
                        freeSize: e.freeFormatted,
                        values1: e.usedKB / 1024 / 1024,
                        values2: e.totalKB / 1024 / 1024
                    }))
            delegate: ColumnLayout {
                id: delegate

                required property var modelData
                readonly property string fs: modelData.fs
                readonly property string fsType: modelData.fsType
                readonly property string mountPoint: modelData.mountPoint
                readonly property string totalMountPointData: modelData.totalMountPointData
                readonly property string totalUsed: modelData.totalUsed
                readonly property string freeSize: modelData.freeSize
                readonly property real values1: modelData.values1
                readonly property real values2: modelData.values2

                RowLayout {
                    StyledText {
                        visible: delegate.fs !== "" || delegate.fs !== ""
                        text: delegate.fs + ": "
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        visible: delegate.fsType !== "" || delegate.fsType !== ""
                        text: delegate.fsType
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                        font.weight: Font.DemiBold
                    }

                    Item {
                        Layout.preferredHeight: 10
                    }
                }

                RowLayout {
                    StyledText {
                        visible: delegate.mountPoint !== "" || delegate.mountPoint !== ""
                        text: delegate.mountPoint
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        visible: delegate.totalMountPointData !== "" || delegate.totalMountPointData !== ""
                        text: delegate.totalMountPointData
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                    }
                }

                RowLayout {
                    StyledText {
                        visible: delegate.totalUsed !== "" || delegate.totalUsed !== ""
                        text: delegate.totalUsed
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        visible: delegate.freeSize !== "" || delegate.freeSize !== ""
                        text: delegate.freeSize
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                    }
                }

                Slider2Values {
                    Layout.fillWidth: true
                    Layout.topMargin: Appearance.spacing.small
                    visible: delegate.values1 > 0 || delegate.values2 > 0
                    usedValue: delegate.values1 / 1048576
                    totalValue: delegate.values2 / 1048576
                }
            }
        }
    }

    component Slider3Values: Item {
        id: root

        readonly property real total: values1 + values2 + values3
        readonly property real systemRatio: total > 0 ? values2 / total : 0
        readonly property real appsRatio: total > 0 ? values3 / total : 0
        readonly property real systemPlusAppsRatio: total > 0 ? (values2 + values3) / total : 0
        property real values1: 0
        property real values2: 0
        property real values3: 0

        implicitHeight: 12

        StyledRect {
            anchors.fill: parent
            radius: height / 2
            color: Colours.withAlpha(Colours.m3Colors.m3Green, 0.2)
        }

        StyledRect {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            width: parent.width * root.systemPlusAppsRatio
            radius: height / 2
            color: Colours.withAlpha(Colours.m3Colors.m3Green, 0.5)
            z: 1

            Behavior on width {
                NAnim {}
            }
            Behavior on color {
                CAnim {}
            }
        }

        StyledRect {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            width: parent.width * root.appsRatio
            radius: height / 2
            color: Colours.m3Colors.m3Green
            z: 2

            Behavior on width {
                NAnim {}
            }
            Behavior on color {
                CAnim {}
            }
        }
    }

    component Slider2Values: Item {
        id: root

        readonly property real usedPercent: totalValue > 0 ? (usedValue / totalValue) : 0
        readonly property real freePercent: 1 - usedPercent

        property real usedValue: 0
        property real totalValue: 100

        implicitHeight: 12

        StyledRect {
            anchors.fill: parent
            radius: height / 2
            color: Colours.withAlpha(Colours.m3Colors.m3Green, 0.2)
        }

        StyledRect {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            implicitWidth: parent.width * root.usedPercent
            radius: height / 2
            color: Colours.m3Colors.m3Green

            Behavior on implicitWidth {
                NAnim {}
            }

            Behavior on color {
                CAnim {}
            }
        }
    }
}
