pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.Services

import "../Components/Base"

StyledComboBox {
    model: Audio.models
    textRole: "readable"
    valueRole: "index"
    currentValue: Audio.activeProfileIndex
    isItemEnabled: md => md.available === "yes"
    disabledLabel: md => qsTr("N/A")
    isItemActive: (md, _) => md.index === Audio.activeProfileIndex
    onActivated: rowIndex => {
        const profile = Audio.models.get(rowIndex);
        if (!profile || profile.available !== "yes")
            return;

        Quickshell.execDetached({
            command: ["pw-cli", "set-param", String(Audio.idPipewire), "Profile", `{ "index": ${profile.index} }`]
        });
    }
}
