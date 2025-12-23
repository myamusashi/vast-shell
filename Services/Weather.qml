pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Configs
import qs.Helpers

Singleton {
    id: root

    // Thx caelestia
    readonly property var weatherIcons: ({
            "113": "clear_day",
            "116": "partly_cloudy_day",
            "119": "cloud",
            "122": "cloud",
            "143": "foggy",
            "176": "rainy",
            "179": "rainy",
            "182": "rainy",
            "185": "rainy",
            "200": "thunderstorm",
            "227": "cloudy_snowing",
            "230": "snowing_heavy",
            "248": "foggy",
            "260": "foggy",
            "263": "rainy",
            "266": "rainy",
            "281": "rainy",
            "284": "rainy",
            "293": "rainy",
            "296": "rainy",
            "299": "rainy",
            "302": "weather_hail",
            "305": "rainy",
            "308": "weather_hail",
            "311": "rainy",
            "314": "rainy",
            "317": "rainy",
            "320": "cloudy_snowing",
            "323": "cloudy_snowing",
            "326": "cloudy_snowing",
            "329": "snowing_heavy",
            "332": "snowing_heavy",
            "335": "snowing",
            "338": "snowing_heavy",
            "350": "rainy",
            "353": "rainy",
            "356": "rainy",
            "359": "weather_hail",
            "362": "rainy",
            "365": "rainy",
            "368": "cloudy_snowing",
            "371": "snowing",
            "374": "rainy",
            "377": "rainy",
            "386": "thunderstorm",
            "389": "thunderstorm",
            "392": "thunderstorm",
            "395": "snowing"
        })

    function getWeatherIcon(code) {
        if (code && weatherIcons.hasOwnProperty(code.toString()))
            return weatherIcons[code.toString()];
        return "air";
    }

    FileView {
        id: weatherFile

        path: Paths.cacheDir + "/weather_shell/weather.json"
        watchChanges: true
        blockLoading: true
        blockWrites: true
        onLoadFailed: err => {
            if (err !== FileViewError.FileNotFound)
                console.log("Failed to read config files");
        }
        onSaveFailed: err => console.log("Failed to save config", FileViewError.toString(err))
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: adapter

            property JsonObject weather: JsonObject {
                property string weatherConditionData: ""
                property string weatherDescriptionData: ""
                property string weatherIconData: "air"
                property string cityData: ""
                property int tempData: 0
                property int tempMinData: 0
                property int tempMaxData: 0
                property int humidityData: 0
                property int windSpeedData: 0
            }
        }
    }

    property string city: Configs.weather.city

    readonly property string weatherConditionData: adapter.weather.weatherConditionData
    readonly property string weatherDescriptionData: adapter.weather.weatherDescriptionData
    readonly property string weatherIconData: adapter.weather.weatherIconData
    readonly property string cityData: adapter.weather.cityData
    readonly property int tempData: adapter.weather.tempData
    readonly property int tempMinData: adapter.weather.tempMinData
    readonly property int tempMaxData: adapter.weather.tempMaxData
    readonly property int humidityData: adapter.weather.humidityData
    readonly property int windSpeedData: adapter.weather.windSpeedData

    function sendRequest(url, callback) {
        let request = new XMLHttpRequest();
        request.onreadystatechange = function () {
            if (request.readyState === XMLHttpRequest.DONE) {
                let response = {
                    "status": request.status,
                    "headers": request.getAllResponseHeaders(),
                    "contentType": request.responseType,
                    "content": request.response
                };
                callback(response);
            }
        };
        request.open("GET", url);
        request.send();
    }

    function updateAdapter(cc, forecast, city) {
        adapter.weather.weatherConditionData = cc?.weatherDesc[0].value ?? "";
        adapter.weather.weatherDescriptionData = cc?.weatherDesc[0].value ?? "";
        adapter.weather.weatherIconData = getWeatherIcon(cc?.weatherCode);
        adapter.weather.cityData = city ?? "";
        adapter.weather.tempData = cc?.temp_C ?? 0;
        adapter.weather.tempMinData = forecast && forecast.length > 0 ? forecast[0].mintempC : 0;
        adapter.weather.tempMaxData = forecast && forecast.length > 0 ? forecast[0].maxtempC : 0;
        adapter.weather.humidityData = cc?.humidity ?? 0;
        adapter.weather.windSpeedData = cc?.windspeedKmph ?? 0;
    }

    function reload() {
        if (!city)
            return;

        const url = `https://wttr.in/${city}?format=j1`;
        sendRequest(url, function (response) {
            if (response.status === 200) {
                try {
                    const json = JSON.parse(response.content);
                    const cc = json.current_condition[0];
                    const forecast = json.weather;

                    updateAdapter(cc, forecast, city);
                } catch (e) {
                    console.error("Failed to parse weather JSON:", e);
                }
            } else {
                console.error("Weather request failed with status:", response.status);
            }
        });
    }

    Timer {
        interval: Configs.weather.reloadTime
        running: true
        repeat: true
        onTriggered: root.reload()
    }
}
