import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Services
import qs.Components.Base

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
            color: Qt.alpha(Colours.m3Colors.m3Green, 0.2)
        }

        StyledRect {
            id: systemAppsBar
            property color _c0From
            property color _c0To
            property bool _c0Active: false
            property real _c0Blend: 1.0

            on_C0BlendChanged: {
                if (!_c0Active) return
                if (_c0Blend >= 1) {
                    color = _c0To
                    _c0Active = false
                } else if (_c0Blend > 0) {
                    color = Colours.blendColors(_c0From, _c0To, _c0Blend)
                }
            }

            NumberAnimation {
                id: _c0Anim
                target: systemAppsBar
                property: "_c0Blend"
                from: 0.0
                to: 1.0
            }

            property color _target: Qt.alpha(Colours.m3Colors.m3Green, 0.5)
            on_TargetChanged: {
                _c0Anim.stop()
                _c0From = systemAppsBar.color
                _c0To = _target
                _c0Active = true
                _c0Blend = 0.0
                _c0Anim.start()
            }

            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            width: parent.width * root.systemPlusAppsRatio
            radius: height / 2
            z: 1

            Behavior on width {
                NAnim {}
            }
        }

        StyledRect {
            id: appsBar
            property color _c1From
            property color _c1To
            property bool _c1Active: false
            property real _c1Blend: 1.0

            on_C1BlendChanged: {
                if (!_c1Active) return
                if (_c1Blend >= 1) {
                    color = _c1To
                    _c1Active = false
                } else if (_c1Blend > 0) {
                    color = Colours.blendColors(_c1From, _c1To, _c1Blend)
                }
            }

            NumberAnimation {
                id: _c1Anim
                target: appsBar
                property: "_c1Blend"
                from: 0.0
                to: 1.0
            }

            property color _target: Colours.m3Colors.m3Green
            on_TargetChanged: {
                _c1Anim.stop()
                _c1From = appsBar.color
                _c1To = _target
                _c1Active = true
                _c1Blend = 0.0
                _c1Anim.start()
            }

            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            width: parent.width * root.appsRatio
            radius: height / 2
            z: 2

            Behavior on width {
                NAnim {}
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
            color: Qt.alpha(Colours.m3Colors.m3Green, 0.2)
        }

        StyledRect {
            id: usedBar
            property color _c2From
            property color _c2To
            property bool _c2Active: false
            property real _c2Blend: 1.0

            on_C2BlendChanged: {
                if (!_c2Active) return
                if (_c2Blend >= 1) {
                    color = _c2To
                    _c2Active = false
                } else if (_c2Blend > 0) {
                    color = Colours.blendColors(_c2From, _c2To, _c2Blend)
                }
            }

            NumberAnimation {
                id: _c2Anim
                target: usedBar
                property: "_c2Blend"
                from: 0.0
                to: 1.0
            }

            property color _target: Colours.m3Colors.m3Green
            on_TargetChanged: {
                _c2Anim.stop()
                _c2From = usedBar.color
                _c2To = _target
                _c2Active = true
                _c2Blend = 0.0
                _c2Anim.start()
            }

            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            implicitWidth: parent.width * root.usedPercent
            radius: height / 2

            Behavior on implicitWidth {
                NAnim {}
            }
        }
    }
}
