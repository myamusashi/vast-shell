pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Components.Button
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

    spacing: Appearance.spacing.small
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
            Layout.fillWidth: true
            color: Colours.m3Colors.m3OnSurfaceVariant
            elide: Text.ElideRight
            font.pixelSize: Appearance.fonts.size.large
            font.weight: Font.Medium
            text: root.modelData.appName
        }

        StyledText {
            Layout.preferredWidth: implicitWidth
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.large
            text: "•"
        }

        StyledText {
            id: timeText

            Layout.preferredWidth: implicitWidth
            color: Colours.m3Colors.m3OnSurfaceVariant
            Component.onCompleted: text = FormatTimeUtils.timeAgoWithIfElse(root.modelData.time)

            Timer {
                interval: 60000
                repeat: true
                running: root.visible
                onTriggered: timeText.text = FormatTimeUtils.timeAgoWithIfElse(root.modelData.time)
            }
        }

        FloatingButton {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 32
            Layout.preferredWidth: 32
            backgroundRadius: Appearance.rounding.large
            color: "transparent"
            icon.color: Colours.m3Colors.m3OnSurfaceVariant
            icon.name: root.isShowMoreBody ? "expand_less" : "expand_more"
            icon.size: Appearance.fonts.size.extraLarge
            onClicked: root.isShowMoreBody = !root.isShowMoreBody
        }
    }

    StyledText {
        color: Colours.m3Colors.m3OnSurface
        elide: Text.ElideRight
        font.pixelSize: Appearance.fonts.size.medium
        font.weight: Font.DemiBold
        maximumLineCount: 2
        text: root.modelData.summary
        width: parent.width
        wrapMode: Text.Wrap
    }

    StyledText {
        color: Colours.m3Colors.m3OnSurface
        font.pixelSize: Appearance.fonts.size.medium
        maximumLineCount: root.isShowMoreBody ? 0 : 1
        text: root.modelData.body || ""
        textFormat: Text.StyledText
        width: parent.width
        wrapMode: Text.Wrap
    }

    Column {
        topPadding: 8
        visible: root.hasActions || root.hasInlineReply
        width: parent.width

        RowLayout {
            id: actionsRow

            spacing: Appearance.spacing.normal
            visible: !root.isReplying
            width: parent.width

            Repeater {
                model: root.modelData?.actions
                delegate: StyledRect {
                    id: actionButton

                    required property int index
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    Layout.preferredWidth: 0
                    color: Colours.m3Colors.m3SurfaceContainerHigh
                    radius: Appearance.rounding.full

                    MArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: actionButton.modelData.invoke()
                    }

                    StyledText {
                        color: Colours.m3Colors.m3OnBackground
                        elide: Text.ElideRight
                        font.pixelSize: Appearance.fonts.size.medium
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
                }
            }

            StyledRect {
                id: replyButton

                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Layout.preferredWidth: 0
                color: Colours.m3Colors.m3SurfaceContainerHigh
                radius: Appearance.rounding.full
                visible: root.hasInlineReply

                MArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.isReplying = true
                }

                StyledText {
                    color: Colours.m3Colors.m3OnBackground
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.fonts.size.medium
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

                spacing: Appearance.spacing.normal
                Component.onCompleted: replyField.forceActiveFocus()

                FloatingButton {
                    id: backButton

                    Layout.preferredHeight: 40
                    Layout.preferredWidth: 40
                    backgroundRadius: Appearance.rounding.full
                    color: Colours.m3Colors.m3SurfaceContainerHigh
                    icon.color: Colours.m3Colors.m3OnBackground
                    icon.name: "arrow_back"
                    icon.size: Appearance.fonts.size.extraLarge
                    onClicked: root.isReplying = false
                }

                MaterialTextField {
                    id: replyField

                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
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

                    Layout.preferredHeight: 40
                    Layout.preferredWidth: 40
                    backgroundRadius: Appearance.rounding.full
                    color: Colours.m3Colors.m3SurfaceContainerHigh
                    icon.color: Qt.alpha(Colours.m3Colors.m3OnBackground, replyField.length > 0 ? 1 : 0.4)
                    icon.name: "send"
                    icon.size: Appearance.fonts.size.extraLarge
                    onClicked: {
                        if (replyField.length > 0)
                            replyRow.sendReply();
                    }
                }
            }
        }
    }
}
