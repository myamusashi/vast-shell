pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Services
import qs.Components

import "../delegate"

Rectangle {
    id: root

    signal placeSelected(string path)

    color: Colours.m3Colors.m3Surface

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

            model: ListModel {
                id: placesModel

                ListElement {
                    label: qsTr("Home")
                    icon: "home"
                    path: ""
                }
                ListElement {
                    label: qsTr("Desktop")
                    icon: "desktop_windows"
                    path: ""
                }
                ListElement {
                    label: qsTr("Documents")
                    icon: "description"
                    path: ""
                }
                ListElement {
                    label: qsTr("Downloads")
                    icon: "download"
                    path: ""
                }
                ListElement {
                    label: qsTr("Music")
                    icon: "music_note"
                    path: ""
                }
                ListElement {
                    label: qsTr("Pictures")
                    icon: "image"
                    path: ""
                }
                ListElement {
                    label: qsTr("Videos")
                    icon: "movie"
                    path: ""
                }
                ListElement {
                    label: qsTr("Computer")
                    icon: "computer"
                    path: "file:///"
                }
            }

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

    function initializePlaces(homePath) {
        placesModel.setProperty(0, "path", homePath);
        placesModel.setProperty(1, "path", StandardPaths.standardLocations(StandardPaths.DesktopLocation)[0]);
        placesModel.setProperty(2, "path", StandardPaths.standardLocations(StandardPaths.DocumentsLocation)[0]);
        placesModel.setProperty(3, "path", StandardPaths.standardLocations(StandardPaths.DownloadLocation)[0]);
        placesModel.setProperty(4, "path", StandardPaths.standardLocations(StandardPaths.MusicLocation)[0]);
        placesModel.setProperty(5, "path", StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]);
        placesModel.setProperty(6, "path", StandardPaths.standardLocations(StandardPaths.MoviesLocation)[0]);
    }

    function clearSelection() {
        placesList.currentIndex = -1;
    }
}
