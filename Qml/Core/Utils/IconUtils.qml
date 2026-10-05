pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property string fallbackSource: Quickshell.iconPath("image-missing")

    function desktopId(node: PwNode): string {
        const appId = node.properties["application.id"];
        if (appId)
            return appId;
        const binary = node.properties["application.process.binary"];
        if (binary)
            return binary.split(".").pop();
        return (node.name ?? "").split(".").pop();
    }
    function guessIconPath(node: PwNode): string {
        if (!node)
            return root.fallbackSource;
        const iconName = node.properties["application.icon-name"];
        if (iconName)
            return root.iconSource(iconName);
        return root.iconForId(root.desktopId(node));
    }
    function iconForId(desktopId: string): string {
        if (!desktopId)
            return root.fallbackSource;
        if (["zen", "zen-twilight", "twilight"].includes(desktopId.toLowerCase())) {
            const zenIcon = Quickshell.hasThemeIcon("zen-beta") ? "zen-beta" : "zen-twilight";
            return root.iconSource(zenIcon);
        }
        return root.iconSource(DesktopEntries.heuristicLookup(desktopId)?.icon);
    }
    function iconSource(value: string): string {
        if (!value)
            return root.fallbackSource;

        if (value.includes("?path=")) {
            const split = value.split("?path=");
            if (split.length === 2) {
                const name = split[0];
                const fileName = name.substring(name.lastIndexOf("/") + 1);
                return `file://${split[1]}/${fileName}`;
            }
        }

        if (value.includes("://"))
            return value;

        if (value.startsWith("/"))
            return `file://${value}`;

        return Quickshell.hasThemeIcon(value) ? Quickshell.iconPath(value) : root.fallbackSource;
    }
}
