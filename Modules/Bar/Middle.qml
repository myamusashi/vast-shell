import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Widgets

Loader {
    active: true
    asynchronous: true

    sourceComponent: RowLayout {
        anchors.centerIn: parent
        anchors.leftMargin: Appearance.margin.small
        spacing: Appearance.spacing.normal

        Mpris {}

        RecordIndicator {}
    }
}
