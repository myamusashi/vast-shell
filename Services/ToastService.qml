pragma Singleton

import QtQuick
import Quickshell

Singleton {
    property ListModel model: ListModel {}

    function show(description, header, icon, duration): void {
        model.append({
            description: description,
            header: header ?? "vast-shell",
            icon: icon ?? "notification-active",
            duration: duration ?? 5000
        });
    }
}
