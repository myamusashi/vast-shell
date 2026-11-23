pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Components.Tooltip
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

ColumnLayout {
    id: root

    required property var    effectKeys
    required property var    effects
    required property bool   invalid
    required property var    match
    required property var    matchKeys
    required property var    rule
    required property string ruleId
    required property var    ruleProblems
    required property var    schema
    required property var    services

    readonly property var    availableEffectList: root.schema.effects.filter(effect => root.effects[effect.key] === undefined)
    readonly property var    availableMatchList: root.schema.matchProps.filter(prop => root.match[prop.key] === undefined)
    readonly property string effectHintText: root.effectSectionHint()

    function                 effectSectionHint(): string {
        const parts = [qsTr("Static effects apply once when the window opens; dynamic ones are re-applied when a matched property changes.")];
        if (root.schema.expressionHint !== "")
            parts.push(root.schema.expressionHint);
        return parts.join(" ");
    }

    function                 syncNameField(): void {
        if (!nameField.activeFocus)
            nameField.text = root.rule?.name ?? "";
    }

    spacing: Appearance.spacing.normal
    Component.onCompleted: root.syncNameField()
    onRuleChanged: root.syncNameField()

    Rectangle {
        Layout.fillWidth: true
        color: Qt.alpha(Colours.m3Colors.m3OutlineVariant, 0.35)
        implicitHeight: 1
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        StyledText {
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.normal
            font.weight: Font.Medium
            text: qsTr("Rule name")
        }

        MaterialTextField {
            id: nameField

            Layout.fillWidth: true
            Layout.maximumWidth: 360
            compact: true
            placeholderText: qsTr("Unique name (optional)")
            onAccepted: root.services.setRuleField(root.ruleId, "name", text)
            onActiveFocusChanged: {
                if (!activeFocus)
                    root.services.setRuleField(root.ruleId, "name", text);
            }
        }

        Item {
            Layout.fillWidth: true
        }
    }

    Rectangle {
        Layout.fillWidth: true
        color: Colours.m3Colors.m3ErrorContainer
        implicitHeight: errorBannerRow.implicitHeight + (Appearance.margin.normal * 2)
        radius: Appearance.rounding.normal
        visible: root.invalid

        RowLayout {
            id: errorBannerRow

            anchors {
                left: parent.left
                margins: Appearance.margin.normal
                right: parent.right
                top: parent.top
            }

            spacing: Appearance.spacing.small

            Icon {
                Layout.alignment: Qt.AlignTop
                color: Colours.m3Colors.m3OnErrorContainer
                font.pixelSize: Appearance.fonts.size.large
                icon: "error"
            }

            StyledText {
                Layout.fillWidth: true
                color: Colours.m3Colors.m3OnErrorContainer
                font.pixelSize: Appearance.fonts.size.small
                text: root.ruleProblems.join("\n")
                wrapMode: Text.Wrap
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        color: Colours.m3Colors.m3SurfaceContainerHigh
        implicitHeight: matchSectionLayout.implicitHeight + (Appearance.margin.normal * 2)
        radius: Appearance.rounding.normal

        ColumnLayout {
            id: matchSectionLayout

            anchors {
                left: parent.left
                margins: Appearance.margin.normal
                right: parent.right
                top: parent.top
            }

            spacing: Appearance.spacing.small

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                StyledText {
                    color: Colours.m3Colors.m3Primary
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.DemiBold
                    text: qsTr("Match")
                }

                RuleSummaryChip {
                    backgroundColor: Colours.m3Colors.m3PrimaryContainer
                    contentColor: Colours.m3Colors.m3OnPrimaryContainer
                    monospace: true
                    text: String(root.matchKeys.length)
                }

                Item {
                    id: matchInfoIcon

                    Layout.alignment: Qt.AlignVCenter
                    implicitHeight: 20
                    implicitWidth: 20

                    Icon {
                        anchors.centerIn: parent
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.large
                        icon: "info"
                    }

                    Tooltip {
                        anchorItem: matchInfoIcon
                        text: qsTr("Every property must match. Regular expressions must match the whole value; prefix with negative: to invert, e.g. ^(kitty)$.")
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                RulePickerField {
                    id: addMatchField

                    items: root.availableMatchList.map(prop => {
                        const label = root.schema.labelFromKey(prop.key);
                        return {
                            item: prop,
                            searchText: prop.key + " " + label,
                            text: label
                        };
                    })
                    placeholderText: qsTr("Add match property")
                    visible: root.availableMatchList.length > 0
                    onItemActivated: prop => root.services.setMatchProp(root.ruleId, prop.key, prop.default)
                }
            }

            StyledText {
                Layout.fillWidth: true
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.small
                text: qsTr("No match properties yet. Add at least one so this rule can match.")
                visible: root.matchKeys.length === 0
                wrapMode: Text.Wrap
            }

            Repeater {
                model: root.matchKeys
                delegate: ColumnLayout {
                    id: matchItemColumn

                    required property int    index
                    required property string modelData

                    readonly property var    propertyDescriptor: root.schema.matchPropByKey(matchItemColumn.modelData)

                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    Rectangle {
                        Layout.fillWidth: true
                        color: Qt.alpha(Colours.m3Colors.m3OutlineVariant, 0.35)
                        implicitHeight: 1
                        visible: matchItemColumn.index > 0
                    }

                    RuleValueRow {
                        Layout.fillWidth: true
                        currentValue: root.match[matchItemColumn.modelData]
                        descriptor: matchItemColumn.propertyDescriptor
                        label: root.schema.labelFromKey(matchItemColumn.modelData)
                        pickValues: root.services.matchPickValues(matchItemColumn.propertyDescriptor)
                        onPickRequested: root.services.refreshMatchPicks()
                        onRemoved: root.services.removeMatchProp(root.ruleId, matchItemColumn.modelData)
                        onValueChanged: value => root.services.setMatchProp(root.ruleId, matchItemColumn.modelData, value)
                    }
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        color: Colours.m3Colors.m3SurfaceContainerHigh
        implicitHeight: effectSectionLayout.implicitHeight + (Appearance.margin.normal * 2)
        radius: Appearance.rounding.normal

        ColumnLayout {
            id: effectSectionLayout

            anchors {
                left: parent.left
                margins: Appearance.margin.normal
                right: parent.right
                top: parent.top
            }

            spacing: Appearance.spacing.small

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                StyledText {
                    color: Colours.m3Colors.m3Primary
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.DemiBold
                    text: qsTr("Effects")
                }

                RuleSummaryChip {
                    backgroundColor: Colours.m3Colors.m3SecondaryContainer
                    contentColor: Colours.m3Colors.m3OnSecondaryContainer
                    monospace: true
                    text: String(root.effectKeys.length)
                }

                Item {
                    id: effectInfoIcon

                    Layout.alignment: Qt.AlignVCenter
                    implicitHeight: 20
                    implicitWidth: 20

                    Icon {
                        anchors.centerIn: parent
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.large
                        icon: "info"
                    }

                    Tooltip {
                        anchorItem: effectInfoIcon
                        text: root.effectHintText
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                RulePickerField {
                    id: addEffectField

                    items: root.availableEffectList.map(effect => {
                        const label = root.schema.labelFromKey(effect.key);
                        return {
                            item: effect,
                            searchText: effect.key + " " + label,
                            text: label
                        };
                    })
                    placeholderText: qsTr("Add effect")
                    showScrollBar: true
                    visible: root.availableEffectList.length > 0
                    onItemActivated: effect => root.services.setEffect(root.ruleId, effect.key, effect.default)
                }
            }

            StyledText {
                Layout.fillWidth: true
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.small
                text: qsTr("No effects configured yet.")
                visible: root.effectKeys.length === 0
                wrapMode: Text.Wrap
            }

            Repeater {
                model: root.effectKeys
                delegate: ColumnLayout {
                    id: effectItemColumn

                    required property int    index
                    required property string modelData

                    readonly property var    effectDescriptor: root.schema.effectByKey(effectItemColumn.modelData)

                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    Rectangle {
                        Layout.fillWidth: true
                        color: Qt.alpha(Colours.m3Colors.m3OutlineVariant, 0.35)
                        implicitHeight: 1
                        visible: effectItemColumn.index > 0
                    }

                    RuleValueRow {
                        Layout.fillWidth: true
                        currentValue: root.effects[effectItemColumn.modelData]
                        descriptor: effectItemColumn.effectDescriptor
                        label: root.schema.labelFromKey(effectItemColumn.modelData)
                        showBadge: true
                        onRemoved: root.services.removeEffect(root.ruleId, effectItemColumn.modelData)
                        onValueChanged: value => root.services.setEffect(root.ruleId, effectItemColumn.modelData, value)
                    }
                }
            }
        }
    }
}
