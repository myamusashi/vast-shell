import QtQuick
import Vast.Lyrics

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils

AnimatedLyricText {
    id: root

    font.family: Fonts.sans
    font.hintingPreference: Font.PreferFullHinting
    font.letterSpacing: 0
    highlightMix: active ? 1.0 : 0.0
    Component.onCompleted: {
        font.variableAxes = {
            "wght": 650,
            "opsz": root.font.pixelSize
        };
    }
    Behavior on highlightMix {
        NAnim {
            duration: Appearance.animations.durations.small
        }
    }
}
