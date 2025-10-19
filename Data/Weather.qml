pragma Singleton

import Quickshell
import QtQuick
import Quickshell.Io

Singleton {
    id: root

    readonly property string weatherConditionData: weatherCondition.text()
    readonly property string weatherDescriptionData: weatherDescription.text()
    readonly property string weatherIconData: weatherIcon.text()
    readonly property string cityData: city.text()
    readonly property int tempData: mainTemp.text()
    readonly property int tempMinData: mainTempMin.text()
    readonly property int tempMaxData: mainTempMax.text()
    readonly property int humidityData: mainHumidity.text()
    readonly property int windSpeedData: windSpeed.text()

    FileView {
        id: weatherCondition
        path: Qt.resolvedUrl(`${Quickshell.env("HOME")}/.cache/weather/main`)

        blockLoading: true
        watchChanges: true
        onFileChanged: this.reload()
    }

    FileView {
        id: weatherDescription
        path: Qt.resolvedUrl(`${Quickshell.env("HOME")}/.cache/weather/description`)

        blockLoading: true
        watchChanges: true
        onFileChanged: this.reload()
    }

    FileView {
        id: weatherIcon
        path: Qt.resolvedUrl(`${Quickshell.env("HOME")}/.cache/weather/icon`)

        blockLoading: true
        watchChanges: true
        onFileChanged: this.reload()
    }

    FileView {
        id: mainTemp
        path: Qt.resolvedUrl(`${Quickshell.env("HOME")}/.cache/weather/temp`)

        blockLoading: true
        watchChanges: true
        onFileChanged: this.reload()
    }

    FileView {
        id: mainTempMin
        path: Qt.resolvedUrl(`${Quickshell.env("HOME")}/.cache/weather/temp_min`)

        blockLoading: true
        watchChanges: true
        onFileChanged: this.reload()
    }

    FileView {
        id: mainTempMax
        path: Qt.resolvedUrl(`${Quickshell.env("HOME")}/.cache/weather/temp_max`)

        blockLoading: true
        watchChanges: true
        onFileChanged: this.reload()
    }

    FileView {
        id: mainHumidity
        path: Qt.resolvedUrl(`${Quickshell.env("HOME")}/.cache/weather/humidity`)

        blockLoading: true
        watchChanges: true
        onFileChanged: this.reload()
    }

    FileView {
        id: windSpeed
        path: Qt.resolvedUrl(`${Quickshell.env("HOME")}/.cache/weather/wind_speed`)

        blockLoading: true
        watchChanges: true
        onFileChanged: this.reload()
    }

    FileView {
        id: city
        path: Qt.resolvedUrl(`${Quickshell.env("HOME")}/.cache/weather/kota`)

        blockLoading: true
        watchChanges: true
        onFileChanged: this.reload()
    }
}
