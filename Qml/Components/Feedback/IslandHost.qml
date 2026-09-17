pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Scope {
    id: root

    required property var service
    required property string propertyName
    required property Component content

    Binding {
        target: root.service
        property: root.propertyName
        value: root.content
    }
}
