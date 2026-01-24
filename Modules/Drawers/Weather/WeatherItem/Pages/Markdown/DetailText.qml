pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property string euroAQI: qsTr(`
The European AQI is a standard system from the European Environment Agency (EEA) for measuring air quality on a scale of 0-100+. This system uses different categories from the USA AQI.


0-20 (Good): Air quality is excellent, no health risks for outdoor activities.


20-40 (Fair): Air quality is good, safe for everyone to do normal activities.


40-60 (Moderate): Air quality is moderate, people with very sensitive respiratory issues may need to reduce intense outdoor activities.


60-80 (Poor): Air quality is poor, sensitive groups such as children, elderly, and people with respiratory problems should reduce heavy outdoor activities.


80-100 (Very Poor): Air quality is very poor, everyone should reduce outdoor activities especially heavy ones. Sensitive groups should stay indoors.

100+ (Extremely Poor): Air quality is extremely hazardous, everyone must avoid outdoor activities and stay indoors with closed ventilation.
`)

    readonly property string usAQI: qsTr(`
The USA AQI is a standard system from the EPA (Environmental Protection Agency) for measuring air quality on a scale of 0-500. The higher the AQI value, the worse the air quality.

0-50 (Good): Air quality is good, safe for everyone to do outdoor activities without restrictions.

51-100 (Moderate): Air quality is acceptable, but people who are very sensitive to air pollution may experience minor health effects.

101-150 (Unhealthy for Sensitive Groups): Sensitive groups such as children, elderly, and people with asthma or heart disease may experience health effects. General public is still safe.

151-200 (Unhealthy): Everyone may begin to experience health effects, sensitive groups may experience more serious effects. Reduce heavy outdoor activities.

201-300 (Very Unhealthy): Serious health alert, everyone is at risk of experiencing health problems. Avoid outdoor activities.
`)

    readonly property string humidity: qsTr(`
Humidity measures the amount of water vapor in the air, typically expressed as relative humidity—the percentage of moisture the air holds compared to its maximum capacity at that temperature. High humidity makes hot weather feel more uncomfortable because sweat evaporates slowly from our skin, while low humidity causes rapid evaporation, leading to dry skin and making cold air feel harsher.


Dew point is the temperature at which air becomes saturated and water vapor condenses into dew or fog. Unlike relative humidity which fluctuates with temperature, dew point provides a stable measure of actual moisture content. Dew points above 65°F (18°C) feel uncomfortable, and above 70°F (21°C) feel oppressive, making it a more reliable indicator of how muggy the air actually feels.
`)

    readonly property string moon: qsTr(`
Lunar illumination shows how much of the moon we can see from Earth, from 0% (new moon) to 100% (full moon). Full moons provide bright light for nighttime activities, while new moons create dark skies perfect for stargazing.

**New Moon (0%)**: The moon sits between Earth and the sun, invisible in the night sky.

**Waxing Crescent**: A thin sliver of light appears on the right side, visible after sunset in the western sky.

**First Quarter (50%)**: Half the moon is lit up, visible from afternoon through midnight.

**Waxing Gibbous**: More than half the moon is illuminated, growing toward full.

**Full Moon (100%)**: The entire moon is bright, rising at sunset and setting at sunrise.

**Waning Gibbous**: Just past full, slightly darkened on the left side, visible late evening into morning.

**Last Quarter (50%)**: Half illuminated on the left side, rises around midnight.

**Waning Crescent**: A thin crescent on the left, visible before dawn in the eastern sky, shrinking until it disappears.
`)

    readonly property string precipitation: qsTr(`
Precipitation is any form of water that falls from the atmosphere to the Earth's surface, including rain, snow, hail, or drizzle. Some important aspects of precipitation include probability, duration, intensity, and accumulation.

The probability of precipitation is expressed as a percentage, indicating the likelihood of rain occurring in a given area. A figure of 30% means that there is a 3 in 10 chance of rain falling in your location. Duration measures how long the precipitation lasts, ranging from a few minutes for a drizzle to several hours for prolonged rain.

Intensity classifies how hard the precipitation falls. Light rain ranges from 0-2.5 mm/hour, moderate rain from 2.5-10 mm/hour, heavy rain from 10-50 mm/hour, and very heavy rain above 50 mm/hour. Accumulation indicates the total rainfall collected over a specific period of time, usually measured in millimeters. An accumulation of 10-20 mm is enough to make the ground wet, while over 50 mm in a day can cause flooding in areas with poor drainage.
`)

    readonly property string pressure: qsTr(`
Surface air pressure measures the weight of the atmosphere above sea level, expressed in hPa (hectopascals) or mbar (millibars). Normal pressure ranges from 1013 to 1015 hPa.
High pressure (above 1020 hPa) usually brings clear and stable weather because the air descends and prevents cloud formation. Conversely, low pressure (below 1000 hPa) is often associated with bad weather, thick clouds, and the possibility of rain because the air rises and condenses.
Rapid changes in pressure indicate significant weather changes. A drastic drop often indicates an approaching storm, while a rapid rise indicates improving weather. Barometers measure this pressure to help predict short-term weather conditions.
`)

    readonly property string sun: qsTr(`
Sunrise occurs when the sun appears above the horizon in the morning, marking the beginning of daylight hours. The exact time varies by location and season. During sunrise, temperatures are typically at their coolest point of the day, and visibility gradually improves as natural light increases.

Sunset is when the sun disappears below the horizon in the evening, ending the period of daylight. Like sunrise, the timing depends on geographic location and time of year. Temperatures begin to drop after sunset, and darkness gradually sets in as twilight fades.
`)

    readonly property string uvIndex: qsTr(`
The UV Index measures the intensity of ultraviolet radiation from the sun that reaches the earth's surface, on a scale of 0-11+. The higher the number, the greater the risk of skin and eye damage from sun exposure.

Low levels (0-2) require minimal protection.

Moderate levels (3-5) require a hat and sunscreen when outdoors for more than 30 minutes.

High levels (6-7) require the use of SPF 30+ sunscreen, a hat, and sunglasses, as well as avoiding direct sunlight at midday.

Very high levels (8-10) can cause skin damage in a short time.

Excessive UV exposure without protection can cause sunburn, premature aging, eye damage, and increase the risk of skin cancer. Even on cloudy days, up to 80% of UV radiation can still penetrate clouds. Peak UV intensity typically occurs between 10 a.m. and 4 p.m.
`)

    readonly property string visibility: qsTr(`
Visibility measures how far you can see clearly, usually expressed in kilometers or meters. Ideal conditions provide visibility of more than 10 km, allowing you to see the landscape clearly.


Precipitation such as heavy rain can reduce visibility to 1-5 km because water droplets block light. Very heavy rain can even limit visibility to less than 1 km. Heavy snow has an even more severe effect, often reducing visibility to just a few hundred meters.


Fog is the main cause of low visibility, especially thick fog, which can reduce visibility to less than 200 meters or even 50 meters in extreme conditions. Smoke, dust, or air pollution can also reduce air quality and limit visibility. Visibility conditions are very important for driving safety, aviation, and outdoor activities.
`)

    readonly property string wind: qsTr(`
Wind speed measures how fast the air is moving, usually expressed in km/h, m/s, or knots. A light breeze ranges from 5-20 km/h, a moderate wind is between 20-40 km/h, and a strong wind is above 40 km/h.


Wind gusts are sudden, brief increases in wind speed, usually lasting less than 20 seconds. Gusts can be 30-50% stronger than the average wind speed and are more dangerous because of their unpredictable nature. For example, if the average wind speed is 30 km/h, gusts can reach 45-50 km/h.


Strong gusts can uproot trees, damage buildings, and make driving dangerous, especially for tall vehicles such as trucks or buses. Outdoor activities such as sailing, hiking, or camping require attention to wind conditions for safety.
`)
}
