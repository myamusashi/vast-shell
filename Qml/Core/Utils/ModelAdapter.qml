pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root
    function countOf(model) {
        if (!model)
            return 0;
        if (typeof model.count === "function")
            return model.count();
        return Number(model.count ?? model.length ?? 0) || 0;
    }

    function itemAt(model, index) {
        if (!model || index < 0 || index >= countOf(model))
            return null;
        return typeof model.get === "function" ? model.get(index) : model[index] ?? null;
    }

    function valueAt(model, index, role) {
        const item = itemAt(model, index);
        return item ? item[role] : undefined;
    }

    function indexOfValue(model, role, value) {
        for (let index = 0; index < countOf(model); index++) {
            if (valueAt(model, index, role) === value)
                return index;
        }
        return -1;
    }

    function displayText(model, index, role, fallback) {
        const value = valueAt(model, index, role);
        return value === undefined || value === null || value === "" ? fallback : String(value);
    }
}
