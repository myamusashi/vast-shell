pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property string fallbackSource: Quickshell.iconPath("image-missing")

    function                 desktopId(node: PwNode): string {
        if (!node)
            return "";
        const props = node.properties ?? {};
        if (props["application.id"])
            return props["application.id"];
        if (props["application.name"])
            return props["application.name"];
        const binary = props["application.process.binary"];
        if (binary)
            return binary.split("/").pop().replace(/^\./, "").replace(/-wrapped$/, "");
        return (node.name ?? "").split(".").pop();
    }

    function                 guessIconPath(node: PwNode): string {
        if (!node)
            return root.fallbackSource;

        const props    = node.properties ?? {};
        const iconName = props["application.icon-name"];
        if (iconName) {
            const direct = root.iconSource(iconName);
            if (direct !== root.fallbackSource)
                return direct;
        }

        const candidates = [iconName, props["application.id"], props["application.name"]];
        const binary     = props["application.process.binary"];
        if (binary) {
            const binBase = binary.split("/").pop();
            candidates.push(binBase.replace(/^\./, "").replace(/-wrapped$/, ""), binBase);
        }
        candidates.push(node.nickname, node.description, node.name);

        for (let i = 0; i < candidates.length; i++) {
            const candidate = candidates[i];
            if (!candidate)
                continue;
            const resolved = root.iconForId(candidate);
            if (resolved !== root.fallbackSource)
                return resolved;
        }

        return root.fallbackSource;
    }

    function                 iconForId(desktopId: string): string {
        if (!desktopId)
            return root.fallbackSource;
        if (["zen", "zen-twilight", "twilight"].includes(desktopId.toLowerCase())) {
            const zenIcon = Quickshell.hasThemeIcon("zen-beta") ? "zen-beta" : "zen-twilight";
            return root.iconSource(zenIcon);
        }

        const entryIcon = DesktopEntries.heuristicLookup(desktopId)?.icon;
        if (entryIcon) {
            const resolved = root.iconSource(entryIcon);
            if (resolved !== root.fallbackSource)
                return resolved;
        }

        const lower      = desktopId.toLowerCase();
        const candidates = [desktopId, lower, lower.replace(/\s+/g, "-")];
        if (lower.includes("."))
            candidates.push(lower.split(".").pop());

        for (let i = 0; i < candidates.length; i++) {
            if (candidates[i] && Quickshell.hasThemeIcon(candidates[i]))
                return Quickshell.iconPath(candidates[i]);
        }

        return root.fallbackSource;
    }

    function                 iconForPlayer(player: MprisPlayer): string {
        if (!player)
            return root.fallbackSource;

        const candidates = [player.desktopEntry, player.identity];
        const dbusPrefix = "org.mpris.MediaPlayer2.";
        if (player.dbusName && player.dbusName.startsWith(dbusPrefix)) {
            const service = player.dbusName.slice(dbusPrefix.length).replace(/\.instance\d+$/, "");
            candidates.push(service);
        }

        for (let i = 0; i < candidates.length; i++) {
            const resolved = root.iconForId(candidates[i]);
            if (resolved !== root.fallbackSource)
                return resolved;
        }

        return root.fallbackSource;
    }

    function                 iconSource(value: string): string {
        if (!value)
            return root.fallbackSource;

        if (value.includes("?path=")) {
            const split = value.split("?path=");
            if (split.length === 2) {
                const name     = split[0];
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
