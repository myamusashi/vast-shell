pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

import qs.Configs
import qs.Helpers

// Thanks to Caelestia once again for your amazing code: https://github.com/caelestia-dots/shell/blob/main/modules/notifications/Notification.qml
Singleton {
    id: root

    property alias dnd: persistentProps.dnd

    readonly property list<Notif> notClosed: list && Array.isArray(list) ? list.filter(n => n && !n.closed) : []
    readonly property list<Notif> popups: list && Array.isArray(list) ? list.filter(n => n && n.popup) : []

    property list<Notif> list: []
    property bool loaded: false

    property int maxNotifications: Configs.noti
    property int maxNotificationAge: 604800000

    function clearAll() {
        if (!root.list || !Array.isArray(root.list))
            return;

        for (const notif of root.list.slice())
            if (notif && typeof notif.close === 'function')
                notif.close();
    }

    function cleanupOldNotifications() {
        if (!root.list || !Array.isArray(root.list))
            return;

        const now = Date.now ? Date.now() : new Date().getTime();
        const oldNotifications = root.list.filter(n => {
            if (!n || !n.time || !(n.time instanceof Date))
                return false;
            const age = now - n.time.getTime();
            return age > root.maxNotificationAge;
        });

        if (oldNotifications.length > 0) {
            console.log(`Cleaning up ${oldNotifications.length} old notification(s)`);
            for (const notif of oldNotifications)
                if (notif && typeof notif.close === 'function')
                    notif.close();
        }
    }

    function enforceNotificationLimit() {
        cleanupOldNotifications();

        if (!root.notClosed || !Array.isArray(root.notClosed))
            return;

        const currentCount = root.notClosed.length;

        if (currentCount >= root.maxNotifications) {
            const sortedNotifs = root.notClosed.slice().sort((a, b) => {
                if (!a || !a.time)
                    return 1;
                if (!b || !b.time)
                    return -1;
                return a.time - b.time;
            });

            const toRemove = currentCount - root.maxNotifications + 1;

            console.log(`Removing ${toRemove} oldest notification(s) to enforce limit`);
            for (let i = 0; i < toRemove && i < sortedNotifs.length; i++) {
                const notif = sortedNotifs[i];
                if (notif && typeof notif.close === 'function')
                    notif.close();
            }
        }
    }

    onListChanged: {
        if (loaded && saveTimer && typeof saveTimer.restart === 'function')
            saveTimer.restart();
    }

    Timer {
        id: saveTimer

        interval: 50
        onTriggered: {
            if (!root.notClosed || !Array.isArray(root.notClosed)) {
                storage.setText("[]");
                return;
            }

            try {
                const dataToSave = root.notClosed.filter(n => n !== null && n !== undefined).map(n => ({
                            time: n.time && n.time.getTime ? n.time.getTime() : Date.now(),
                            id: n.id ?? "",
                            summary: n.summary ?? "",
                            body: n.body ?? "",
                            appIcon: n.appIcon ?? "",
                            appName: n.appName ?? "",
                            image: n.image ?? "",
                            expireTimeout: n.expireTimeout ?? 5000,
                            urgency: n.urgency ?? 0,
                            resident: n.resident ?? false,
                            hasActionIcons: n.hasActionIcons ?? false,
                            actions: Array.isArray(n.actions) ? n.actions : []
                        }));

                storage.setText(JSON.stringify(dataToSave, null, 2));
            } catch (error) {
                console.error("Failed to save notifications:", error);
            }
        }
    }

    Timer {
        id: cleanupTimer

        interval: 3600000
        running: true
        repeat: true
        triggeredOnStart: false
        onTriggered: {
            if (root && typeof root.cleanupOldNotifications === 'function')
                root.cleanupOldNotifications();
        }
    }

    PersistentProperties {
        id: persistentProps

        property bool dnd: false
        reloadableId: "notifs"
    }

    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        actionIconsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        bodySupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => {
            if (!notif) {
                console.error("Received null notification");
                return;
            }

            if (typeof notif.tracked !== 'undefined')
                notif.tracked = true;

            if (root && typeof root.enforceNotificationLimit === 'function')
                root.enforceNotificationLimit();

            let comp = null;
            try {
                comp = notifComponent.createObject(root, {
                    popup: persistentProps ? !persistentProps.dnd : true,
                    notification: notif
                });
            } catch (error) {
                console.error("Failed to create notification component:", error);
                return;
            }

            if (comp && root && root.list && Array.isArray(root.list))
                root.list = [comp, ...root.list];
        }
    }

    FileView {
        id: storage

        path: (Paths && Paths.cacheDir ? Paths.cacheDir : "/tmp") + "/mushell/notifications.json"
        onLoaded: {
            try {
                const content = text ? text() : "";
                if (!content || typeof content !== 'string' || content.trim() === "") {
                    console.log("No cached notifications found");
                    root.loaded = true;
                    return;
                }

                let data = null;
                try {
                    data = JSON.parse(content);
                } catch (parseError) {
                    console.error("Failed to parse notification cache:", parseError);
                    root.loaded = true;
                    return;
                }

                if (!Array.isArray(data)) {
                    console.error("Invalid notification cache format");
                    root.loaded = true;
                    return;
                }

                const now = Date.now ? Date.now() : new Date().getTime();
                let loadedCount = 0;

                for (const notifData of data) {
                    if (!notifData || typeof notifData !== 'object')
                        continue;

                    const notifTime = notifData.time ?? 0;
                    const notifAge = now - notifTime;

                    if (notifAge > root.maxNotificationAge)
                        continue;

                    let notif = null;
                    try {
                        notif = notifComponent.createObject(root, {
                            time: new Date(notifTime),
                            id: notifData.id ?? "",
                            summary: notifData.summary ?? "",
                            body: notifData.body ?? "",
                            appIcon: notifData.appIcon ?? "",
                            appName: notifData.appName ?? "",
                            image: notifData.image ?? "",
                            expireTimeout: notifData.expireTimeout ?? 5000,
                            urgency: notifData.urgency ?? 0,
                            resident: notifData.resident ?? false,
                            hasActionIcons: notifData.hasActionIcons ?? false,
                            actions: Array.isArray(notifData.actions) ? notifData.actions : []
                        });
                    } catch (createError) {
                        console.error("Failed to create notification from cache:", createError);
                        continue;
                    }

                    if (notif && root.list && Array.isArray(root.list)) {
                        root.list.push(notif);
                        loadedCount++;
                    }

                    if (loadedCount >= root.maxNotifications)
                        break;
                }

                if (root.list && Array.isArray(root.list)) {
                    root.list.sort((a, b) => {
                        if (!a || !a.time)
                            return 1;
                        if (!b || !b.time)
                            return -1;
                        return b.time - a.time;
                    });
                }

                console.log(`Loaded ${loadedCount} notification(s) from cache`);
                root.loaded = true;
            } catch (error) {
                console.error("Failed to load notifications:", error);
                root.loaded = true;
            }
        }

        onLoadFailed: error => {
            console.log("Notification cache doesn't exist, creating it");
            if (storage && typeof storage.setText === 'function')
                storage.setText("[]");

            root.loaded = true;
        }
    }

    component Notif: QtObject {
        id: notif

        property bool popup: false
        property bool closed: false

        property date time: new Date()
        readonly property string timeStr: {
            if (!Time || !Time.date || !(Time.date instanceof Date) || !notif.time || !(notif.time instanceof Date))
                return qsTr("now");

            const diff = Time.date.getTime() - notif.time.getTime();
            if (diff < 0)
                return qsTr("now");

            const m = Math.floor(diff / 60000);

            if (m < 1)
                return qsTr("now");

            const h = Math.floor(m / 60);
            const d = Math.floor(h / 24);

            if (d > 0)
                return `${d}d`;
            if (h > 0)
                return `${h}h`;
            return `${m}m`;
        }

        property var notification: null
        property string id: ""
        property string summary: ""
        property string body: ""
        property string appIcon: ""
        property string appName: ""
        property string image: ""
        property real expireTimeout: 5000
        property int urgency: NotificationUrgency ? NotificationUrgency.Normal : 0
        property bool resident: false
        property bool hasActionIcons: false
        property list<var> actions: []

        readonly property Connections conn: Connections {
            target: notif.notification && notif.notification instanceof Notification ? notif.notification : null

            function onClosed() {
                if (notif && typeof notif.close === 'function')
                    notif.close();
            }

            function onSummaryChanged() {
                if (notif && notif.notification)
                    notif.summary = notif.notification.summary ?? "";
            }

            function onBodyChanged() {
                if (notif && notif.notification)
                    notif.body = notif.notification.body ?? "";
            }

            function onAppIconChanged() {
                if (notif && notif.notification)
                    notif.appIcon = notif.notification.appIcon ?? "";
            }

            function onAppNameChanged() {
                if (notif && notif.notification)
                    notif.appName = notif.notification.appName ?? "";
            }

            function onImageChanged() {
                if (notif && notif.notification)
                    notif.image = notif.notification.image ?? "";
            }

            function onExpireTimeoutChanged() {
                if (notif && notif.notification)
                    notif.expireTimeout = notif.notification.expireTimeout ?? 5000;
            }

            function onUrgencyChanged() {
                if (notif && notif.notification)
                    notif.urgency = notif.notification.urgency ?? 0;
            }

            function onResidentChanged() {
                if (notif && notif.notification)
                    notif.resident = notif.notification.resident ?? false;
            }

            function onHasActionIconsChanged() {
                if (notif && notif.notification)
                    notif.hasActionIcons = notif.notification.hasActionIcons ?? false;
            }

            function onActionsChanged() {
                if (notif && notif.notification && Array.isArray(notif.notification.actions)) {
                    notif.actions = notif.notification.actions.filter(a => a !== null && a !== undefined).map(a => ({
                                identifier: a.identifier ?? "",
                                text: a.text ?? "",
                                invoke: typeof a.invoke === 'function' ? () => a.invoke() : () => {}
                            }));
                } else
                    notif.actions = [];
            }
        }

        function dismissPopup() {
            popup = false;
        }

        function close() {
            if (!notif)
                return;

            notif.closed = true;

            if (root && root.list && Array.isArray(root.list) && root.list.includes(notif)) {
                root.list = root.list.filter(n => n !== notif);

                if (notif.notification && typeof notif.notification.dismiss === 'function') {
                    try {
                        notif.notification.dismiss();
                    } catch (e) {
                        console.error("Error dismissing notification:", e);
                    }
                }

                if (conn)
                    conn.target = null;

                try {
                    notif.destroy();
                } catch (e) {
                    console.error("Error destroying notification:", e);
                }
            }
        }

        Component.onCompleted: {
            if (!notif.notification)
                return;

            try {
                notif.id = notif.notification.id ?? "";
                notif.summary = notif.notification.summary ?? "";
                notif.body = notif.notification.body ?? "";
                notif.appIcon = notif.notification.appIcon ?? "";
                notif.appName = notif.notification.appName ?? "";
                notif.image = notif.notification.image ?? "";
                notif.expireTimeout = notif.notification.expireTimeout ?? 5000;
                notif.urgency = notif.notification.urgency ?? (NotificationUrgency ? NotificationUrgency.Normal : 0);
                notif.resident = notif.notification.resident ?? false;
                notif.hasActionIcons = notif.notification.hasActionIcons ?? false;

                if (Array.isArray(notif.notification.actions)) {
                    notif.actions = notif.notification.actions.filter(a => a !== null && a !== undefined).map(a => ({
                                identifier: a.identifier ?? "",
                                text: a.text ?? "",
                                invoke: typeof a.invoke === 'function' ? () => a.invoke() : () => {}
                            }));
                }
            } catch (error) {
                console.error("Error initializing notification:", error);
            }
        }

        Component.onDestruction: {
            if (conn)
                conn.target = null;
        }
    }

    Component {
        id: notifComponent

        Notif {}
    }

    Component.onDestruction: {
        if (cleanupTimer && typeof cleanupTimer.stop === 'function')
            cleanupTimer.stop();

        if (!root.list || !Array.isArray(root.list))
            return;

        for (const notif of root.list.slice()) {
            try {
                if (notif && typeof notif.close === 'function')
                    notif.close();
            } catch (e) {
                console.error("Error cleaning up notification:", e);
            }
        }
    }
}
