pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Services
import qs.Components.Base
import qs.Components.Effects

PopupWidget {
    id: diskInfo

    function syncFilesystems() {
        const list = SystemUsage.filesystemNames;

        for (let i = filesystemModel.count - 1; i >= 0; i--) {
            if (!list.some(entry => entry.name === filesystemModel.get(i).filesystem))
                filesystemModel.remove(i, 1);
        }

        for (let i = 0; i < list.length; i++) {
            const entry = list[i];
            const row   = {
                filesystem: entry.name,
                filesystemType: entry.type,
                mountPoint: entry.mountpoint,
                totalMountPointData: SystemUsage.formatKB(entry.totalKB),
                totalUsed: SystemUsage.formatKB(entry.usedKB),
                freeSize: SystemUsage.formatKB(entry.freeKB),
                usedValue: entry.usedKB / 1024 / 1024,
                totalValue: entry.totalKB / 1024 / 1024
            };
            let index   = -1;
            for (let j = 0; j < filesystemModel.count; j++) {
                if (filesystemModel.get(j).filesystem === entry.name) {
                    index = j;
                    break;
                }
            }
            if (index >= 0)
                filesystemModel.set(index, row);
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
            model: [
                {
                    color: Colours.m3Colors.m3Green,
                    text: qsTr("Root"),
                    value: SystemUsage.formatKB(SystemUsage.storageAppsData)
                },
                {
                    color: Qt.alpha(Colours.m3Colors.m3Green, 0.7),
                    text: qsTr("Boot"),
                    value: SystemUsage.formatKB(SystemUsage.storageSystem)
                },
                {
                    color: Qt.alpha(Colours.m3Colors.m3Green, 0.3),
                    text: qsTr("Free"),
                    value: SystemUsage.formatKB(SystemUsage.storageFree)
                }
            ]
            delegate: RowLayout {
                required property var modelData

                StyledRect {
                    color: parent.modelData.color
                    implicitHeight: 15
                    implicitWidth: 15
                }

                StyledText {
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    text: parent.modelData.text
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    text: parent.modelData.value
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

                    Item {
                        Layout.preferredHeight: 10
                    }
                }

                RowLayout {

                    StyledText {
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                        text: delegate.mountPoint
                        visible: delegate.mountPoint !== "" || delegate.mountPoint !== ""
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                        text: delegate.totalMountPointData
                        visible: delegate.totalMountPointData !== "" || delegate.totalMountPointData !== ""
                    }
                }

                RowLayout {

                    StyledText {
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                        text: delegate.totalUsed
                        visible: delegate.totalUsed !== "" || delegate.totalUsed !== ""
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                        text: delegate.freeSize
                        visible: delegate.freeSize !== "" || delegate.freeSize !== ""
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

            property color target: Colours.m3Colors.m3Green

            implicitWidth: parent.width * root.usedPercent
            radius: height / 2
            Behavior on implicitWidth {
                SpringAnimation {
                    damping: 0.5
                    spring: 2
                }
            }

            BlendColor {
                host: usedBar
                target: usedBar.target
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

            property color target: Qt.alpha(Colours.m3Colors.m3Green, 0.5)

            radius: height / 2
            width: parent.width * root.systemPlusAppsRatio
            z: 1
            Behavior on width {
                SpringAnimation {
                    damping: 0.5
                    spring: 2
                }
            }

            BlendColor {
                host: systemAppsBar
                target: systemAppsBar.target
            }

            anchors {
                bottom: parent.bottom
                left: parent.left
                top: parent.top
            }
        }

        StyledRect {
            id: appsBar

            property color target: Colours.m3Colors.m3Green

            radius: height / 2
            width: parent.width * root.appsRatio
            z: 2
            Behavior on width {
                SpringAnimation {
                    damping: 0.5
                    spring: 2
                }
            }

            BlendColor {
                host: appsBar
                target: appsBar.target
            }

            anchors {
                bottom: parent.bottom
                left: parent.left
                top: parent.top
            }
        }
    }
}
