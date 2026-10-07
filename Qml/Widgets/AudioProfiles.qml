pragma ComponentBehavior: Bound

import QtQuick
import Vast.Audio

import qs.Core.Configs
import qs.Components.Button
import qs.Services

SplitButton {
    id: root

    readonly property int    profileCount: profileModel ? profileModel.count : 0
    readonly property var    profileModel: resolvedCard ? resolvedCard.profiles : null
    readonly property var    resolvedCard: card
    readonly property int    selectedIndex: {
        if (!resolvedCard)
            return -1;
        for (let i = 0; i < profileCount; ++i) {
            const profile = profileAt(i);
            if (profile && profile.index === resolvedCard.activeIndex)
                return i;
        }
        return -1;
    }
    readonly property string selectedLabel: {
        const profile = selectedIndex >= 0 ? profileAt(selectedIndex) : null;
        return profile ? profile.readable : "";
    }

    property var             card: Audio.defaultSinkCard

    function                 profileAt(i) {
        return profileModel ? profileModel.get(i) : null;
    }

    currentIndex: selectedIndex
    disabledLabel: md => qsTr("N/A")
    isItemEnabled: md => md.available === "yes"
    leadingFillsWidth: true
    model: profileModel
    text: selectedLabel
    textRole: "readable"
    onMenuItemActivated: rowIndex => {
        const profile = profileAt(rowIndex);
        if (!profile || profile.available !== "yes" || !resolvedCard)
            return;

        AudioProfilesWatcher.setProfile(resolvedCard.deviceId, profile.index);

        const deviceName = resolvedCard.name;
        if (deviceName) {
            const profiles             = Configs.audio.sinkProfiles;
            const copied               = Object.assign({}, profiles || {});
            copied[deviceName]         = profile.index;
            Configs.audio.sinkProfiles = copied;
        }
    }
}
