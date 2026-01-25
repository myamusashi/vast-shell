pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Hyprland

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

import "WeatherItem/Pages" as WP
import "WeatherItem" as WI

Item {
    id: root

    anchors {
        right: parent.right
        verticalCenter: parent.verticalCenter
    }

    implicitHeight: parent.height
    implicitWidth: GlobalStates.isWeatherPanelOpen ? parent.width * 0.25 : 0
    visible: window.modelData.name === Hypr.focusedMonitor.name

    readonly property bool anyPageOpen: humidityPages.isOpen || sunPages.isOpen || pressurePages.isOpen || visibilityPages.isOpen || windPages.isOpen || uvIndexPages.isOpen || aqiPages.isOpen || precipitationPages.isOpen || moonPages.isOpen

    Behavior on implicitWidth {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Repeater {
        model: [Qt.TopLeftCorner, Qt.BottomLeftCorner]
        Corner {
            required property var modelData

            location: modelData
            extensionSide: Qt.Horizontal
            radius: GlobalStates.isWeatherPanelOpen ? 40 : 0
            color: GlobalStates.drawerColors
        }
    }

    IpcHandler {
        target: "weather"

        function open() {
            GlobalStates.openPanel("weather");
        }

        function close() {
            GlobalStates.closePanel("weather");
        }

        function toggle() {
            GlobalStates.togglePanel("weather");
        }
    }

    GlobalShortcut {
        name: "weather"
        onPressed: GlobalStates.togglePanel("weather")
    }

    StyledRect {
        id: rect

        anchors.fill: parent
        radius: 0
        clip: true
        color: GlobalStates.drawerColors

        Flickable {
            id: flickable

            anchors.fill: parent
            contentWidth: width
            contentHeight: mainLoader.item ? mainLoader.item.implicitHeight + 40 : 0
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                id: scrollBar

                anchors {
                    right: flickable.right
                    top: flickable.top
                    bottom: flickable.bottom
                }

                policy: ScrollBar.AsNeeded
                width: 6
                contentItem: StyledRect {
                    implicitWidth: 6
                    radius: Appearance.rounding.small
                    color: Colours.m3Colors.m3Primary
                    opacity: scrollBar.pressed ? 0.8 : 0.5
                }
                background: StyledRect {
                    implicitWidth: 6
                    radius: Appearance.rounding.small
                    color: Colours.m3Colors.m3OutlineVariant
                    opacity: 0.3
                }
            }

            Loader {
                id: mainLoader

                anchors.fill: parent
                active: window.modelData.name === Hypr.focusedMonitor.name
                asynchronous: true

                sourceComponent: ColumnLayout {
                    id: contentColumn

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 20
                    }

                    spacing: Appearance.spacing.normal

                    Headers {}

                    Loader {
                        id: summaryLoader

                        Layout.fillWidth: true
                        active: Configs.weather.enableQuickSummary && GlobalStates.isWeatherPanelOpen

                        sourceComponent: StyledRect {
                            implicitHeight: summaryText.implicitHeight + 20
                            color: Colours.m3Colors.m3SurfaceContainer
                            radius: Appearance.rounding.normal

                            StyledText {
                                id: summaryText

                                anchors.fill: parent
                                anchors.margins: 10
                                text: Weather.getQuickSummary()
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.small
                                wrapMode: Text.WordWrap
                                horizontalAlignment: Text.AlignLeft
                            }
                        }
                    }

                    Loader {
                        id: forecastLoader

                        Layout.fillWidth: true
                        active: ((Weather.hourlyForecast && Weather.hourlyForecast.length > 0) || (Weather.dailyForecast && Weather.dailyForecast.length > 0)) && GlobalStates.isWeatherPanelOpen
                        asynchronous: true

                        sourceComponent: ColumnLayout {
                            spacing: Appearance.spacing.large

                            WI.ForecastHourly {
                                Layout.fillWidth: true
                            }

                            WI.ForecastDaily {
                                Layout.fillWidth: true
                            }
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignCenter
                        columns: 2
                        columnSpacing: Appearance.spacing.large
                        rowSpacing: Appearance.spacing.large

                        GridLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignCenter
                            columns: 2
                            columnSpacing: Appearance.spacing.large
                            rowSpacing: Appearance.spacing.large

                            Loader {
                                id: humidityCard

                                Layout.preferredWidth: 150
                                Layout.preferredHeight: 150
                                active: GlobalStates.isWeatherPanelOpen
                                sourceComponent: Component {
                                    WI.Humidity {
                                        anchors.fill: parent
                                        MArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            enabled: !root.anyPageOpen
                                            onClicked: {
                                                humidityPages.zoomOriginX = humidityCard.mapToItem(root, 0, 0).x + humidityCard.width / 2;
                                                humidityPages.zoomOriginY = humidityCard.mapToItem(root, 0, 0).y + humidityCard.height / 2;
                                                humidityPages.isOpen = true;
                                            }
                                        }
                                    }
                                }
                            }

                            Loader {
                                id: sunCard

                                Layout.preferredWidth: 150
                                Layout.preferredHeight: 150
                                active: GlobalStates.isWeatherPanelOpen
                                sourceComponent: Component {
                                    WI.Sun {
                                        anchors.fill: parent
                                        MArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            enabled: !root.anyPageOpen
                                            onClicked: {
                                                sunPages.zoomOriginX = sunCard.mapToItem(root, 0, 0).x + sunCard.width / 2;
                                                sunPages.zoomOriginY = sunCard.mapToItem(root, 0, 0).y + sunCard.height / 2;
                                                sunPages.isOpen = true;
                                            }
                                        }
                                    }
                                }
                            }

                            Loader {
                                id: pressureCard

                                Layout.preferredWidth: 150
                                Layout.preferredHeight: 150
                                active: GlobalStates.isWeatherPanelOpen
                                sourceComponent: Component {
                                    WI.Pressure {
                                        anchors.fill: parent
                                        MArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            enabled: !root.anyPageOpen
                                            onClicked: {
                                                pressurePages.zoomOriginX = pressureCard.mapToItem(root, 0, 0).x + pressureCard.width / 2;
                                                pressurePages.zoomOriginY = pressureCard.mapToItem(root, 0, 0).y + pressureCard.height / 2;
                                                pressurePages.isOpen = true;
                                            }
                                        }
                                    }
                                }
                            }

                            Loader {
                                id: visibilityCard

                                Layout.preferredWidth: 150
                                Layout.preferredHeight: 150
                                active: GlobalStates.isWeatherPanelOpen
                                sourceComponent: Component {
                                    WI.Visibility {
                                        anchors.fill: parent
                                        MArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            enabled: !root.anyPageOpen
                                            onClicked: {
                                                visibilityPages.zoomOriginX = visibilityCard.mapToItem(root, 0, 0).x + visibilityCard.width / 2;
                                                visibilityPages.zoomOriginY = visibilityCard.mapToItem(root, 0, 0).y + visibilityCard.height / 2;
                                                visibilityPages.isOpen = true;
                                            }
                                        }
                                    }
                                }
                            }

                            Loader {
                                id: windCard

                                Layout.preferredWidth: 150
                                Layout.preferredHeight: 150
                                active: GlobalStates.isWeatherPanelOpen
                                sourceComponent: Component {
                                    WI.Wind {
                                        anchors.fill: parent
                                        MArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            enabled: !root.anyPageOpen
                                            onClicked: {
                                                windPages.zoomOriginX = windCard.mapToItem(root, 0, 0).x + windCard.width / 2;
                                                windPages.zoomOriginY = windCard.mapToItem(root, 0, 0).y + windCard.height / 2;
                                                windPages.isOpen = true;
                                            }
                                        }
                                    }
                                }
                            }

                            Loader {
                                id: uvIndexCard

                                Layout.preferredWidth: 150
                                Layout.preferredHeight: 150
                                active: GlobalStates.isWeatherPanelOpen
                                asynchronous: true
                                sourceComponent: Component {
                                    WI.UVIndex {
                                        anchors.fill: parent
                                        MArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            enabled: !root.anyPageOpen
                                            onClicked: {
                                                uvIndexPages.zoomOriginX = uvIndexCard.mapToItem(root, 0, 0).x + uvIndexCard.width / 2;
                                                uvIndexPages.zoomOriginY = uvIndexCard.mapToItem(root, 0, 0).y + uvIndexCard.height / 2;
                                                uvIndexPages.isOpen = true;
                                            }
                                        }
                                    }
                                }
                            }

                            Loader {
                                id: aqiCard

                                Layout.preferredWidth: 150
                                Layout.preferredHeight: 150
                                active: GlobalStates.isWeatherPanelOpen
                                sourceComponent: Component {
                                    WI.AQI {
                                        anchors.fill: parent
                                        MArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            enabled: !root.anyPageOpen
                                            onClicked: {
                                                aqiPages.zoomOriginX = aqiCard.mapToItem(root, 0, 0).x + aqiCard.width / 2;
                                                aqiPages.zoomOriginY = aqiCard.mapToItem(root, 0, 0).y + aqiCard.height / 2;
                                                aqiPages.isOpen = true;
                                            }
                                        }
                                    }
                                }
                            }

                            Loader {
                                id: precipitationCard

                                Layout.preferredWidth: 150
                                Layout.preferredHeight: 150
                                active: GlobalStates.isWeatherPanelOpen
                                sourceComponent: Component {
                                    WI.Precipitation {
                                        anchors.fill: parent
                                        MArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            enabled: !root.anyPageOpen
                                            onClicked: {
                                                precipitationPages.zoomOriginX = precipitationCard.mapToItem(root, 0, 0).x + precipitationCard.width / 2;
                                                precipitationPages.zoomOriginY = precipitationCard.mapToItem(root, 0, 0).y + precipitationCard.height / 2;
                                                precipitationPages.isOpen = true;
                                            }
                                        }
                                    }
                                }
                            }

                            Loader {
                                id: moonCard

                                Layout.preferredWidth: 150
                                Layout.preferredHeight: 150
                                active: GlobalStates.isWeatherPanelOpen
                                sourceComponent: Component {
                                    WI.Moon {
                                        anchors.fill: parent
                                        MArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            enabled: !root.anyPageOpen
                                            z: 999
                                            onClicked: {
                                                moonPages.zoomOriginX = moonCard.mapToItem(root, 0, 0).x + moonCard.width / 2;
                                                moonPages.zoomOriginY = moonCard.mapToItem(root, 0, 0).y + moonCard.height / 2;
                                                moonPages.isOpen = true;
                                            }
                                        }
                                    }
                                }
                            }

                            Loader {
                                id: cloudinessCard

                                Layout.preferredWidth: 150
                                Layout.preferredHeight: 150
                                active: GlobalStates.isWeatherPanelOpen
                                sourceComponent: Component {
                                    WI.Cloudiness {
                                        anchors.fill: parent
                                    }
                                }
                            }
                        }
                    }
                    Item {
                        Layout.fillHeight: true
                        Layout.preferredHeight: 20
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        visible: root.anyPageOpen
        enabled: root.anyPageOpen
        hoverEnabled: true

        onClicked: {}
        onPressed: {}
        onReleased: {}
    }

    WP.Humidity {
        id: humidityPages
    }

    WP.Sun {
        id: sunPages
    }

    WP.Pressure {
        id: pressurePages
    }

    WP.Visibility {
        id: visibilityPages
    }

    WP.Wind {
        id: windPages
    }

    WP.AQI {
        id: aqiPages
    }

    WP.Precipitation {
        id: precipitationPages
    }

    WP.Moon {
        id: moonPages
    }

    WP.UVIndex {
        id: uvIndexPages
    }
}
