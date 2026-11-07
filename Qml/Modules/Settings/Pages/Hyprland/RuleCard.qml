pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Components.Button
import qs.Core.Configs
import qs.Services

Rectangle {
    id: root

    required property int    index
    required property string modelData

    readonly property var    availableEffectList: root.schema.effects.filter(effect => root.effects[effect.key] === undefined)
    readonly property var    availableMatchList: root.schema.matchProps.filter(prop => root.match[prop.key] === undefined)
    readonly property var    effects: root.rule !== null && typeof root.rule.effects === "object" && root.rule.effects !== null ? root.rule.effects : {}
    readonly property bool   invalid: root.ruleProblems.length > 0
    readonly property var    match: root.rule !== null && typeof root.rule.match === "object" && root.rule.match !== null ? root.rule.match : {}
    readonly property var    rule: root.services.ruleById(root.modelData)
    readonly property var    ruleProblems: root.services.problems[root.modelData] ?? []

    property string          effectKeyCache: ""
    property var             effectKeys: []
    property string          matchKeyCache: ""
    property var             matchKeys: []
    property int             ruleCount
    property var             schema
    property var             services

    function                 availableEffects(): var {
        return root.availableEffectList;
    }

    function                 availableMatchProps(): var {
        return root.availableMatchList;
    }

    function                 effectSectionHint(): string {
        const parts = [qsTr("Static effects apply once when the window opens; dynamic ones are re-applied when a matched property changes.")];
        if (root.schema.expressionHint !== "")
            parts.push(root.schema.expressionHint);
        return parts.join(" ");
    }

    function                 refreshEffectKeys(): void {
        const keys   = Object.keys(root.effects);
        const joined = keys.join("\u0002");
        if (joined === root.effectKeyCache)
            return;
        root.effectKeyCache = joined;
        root.effectKeys     = keys;
    }

    function                 refreshMatchKeys(): void {
        const keys   = Object.keys(root.match);
        const joined = keys.join("\u0002");
        if (joined === root.matchKeyCache)
            return;
        root.matchKeyCache = joined;
        root.matchKeys     = keys;
    }

    Component.onCompleted: {
        root.refreshMatchKeys();
        root.refreshEffectKeys();
    }
    onEffectsChanged: root.refreshEffectKeys()
    onMatchChanged: root.refreshMatchKeys()
    onRuleChanged: {
        if (!nameField.activeFocus)
            nameField.text = root.rule?.name ?? "";
    }
    Layout.fillWidth: true
    color: Colours.m3Colors.m3SurfaceContainerLow
    implicitHeight: cardLayout.implicitHeight + (Appearance.margin.large * 2)
    radius: Appearance.rounding.large

    Elevation {
        anchors.fill: parent
        level: 1
        radius: root.radius
        z: -1
    }

    Rectangle {
        anchors.fill: parent
        border.color: Colours.m3Colors.m3Error
        border.width: 2
        color: "transparent"
        radius: root.radius
        visible: root.invalid
    }

    ColumnLayout {
        id: cardLayout

        spacing: Appearance.spacing.normal

        anchors {
            left: parent.left
            margins: Appearance.margin.large
            right: parent.right
            top: parent.top
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            StyledSwitch {
                Layout.alignment: Qt.AlignVCenter
                checked: root.rule?.enabled ?? true
                onToggled: root.services.setRuleField(root.modelData, "enabled", checked)
            }

            MaterialTextField {
                id: nameField

                Layout.fillWidth: true
                Layout.maximumWidth: 320
                placeholderText: qsTr("Unique name (optional)")
                onAccepted: root.services.setRuleField(root.modelData, "name", text)
                onActiveFocusChanged: {
                    if (!activeFocus)
                        root.services.setRuleField(root.modelData, "name", text);
                }
            }

            FloatingButton {
                Layout.alignment: Qt.AlignVCenter
                enabled: root.index > 0
                size: "small"
                icon.color: Colours.m3Colors.m3OnSurfaceVariant
                icon.name: "keyboard_arrow_up"
                onClicked: root.services.moveRule(root.modelData, -1)
            }

            FloatingButton {
                Layout.alignment: Qt.AlignVCenter
                enabled: root.index < root.ruleCount - 1
                size: "small"
                icon.color: Colours.m3Colors.m3OnSurfaceVariant
                icon.name: "keyboard_arrow_down"
                onClicked: root.services.moveRule(root.modelData, 1)
            }

            FloatingButton {
                Layout.alignment: Qt.AlignVCenter
                size: "small"
                icon.color: Colours.m3Colors.m3OnSurfaceVariant
                icon.name: "content_copy"
                onClicked: root.services.duplicateRule(root.modelData)
            }

            FloatingButton {
                Layout.alignment: Qt.AlignVCenter
                size: "small"
                icon.color: Colours.m3Colors.m3Error
                icon.name: "delete"
                onClicked: root.services.deleteRule(root.modelData)
            }
        }

        StyledText {
            Layout.fillWidth: true
            color: Colours.m3Colors.m3Error
            font.pixelSize: Appearance.fonts.size.small
            text: root.ruleProblems.join(" ")
            visible: root.invalid
            wrapMode: Text.Wrap
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            StyledText {
                color: Colours.m3Colors.m3Primary
                font.pixelSize: Appearance.fonts.size.large
                font.weight: Font.DemiBold
                text: qsTr("Match")
            }

            Item {
                Layout.fillWidth: true
            }

            SplitButton {
                id: addPropButton

                visible: root.availableMatchList.length > 0
                text: qsTr("Add property")
                model: root.availableMatchList.map(prop => {
                    return {
                        text: root.schema.labelFromKey(prop.key)
                    };
                })
                onClicked: addPropButton.openMenu()
                onMenuItemActivated: index => {
                    const prop = root.availableMatchList[index];
                    root.services.setMatchProp(root.modelData, prop.key, prop.default);
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            color: Qt.alpha(Colours.m3Colors.m3OnSurface, 0.5)
            font.pixelSize: Appearance.fonts.size.small
            text: qsTr("Every property must match. Regular expressions must match the whole value; prefix with negative: to invert, e.g. ^(kitty)$.")
            wrapMode: Text.Wrap
        }

        Repeater {
            model: root.matchKeys
            delegate: RuleValueRow {
                id: matchRow

                required property string modelData

                readonly property var    propDescriptor: root.schema.matchPropByKey(matchRow.modelData)

                Layout.fillWidth: true
                currentValue: root.match[matchRow.modelData]
                descriptor: matchRow.propDescriptor
                label: root.schema.labelFromKey(matchRow.modelData)
                pickValues: root.services.matchPickValues(matchRow.propDescriptor)
                onPickRequested: root.services.refreshMatchPicks()
                onRemoved: root.services.removeMatchProp(root.modelData, matchRow.modelData)
                onValueChanged: value => root.services.setMatchProp(root.modelData, matchRow.modelData, value)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            StyledText {
                color: Colours.m3Colors.m3Primary
                font.pixelSize: Appearance.fonts.size.large
                font.weight: Font.DemiBold
                text: qsTr("Effects")
            }

            Item {
                Layout.fillWidth: true
            }

            SplitButton {
                id: addEffectButton

                visible: root.availableEffectList.length > 0
                text: qsTr("Add effect")
                model: root.availableEffectList.map(effect => {
                    return {
                        text: root.schema.labelFromKey(effect.key)
                    };
                })
                showScrollBar: true
                onClicked: addEffectButton.openMenu()
                onMenuItemActivated: index => {
                    const effect = root.availableEffectList[index];
                    root.services.setEffect(root.modelData, effect.key, effect.default);
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            color: Qt.alpha(Colours.m3Colors.m3OnSurface, 0.5)
            font.pixelSize: Appearance.fonts.size.small
            text: root.effectSectionHint()
            wrapMode: Text.Wrap
        }

        Repeater {
            model: root.effectKeys
            delegate: RuleValueRow {
                id: effectRow

                required property string modelData

                readonly property var    effectDescriptor: root.schema.effectByKey(effectRow.modelData)

                Layout.fillWidth: true
                currentValue: root.effects[effectRow.modelData]
                descriptor: effectRow.effectDescriptor
                label: root.schema.labelFromKey(effectRow.modelData)
                showBadge: true
                onRemoved: root.services.removeEffect(root.modelData, effectRow.modelData)
                onValueChanged: value => root.services.setEffect(root.modelData, effectRow.modelData, value)
            }
        }
    }
}
