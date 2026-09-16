pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var usaBounds: [50, 100, 150, 200, 300]
    readonly property var usaCategories: [
        {
            max: 50,
            label: qsTr("Good")
        },
        {
            max: 100,
            label: qsTr("Fair")
        },
        {
            max: 150,
            label: qsTr("Moderate")
        },
        {
            max: 200,
            label: qsTr("Poor")
        },
        {
            max: 300,
            label: qsTr("Very Poor")
        },
        {
            max: 500,
            label: qsTr("Hazardous")
        }
    ]

    function categoryFor(value, categories) {
        const values = categories ?? usaCategories;
        for (const category of values) {
            if (value <= category.max)
                return category;
        }
        return values[values.length - 1];
    }

    function fraction(value, bounds, max) {
        const segmentCount = bounds.length + 1;
        const segmentWidth = 1 / segmentCount;
        let lower = 0;
        for (let i = 0; i < bounds.length; i++) {
            const upper = bounds[i];
            if (value <= upper)
                return (i + Math.max(0, Math.min(1, (value - lower) / (upper - lower)))) * segmentWidth;
            lower = upper;
        }
        return Math.min(1, (bounds.length + Math.max(0, (value - lower) / (max - lower))) * segmentWidth);
    }
}
