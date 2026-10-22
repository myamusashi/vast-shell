pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Components.Button
import qs.Core.Configs
import qs.Services

ColumnLayout {
    id: root

    required property var controller

    property alias        carousel: wallpaperCarousel
    property alias        searchField: searchField

    spacing: Appearance.spacing.normal

    SearchField {
        id: searchField

        Layout.fillWidth: true
        carousel: wallpaperCarousel
        controller: root.controller
    }

    ConnectedButtonGroup {
        Layout.alignment: Qt.AlignHCenter
        currentIndex: root.controller?.wallpaperType ?? 0
        model: [qsTr("Static"), qsTr("Video")]
        onClicked: index => {
            root.controller.wallpaperType = index;
            Qt.callLater(() => wallpaperCarousel.selectCurrentWallpaper());
        }
    }

    Carousel {
        id: wallpaperCarousel

        Layout.fillHeight: true
        Layout.fillWidth: true
        controller: root.controller
        thumbnailAvailability: root.controller?.thumbnailAvailability ?? ({})
        visibleWallpapers: root.controller?.visibleWallpapers ?? []
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        color: Colours.m3Colors.m3OnSurface
        font.pixelSize: Appearance.fonts.size.small
        text: wallpaperCarousel.count > 0 ? (wallpaperCarousel.currentIndex + 1) + " / " + wallpaperCarousel.count : "0 / 0"
    }
}
