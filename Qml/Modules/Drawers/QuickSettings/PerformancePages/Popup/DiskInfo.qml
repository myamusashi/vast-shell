pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Services
import qs.Components.Base

PopupWidget {
    id: diskInfo

    function syncFilesystems() {
        const list = SystemUsage.filesystemNames;

        for (let modelIndex = filesystemModel.count - 1; modelIndex >= 0; modelIndex--) {
            if (!list.some(entry => entry.name === filesystemModel.get(modelIndex).filesystem))
                filesystemModel.remove(modelIndex, 1);
        }

        for (let entryIndex = 0; entryIndex < list.length; entryIndex++) {
            const entry       = list[entryIndex];
            const row         = {
                filesystem: entry.name,
                filesystemType: entry.type,
                mountPoint: entry.mountpoint,
                totalMountPointData: SystemUsage.formatKB(entry.totalKB),
                totalUsed: SystemUsage.formatKB(entry.usedKB),
                freeSize: SystemUsage.formatKB(entry.freeKB),
                usedValue: entry.usedKB / 1024 / 1024,
                totalValue: entry.totalKB / 1024 / 1024
            };
            let existingIndex = -1;
            for (let modelIndex = 0; modelIndex < filesystemModel.count; modelIndex++) {
                if (filesystemModel.get(modelIndex).filesystem === entry.name) {
                    existingIndex = modelIndex;
                    break;
                }
            }
            if (existingIndex >= 0)
                filesystemModel.set(existingIndex, row);
            else
                filesystemModel.append(row);
        }
    }

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
            model: filesystemModel
            delegate: ColumnLayout {
                id: delegate

                required property var    modelData

                readonly property string filesystem: modelData.filesystem
                readonly property string filesystemType: modelData.filesystemType
                readonly property string freeSize: modelData.freeSize
                readonly property string mountPoint: modelData.mountPoint
                readonly property string totalMountPointData: modelData.totalMountPointData
                readonly property string totalUsed: modelData.totalUsed
                readonly property real   totalValue: modelData.totalValue
                readonly property real   usedValue: modelData.usedValue

                RowLayout {

                    StyledText {
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                        text: delegate.filesystem + ": "
                        visible: delegate.filesystem !== ""
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
                        text: delegate.totalMountPointData
                        visible: delegate.totalMountPointData !== ""
                    }
                }

                RowLayout {

                    StyledText {
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                        text: delegate.totalUsed
                        visible: delegate.totalUsed !== ""
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                        text: delegate.freeSize
                        visible: delegate.freeSize !== ""
                    }
                }

                Slider2Values {
                    Layout.fillWidth: true
                    Layout.topMargin: Appearance.spacing.small
                    totalValue: delegate.totalValue / 1048576
                    usedValue: delegate.usedValue / 1048576
                    visible: delegate.usedValue > 0 || delegate.totalValue > 0
                }
            }
        }
    }
    Component.onCompleted: syncFilesystems()

    ListModel {
        id: filesystemModel
    }

    Connections {

        function onFilesystemNamesChanged() {
            diskInfo.syncFilesystems();
        }

        target: SystemUsage
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
