pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Services

import "../../../Base"
import "../delegate"

Rectangle {
    id: root

    signal placeSelected(string path)

    color: Colours.m3Colors.m3Surface

    function xdgPath(type) {
        const locs = StandardPaths.standardLocations(type);
        return locs.length > 0 ? locs[0].toString().replace("file://", "") : null;
    }

    function clearSelection() {
        placesList.currentIndex = -1;
    }

    Rectangle {
        anchors.right: parent.right
        implicitWidth: 1
        implicitHeight: parent.height
        color: Colours.m3Colors.m3OutlineVariant
        opacity: 0.4
    }

    ColumnLayout {
        anchors {
            fill: parent
            topMargin: Appearance.margin.normal
            leftMargin: Appearance.margin.small
            rightMargin: Appearance.margin.small
        }
        spacing: Appearance.spacing.small

        StyledText {
            text: qsTr("Places")
            font.pixelSize: Appearance.fonts.size.small
            font.letterSpacing: 0.8
            color: Colours.m3Colors.m3OnSurfaceVariant
            leftPadding: Appearance.margin.normal
            bottomPadding: Appearance.spacing.small
            Layout.fillWidth: true
        }

        ListView {
            id: placesList

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Appearance.spacing.small
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
            delegate: PlaceItem {
                required property var model
                required property int index

                implicitWidth: placesList.width
                label: model.label
                icon: model.icon
                isSelected: ListView.isCurrentItem

                onClicked: {
                    placesList.currentIndex = index;
                    root.placeSelected(model.path);
                }
            }
        }
    }
}
