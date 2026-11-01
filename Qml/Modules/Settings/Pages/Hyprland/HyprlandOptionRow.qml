pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.Components.Base
import qs.Components.Button
import qs.Core.Configs
import qs.Services
import qs.Services.Hyprland

import "../../Components"

SettingRow {
    id: root

    required property var    descriptor

    readonly property var    choices: HyprlandGeneralSchema.choicesFor(descriptor.path)
    readonly property var    currentValue: {
        const pending = GeneralServices.pendingValue(category, leafPath);
        return pending === undefined ? defaultValue : pending;
    }
    readonly property var    defaultValue: descriptor.default
    readonly property string leafPath: descriptor.path.substring(descriptor.path.indexOf(".") + 1)
    readonly property bool   modified: GeneralServices.pendingValue(category, leafPath) !== undefined

    property string          category

    function                 choiceIndex(): int {
        return choices === null ? -1 : choices.findIndex(choice => choice.value === currentValue);
    }
    function                 clampNumber(value: real): real {
        if (descriptor.min !== undefined && value < descriptor.min)
            return descriptor.min;
        if (descriptor.max !== undefined && value > descriptor.max)
            return descriptor.max;
        return value;
    }
    function                 commitGaps(uniformText: string, topText: string, leftText: string, rightText: string, bottomText: string): void {
        const sides   = {};
        let hasSide   = false;
        const entries = [["top", topText], ["left", leftText], ["right", rightText], ["bottom", bottomText]];
        for (const [side, text] of entries) {
            const parsed = parseInt(text, 10);
            if (!isNaN(parsed)) {
                sides[side] = parsed;
                hasSide     = true;
            }
        }
        if (hasSide) {
            writeValue(sides);
            return;
        }
        const uniform = parseInt(uniformText, 10);
        if (!isNaN(uniform))
            writeValue(clampNumber(uniform));
    }
    function                 commitNumber(text: string): void {
        const parsed = descriptor.type === "int" ? parseInt(text, 10) : parseFloat(text);
        if (isNaN(parsed))
            return;
        writeValue(clampNumber(parsed));
    }
    function                 commitSliderValue(value: real): void {
        writeValue(descriptor.type === "int" ? Math.round(value) : Number(value.toFixed(4)));
    }
    function                 commitVec2(xText: string, yText: string): void {
        const current = Array.isArray(currentValue) ? currentValue : [0, 0];
        const x       = parseFloat(xText);
        const y       = parseFloat(yText);
        writeValue([isNaN(x) ? (current[0] ?? 0) : x, isNaN(y) ? (current[1] ?? 0) : y]);
    }
    function                 currentChoiceLabel(): string {
        const index = choiceIndex();
        if (index >= 0)
            return choices[index].label;
        return currentValue === null || currentValue === undefined ? "" : String(currentValue);
    }
    function                 currentEnumLabel(): string {
        const values  = descriptor.values;
        const index   = values.indexOf(String(currentValue ?? ""));
        const current = index >= 0 ? values[index] : String(currentValue ?? "");
        return current === "" ? qsTr("Default") : current;
    }
    function                 descriptionText(): string {
        const parts = [];
        const base  = HyprlandGeneralSchema.descriptionFor(descriptor.path);
        if (base !== "")
            parts.push(base);
        if (descriptor.note !== undefined && descriptor.note !== "")
            parts.push(descriptor.note);
        return parts.join(" · ");
    }
    function                 enumIndex(): int {
        return descriptor.values.indexOf(String(currentValue ?? ""));
    }
    function                 gapSideText(side: string): string {
        return (currentValue !== null && typeof currentValue === "object" && !Array.isArray(currentValue)) ? String(currentValue[side] ?? "") : "";
    }
    function                 gapUniformText(): string {
        return typeof currentValue === "number" ? String(currentValue) : "";
    }
    function                 hasSliderRange(): bool {
        return descriptor.min !== undefined && descriptor.max !== undefined;
    }
    function                 isValidColor(text: string): bool {
        if (text === "")
            return true;
        if (/^#([0-9a-fA-F]{3}|[0-9a-fA-F]{4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(text))
            return true;
        if (/^0x[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(text))
            return true;
        if (/^rgba?\([0-9a-fA-F]{6}([0-9a-fA-F]{2})?\)$/.test(text))
            return true;
        return /^rgba?\(\d+(\.\d+)?(,\d+(\.\d+)?){2,3}\)$/.test(text);
    }
    function                 sliderDecimals(): int {
        if (descriptor.type === "int")
            return 0;
        const text = String(sliderStep());
        return text.includes(".") ? text.split(".")[1].length : 0;
    }
    function                 sliderStep(): real {
        if (descriptor.type === "int")
            return 1;
        const target    = (descriptor.max - descriptor.min) / 100;
        const niceSteps = [0.01, 0.02, 0.05, 0.1, 0.2, 0.25, 0.5, 1.0, 2.0, 2.5, 5.0, 10.0];
        for (const candidate of niceSteps) {
            if (candidate >= target)
                return candidate;
        }
        return 10.0;
    }
    function                 swatchColor(value: var): color {
        if (typeof value !== "string" || value === "")
            return "transparent";
        let candidate = value.trim();
        if (candidate.startsWith("0x"))
            candidate = `#${candidate.substring(2)}`;
        try {
            return Qt.color(candidate);
        } catch (error) {
            return "transparent";
        }
    }
    function                 vecComponent(index: int): string {
        return Array.isArray(currentValue) ? String(currentValue[index] ?? 0) : "0";
    }
    function                 writeValue(value: var): void {
        GeneralServices.setPendingValue(category, leafPath, value);
    }

    label: HyprlandGeneralSchema.optionLabel(descriptor.path)
    description: descriptionText()

    Rectangle {
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredHeight: 6
        Layout.preferredWidth: 6
        color: Colours.m3Colors.m3Primary
        radius: 3
        visible: root.modified
    }

    Loader {
        Layout.alignment: Qt.AlignVCenter
        sourceComponent: {
            if (root.choices !== null)
                return choiceEditor;
            if (root.descriptor.type === "bool")
                return boolEditor;
            if ((root.descriptor.type === "int" || root.descriptor.type === "float") && root.hasSliderRange())
                return sliderEditor;
            if (root.descriptor.type === "int" || root.descriptor.type === "float")
                return numberEditor;
            if (root.descriptor.type === "enum")
                return enumEditor;
            if (root.descriptor.type === "color")
                return colorEditor;
            if (root.descriptor.type === "vec2")
                return vec2Editor;
            if (root.descriptor.type === "gaps")
                return gapsEditor;
            return stringEditor;
        }
    }

    component EditorField: StyledTextInput {
        autoFocus: false
        placeholderText: ""
        toggleButtonVisible: false
    }
    component SideField: EditorField {
        property string sidePlaceholder: ""

        implicitWidth: 52
        placeholderText: sidePlaceholder
    }

    Component {
        id: boolEditor

        StyledSwitch {
            checked: root.currentValue === true
            onToggled: root.writeValue(checked)
        }
    }

    Component {
        id: choiceEditor

        SplitButton {
            id: choiceButton

            text: root.currentChoiceLabel()
            model: root.choices.map(choice => {
                return {
                    text: choice.label
                };
            })
            currentIndex: root.choiceIndex()
            onClicked: choiceButton.openMenu()
            onMenuItemActivated: index => root.writeValue(root.choices[index].value)
        }
    }

    Component {
        id: sliderEditor

        StyledSlide {
            Layout.preferredWidth: 220
            from: root.descriptor.min
            popupDecimals: root.sliderDecimals()
            popupOnHoverToo: true
            snapMode: Slider.SnapOnRelease
            stepSize: root.sliderStep()
            to: root.descriptor.max
            value: root.currentValue
            onMoved: root.commitSliderValue(value)
        }
    }

    Component {
        id: numberEditor

        EditorField {
            id: numberField

            implicitWidth: 90
            onAccepted: root.commitNumber(text)
            onIsFocusedChanged: {
                if (!isFocused)
                    root.commitNumber(text);
            }

            Binding {
                target: numberField
                property: "text"
                value: root.currentValue === null || root.currentValue === undefined ? "" : String(root.currentValue)
                when: !numberField.isFocused
            }
        }
    }

    Component {
        id: stringEditor

        EditorField {
            id: stringField

            implicitWidth: 200
            onAccepted: root.writeValue(text)
            onIsFocusedChanged: {
                if (!isFocused)
                    root.writeValue(text);
            }

            Binding {
                target: stringField
                property: "text"
                value: root.currentValue === null || root.currentValue === undefined ? "" : String(root.currentValue)
                when: !stringField.isFocused
            }
        }
    }

    Component {
        id: enumEditor

        SplitButton {
            id: enumButton

            text: root.currentEnumLabel()
            model: root.descriptor.values.map(value => {
                return {
                    text: value === "" ? qsTr("Default") : value
                };
            })
            currentIndex: root.enumIndex()
            showScrollBar: true
            onClicked: enumButton.openMenu()
            onMenuItemActivated: index => root.writeValue(root.descriptor.values[index])
        }
    }

    Component {
        id: colorEditor

        RowLayout {
            spacing: Appearance.spacing.small

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: 20
                Layout.preferredWidth: 20
                border.color: Colours.m3Colors.m3OutlineVariant
                border.width: 1
                color: root.swatchColor(root.currentValue)
                radius: 4
            }

            EditorField {
                id: colorField

                implicitWidth: 160
                onAccepted: {
                    if (root.isValidColor(text))
                        root.writeValue(text);
                }
                onIsFocusedChanged: {
                    if (!isFocused && root.isValidColor(text))
                        root.writeValue(text);
                }

                Binding {
                    target: colorField
                    property: "text"
                    value: String(root.currentValue ?? "")
                    when: !colorField.isFocused
                }
            }
        }
    }

    Component {
        id: vec2Editor

        RowLayout {
            spacing: Appearance.spacing.small

            EditorField {
                id: vecXField

                implicitWidth: 70
                placeholderText: qsTr("X")
                onAccepted: root.commitVec2(vecXField.text, vecYField.text)
                onIsFocusedChanged: {
                    if (!isFocused)
                        root.commitVec2(vecXField.text, vecYField.text);
                }

                Binding {
                    target: vecXField
                    property: "text"
                    value: root.vecComponent(0)
                    when: !vecXField.isFocused
                }
            }

            EditorField {
                id: vecYField

                implicitWidth: 70
                placeholderText: qsTr("Y")
                onAccepted: root.commitVec2(vecXField.text, vecYField.text)
                onIsFocusedChanged: {
                    if (!isFocused)
                        root.commitVec2(vecXField.text, vecYField.text);
                }

                Binding {
                    target: vecYField
                    property: "text"
                    value: root.vecComponent(1)
                    when: !vecYField.isFocused
                }
            }
        }
    }

    Component {
        id: gapsEditor

        RowLayout {
            spacing: Appearance.spacing.small

            EditorField {
                id: uniformField

                implicitWidth: 70
                placeholderText: qsTr("All")
                onAccepted: root.commitGaps(uniformField.text, topField.text, leftField.text, rightField.text, bottomField.text)
                onIsFocusedChanged: {
                    if (!isFocused)
                        root.commitGaps(uniformField.text, topField.text, leftField.text, rightField.text, bottomField.text);
                }

                Binding {
                    target: uniformField
                    property: "text"
                    value: root.gapUniformText()
                    when: !uniformField.isFocused
                }
            }

            SideField {
                id: topField

                sidePlaceholder: qsTr("T")
                onAccepted: root.commitGaps(uniformField.text, topField.text, leftField.text, rightField.text, bottomField.text)
                onIsFocusedChanged: {
                    if (!isFocused)
                        root.commitGaps(uniformField.text, topField.text, leftField.text, rightField.text, bottomField.text);
                }

                Binding {
                    target: topField
                    property: "text"
                    value: root.gapSideText("top")
                    when: !topField.isFocused
                }
            }

            SideField {
                id: leftField

                sidePlaceholder: qsTr("L")
                onAccepted: root.commitGaps(uniformField.text, topField.text, leftField.text, rightField.text, bottomField.text)
                onIsFocusedChanged: {
                    if (!isFocused)
                        root.commitGaps(uniformField.text, topField.text, leftField.text, rightField.text, bottomField.text);
                }

                Binding {
                    target: leftField
                    property: "text"
                    value: root.gapSideText("left")
                    when: !leftField.isFocused
                }
            }

            SideField {
                id: rightField

                sidePlaceholder: qsTr("R")
                onAccepted: root.commitGaps(uniformField.text, topField.text, leftField.text, rightField.text, bottomField.text)
                onIsFocusedChanged: {
                    if (!isFocused)
                        root.commitGaps(uniformField.text, topField.text, leftField.text, rightField.text, bottomField.text);
                }

                Binding {
                    target: rightField
                    property: "text"
                    value: root.gapSideText("right")
                    when: !rightField.isFocused
                }
            }

            SideField {
                id: bottomField

                sidePlaceholder: qsTr("B")
                onAccepted: root.commitGaps(uniformField.text, topField.text, leftField.text, rightField.text, bottomField.text)
                onIsFocusedChanged: {
                    if (!isFocused)
                        root.commitGaps(uniformField.text, topField.text, leftField.text, rightField.text, bottomField.text);
                }

                Binding {
                    target: bottomField
                    property: "text"
                    value: root.gapSideText("bottom")
                    when: !bottomField.isFocused
                }
            }
        }
    }
}
