import QtQuick

import qs.Core.Configs

StyledRect {
    required property bool layerEnabled
    required property bool layerPressed
    required property bool layerHovered

    opacity: (layerEnabled ? (layerPressed ? 0.10 : layerHovered ? 0.08 : 0.0) : 0.0)

    Behavior on opacity {
        NAnim {
            duration: Appearance.animations.durations.small
        }
    }
}
