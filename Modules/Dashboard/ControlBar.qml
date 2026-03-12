import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

ClippingRectangle {
    id: root

    anchors.fill: parent
    implicitWidth: content.width
    implicitHeight: content.implicitHeight

    RowLayout {
        id: content

        implicitWidth: parent.width
    }
}
