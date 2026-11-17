import QtQuick
import QtQuick.Layouts

import qs.Widgets

RowLayout {
    id: root

    Mpris {
        Layout.alignment: Qt.AlignVCenter
    }

    RecordIndicator {
        Layout.alignment: Qt.AlignVCenter
    }
}
