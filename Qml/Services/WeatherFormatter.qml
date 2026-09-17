pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell

import qs.Core.Utils

import "Weather/weatherData.js" as WD

Singleton {
    function iconFor(code, isDayTime, dayIcons, nightIcons) {
        if (code === null || code === undefined)
            return WeatherIcon.windy;
        const codeStr = code.toString();
        if (!isDayTime && nightIcons[codeStr])
            return nightIcons[codeStr];
        return dayIcons[codeStr] || WeatherIcon.windy;
    }

    function formatHourOfDay(timeStr) {
        if (!timeStr)
            return "";
        try {
            const date = new Date(timeStr);
            return `${String(date.getHours()).padStart(2, "0")}:${String(date.getMinutes()).padStart(2, "0")}`;
        } catch (e) {
            return timeStr;
        }
    }

    function forecastHour(entry) {
        const time = String(entry?.time || "").split(" ")[1] || entry?.time || "";
        return Number(String(time).split(":")[0]);
    }

    function hourlyFromNow(forecast, currentMinutes) {
        const currentHour = Math.floor(currentMinutes / 60);
        return (forecast || []).filter(function (entry) {
            const hour = forecastHour(entry);
            return isFinite(hour) && hour >= currentHour;
        });
    }

    function isCurrentForecastHour(entry, currentMinutes) {
        return forecastHour(entry) === Math.floor(currentMinutes / 60);
    }

    function moonPhaseText(phase) {
        switch (phase) {
        case "New Moon":
            return qsTr("New Moon");
        case "Waxing Crescent":
            return qsTr("Waxing Crescent");
        case "First Quarter":
            return qsTr("First Quarter");
        case "Waxing Gibbous":
            return qsTr("Waxing Gibbous");
        case "Full Moon":
            return qsTr("Full Moon");
        case "Waning Gibbous":
            return qsTr("Waning Gibbous");
        case "Last Quarter":
            return qsTr("Last Quarter");
        case "Waning Crescent":
            return qsTr("Waning Crescent");
        default:
            return phase || qsTr("Unknown");
        }
    }

    function formatDate(dateStr) {
        if (!dateStr)
            return "";
        try {
            return new Date(dateStr).toLocaleDateString("en-US", {
                weekday: "long",
                month: "short",
                day: "numeric"
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
            return `${String(hours).padStart(2, "0")}:${match[2]}`;
        } catch (e) {
            return timeStr;
        }
    }

    function calculateDayLength(sunRise, sunSet) {
        if (!sunRise || !sunSet)
            return {
                hours: 0,
                minutes: 0
            };
        try {
            const [rh, rm] = sunRise.split(":").map(Number);
            const [sh, sm] = sunSet.split(":").map(Number);
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

    function weatherStatus(code) {
        return WD.statusTexts[code] || "Unknown";
    }

    function windDirectionText(degrees) {
        return WD.getWindDirection(degrees);
    }

    function europeanAQIInfo(aqi) {
        return WD.getAQIInfo(aqi, WD.europeanAQI);
    }

    function usAQIInfo(aqi) {
        return WD.getAQIInfo(aqi, WD.usAQI);
    }

    function dominantPollutant(pm25, pm10) {
        const pm25Ratio = pm25 / 15.0;
        const pm10Ratio = pm10 / 45.0;
        if (pm25Ratio > pm10Ratio && pm25 > 15)
            return "PM2.5";
        if (pm10 > 45)
            return "PM10";
        if (pm25 > pm10)
            return "PM2.5";
        return "PM10";
    }

    function healthRecommendation(euAQI, usAQI, pm25, pm10) {
        let maxAQI = euAQI;
        if (usAQI > 150)
            maxAQI = usAQI;
        if (maxAQI <= 50)
            return "Perfect day for outdoor activities! Air quality is excellent.";
        if (maxAQI <= 75)
            return "Good for most outdoor activities. Sensitive individuals (children, elderly, those with respiratory conditions) should be cautious.";
        if (maxAQI <= 100)
            return "Consider limiting prolonged outdoor activities, especially if you're sensitive to air pollution. Take more breaks during outdoor exercise.";
        if (maxAQI <= 150)
            return "Reduce prolonged or heavy outdoor exertion. Reschedule strenuous activities or take more breaks. Sensitive groups should avoid prolonged outdoor activities.";
        if (maxAQI <= 200)
            return "Avoid prolonged outdoor exertion. Everyone should reduce outdoor activities. Keep outdoor activities short and less strenuous.";
        return "Avoid all outdoor physical activities. Stay indoors, keep windows closed, and use air purifiers if available. Sensitive groups should remain indoors.";
    }

    function quickSummary(data) {
        if (!data.weatherLoaded)
            return "";
        const parts = [];
        const humidity = data.humidity;
        const temperature = data.temperature;
        const europeanAQI = data.europeanAQI;
        const usAQI = data.usAQI;
        const uvIndex = data.uvIndex;
        const precipitation = data.precipitation;
        const windSpeed = data.windSpeed;
        const temperatureMax = data.temperatureMax;
        const temperatureMin = data.temperatureMin;
        const visibility = data.visibility;
        const feelsLike = data.feelsLike;

        if (humidity > 80 && temperature > 25)
            parts.push(qsTr("A muggy and warm day — take care in the sun."));
        else if (humidity > 80 && temperature <= 25)
            parts.push(qsTr("A humid day with sticky conditions."));
        else if (temperature > 30)
            parts.push(qsTr("A hot day ahead — stay hydrated and seek shade."));
        else if (temperature < 10)
            parts.push(qsTr("A cold day — dress warmly before heading out."));
        else if (temperature >= 20 && temperature <= 28 && humidity < 60)
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

        if (temperatureMax > 0 && temperatureMin !== temperatureMax && Math.abs(temperatureMax - temperatureMin) > 8)
            priorityItems.push({
                priority: 5,
                text: qsTr("Large temperature swing today: %1° to %2° — dress in layers.").arg(temperatureMin).arg(temperatureMax)
            });
        else if (temperatureMax > 0 && temperatureMin !== temperatureMax)
            priorityItems.push({
                priority: 3,
                text: qsTr("Temperature ranging from %1° to %2° today.").arg(temperatureMin).arg(temperatureMax)
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
        if (temperature >= 18 && temperature <= 26 && humidity < 65 && uvIndex < 5 && precipitation === 0)
            priorityItems.push({
                priority: 4,
                text: qsTr("Perfect weather for outdoor activities.")
            });

        priorityItems.sort((a, b) => b.priority - a.priority);
        priorityItems.slice(0, 3).forEach(i => parts.push(i.text));
        if (parts.length < 2)
            parts.push(qsTr("Current temperature is %1° with feels like %2°.").arg(temperature).arg(feelsLike));

        const finalParts = parts.slice(0, 4);
        return finalParts.length === 0 ? "" : finalParts[0] + "\n\n• " + finalParts.slice(1).join("\n\n• ");
    }
}
