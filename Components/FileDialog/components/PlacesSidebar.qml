pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import QtQuick.Layouts

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
            topMargin: 12
            leftMargin: 8
            rightMargin: 8
        }
        spacing: 2

        StyledText {
            text: "Places"
            font.pixelSize: 11
            font.letterSpacing: 0.8
            color: Colours.m3Colors.m3OnSurfaceVariant
            leftPadding: 16
            bottomPadding: 4
            Layout.fillWidth: true
        }

        ListView {
			id: placesList

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            currentIndex: -1
            highlightFollowsCurrentItem: false

            model: ListModel {
				id: placesModel

                ListElement {
                    label: "Home"
                    icon: "🏠"
                    path: ""
                }
                ListElement {
                    label: "Desktop"
                    icon: "🖥️"
                    path: ""
                }
                ListElement {
                    label: "Documents"
                    icon: "📄"
                    path: ""
                }
                ListElement {
                    label: "Downloads"
                    icon: "📥"
                    path: ""
                }
                ListElement {
                    label: "Music"
                    icon: "🎵"
                    path: ""
                }
                ListElement {
                    label: "Pictures"
                    icon: "🖼️"
                    path: ""
                }
                ListElement {
                    label: "Videos"
                    icon: "🎬"
                    path: ""
                }
                ListElement {
                    label: "Computer"
                    icon: "💻"
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
