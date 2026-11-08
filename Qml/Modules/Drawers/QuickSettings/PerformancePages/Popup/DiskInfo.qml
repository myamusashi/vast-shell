pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Services
import qs.Components.Base

PopupWidget {
    id: diskInfo

    icon: "storage"
    text: qsTr("Storage")
    content: ColumnLayout {

        RowLayout {

            StyledText {
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large
                font.weight: Font.DemiBold
                text: SystemUsage.diskProp.toFixed(0) + qsTr(" GB used")
            }

            StyledText {
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large
                font.weight: Font.DemiBold
                text: (SystemUsage.diskTotal / 1048576).toFixed(0) + qsTr(" GB total")
            }
        }

        Slider3Values {
            Layout.fillWidth: true
            Layout.topMargin: Appearance.spacing.small
            appsValue: SystemUsage.storageAppsData / 1048576
            freeValue: SystemUsage.storageFree / 1048576
            systemValue: SystemUsage.storageSystem / 1048576
        }

        Repeater {
            model: [qsTr("Root"), qsTr("Boot"), qsTr("Free")]
            delegate: RowLayout {
                id: storageSummaryRow

                required property int    index
                required property string modelData

                StyledRect {
                    color: storageSummaryRow.index === 0 ? Colours.m3Colors.m3Green : storageSummaryRow.index === 1 ? Qt.alpha(Colours.m3Colors.m3Green, 0.7) : Qt.alpha(Colours.m3Colors.m3Green, 0.3)
                    implicitHeight: 15
                    implicitWidth: 15
                }

                StyledText {
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    text: storageSummaryRow.modelData
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    text: storageSummaryRow.index === 0 ? SystemUsage.formatKB(SystemUsage.storageAppsData) : storageSummaryRow.index === 1 ? SystemUsage.formatKB(SystemUsage.storageSystem) : SystemUsage.formatKB(SystemUsage.storageFree)
                }
            }
        }

        StyledText {
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.large
            font.weight: Font.DemiBold
            text: qsTr("Internal storage")
        }

        Repeater {
            model: SystemUsage.filesystems
            delegate: ColumnLayout {
                id: delegate

                required property string deviceName
                required property string filesystemType
                required property string mountPoint
                required property string formattedTotal
                required property string formattedUsed
                required property string formattedFree
                required property real   totalKiB
                required property real   usedKiB

                RowLayout {

                    StyledText {
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                        text: delegate.deviceName + ": "
                        visible: delegate.deviceName !== ""
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                        font.weight: Font.DemiBold
                        text: delegate.filesystemType
                        visible: delegate.filesystemType !== ""
                    }
                }

                RowLayout {

                    StyledText {
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                        text: delegate.mountPoint
                        visible: delegate.mountPoint !== ""
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                        text: delegate.formattedTotal
                        visible: delegate.formattedTotal !== ""
                    }
                }

                RowLayout {

                    StyledText {
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                        text: delegate.formattedUsed
                        visible: delegate.formattedUsed !== ""
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                        text: delegate.formattedFree
                        visible: delegate.formattedFree !== ""
                    }
                }

                Slider2Values {
                    Layout.fillWidth: true
                    Layout.topMargin: Appearance.spacing.small
                    totalValue: delegate.totalKiB
                    usedValue: delegate.usedKiB
                    visible: delegate.usedKiB > 0 || delegate.totalKiB > 0
                }
            }
        }
    }
    component Slider2Values: Item {
        id: root

        readonly property real freePercent: 1 - usedPercent
        readonly property real usedPercent: totalValue > 0 ? (usedValue / totalValue) : 0

        property real          totalValue: 100
        property real          usedValue: 0

        implicitHeight: 12

        StyledRect {
            anchors.fill: parent
            color: Qt.alpha(Colours.m3Colors.m3Green, 0.2)
            radius: height / 2
        }

        StyledRect {
            id: usedBar

            color: Colours.m3Colors.m3Green
            implicitWidth: parent.width * root.usedPercent
            radius: height / 2
            Behavior on implicitWidth {
                SpringAnimation {
                    damping: 0.5
                    spring: 2
                }
            }

            anchors {
                bottom: parent.bottom
                left: parent.left
                top: parent.top
            }
        }
    }
    component Slider3Values: Item {
        id: root

        readonly property real appsRatio: total > 0 ? appsValue / total : 0
        readonly property real systemPlusAppsRatio: total > 0 ? (systemValue + appsValue) / total : 0
        readonly property real systemRatio: total > 0 ? systemValue / total : 0
        readonly property real total: freeValue + systemValue + appsValue

        property real          appsValue: 0
        property real          freeValue: 0
        property real          systemValue: 0

        implicitHeight: 12

        StyledRect {
            anchors.fill: parent
            color: Qt.alpha(Colours.m3Colors.m3Green, 0.2)
            radius: height / 2
        }

        StyledRect {
            id: systemAppsBar

            color: Qt.alpha(Colours.m3Colors.m3Green, 0.5)
            radius: height / 2
            width: parent.width * root.systemPlusAppsRatio
            z: 1
            Behavior on width {
                SpringAnimation {
                    damping: 0.5
                    spring: 2
                }
            }

            anchors {
                bottom: parent.bottom
                left: parent.left
                top: parent.top
            }
        }

        StyledRect {
            id: appsBar

            color: Colours.m3Colors.m3Green
            radius: height / 2
            width: parent.width * root.appsRatio
            z: 2
            Behavior on width {
                SpringAnimation {
                    damping: 0.5
                    spring: 2
                }
            }

            anchors {
                bottom: parent.bottom
                left: parent.left
                top: parent.top
            }
        }
    }
}
