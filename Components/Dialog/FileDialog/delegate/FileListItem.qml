import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Core.Utils
import qs.Services

import "../../../Base"

Rectangle {
    id: root

    property alias fileName: fileName.text
    property int fileSize: 0
    property var fileModified
    property string filePath: ""
    property bool isFolder: false
    property bool isSelected: false
    property int itemIndex: 0

    signal clicked
    signal doubleClicked

    implicitHeight: 48
    clip: true
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
        target: root
        property: "_c0Blend"
        from: 0.0
        to: 1.0
        duration: Appearance.animations.durations.small
    }

    property color _target: root.isSelected ? Qt.alpha(Colours.m3Colors.m3Primary, 0.3) : "transparent"
    on_TargetChanged: {
        _c0Anim.stop()
        _c0From = root.color
        _c0To = _target
        _c0Active = true
        _c0Blend = 0.0
        _c0Anim.start()
    }

    function getFileExtension(name, folder) {
        if (folder)
            return qsTr("Folder");
        var dot = name.lastIndexOf(".");
        return dot >= 0 ? name.substring(dot + 1).toUpperCase() + " " + qsTr("file") : qsTr("File");
    }

    function formatSize(bytes) {
        if (bytes < 1024)
            return bytes + " " + qsTr("B");
        if (bytes < 1048576)
            return (bytes / 1024).toFixed(1) + " " + qsTr("KiB");
        if (bytes < 1073741824)
            return (bytes / 1048576).toFixed(1) + " " + qsTr("MiB");
        return (bytes / 1073741824).toFixed(1) + " " + qsTr("GiB");
    }

    Rectangle {
        anchors.fill: parent
        color: Colours.m3Colors.m3OnSurface
        opacity: !root.isSelected && (root.itemIndex % 2 !== 0) ? 0.03 : 0

        Behavior on opacity {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: Appearance.margin.small
            rightMargin: Appearance.margin.normal
        }
        spacing: Appearance.spacing.small

        Icon {
            id: iconItem
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
                target: iconItem
                property: "_c1Blend"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.small
            }

            property color _target: root.isSelected ? Colours.m3Colors.m3OnPrimaryContainer : (root.isFolder ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant)
            on_TargetChanged: {
                _c1Anim.stop()
                _c1From = iconItem.color
                _c1To = _target
                _c1Active = true
                _c1Blend = 0.0
                _c1Anim.start()
            }

            icon: root.isFolder ? "folder" : "description"
            font.pixelSize: Appearance.fonts.size.large
            Layout.preferredWidth: 32
        }

        StyledText {
            id: fileName
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
                target: fileName
                property: "_c2Blend"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.small
            }

            property color _target: root.isSelected ? Colours.m3Colors.m3OnPrimaryContainer : root.fileName.startsWith(".") ? Colours.m3Colors.m3OnSurfaceVariant : Colours.m3Colors.m3OnSurface
            on_TargetChanged: {
                _c2Anim.stop()
                _c2From = fileName.color
                _c2To = _target
                _c2Active = true
                _c2Blend = 0.0
                _c2Anim.start()
            }

            Layout.fillWidth: true
            text: ""
            font.pixelSize: Appearance.fonts.size.normal
            elide: Text.ElideRight
            leftPadding: 2
        }

        StyledText {
            id: sizeText
            property color _c3From
            property color _c3To
            property bool _c3Active: false
            property real _c3Blend: 1.0

            on_C3BlendChanged: {
                if (!_c3Active) return
                if (_c3Blend >= 1) {
                    color = _c3To
                    _c3Active = false
                } else if (_c3Blend > 0) {
                    color = Colours.blendColors(_c3From, _c3To, _c3Blend)
                }
            }

            NumberAnimation {
                id: _c3Anim
                target: sizeText
                property: "_c3Blend"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.small
            }

            property color _target: root.isSelected ? Colours.m3Colors.m3OnPrimaryContainer : Colours.m3Colors.m3OnSurfaceVariant
            on_TargetChanged: {
                _c3Anim.stop()
                _c3From = sizeText.color
                _c3To = _target
                _c3Active = true
                _c3Blend = 0.0
                _c3Anim.start()
            }

            text: root.isFolder ? "" : root.formatSize(root.fileSize)
            font.pixelSize: Appearance.fonts.size.small
            Layout.preferredWidth: 76
            horizontalAlignment: Text.AlignRight
        }

        StyledText {
            id: extText
            property color _c4From
            property color _c4To
            property bool _c4Active: false
            property real _c4Blend: 1.0

            on_C4BlendChanged: {
                if (!_c4Active) return
                if (_c4Blend >= 1) {
                    color = _c4To
                    _c4Active = false
                } else if (_c4Blend > 0) {
                    color = Colours.blendColors(_c4From, _c4To, _c4Blend)
                }
            }

            NumberAnimation {
                id: _c4Anim
                target: extText
                property: "_c4Blend"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.small
            }

            property color _target: root.isSelected ? Colours.m3Colors.m3OnPrimaryContainer : Colours.m3Colors.m3OnSurfaceVariant
            on_TargetChanged: {
                _c4Anim.stop()
                _c4From = extText.color
                _c4To = _target
                _c4Active = true
                _c4Blend = 0.0
                _c4Anim.start()
            }

            text: root.getFileExtension(root.fileName, root.isFolder)
            font.pixelSize: Appearance.fonts.size.small
            Layout.preferredWidth: 90
            leftPadding: 10
            elide: Text.ElideRight
        }

        StyledText {
            id: dateText
            property color _c5From
            property color _c5To
            property bool _c5Active: false
            property real _c5Blend: 1.0

            on_C5BlendChanged: {
                if (!_c5Active) return
                if (_c5Blend >= 1) {
                    color = _c5To
                    _c5Active = false
                } else if (_c5Blend > 0) {
                    color = Colours.blendColors(_c5From, _c5To, _c5Blend)
                }
            }

            NumberAnimation {
                id: _c5Anim
                target: dateText
                property: "_c5Blend"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.small
            }

            property color _target: root.isSelected ? Colours.m3Colors.m3OnPrimaryContainer : Colours.m3Colors.m3OnSurfaceVariant
            on_TargetChanged: {
                _c5Anim.stop()
                _c5From = dateText.color
                _c5To = _target
                _c5Active = true
                _c5Blend = 0.0
                _c5Anim.start()
            }

            text: Qt.formatDateTime(root.fileModified, "yyyy-MM-dd hh:mm")
            font.pixelSize: Appearance.fonts.size.small
            Layout.preferredWidth: 110
            leftPadding: 6
        }
    }

    MArea {
        layerRadius: root.radius
        onClicked: root.clicked()
        onDoubleClicked: root.doubleClicked()
    }
}
