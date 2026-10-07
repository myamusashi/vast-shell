pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtCore

import qs.Core.Configs
import qs.Services

import "../../../Base"
import "../delegate"

Rectangle {
    id: root

    signal   placeSelected(string path)

    function clearSelection() {
        placesList.currentIndex = -1;
    }
    function xdgPath(type) {
        const locs = StandardPaths.standardLocations(type);
        return locs.length > 0 ? locs[0].toString().replace("file://", "") : null;
    }

    color: Colours.m3Colors.m3Surface

    Rectangle {
        anchors.right: parent.right
        color: Colours.m3Colors.m3OutlineVariant
        implicitHeight: parent.height
        implicitWidth: 1
        opacity: 0.4
    }

    ColumnLayout {
        spacing: Appearance.spacing.small

        anchors {
            fill: parent
            leftMargin: Appearance.margin.small
            rightMargin: Appearance.margin.small
            topMargin: Appearance.margin.normal
        }

        StyledText {
            Layout.fillWidth: true
            bottomPadding: Appearance.spacing.small
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.letterSpacing: 0.8
            font.pixelSize: Appearance.fonts.size.small
            leftPadding: Appearance.margin.normal
            text: qsTr("Places")
        }

        ListView {
            id: placesList

            Layout.fillHeight: true
            Layout.fillWidth: true
            clip: true
            currentIndex: -1
            highlightFollowsCurrentItem: false
            model: [
                {
                    label: qsTr("Home"),
                    icon: "home",
                    path: root.xdgPath(StandardPaths.HomeLocation)
                },
                {
                    label: qsTr("Desktop"),
                    icon: "desktop_windows",
                    path: root.xdgPath(StandardPaths.DesktopLocation)
                },
                {
                    label: qsTr("Documents"),
                    icon: "description",
                    path: root.xdgPath(StandardPaths.DocumentsLocation)
                },
                {
                    label: qsTr("Downloads"),
                    icon: "download",
                    path: root.xdgPath(StandardPaths.DownloadLocation)
                },
                {
                    label: qsTr("Music"),
                    icon: "music_note",
                    path: root.xdgPath(StandardPaths.MusicLocation)
                },
                {
                    label: qsTr("Pictures"),
                    icon: "image",
                    path: root.xdgPath(StandardPaths.PicturesLocation)
                },
                {
                    label: qsTr("Videos"),
                    icon: "movie",
                    path: root.xdgPath(StandardPaths.MoviesLocation)
                },
                {
                    label: qsTr("Computer"),
                    icon: "computer",
                    path: "file:///"
                },
            ]
            spacing: Appearance.spacing.small
            delegate: PlaceItem {
                required property int index
                required property var model

                icon: model.icon
                implicitWidth: placesList.width
                isSelected: ListView.isCurrentItem
                label: model.label
                onClicked: {
                    placesList.currentIndex = index;
                    root.placeSelected(model.path);
                }
            }
        }
    }
}
