import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Vast.Clipboard

import qs.Components.Feedback
import qs.Components.Button
import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    property int entryId: -1

    signal copyRequested(int id)
    signal pinToggled(int id, bool newState)

    function requestPreview(): void {
        entryDetails.clear();
        previewTimeout.stop();

        if (root.entryId < 0)
            return;

        entryDetails.loading = true;
        previewTimeout.restart();
        ClipboardManager.requestFullEntry(root.entryId);
    }

    onEntryIdChanged: requestPreview()

    Connections {
        function onFullEntryFailed(id) {
            if (id !== root.entryId)
                return;
            previewTimeout.stop();
            entryDetails.loading = false;
            entryDetails.error = true;
        }
        function onFullEntryReady(entry) {
            if (entry.id !== root.entryId)
                return;
            previewTimeout.stop();
            entryDetails.error = false;
            entryDetails.entryType = entry.type ?? "text";
            entryDetails.isImage = entry.type === "image";
            entryDetails.content = entry.content ?? "";
            entryDetails.sourceApp = entry.sourceApp ?? "";
            entryDetails.pinned = entry.pinned ?? false;
            entryDetails.sizeBytes = entry.sizeBytes ?? 0;
            entryDetails.timestamp = FormatTimeUtils.formatClipboard(entry.timestamp ?? 0);
            entryDetails.fileName = entry.fileName ?? "";

            entryDetails.previewPath = entry.previewPath ?? "";

            entryDetails.loading = false;
        }

        target: ClipboardManager
    }
    Timer {
        id: previewTimeout

        property int retry: 0

        interval: 150
        repeat: true

        onTriggered: {
            if (entryDetails.loading) {
                if (retry < entryDetails.previewLoadRetry) {
                    retry++;
                    root.requestPreview();
                } else {
                    stop();
                    retry = 0;
                    entryDetails.loading = false;
                    entryDetails.error = true;
                }
            } else {
                stop();
            }
        }
    }
    QtObject {
        id: entryDetails

        property string content: ""
        property string entryType: "text"
        property bool error: false
        property string fileName: ""
        readonly property bool isHtml: entryType === "html"
        property bool isImage: false
        property bool loading: false
        readonly property int maxPreviewChars: 20000
        property bool pinned: false
        readonly property string previewContent: {
            if (!truncated)
                return content;
            if (!isHtml)
                return content.slice(0, maxPreviewChars);
            const cut = content.lastIndexOf(">", maxPreviewChars);
            return content.slice(0, cut > 0 ? cut + 1 : maxPreviewChars);
        }
        readonly property int previewLoadRetry: 3
        property string previewPath: ""
        property int sizeBytes: 0
        property string sourceApp: ""
        property string timestamp: ""
        readonly property bool truncated: content.length > maxPreviewChars

        function clear() {
            loading = false;
            error = false;
            isImage = false;
            previewPath = "";
            content = "";
            sourceApp = "";
            timestamp = "";
            pinned = false;
            sizeBytes = 0;
            entryType = "text";
            fileName = "";
        }
    }
    Column {
        anchors.centerIn: parent
        spacing: Appearance.spacing.normal
        visible: root.entryId < 0

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.extraLarge
            icon: "content_paste"
        }
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.normal
            text: qsTr("Select an entry to preview")
        }
    }
    LoadingIndicator {
        anchors.centerIn: parent
        contained: true
        implicitHeight: 30
        implicitWidth: 30
        status: root.entryId >= 0 && entryDetails.loading
    }
    Column {
        anchors.centerIn: parent
        spacing: Appearance.spacing.normal
        visible: root.entryId >= 0 && !entryDetails.loading && entryDetails.error

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            color: Colours.m3Colors.m3Error
            font.pixelSize: Appearance.fonts.size.extraLarge
            icon: "error"
        }
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.normal
            text: qsTr("Couldn't load preview")
        }
        ExtendedFloatingButton {
            anchors.horizontalCenter: parent.horizontalCenter
            color: Colours.m3Colors.m3SecondaryContainer
            icon.name: "refresh"
            text: qsTr("Retry")
            textColor: Colours.m3Colors.m3OnSecondaryContainer

            onClicked: root.requestPreview()
        }
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Appearance.margin.normal
        spacing: Appearance.spacing.large
        visible: root.entryId >= 0 && !entryDetails.loading && !entryDetails.error

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.smaller

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                RowLayout {
                    spacing: Appearance.spacing.small

                    StyledRect {
                        color: Qt.alpha(entryDetails.isImage ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3SurfaceContainerHigh, 0.18)
                        implicitHeight: 20
                        implicitWidth: 20
                        radius: Appearance.rounding.small

                        Icon {
                            anchors.centerIn: parent
                            color: entryDetails.isImage ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurface
                            font.pixelSize: Appearance.fonts.size.large
                            icon: entryDetails.isImage ? "image" : "assignment"
                        }
                    }
                    StyledText {
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                        font.weight: Font.Medium
                        text: entryDetails.isImage ? qsTr("Image") : qsTr("Text")
                    }
                    StyledText {
                        Layout.fillWidth: false
                        Layout.maximumWidth: 220
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        elide: Text.ElideRight
                        font.pixelSize: Appearance.fonts.size.normal
                        text: entryDetails.fileName
                        visible: entryDetails.isImage && entryDetails.fileName.length > 0
                    }
                    StyledRect {
                        color: Qt.alpha(Colours.m3Colors.m3SecondaryContainer, 0.8)
                        implicitHeight: 18
                        implicitWidth: srcLabel.implicitWidth + Appearance.padding.normal
                        radius: Appearance.rounding.small
                        visible: entryDetails.sourceApp.length > 0

                        StyledText {
                            id: srcLabel

                            anchors.centerIn: parent
                            color: Colours.m3Colors.m3OnSecondaryContainer
                            font.pixelSize: Appearance.fonts.size.small
                            text: entryDetails.sourceApp
                        }
                    }
                }
                RowLayout {
                    spacing: Appearance.spacing.smaller

                    StyledText {
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.small
                        text: entryDetails.timestamp
                    }
                    StyledText {
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.small
                        text: FormatTimeUtils.formatSize(entryDetails.sizeBytes)
                    }
                }
            }

            // Pin button
            FloatingButton {
                color: Qt.alpha(Colours.m3Colors.m3SurfaceContainerHigh, 0.5)
                icon.color: entryDetails.pinned ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant
                icon.name: entryDetails.pinned ? "keep" : "keep_off"
                size: "small"

                onClicked: root.pinToggled(root.entryId, !entryDetails.pinned)
            }
            ExtendedFloatingButton {
                color: Colours.m3Colors.m3SecondaryContainer
                icon.name: "content_copy"
                text: qsTr("Copy")
                textColor: Colours.m3Colors.m3OnSecondaryContainer

                onClicked: root.copyRequested(root.entryId)
            }
        }
        Rectangle {
            Layout.fillWidth: true
            color: Qt.alpha(Colours.m3Colors.m3OutlineVariant, 0.6)
            implicitHeight: 1
        }

        // Text preview
        ScrollView {
            id: textScroll

            Layout.fillHeight: true
            Layout.fillWidth: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            clip: true
            visible: !entryDetails.isImage

            Keys.onPressed: event => {
                if (event.key === Qt.Key_PageUp) {
                    contentItem.contentY = Math.max(0, contentItem.contentY - height); // qmllint disable
                    event.accepted = true;
                }
                if (event.key === Qt.Key_PageDown) {
                    contentItem.contentY = Math.min(contentItem.contentHeight - height, contentItem.contentY + height); // qmllint disable
                    event.accepted = true;
                }
                if (event.key === Qt.Key_Up) {
                    contentItem.contentY = Math.max(0, contentItem.contentY - 40); // qmllint disable
                    event.accepted = true;
                }
                if (event.key === Qt.Key_Down) {
                    contentItem.contentY = Math.min(contentItem.contentHeight - height, contentItem.contentY + 40); // qmllint disable
                    event.accepted = true;
                }
            }

            ColumnLayout {
                spacing: Appearance.spacing.small
                width: textScroll.width

                TextEdit {
                    Layout.fillWidth: true
                    color: Colours.m3Colors.m3OnSurface
                    font.family: entryDetails.isHtml ? Fonts.sans : Fonts.mono
                    font.pixelSize: Appearance.fonts.size.medium
                    padding: Appearance.padding.small
                    readOnly: true
                    selectByKeyboard: true
                    selectByMouse: true
                    selectedTextColor: Colours.m3Colors.m3OnSurface
                    selectionColor: Qt.alpha(Colours.m3Colors.m3Primary, 0.35)
                    text: entryDetails.previewContent
                    textFormat: entryDetails.isHtml ? TextEdit.RichText : TextEdit.PlainText
                    wrapMode: TextEdit.Wrap
                }
                StyledText {
                    Layout.fillWidth: true
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.small
                    text: qsTr("Preview truncated (%1 of %2 shown) — copy to get the full content").arg(FormatTimeUtils.formatSize(entryDetails.maxPreviewChars)).arg(FormatTimeUtils.formatSize(entryDetails.content.length))
                    visible: entryDetails.truncated
                }
            }
        }
        ScrollView {
            id: imageScroll

            Layout.fillHeight: true
            Layout.fillWidth: true
            ScrollBar.horizontal.policy: ScrollBar.AsNeeded
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            clip: true
            visible: entryDetails.isImage

            Keys.onDownPressed: contentItem.contentY += 40 // qmllint disable
            Keys.onLeftPressed: contentItem.contentX -= 40 // qmllint disable
            Keys.onRightPressed: contentItem.contentX += 40 // qmllint disable

            Keys.onUpPressed: contentItem.contentY -= 40 // qmllint disable

            WheelHandler {
                id: imageZoom

                property real scale: 1.0

                acceptedModifiers: Qt.ControlModifier

                onWheel: event => {
                    const step = event.angleDelta.y / 120;
                    scale = Math.max(0.25, Math.min(4.0, scale + step * 0.15));
                }
            }
            Item {
                height: Math.max(imageScroll.height, previewImage.paintedHeight * imageZoom.scale)
                width: Math.max(imageScroll.width, previewImage.paintedWidth * imageZoom.scale)

                Image {
                    id: previewImage

                    anchors.centerIn: parent
                    asynchronous: true
                    fillMode: Image.PreserveAspectFit
                    height: imageScroll.height * imageZoom.scale
                    opacity: status === Image.Ready ? 1.0 : 0.0
                    smooth: true
                    source: entryDetails.previewPath.length > 0 ? ("file://" + entryDetails.previewPath) : ""
                    sourceSize: Qt.size(300, 300)
                    width: imageScroll.width * imageZoom.scale

                    Behavior on opacity {
                        NAnim {
                        }
                    }
                }
                StyledText {
                    anchors.centerIn: parent
                    color: Colours.m3Colors.m3Secondary
                    font.pixelSize: Appearance.fonts.size.medium
                    text: qsTr("Loading…")
                    visible: previewImage.status === Image.Loading
                }
            }
        }
    }
}
