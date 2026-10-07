pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Scope {
    id: root

    required property Component content
    required property string    propertyName
    required property var       service

    Binding {
        property: root.propertyName
        target: root.service
        value: root.content
    }
}
