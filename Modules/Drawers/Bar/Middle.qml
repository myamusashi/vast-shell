import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Widgets

RowLayout {
    anchors.centerIn: parent
    spacing: Appearance.spacing.normal

    Mpris {}
    RecordIndicator {}
}
