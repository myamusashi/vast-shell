pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.Core.States
import qs.Services

Scope {
    id: root

    property point  endPos
    property string frozenImageUrl: ""
    property string mode: "single"
    property bool   selecting: false
    property point  startPos
    property var    virtualScreens: []

    signal          cancelled
    signal          geometrySelected(string geometry)

    function        close() {
        mode                         = "single";
        frozenImageUrl               = "";
        GlobalStates.isSelectionOpen = false;
    }
    function        open() {
        startPos                     = Qt.point(0, 0);
        endPos                       = Qt.point(0, 0);
        selecting                    = false;
        GlobalStates.isSelectionOpen = true;
    }
    function        openCrossMonitor(frozenUrl) {
        mode           = "cross-monitor";
        frozenImageUrl = frozenUrl;
        open();
    }

    Variants {
        model: GlobalStates.isSelectionOpen ? Quickshell.screens : []
        delegate: PanelWindow {
            id: window

            required property ShellScreen modelData

            readonly property real        offsetX: modelData.x
            readonly property real        offsetY: modelData.y

            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.layer: WlrLayer.Overlay
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            screen: modelData

            anchors {
                bottom: true
                left: true
                right: true
                top: true
            }

            Image {
                anchors.fill: parent
                cache: false
                fillMode: Image.PreserveAspectCrop
                source: root.mode === "cross-monitor" ? root.frozenImageUrl : ""
                visible: root.mode === "cross-monitor" && root.frozenImageUrl !== ""
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(Colours.m3Colors.m3Background, 0.5)
            }

            Rectangle {
                border.color: Colours.m3Colors.m3OnSurface
                border.width: 2
                color: "transparent"
                height: Math.abs(root.endPos.y - root.startPos.y)
                visible: root.selecting
                width: Math.abs(root.endPos.x - root.startPos.x)
                x: Math.min(root.startPos.x, root.endPos.x) - window.offsetX
                y: Math.min(root.startPos.y, root.endPos.y) - window.offsetY

                Rectangle {
                    anchors.fill: parent
                    color: Qt.alpha(Colours.m3Colors.m3OnSurface, 0.25)
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.CrossCursor
                onPositionChanged: e => {
                    if (root.selecting)
                        root.endPos = Qt.point(e.x + window.offsetX, e.y + window.offsetY);
                }
                onPressed: e => {
                    root.startPos  = Qt.point(e.x + window.offsetX, e.y + window.offsetY);
                    root.endPos    = Qt.point(e.x + window.offsetX, e.y + window.offsetY);
                    root.selecting = true;
                }
                onReleased: e => {
                    root.selecting   = false;
                    const releasePos = Qt.point(e.x + window.offsetX, e.y + window.offsetY);
                    root.close();

                    const x = Math.min(root.startPos.x, releasePos.x);
                    const y = Math.min(root.startPos.y, releasePos.y);
                    const w = Math.abs(releasePos.x - root.startPos.x);
                    const h = Math.abs(releasePos.y - root.startPos.y);

                    if (w < 5 || h < 5) {
                        root.cancelled();
                        return;
                    }
                    root.geometrySelected(`${Math.round(x)},${Math.round(y)} ${Math.round(w)}x${Math.round(h)}`);
                }
            }

            Item {
                id: focusCatcher

                anchors.fill: parent
                focus: GlobalStates.isSelectionOpen
                Component.onCompleted: forceActiveFocus()
                Keys.onEscapePressed: {
                    root.close();
                    root.cancelled();
                }
            }
        }
    }
}
