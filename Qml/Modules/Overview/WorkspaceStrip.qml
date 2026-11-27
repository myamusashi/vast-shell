pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Components.Base
import qs.Core.Configs
import qs.Services

Item {
    id: root

    required property string activeFocusZone
    required property bool   allowHover
    required property string dragTargetWorkspaceAddress
    required property int    focusedCardIndex
    required property string hoveredWorkspaceAddress
    required property string lockedSourceWorkspaceAddress
    required property string monitorActiveWorkspaceAddress
    required property real   monitorHeight
    required property real   monitorWidth
    required property real   monitorX
    required property real   monitorY
    required property var    monitorWorkspaces
    required property string nextWorkspaceAddress
    required property string selectedWorkspaceAddress
    required property var    toplevelsByWorkspace

    readonly property int    cardOverflowPadding: 6
    readonly property real   maxStripWidth: Math.max(240, parent ? parent.width - Appearance.margin.large * 2 : 900)
    readonly property int    stripPadding: Appearance.padding.large

    signal                   newWorkspaceClicked
    signal                   workspaceClicked(string workspaceAddress, int cardIndex)
    signal                   workspaceDoubleClicked(string workspaceAddress)
    signal                   workspaceHoverEntered(string workspaceAddress)
    signal                   workspaceHoverExited(string workspaceAddress)

    function                 workspaceAddressAtScenePoint(sceneX: real, sceneY: real): string {
        return OverviewServices.workspaceAddressAtScenePoint(workspaceRepeater, newWorkspaceCard, root.nextWorkspaceAddress, sceneX, sceneY);
    }

    implicitHeight: stripSurface.implicitHeight
    implicitWidth: Math.min(root.maxStripWidth, cardsFlickable.contentWidth + root.stripPadding * 2)
    onFocusedCardIndexChanged: OverviewServices.ensureCardVisible(cardsFlickable, workspaceRepeater, newWorkspaceCard, focusedCardIndex)

    Elevation {
        level: 3
        radius: stripSurface.radius
    }

    StyledRect {
        id: stripSurface

        anchors.fill: parent
        border.color: Colours.m3Colors.m3OutlineVariant
        border.width: 1
        color: OverviewServices.color
        implicitHeight: cardsFlickable.implicitHeight + root.stripPadding * 2
        radius: Appearance.rounding.large

        MouseArea {
            acceptedButtons: Qt.AllButtons
            anchors.fill: parent
        }

        Flickable {
            id: cardsFlickable

            anchors {
                fill: parent
                margins: root.stripPadding
            }

            boundsBehavior: Flickable.StopAtBounds
            clip: true
            contentHeight: cardsRow.implicitHeight + root.cardOverflowPadding * 2
            contentWidth: cardsRow.implicitWidth + root.cardOverflowPadding * 2
            flickableDirection: Flickable.HorizontalFlick
            implicitHeight: cardsRow.implicitHeight + root.cardOverflowPadding * 2
            interactive: contentWidth > width
            pressDelay: 0

            RowLayout {
                id: cardsRow

                spacing: Appearance.spacing.large
                x: root.cardOverflowPadding
                y: root.cardOverflowPadding

                Repeater {
                    id: workspaceRepeater

                    model: ScriptModel {
                        objectProp: "address"
                        values: root.monitorWorkspaces
                    }
                    delegate: WorkspaceCard {
                        required property int index
                        required property var modelData

                        allowHover: root.allowHover
                        isDragOver: root.dragTargetWorkspaceAddress === modelData.address
                        isHovered: root.hoveredWorkspaceAddress === modelData.address
                        isKeyboardFocused: root.activeFocusZone === "cards" && root.focusedCardIndex === index
                        isLockedSource: root.lockedSourceWorkspaceAddress !== "" && root.lockedSourceWorkspaceAddress === modelData.address
                        isMonitorActive: modelData.address === root.monitorActiveWorkspaceAddress
                        isNewWorkspaceCard: false
                        isSelected: root.selectedWorkspaceAddress === modelData.address
                        monitorHeight: root.monitorHeight
                        monitorWidth: root.monitorWidth
                        monitorX: root.monitorX
                        monitorY: root.monitorY
                        wallpaperSource: Colours.wallpaperSource
                        workspaceAddress: modelData.address
                        workspaceName: modelData.name
                        workspaceToplevels: root.toplevelsByWorkspace[modelData.address] ?? []
                        onClicked: workspaceAddress => root.workspaceClicked(workspaceAddress, index)
                        onDoubleClicked: workspaceAddress => root.workspaceDoubleClicked(workspaceAddress)
                        onHoverEntered: workspaceAddress => root.workspaceHoverEntered(workspaceAddress)
                        onHoverExited: workspaceAddress => root.workspaceHoverExited(workspaceAddress)
                    }
                }

                WorkspaceCard {
                    id: newWorkspaceCard

                    readonly property int cardSlotIndex: root.monitorWorkspaces.length

                    allowHover: root.allowHover
                    isDragOver: root.dragTargetWorkspaceAddress === root.nextWorkspaceAddress
                    isHovered: root.hoveredWorkspaceAddress === root.nextWorkspaceAddress
                    isKeyboardFocused: root.activeFocusZone === "cards" && root.focusedCardIndex === cardSlotIndex
                    isLockedSource: false
                    isMonitorActive: false
                    isNewWorkspaceCard: true
                    isSelected: root.selectedWorkspaceAddress === root.nextWorkspaceAddress
                    monitorHeight: root.monitorHeight
                    monitorWidth: root.monitorWidth
                    monitorX: root.monitorX
                    monitorY: root.monitorY
                    wallpaperSource: ""
                    workspaceAddress: root.nextWorkspaceAddress
                    workspaceName: ""
                    workspaceToplevels: []
                    onClicked: root.newWorkspaceClicked()
                    onHoverEntered: workspaceAddress => root.workspaceHoverEntered(workspaceAddress)
                    onHoverExited: workspaceAddress => root.workspaceHoverExited(workspaceAddress)
                }
            }
        }
    }
}
