pragma ComponentBehavior: Bound

import QtQuick
import Vast.Lyrics

import qs.Core.Configs
import qs.Core.Utils
import qs.Services

LyricsCanvas {
    id: root

    active: visible
    onActiveChanged: Lyrics.setPositionConsumerActive(root, root.active)
    activeColor: Colours.m3Colors.m3Primary
    activeFontSize: Appearance.fonts.size.large
    currentLineIndex: Lyrics.currentLineIndex
    font.family: Fonts.sans
    horizontalAlignment: Text.AlignLeft
    inactiveColor: Colours.m3Colors.m3Secondary
    inactiveFontSize: Appearance.fonts.size.normal
    lines: Lyrics.lines
    positionMs: Lyrics.positionMs
    raised: true
    spacing: Appearance.spacing.larger
    styleColor: Qt.alpha(Colours.m3Colors.m3Scrim, 0.5)
    synced: Lyrics.synced
    Component.onCompleted: Lyrics.setPositionConsumerActive(root, root.active)
    Component.onDestruction: Lyrics.setPositionConsumerActive(root, false)
}
