pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base.DrawerComponents
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

import "Calendar/"
import "Date/"
import "Events/"
import "WeatherSummary/"

Drawer {
    id: container

    readonly property bool onFocusedMonitor: FocusedMonitor.isOnFocusedMonitor(panelWindow.modelData.name) // qmllint disable
    readonly property bool shouldBeActive: open && onFocusedMonitor

    property bool          keepAlive: false

    alignment: Qt.AlignRight
    animationDuration: Appearance.animations.durations.expressiveDefaultSpatial
    animationEasingCurve: Appearance.animations.curves.expressiveDefaultSpatial
    color: GlobalStates.drawerColors
    cornerRadius: Appearance.rounding.normal
    depth: 500
    edge: Qt.TopEdge
    filletRadius: 40
    length: parent.width * 0.4
    open: GlobalStates.isDashboardOpen
    onOpenChanged: {
        if (!open) {
            GlobalStates.isEditTodoListOpen = false;
            GlobalStates.isAddTodoListOpen  = false;
        }
    }
    onShouldBeActiveChanged: {
        if (shouldBeActive)
            keepAlive = true;
    }

    Timer {
        id: idleUnloadTimer

        interval: 120000
        running: container.keepAlive && !container.shouldBeActive
        onTriggered: container.keepAlive = false
    }

    Loader {
        id: contentLoader

        active: container.shouldBeActive || container.keepAlive
        anchors.fill: parent
        asynchronous: true
        sourceComponent: RowLayout {

            anchors {
                fill: parent
                margins: Appearance.margin.normal
            }

            spacing: Appearance.spacing.large

            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                spacing: Appearance.spacing.large

                DateHeader {}

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Colours.m3Colors.m3OutlineVariant
                }

                WeatherSummary {}
            }

            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                color: Colours.m3Colors.m3OutlineVariant
            }

            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                spacing: Appearance.spacing.large

                Calendar {
                    id: calendar

                    Layout.fillHeight: false
                    Layout.fillWidth: true
                }

                Events {
                    selectedDate: calendar.selectedDate
                }
            }
        }
    }
}
