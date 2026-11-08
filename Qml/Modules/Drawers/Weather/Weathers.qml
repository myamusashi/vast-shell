pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Components.Base.DrawerComponents
import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

import "WeatherItem/Pages" as WeatherPages
import "WeatherItem" as WeatherItems

Drawer {
    id: root

    readonly property bool anyPageOpen: drawerLoader.item ? drawerLoader.item.anyPageOpen : false // qmllint disable
    readonly property bool onFocusedMonitor: FocusedMonitor.isOnFocusedMonitor(panelWindow.modelData.name) // qmllint disable
    readonly property bool shouldBeActive: open && onFocusedMonitor

    property bool          keepAlive: false

    animationDuration: Appearance.animations.durations.expressiveDefaultSpatial
    animationEasingCurve: Appearance.animations.curves.expressiveDefaultSpatial
    color: GlobalStates.drawerColors
    cornerRadius: 0
    depth: parent.width * 0.25
    edge: Qt.RightEdge
    filletRadius: 0
    length: parent.height - anchors.topMargin - anchors.bottomMargin
    open: GlobalStates.isWeatherPanelOpen
    onOpenChanged: {
        if (!open && drawerLoader.item)
            drawerLoader.item.closeAllPages(); // qmllint disable
    }
    onShouldBeActiveChanged: {
        if (shouldBeActive)
            keepAlive = true;
    }

    Timer {
        id: idleUnloadTimer

        interval: 120000
        running: root.keepAlive && !root.shouldBeActive
        onTriggered: root.keepAlive = false
    }

    Loader {
        id: drawerLoader

        active: root.shouldBeActive || root.keepAlive
        anchors.fill: parent
        asynchronous: true
        sourceComponent: Item {
            id: drawerContent

            readonly property bool anyPageOpen: humidityPages.isOpen || sunPages.isOpen || pressurePages.isOpen || visibilityPages.isOpen || windPages.isOpen || uvIndexPages.isOpen || aqiPages.isOpen || precipitationPages.isOpen || moonPages.isOpen

            function               closeAllPages() {
                humidityPages.isOpen      = false;
                sunPages.isOpen           = false;
                pressurePages.isOpen      = false;
                visibilityPages.isOpen    = false;
                windPages.isOpen          = false;
                uvIndexPages.isOpen       = false;
                aqiPages.isOpen           = false;
                precipitationPages.isOpen = false;
                moonPages.isOpen          = false;
            }

            Flickable {
                id: flickable

                anchors.fill: parent
                boundsBehavior: Flickable.StopAtBounds
                clip: true
                contentHeight: contentColumn.implicitHeight + 40
                contentWidth: width
                ScrollBar.vertical: ScrollBar {
                    id: scrollBar

                    policy: ScrollBar.AsNeeded
                    width: 6
                    background: StyledRect {
                        color: Colours.m3Colors.m3OutlineVariant
                        implicitWidth: 6
                        opacity: 0.3
                        radius: Appearance.rounding.small
                    }
                    contentItem: StyledRect {
                        color: Colours.m3Colors.m3Primary
                        implicitWidth: 6
                        opacity: scrollBar.pressed ? 0.8 : 0.5
                        radius: Appearance.rounding.small
                    }

                    anchors {
                        bottom: flickable.bottom
                        right: flickable.right
                        top: flickable.top
                    }
                }

                ColumnLayout {
                    id: contentColumn

                    spacing: Appearance.spacing.normal
                    visible: GlobalStates.isWeatherPanelOpen

                    anchors {
                        left: parent.left
                        margins: 20
                        right: parent.right
                        top: parent.top
                    }

                    Headers {}

                    Loader {
                        id: summaryLoader

                        Layout.fillWidth: true
                        active: Configs.weather.enableQuickSummary && GlobalStates.isWeatherPanelOpen
                        asynchronous: true
                        sourceComponent: WrapperRectangle {
                            color: Colours.m3Colors.m3SurfaceContainer
                            implicitHeight: summaryText.implicitHeight + 20
                            margin: Appearance.margin.normal
                            radius: Appearance.rounding.normal

                            StyledText {
                                id: summaryText

                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.small
                                horizontalAlignment: Text.AlignLeft
                                text: Weather.quickSummaryText
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        active: ((Weather.hourlyForecast && Weather.hourlyForecast.length > 0) || (Weather.dailyForecast && Weather.dailyForecast.length > 0)) && GlobalStates.isWeatherPanelOpen
                        asynchronous: true
                        sourceComponent: ColumnLayout {
                            spacing: Appearance.spacing.large

                            WeatherItems.ForecastHourly {
                                Layout.fillWidth: true
                            }

                            WeatherItems.ForecastDaily {
                                Layout.fillWidth: true
                            }
                        }
                    }

                    GridLayout {
                        Layout.alignment: Qt.AlignCenter
                        Layout.fillWidth: true
                        columnSpacing: Appearance.spacing.large
                        columns: 2
                        rowSpacing: Appearance.spacing.large

                        Card {
                            zoomPage: humidityPages
                            content: WeatherItems.Humidity {
                                anchors.fill: parent
                            }
                        }

                        Card {
                            zoomPage: sunPages
                            content: WeatherItems.Sun {
                                anchors.fill: parent
                            }
                        }

                        Card {
                            zoomPage: pressurePages
                            content: WeatherItems.Pressure {
                                anchors.fill: parent
                            }
                        }

                        Card {
                            zoomPage: visibilityPages
                            content: WeatherItems.Visibility {
                                anchors.fill: parent
                            }
                        }

                        Card {
                            zoomPage: windPages
                            content: WeatherItems.Wind {
                                anchors.fill: parent
                            }
                        }

                        Card {
                            zoomPage: uvIndexPages
                            content: WeatherItems.UVIndex {
                                anchors.fill: parent
                            }
                        }

                        Card {
                            zoomPage: aqiPages
                            content: WeatherItems.AQI {
                                anchors.fill: parent
                            }
                        }

                        Card {
                            zoomPage: precipitationPages
                            content: WeatherItems.Precipitation {
                                anchors.fill: parent
                            }
                        }

                        Card {
                            zoomPage: moonPages
                            content: WeatherItems.Moon {
                                anchors.fill: parent
                            }
                        }

                        WeatherItems.Cloudiness {
                            implicitHeight: 150
                            implicitWidth: 150
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                        Layout.preferredHeight: 20
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: drawerContent.anyPageOpen
                hoverEnabled: true
                visible: drawerContent.anyPageOpen
                onClicked: {}
                onPressed: {}
                onReleased: {}
            }

            WeatherPages.Humidity {
                id: humidityPages
            }

            WeatherPages.Sun {
                id: sunPages
            }

            WeatherPages.Pressure {
                id: pressurePages
            }

            WeatherPages.Visibility {
                id: visibilityPages
            }

            WeatherPages.Wind {
                id: windPages
            }

            WeatherPages.AQI {
                id: aqiPages
            }

            WeatherPages.Precipitation {
                id: precipitationPages
            }

            WeatherPages.Moon {
                id: moonPages
            }

            WeatherPages.UVIndex {
                id: uvIndexPages
            }
        }
    }

    component Card: Item {
        id: cardRoot

        required property var  zoomPage

        default property alias content: cardContent.data

        implicitHeight: 150
        implicitWidth: 150

        Item {
            id: cardContent

            anchors.fill: parent
        }

        MArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            enabled: !root.anyPageOpen
            onClicked: {
                cardRoot.zoomPage.zoomOriginX = cardRoot.mapToItem(root, 0, 0).x + cardRoot.width / 2;
                cardRoot.zoomPage.zoomOriginY = cardRoot.mapToItem(root, 0, 0).y + cardRoot.height / 2;
                cardRoot.zoomPage.isOpen      = true;
            }
        }
    }
}
