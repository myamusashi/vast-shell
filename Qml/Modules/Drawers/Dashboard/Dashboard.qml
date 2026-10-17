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

    Loader {
        id: contentLoader

        active: FocusedMonitor.isOnFocusedMonitor(window.modelData.name) && container.open // qmllint disable
        anchors.fill: parent
        asynchronous: true
        onActiveChanged: {
            if (!active) {
                GlobalStates.isEditTodoListOpen = false;
                GlobalStates.isAddTodoListOpen  = false;
            }
        }
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

                Date {}

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
