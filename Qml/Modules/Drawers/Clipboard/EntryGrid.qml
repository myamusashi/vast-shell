pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Vast.Clipboard

import qs.Core.Configs
import qs.Services
import qs.Components.Base

Item {
    id: root

    required property string searchText
    required property var    uiState

    property alias           entryList: entryList
    property alias           verticalFlick: verticalFlick

    implicitHeight: entryList.height

    Flickable {
        id: verticalFlick

        anchors.bottom: pageIndicatorRow.top
        anchors.bottomMargin: Appearance.margin.small
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: Appearance.margin.small
        clip: true
        contentHeight: entryList.height
        contentWidth: width
        flickableDirection: Flickable.VerticalFlick
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }
        onDragStarted: scrollAnim.stop()
        onDraggingChanged: scrollAnim.stop()
        onFlickStarted: scrollAnim.stop()

        GridView {
            id: entryList

            readonly property int currentPage: Math.max(0, Math.min(totalPages - 1, Math.round(contentX / width)))
            readonly property int itemsPerPage: Math.max(1, Configs.clipboard.listEntries)
            readonly property int maxVisibleCount: Math.min(count, Configs.clipboard.maxEntries)
            readonly property int totalPages: Math.max(1, Math.ceil(maxVisibleCount / itemsPerPage))
            readonly property int visualEnd: root.uiState.visualActive ? Math.max(root.uiState.visualAnchor, currentIndex) : -1
            readonly property int visualSelectableCount: {
                let n = 0;
                for (let i = visualStart; i <= visualEnd; ++i) {
                    const t = ClipboardManager.model.typeAtRow(i);
                    if (t === "text" || t === "html")
                        ++n;
                }
                return n;
            }
            readonly property int visualStart: root.uiState.visualActive ? Math.min(root.uiState.visualAnchor, currentIndex) : -1

            function              ensureCurrentVisible() {
                const itemY    = (currentIndex % itemsPerPage) * cellHeight;
                const viewport = verticalFlick.height;
                const currentY = verticalFlick.contentY;
                let targetY    = -1;
                if (itemY < currentY)
                    targetY = itemY;
                else if (itemY + cellHeight > currentY + viewport)
                    targetY = itemY + cellHeight - viewport;
                if (targetY < 0)
                    return;
                targetY = Math.max(0, Math.min(targetY, verticalFlick.contentHeight - viewport));
                scrollAnim.stop();
                scrollAnim.to = targetY;
                scrollAnim.start();
            }
            function              moveCurrentIndexByPage(delta) {
                const page    = currentPage;
                const newPage = page + delta;
                if (newPage < 0 || newPage >= totalPages)
                    return;

                const row       = currentIndex % itemsPerPage;
                const pageStart = newPage * itemsPerPage;
                const pageEnd   = Math.min(pageStart + itemsPerPage, count) - 1;

                currentIndex    = Math.min(Math.max(pageStart + row, pageStart), pageEnd);
                contentX        = newPage * width;
            }
            function              moveCurrentIndexDown() {
                if (currentIndex < count - 1)
                    currentIndex++;
            }
            function              moveCurrentIndexLeft() {
                moveCurrentIndexByPage(-1);
            }
            function              moveCurrentIndexRight() {
                moveCurrentIndexByPage(1);
            }
            function              moveCurrentIndexUp() {
                if (currentIndex > 0)
                    currentIndex--;
            }
            function              visualSelectedIds(): var {
                const ids   = [];
                const start = Math.min(root.uiState.visualAnchor, currentIndex);
                const end   = Math.max(root.uiState.visualAnchor, currentIndex);
                for (let i = start; i <= end; ++i)
                    ids.push(ClipboardManager.model.idAtRow(i));
                return ids;
            }

            ScrollBar.horizontal: horizontalScrollBar
            boundsBehavior: Flickable.StopAtBounds
            cellHeight: 64 + Appearance.spacing.small
            cellWidth: width
            clip: false
            currentIndex: 0
            flow: GridView.FlowTopToBottom
            height: Math.max(1, Configs.clipboard.listEntries) * (64 + Appearance.spacing.small)
            highlightFollowsCurrentItem: true
            highlightMoveDuration: 200
            highlightRangeMode: GridView.ApplyRange
            maximumFlickVelocity: 1000
            model: ClipboardManager.model
            snapMode: GridView.SnapOneRow
            width: verticalFlick.width
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AlwaysOff
            }
            add: Transition {

                NAnim {
                    from: 0
                    properties: "opacity,scale"
                    to: 1
                }
            }
            addDisplaced: Transition {

                NAnim {
                    duration: Appearance.animations.durations.small
                    properties: "opacity,scale"
                    to: 1
                }
            }
            delegate: Delegate {
                required property var modelData

                entryId: modelData.entryId
                fileName: modelData.fileName
                height: 64
                inVisual: root.uiState.visualActive && index >= entryList.visualStart && index <= entryList.visualEnd
                isSelected: GridView.isCurrentItem // qmllint disable
                pinned: modelData.pinned
                preview: modelData.preview
                sourceApp: modelData.sourceApp
                timestamp: modelData.timestamp
                type: modelData.type
                visible: index < Configs.clipboard.maxEntries
                width: GridView.view.cellWidth // qmllint disable
                onActivated: ClipboardManager.copyToClipboard(entryId)
                onPinToggled: (id, s) => ClipboardManager.pin(id, s)
                onRemoveRequested: id => ClipboardManager.remove(id)
            }
            displaced: Transition {

                NAnim {
                    duration: Appearance.animations.durations.small
                    properties: "opacity,scale"
                    to: 1
                }
            }
            highlight: StyledRect {
                color: Colours.m3Colors.m3SurfaceContainerHigh
                height: entryList.cellHeight
                width: entryList.cellWidth
            }
            move: Transition {

                NAnim {
                    duration: Appearance.animations.durations.small
                    properties: "x,y"
                }

                NAnim {
                    duration: Appearance.animations.durations.small
                    properties: "opacity,scale"
                    to: 1
                }
            }
            rebound: Transition {

                NAnim {
                    properties: "x,y"
                }
            }
            remove: Transition {

                NAnim {
                    from: 1
                    properties: "opacity,scale"
                    to: 0
                }
            }
            onContentXChanged: {
                var maxContentX = Math.max(0, (totalPages - 1) * width);
                if (contentX > maxContentX) {
                    contentX = maxContentX;
                }
            }
            onCurrentIndexChanged: ensureCurrentVisible()

            NAnim {
                id: scrollAnim

                duration: Appearance.animations.durations.small
                property: "contentY"
                target: verticalFlick
            }
        }
    }

    StyledText {
        anchors.centerIn: verticalFlick
        color: Colours.m3Colors.m3OnSurfaceVariant
        font.pixelSize: Appearance.fonts.size.medium
        text: root.searchText.length > 0 ? qsTr("No results for ") + root.searchText : qsTr("Clipboard is empty")
        visible: entryList.count === 0
    }

    Row {
        id: pageIndicatorRow

        anchors.bottom: horizontalScrollBar.top
        anchors.bottomMargin: Appearance.margin.small
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 6
        visible: entryList.totalPages > 1

        Repeater {
            model: entryList.totalPages
            delegate: Rectangle {
                required property int index

                color: entryList.currentPage === index ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OutlineVariant
                implicitHeight: 6
                implicitWidth: entryList.currentPage === index ? 16 : 6
                opacity: entryList.currentPage === index ? 1.0 : 0.5
                radius: 3
                Behavior on implicitWidth {
                    NAnim {}
                }
                Behavior on opacity {
                    NAnim {}
                }
            }
        }
    }

    ScrollBar {
        id: horizontalScrollBar

        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        orientation: Qt.Horizontal
        policy: ScrollBar.AsNeeded
    }
}
