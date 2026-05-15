pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Core.Utils
import qs.Core.States
import qs.Core.Configs
import qs.Services

Singleton {
    id: root

    // readonly loading states
    readonly property bool isInitialLoading: isLoading && !loaded
    readonly property bool canRefresh: !isLoading
    readonly property bool hasData: loaded
    readonly property bool isLoading: weatherLoading || aqiLoading || astronomyLoading
    readonly property bool isRefreshing: isLoading && loaded

    readonly property var weatherIcons: ({
            "0": WeatherIcon.day_sunny,
            "1": WeatherIcon.day_cloudy,
            "2": WeatherIcon.day_cloudy,
            "3": WeatherIcon.cloud,
            "45": WeatherIcon.fog,
            "48": WeatherIcon.fog,
            "51": WeatherIcon.rain,
            "53": WeatherIcon.rain,
            "55": WeatherIcon.rain,
            "56": WeatherIcon.sleet,
            "57": WeatherIcon.sleet,
            "61": WeatherIcon.rain,
            "63": WeatherIcon.rain,
            "65": WeatherIcon.rain,
            "66": WeatherIcon.rain_mix,
            "67": WeatherIcon.rain_mix,
            "71": WeatherIcon.snow,
            "73": WeatherIcon.snow,
            "75": WeatherIcon.snow,
            "77": WeatherIcon.snow,
            "80": WeatherIcon.showers,
            "81": WeatherIcon.showers,
            "82": WeatherIcon.storm_showers,
            "85": WeatherIcon.snow,
            "86": WeatherIcon.snow,
            "95": WeatherIcon.thunderstorm,
            "96": WeatherIcon.thunderstorm,
            "99": WeatherIcon.thunderstorm
        })

    readonly property var weatherIconsNight: ({
            "0": WeatherIcon.night_clear,
            "1": WeatherIcon.night_cloudy,
            "2": WeatherIcon.night_cloudy
        })

    readonly property var weatherSchema: [
        {
            key: "latitude",
            def: 0.0
        },
        {
            key: "longitude",
            def: 0.0
        },
        {
            key: "timezone",
            def: ""
        },
        {
            key: "elevation",
            def: 0.0
        },
        {
            key: "weatherCondition",
            def: ""
        },
        {
            key: "weatherDescription",
            def: ""
        },
        {
            key: "weatherIcon",
            def: "air"
        },
        {
            key: "weatherCode",
            def: 0
        },
        {
            key: "isDay",
            def: true
        },
        {
            key: "temp",
            def: 0
        },
        {
            key: "tempMin",
            def: 0
        },
        {
            key: "tempMax",
            def: 0
        },
        {
            key: "feelsLike",
            def: 0
        },
        {
            key: "humidity",
            def: 0
        },
        {
            key: "dewPoint",
            def: 0.0
        },
        {
            key: "windSpeed",
            def: 0
        },
        {
            key: "windDirection",
            def: ""
        },
        {
            key: "windDirectionDegrees",
            def: 0
        },
        {
            key: "uvIndex",
            def: 0
        },
        {
            key: "pressure",
            def: 0
        },
        {
            key: "visibility",
            def: 0.0
        },
        {
            key: "cloudCover",
            def: 0
        },
        {
            key: "precipitation",
            def: 0.0
        },
        {
            key: "precipitationDaily",
            def: 0.0
        },
        {
            key: "hourlyForecast",
            def: []
        },
        {
            key: "dailyForecast",
            def: []
        },
        {
            key: "europeanAQI",
            def: 0
        },
        {
            key: "europeanAQICategory",
            def: ""
        },
        {
            key: "europeanAQIColor",
            def: ""
        },
        {
            key: "europeanDescription",
            def: ""
        },
        {
            key: "usAQI",
            def: 0
        },
        {
            key: "usAQICategory",
            def: ""
        },
        {
            key: "usAQIColor",
            def: ""
        },
        {
            key: "usDescription",
            def: ""
        },
        {
            key: "pm10",
            def: 0.0
        },
        {
            key: "pm25",
            def: 0.0
        },
        {
            key: "dominantPollutant",
            def: ""
        },
        {
            key: "healthRecommendation",
            def: ""
        },
        {
            key: "hourlyAQIForecast",
            def: []
        },
        {
            key: "sunRise",
            def: ""
        },
        {
            key: "sunSet",
            def: ""
        },
        {
            key: "moonRise",
            def: ""
        },
        {
            key: "moonSet",
            def: ""
        },
        {
            key: "moonPhase",
            def: ""
        },
        {
            key: "moonIllumination",
            def: 0
        },
        {
            key: "isMoonUp",
            def: false
        },
        {
            key: "isSunUp",
            def: false
        },
        {
            key: "locationName",
            def: ""
        },
        {
            key: "locationRegion",
            def: ""
        },
        {
            key: "locationCountry",
            def: ""
        },
        {
            key: "timeZoneIdentifier",
            def: ""
        },
        {
            key: "lastUpdateWeather",
            def: ""
        },
        {
            key: "lastUpdateAQI",
            def: ""
        },
        {
            key: "lastUpdateAstronomy",
            def: ""
        }
    ]

    // Weather properties
    property real latitude: 0.0
    property real longitude: 0.0
    property string timezone: ""
    property real elevation: 0.0
    property string lastUpdateWeather
    property string weatherCondition: ""
    property string weatherDescription: ""
    property string weatherIcon: "air"
    property int weatherCode: 0
    property bool isDay: true
    property int temp: 0
    property int tempMin: 0
    property int tempMax: 0
    property int feelsLike: 0
    property int humidity: 0
    property real dewPoint: 0.0
    property int windSpeed: 0
    property string windDirection: ""
    property int windDirectionDegrees: 0
    property int uvIndex: 0
    property int pressure: 0
    property real visibility: 0.0
    property int cloudCover: 0
    property real precipitation: 0.0
    property real precipitationDaily: 0.0
    property string lastUpdateAstronomy
    property string sunRise: ""
    property string sunSet: ""
    property string dayLength: ""
    property string moonRise: ""
    property string moonSet: ""
    property string moonPhase: ""
    property int moonIllumination: 0
    property bool isMoonUp: false
    property bool isSunUp: false

    property var hourlyForecast: []
    property var dailyForecast: []

    // AQI properties
    property string lastUpdateAQI
    property int europeanAQI: 0
    property string europeanAQICategory: ""
    property string europeanAQIColor: ""
    property string europeanDescription: ""
    property int usAQI: 0
    property string usAQICategory: ""
    property string usAQIColor: ""
    property string usDescription: ""
    property real pm10: 0.0
    property real pm25: 0.0
    property string dominantPollutant: ""
    property string healthRecommendation: ""
    property var hourlyAQIForecast: []

    // Loading states
    property bool weatherLoaded: false
    property bool weatherLoading: false
    property bool aqiLoaded: false
    property bool aqiLoading: false
    property bool astronomyLoaded: false
    property bool astronomyLoading: false
    property bool loaded: weatherLoaded && aqiLoaded && astronomyLoaded

    // Locations
    property string locationName: ""
    property string locationRegion: ""
    property string locationCountry: ""
    property string timeZoneIdentifier: ""

    property string configLatitude: Configs.weather.latitude
    property string configLongitude: Configs.weather.longitude
    property int reloadInterval: Configs.weather.reloadTime || 1800000

    property var _activeWeatherRequest: null
    property var _activeAQIRequest: null
    property var _activeAstronomyRequest: null

    function getWeatherIconFromCode(code, isDayTime) {
        if (code === null || code === undefined)
            return WeatherIcon.windy;
        const codeStr = code.toString();
        if (!isDayTime && weatherIconsNight[codeStr])
            return weatherIconsNight[codeStr];
        return weatherIcons[codeStr] || WeatherIcon.windy;
    }

    function formatTime(timeStr) {
        if (!timeStr)
            return "";
        try {
            const date = new Date(timeStr);
            return `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`;
        } catch (e) {
            return timeStr;
        }
    }

    function formatDate(dateStr) {
        if (!dateStr)
            return "";
        try {
            return new Date(dateStr).toLocaleDateString('en-US', {
                weekday: 'long',
                month: 'short',
                day: 'numeric'
            });
        } catch (e) {
            return dateStr;
        }
    }

    function parseAstronomyTime(timeStr) {
        if (!timeStr)
            return "";
        try {
            const match = timeStr.match(/(\d{1,2}):(\d{2})\s*(AM|PM)/i);
            if (!match)
                return timeStr;
            let hours = parseInt(match[1]);
            const period = match[3].toUpperCase();
            if (period === "PM" && hours !== 12)
                hours += 12;
            else if (period === "AM" && hours === 12)
                hours = 0;
            return `${String(hours).padStart(2, '0')}:${match[2]}`;
        } catch (e) {
            return timeStr;
        }
    }

    function calculateDayLength() {
        if (!sunRise || !sunSet)
            return {
                hours: 0,
                minutes: 0
            };
        try {
            const [rh, rm] = sunRise.split(':').map(Number);
            const [sh, sm] = sunSet.split(':').map(Number);
            let total = (sh * 60 + sm) - (rh * 60 + rm);
            if (total < 0)
                total += 24 * 60;
            return {
                hours: Math.floor(total / 60),
                minutes: total % 60
            };
        } catch (e) {
            return {
                hours: 0,
                minutes: 0
            };
        }
    }

    function getQuickSummary() {
        if (!weatherLoaded)
            return "";
        const parts = [];

        if (humidity > 80 && temp > 25)
            parts.push(qsTr("A muggy and warm day — take care in the sun."));
        else if (humidity > 80 && temp <= 25)
            parts.push(qsTr("A humid day with sticky conditions."));
        else if (temp > 30)
            parts.push(qsTr("A hot day ahead — stay hydrated and seek shade."));
        else if (temp < 10)
            parts.push(qsTr("A cold day — dress warmly before heading out."));
        else if (temp >= 20 && temp <= 28 && humidity < 60)
            parts.push(qsTr("A pleasant day with comfortable conditions."));
        else
            parts.push(qsTr("Today's weather looks moderate."));

        const priorityItems = [];
        if (europeanAQI > 80 || usAQI > 150)
            priorityItems.push({
                priority: 10,
                text: qsTr("Air quality is poor right now — consider limiting time outside.")
            });
        else if (europeanAQI > 60 || usAQI > 100)
            priorityItems.push({
                priority: 7,
                text: qsTr("Air quality is moderate — sensitive groups should take precautions.")
            });

        if (uvIndex >= 8)
            priorityItems.push({
                priority: 9,
                text: qsTr("UV index is very high (%1) — avoid direct sun exposure.").arg(uvIndex)
            });
        else if (uvIndex >= 6)
            priorityItems.push({
                priority: 6,
                text: qsTr("Strong UV levels at %1 — use sun protection.").arg(uvIndex)
            });

        if (precipitation > 5)
            priorityItems.push({
                priority: 8,
                text: qsTr("Heavy rain expected — bring an umbrella.")
            });
        else if (precipitation > 0.5)
            priorityItems.push({
                priority: 5,
                text: qsTr("Light rain possible — keep an umbrella handy.")
            });

        if (windSpeed > 50)
            priorityItems.push({
                priority: 8,
                text: qsTr("Very windy conditions at %1 km/h — be cautious outdoors.").arg(windSpeed)
            });
        else if (windSpeed > 30)
            priorityItems.push({
                priority: 4,
                text: qsTr("Breezy day with winds around %1 km/h.").arg(windSpeed)
            });

        if (tempMax > 0 && tempMin !== tempMax && Math.abs(tempMax - tempMin) > 8)
            priorityItems.push({
                priority: 5,
                text: qsTr("Large temperature swing today: %1° to %2° — dress in layers.").arg(tempMin).arg(tempMax)
            });
        else if (tempMax > 0 && tempMin !== tempMax)
            priorityItems.push({
                priority: 3,
                text: qsTr("Temperature ranging from %1° to %2° today.").arg(tempMin).arg(tempMax)
            });

        if (humidity > 85)
            priorityItems.push({
                priority: 6,
                text: qsTr("Very sticky conditions with %1% humidity.").arg(humidity)
            });
        if (visibility < 1)
            priorityItems.push({
                priority: 7,
                text: qsTr("Poor visibility at %1 km — drive carefully.").arg(visibility.toFixed(1))
            });
        if (temp >= 18 && temp <= 26 && humidity < 65 && uvIndex < 5 && precipitation === 0)
            priorityItems.push({
                priority: 4,
                text: qsTr("Perfect weather for outdoor activities.")
            });

        priorityItems.sort((a, b) => b.priority - a.priority);
        priorityItems.slice(0, 3).forEach(i => parts.push(i.text));
        if (parts.length < 2)
            parts.push(qsTr("Current temperature is %1° with feels like %2°.").arg(temp).arg(feelsLike));

        const isFinal = parts.slice(0, 4);
        return isFinal.length === 0 ? "" : isFinal[0] + "\n\n• " + isFinal.slice(1).join("\n\n• ");
    }

    function _cleanupRequest(request) {
        if (request) {
            try {
                request.onreadystatechange = null;
                request.onerror = null;
                request.ontimeout = null;
            } catch (e) {
                console.error("Error cleaning up request handlers:", e);
            }
        }
    }

    function _fetchData(config) {
        const lat = parseFloat(configLatitude);
        const lon = parseFloat(configLongitude);
        if (isNaN(lat) || isNaN(lon)) {
            ToastService.show(qsTr("Invalid coordinates"), qsTr("Weather"), "weather-clear-symbolic", 3000);
            return;
        }
        if (root[config.loadingProp])
            return;

        if (root[config.requestProp]) {
            try {
                root[config.requestProp].abort();
            } catch (e) {}
            _cleanupRequest(root[config.requestProp]);
            root[config.requestProp] = null;
        }

        root[config.loadingProp] = true;
        const request = new XMLHttpRequest();
        root[config.requestProp] = request;
        request.timeout = 30000;

        request.onreadystatechange = function () {
            if (request.readyState !== XMLHttpRequest.DONE)
                return;
            if (request === root[config.requestProp])
                root[config.requestProp] = null;

            if (request.status === 200) {
                try {
                    config.onSuccess(JSON.parse(request.responseText));
                    ToastService.show(qsTr("%1 updated").arg(config.label), qsTr("Weather"), "weather-clear-symbolic", 2000);
                } catch (e) {
                    ToastService.show(qsTr("%1 failed: bad data").arg(config.label), qsTr("Weather"), "weather-error-symbolic", 3000);
                    root[config.loadingProp] = false;
                }
            } else {
                ToastService.show(qsTr("%1 failed (%2)").arg(config.label).arg(request.status), qsTr("Weather"), "weather-error-symbolic", 3000);
                root[config.loadingProp] = false;
            }
            _cleanupRequest(request);
        };

        const fail = reason => () => {
                ToastService.show(qsTr("%1 %2").arg(config.label).arg(reason), qsTr("Weather"), "weather-error-symbolic", 3000);
                if (request === root[config.requestProp])
                    root[config.requestProp] = null;
                root[config.loadingProp] = false;
                _cleanupRequest(request);
            };
        request.onerror = fail(qsTr("network error"));
        request.ontimeout = fail(qsTr("timed out"));

        request.open("GET", `${config.url}?latitude=${lat}&longitude=${lon}`);
        request.send();
    }

    function reloadWeather() {
        _fetchData({
            url: "https://weather.myamusashi.cc/v1/forecast",
            loadingProp: "weatherLoading",
            requestProp: "_activeWeatherRequest",
            onSuccess: updateWeatherData,
            label: "Weather"
        });
    }
    function reloadAQI() {
        _fetchData({
            url: "https://aqi.myamusashi.cc/v1/aqi",
            loadingProp: "aqiLoading",
            requestProp: "_activeAQIRequest",
            onSuccess: updateAQIData,
            label: "AQI"
        });
    }
    function reloadAstronomy() {
        _fetchData({
            url: "https://astronomy.myamusashi.cc/v1/astronomy",
            loadingProp: "astronomyLoading",
            requestProp: "_activeAstronomyRequest",
            onSuccess: updateAstronomyData,
            label: "Astronomy"
        });
    }

    function reload() {
        reloadWeather();
        reloadAQI();
        reloadAstronomy();
    }

    function refresh() {
        if (canRefresh) {
            console.log("[WEATHER SERVICES] Refresh/reload weather data");
            reload();
            return true;
        } else {
            console.log("[WEATHER SERVICES] Cannot refresh: already loading");
            return false;
        }
    }

    function updateWeatherData(json) {
        try {
            const loc = json.location || {}, cur = json.current || {}, det = json.details || {};
            const hourly = json.hourly_forecast || [], daily = json.daily_forecast || {};
            const hum = det.humidity || {}, wind = det.wind || {};

            weatherLoaded = true;
            weatherLoading = false;
            lastUpdateWeather = cur.last_update || Date.now();
            latitude = loc.latitude || 0.0;
            longitude = loc.longitude || 0.0;
            timezone = loc.timezone || "";
            elevation = loc.elevation || 0.0;

            temp = Math.round(cur.temperature || 0);
            feelsLike = Math.round(cur.feels_like || 0);
            tempMin = Math.round(cur.min_temp || 0);
            tempMax = Math.round(cur.max_temp || 0);
            weatherCode = cur.weather_code || 0;
            weatherCondition = cur.status || "";
            weatherDescription = cur.status || "";
            isDay = cur.is_day || false;
            weatherIcon = getWeatherIconFromCode(cur.weather_code, cur.is_day);

            humidity = hum.percentage || 0;
            dewPoint = hum.dew_point || 0.0;
            windSpeed = Math.round(wind.speed_kmh || 0);
            windDirection = wind.direction_text || "";
            windDirectionDegrees = wind.direction_degrees || 0;
            uvIndex = Math.round(det.uv_index || 0);
            pressure = Math.round(det.surface_pressure_hpa || 0);
            visibility = det.visibility_km || 0.0;
            cloudCover = det.cloudiness_percent || 0;
            precipitation = det.precipitation_current_mm || 0.0;
            precipitationDaily = det.precipitation_daily_mm || 0.0;

            hourlyForecast = hourly.map(h => ({
                        time: formatTime(h.time),
                        fullTime: h.time,
                        temperature: Math.round(h.temperature),
                        humidity: h.humidity,
                        weatherCode: h.weather_code,
                        weatherIcon: getWeatherIconFromCode(h.weather_code, h.is_day),
                        isDay: h.is_day,
                        precipitation: h.precipitation_mm || 0.0,
                        probability: h.probability_percent || 0,
                        pressure: h.pressure_hpa || 0.0,
                        windSpeed: h.wind.speed_kmh || 0.0,
                        windDirectionDegrees: h.wind.direction_degrees || 0,
                        windDirectionText: h.wind.direction_text || ""
                    }));

            dailyForecast = daily.map(d => ({
                        date: d.date,
                        day: d.day,
                        dateFormatted: d.date_formatted,
                        maxTemp: Math.round(d.max_temp),
                        minTemp: Math.round(d.min_temp),
                        humidity: d.humidity,
                        weatherCode: d.weather_code,
                        weatherIcon: getWeatherIconFromCode(d.weather_code, true),
                        rainProbability: d.rain_probability,
                        sunrise: formatTime(d.sunrise),
                        sunset: formatTime(d.sunset),
                        precipitation: d.precipitation_mm || 0.0,
                        rain: d.rain_mm || 0.0,
                        showers: d.showers_mm || 0.0
                    }));

            saveTimer.restart();
            console.log("Weather data updated successfully");
        } catch (e) {
            console.error("Failed to update weather data:", e);
            weatherLoading = false;
        }
    }

    function updateAQIData(json) {
        try {
            const loc = json.location || {}, cur = json.current || {}, hourly = json.hourly_forecast || [];

            aqiLoaded = true;
            aqiLoading = false;
            lastUpdateAQI = cur.last_update || Date.now();

            if (!latitude) {
                latitude = loc.latitude || 0.0;
                longitude = loc.longitude || 0.0;
                timezone = loc.timezone || "";
                elevation = loc.elevation || 0.0;
            }

            europeanAQI = cur.european_aqi || 0;
            europeanAQICategory = cur.european_aqi_category || "";
            europeanAQIColor = cur.european_aqi_color || "";
            europeanDescription = cur.european_description || "";
            usAQI = cur.us_aqi || 0;
            usAQICategory = cur.us_aqi_category || "";
            usAQIColor = cur.us_aqi_color || "";
            usDescription = cur.us_description || "";
            pm10 = cur.pm10_ugm3 || 0.0;
            pm25 = cur.pm25_ugm3 || 0.0;
            dominantPollutant = cur.dominant_pollutant || "";
            healthRecommendation = json.health_recommendation || "";

            hourlyAQIForecast = hourly.map(h => ({
                        time: formatTime(h.time),
                        fullTime: h.time,
                        europeanAQI: h.european_aqi,
                        europeanAQICategory: h.european_aqi_category,
                        usAQI: h.us_aqi,
                        usAQICategory: h.us_aqi_category,
                        pm10: h.pm10_ugm3,
                        pm25: h.pm25_ugm3
                    }));

            saveTimer.restart();
        } catch (e) {
            console.error("Failed to update AQI data:", e);
            aqiLoading = false;
        }
    }

    function updateAstronomyData(json) {
        try {
            const astro = json.astro || {}, loc = json.location || {};
            astronomyLoaded = true;
            astronomyLoading = false;

            sunRise = parseAstronomyTime(astro.sunrise);
            sunSet = parseAstronomyTime(astro.sunset);
            moonRise = parseAstronomyTime(astro.moonrise);
            moonSet = parseAstronomyTime(astro.moonset);
            moonPhase = astro.moon_phase || "";
            moonIllumination = astro.moon_illumination || 0;
            isMoonUp = astro.is_moon_up === 1;
            isSunUp = astro.is_sun_up === 1;
            dayLength = "";

            locationName = loc.name || "";
            locationRegion = loc.region || "";
            locationCountry = loc.country || "";
            timeZoneIdentifier = loc.tz_id || "";
            lastUpdateAstronomy = loc.localtime || Date.now();

            saveTimer.restart();
        } catch (e) {
            console.error("Failed to update astronomy data:", e);
            astronomyLoading = false;
        }
    }

    function buildSaveData() {
        const data = {
            timestamp: Date.now()
        };
        for (const field of weatherSchema)
            data[field.key] = root[field.key];
        return data;
    }

    function restoreFromCache(data) {
        for (const field of weatherSchema)
            root[field.key] = data[field.key] ?? field.def;
    }

    function _reloadIfLoaded() {
        if (weatherLoaded || aqiLoaded || astronomyLoaded)
            reload();
    }

    Timer {
        id: reloadTimer

        interval: root.reloadInterval
        running: GlobalStates.isWeatherPanelOpen
        repeat: GlobalStates.isWeatherPanelOpen
        triggeredOnStart: false
        onTriggered: root.reload()
    }

    Timer {
        id: saveTimer

        interval: 100
        onTriggered: storage.setText(JSON.stringify(root.buildSaveData(), null, 2))
    }

    FileView {
        id: storage

        path: Paths.cacheDir + "/weather_shell/weather.json"
        onLoaded: {
            try {
                const content = text();
                if (!content.trim()) {
                    console.log("No cached weather data found, fetching fresh data");
                    ToastService.show(qsTr("No cached weather data found, fetching fresh data"), qsTr("Weather"), "weather-clear-symbolic", 3000);
                    root.reload();
                    return;
                }

                const data = JSON.parse(content);
                console.log("Loading weather data from cache...");
                root.restoreFromCache(data);

                root.weatherLoaded = true;
                root.aqiLoaded = true;
                root.astronomyLoaded = true;

                const age = Math.floor((Date.now() - (data.timestamp || 0)) / 60000);
                console.log(`Loaded weather data from cache (${age} minutes old)`);
                console.log("Fetching fresh weather data in background...");

                reloadTimer.start();
                root.reload();
            } catch (error) {
                console.error("Failed to load weather cache:", error);
                root.reload();
            }
        }
        onLoadFailed: error => {
            console.log("Weather cache doesn't exist, creating it and fetching data");
            setText("{}");
            root.reload();
        }
    }

    Component.onDestruction: {
        for (const prop of ["_activeWeatherRequest", "_activeAQIRequest", "_activeAstronomyRequest"]) {
            if (root[prop]) {
                try {
                    root[prop].abort();
                } catch (e) {}
                _cleanupRequest(root[prop]);
                root[prop] = null;
            }
        }
    }
    onConfigLatitudeChanged: _reloadIfLoaded()
    onConfigLongitudeChanged: _reloadIfLoaded()
}
