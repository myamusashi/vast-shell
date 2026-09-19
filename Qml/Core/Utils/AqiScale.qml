pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property list<int> europeBounds: [25, 50, 75, 100, 150]
    readonly property list<int> usaBounds: [50, 100, 150, 200, 300]
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
        if (!isFinite(value) || !bounds || bounds.length === 0)
            return 0;

        const segments = bounds.length + 1;
        let lower = 0;

        for (let i = 0; i < bounds.length; i++) {
            if (value <= bounds[i]) {
                const t = (value - lower) / (bounds[i] - lower);
                return (i + t) / segments;
            }
            lower = bounds[i];
        }

        const t = max > lower ? (value - lower) / (max - lower) : 1;
        return Math.min(1, (bounds.length + Math.max(0, t)) / segments);
    }
}
