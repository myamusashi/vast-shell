pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Components.Button
import qs.Components.Tooltip
import qs.Services

Column {
    id: root

    required property var  modelData

    readonly property bool hasActions: (root.modelData?.actions?.length ?? 0) > 0
    readonly property bool hasInlineReply: root.modelData?.hasInlineReply ?? false

    property bool          isReplying: false
    property bool          isShowMoreBody: false
    property bool          replyFocused: false

    function               syncInlineReplyFocus(): void {
        const hasReply = root.hasInlineReply;
        if (root.replyFocused && hasReply)
            GlobalStates.inlineReplyOwner = root;
        else if (GlobalStates.inlineReplyOwner === root)
            GlobalStates.inlineReplyOwner = null;
    }

    spacing: 4
    Component.onDestruction: {
        if (GlobalStates.inlineReplyOwner === root)
            GlobalStates.inlineReplyOwner = null;
    }
    onHasInlineReplyChanged: {
        if (!hasInlineReply)
            isReplying = false;
        syncInlineReplyFocus();
    }
    onModelDataChanged: {
        isReplying = false;
        syncInlineReplyFocus();
    }
    onReplyFocusedChanged: syncInlineReplyFocus()

    RowLayout {
        spacing: Appearance.spacing.small
        width: parent.width

        StyledText {
            id: appNameText

            Layout.fillWidth: true
            color: Colours.m3Colors.m3OnSurfaceVariant
            elide: Text.ElideRight
            font.pixelSize: Appearance.fonts.size.small
            font.weight: Font.Medium
            text: root.modelData.appName

            Tooltip {
                anchorItem: appNameText
                enabled: appNameText.truncated
                text: appNameText.text
            }
        }

        StyledText {
            Layout.preferredWidth: implicitWidth
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.small
            text: "•"
        }

        StyledText {
            id: timeText

            Layout.preferredWidth: implicitWidth
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.small
            Component.onCompleted: text = FormatTimeUtils.timeAgoWithIfElse(root.modelData.time)

            Timer {
                interval: 60000
                repeat: true
                running: root.visible
                onTriggered: timeText.text = FormatTimeUtils.timeAgoWithIfElse(root.modelData.time)
            }

            Tooltip {
                anchorItem: timeText
                text: root.modelData?.time ? FormatTimeUtils.formatTimestampWithTime(root.modelData.time) : ""
            }
        }

        FloatingButton {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 24
            Layout.preferredWidth: 24
            backgroundRadius: 6
            color: "transparent"
            icon.color: Colours.m3Colors.m3OnSurfaceVariant
            icon.name: root.isShowMoreBody ? "expand_less" : "expand_more"
            icon.size: Appearance.fonts.size.large
            tooltipText: root.isShowMoreBody ? qsTr("Show less") : qsTr("Show more")
            onClicked: root.isShowMoreBody = !root.isShowMoreBody
        }
    }

    StyledText {
        id: summaryText

        color: Colours.m3Colors.m3OnSurface
        elide: Text.ElideRight
        font.pixelSize: Appearance.fonts.size.medium
        font.weight: Font.DemiBold
        maximumLineCount: 2
        text: root.modelData.summary
        width: parent.width
        wrapMode: Text.Wrap

        Tooltip {
            anchorItem: summaryText
            enabled: summaryText.truncated
            text: summaryText.text
        }
    }

    StyledText {
        color: Colours.m3Colors.m3OnSurfaceVariant
        font.pixelSize: Appearance.fonts.size.small
        maximumLineCount: root.isShowMoreBody ? 0 : 1
        text: root.modelData.body || ""
        textFormat: Text.StyledText
        width: parent.width
        wrapMode: Text.Wrap
    }

    Column {
        topPadding: 4
        visible: root.hasActions || root.hasInlineReply
        width: parent.width

        RowLayout {
            id: actionsRow

            spacing: 6
            visible: !root.isReplying
            width: parent.width

            Repeater {
                model: root.modelData?.actions
                delegate: StyledRect {
                    id: actionButton

                    required property int index
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    Layout.preferredWidth: 0
                    color: actionMouse.containsMouse ? Colours.m3Colors.m3SurfaceContainerHighest : Colours.m3Colors.m3SurfaceContainerHigh
                    radius: 8

                    MArea {
                        id: actionMouse

                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: actionButton.modelData.invoke()
                    }

                    StyledText {
                        id: actionLabel

                        color: Colours.m3Colors.m3OnBackground
                        elide: Text.ElideRight
                        font.pixelSize: Appearance.fonts.size.small
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        text: actionButton.modelData.text

                        anchors {
                            left: parent.left
                            leftMargin: Appearance.padding.small
                            right: parent.right
                            rightMargin: Appearance.padding.small
                            verticalCenter: parent.verticalCenter
                        }
                    }

                    Tooltip {
                        anchorItem: actionButton
                        enabled: actionLabel.truncated
                        text: actionButton.modelData.text ?? ""
                    }
                }
            }

            StyledRect {
                id: replyButton

                Layout.fillWidth: true
                Layout.preferredHeight: 28
                Layout.preferredWidth: 0
                color: replyMouse.containsMouse ? Colours.m3Colors.m3SurfaceContainerHighest : Colours.m3Colors.m3SurfaceContainerHigh
                radius: 8
                visible: root.hasInlineReply

                MArea {
                    id: replyMouse

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.isReplying = true
                }

                StyledText {
                    color: Colours.m3Colors.m3OnBackground
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.fonts.size.small
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignHCenter
                    text: qsTr("Reply")

                    anchors {
                        left: parent.left
                        leftMargin: Appearance.padding.small
                        right: parent.right
                        rightMargin: Appearance.padding.small
                        verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        Loader {
            id: replyLoader

            active: root.isReplying && root.hasInlineReply
            visible: active
            width: parent.width
            onActiveChanged: {
                if (!active)
                    root.replyFocused = false;
            }
            sourceComponent: RowLayout {
                id: replyRow

                function sendReply(): void {
                    const text = replyField.text.trim();
                    if (text === "")
                        return;
                    root.modelData.sendInlineReply(text);
                    replyField.text = "";
                    root.isReplying = false;
                }

                spacing: 6
                Component.onCompleted: replyField.forceActiveFocus()

                FloatingButton {
                    id: backButton

                    Layout.preferredHeight: 28
                    Layout.preferredWidth: 28
                    backgroundRadius: 8
                    color: Colours.m3Colors.m3SurfaceContainerHigh
                    icon.color: Colours.m3Colors.m3OnBackground
                    icon.name: "arrow_back"
                    icon.size: Appearance.fonts.size.large
                    tooltipText: qsTr("Cancel reply")
                    onClicked: root.isReplying = false
                }

                MaterialTextField {
                    id: replyField

                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    compact: true
                    outlined: true
                    placeholderText: root.modelData.inlineReplyPlaceholder !== "" ? root.modelData.inlineReplyPlaceholder : qsTr("Reply…")
                    onAccepted: replyRow.sendReply()
                    onActiveFocusChanged: root.replyFocused = activeFocus
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            event.accepted  = true;
                            root.isReplying = false;
                        }
                    }
                }

                FloatingButton {
                    id: sendButton

                    Layout.preferredHeight: 28
                    Layout.preferredWidth: 28
                    backgroundRadius: 8
                    buttonEnabled: replyField.text.trim().length > 0
                    color: Colours.m3Colors.m3SurfaceContainerHigh
                    disabledTooltipText: qsTr("Type a message to reply")
                    icon.color: Qt.alpha(Colours.m3Colors.m3OnBackground, replyField.text.trim().length > 0 ? 1 : 0.4)
                    icon.name: "send"
                    icon.size: Appearance.fonts.size.large
                    tooltipText: qsTr("Send reply")
                    onClicked: {
                        if (replyField.text.trim().length > 0)
                            replyRow.sendReply();
                    }
                }
            }
        }
    }
}
