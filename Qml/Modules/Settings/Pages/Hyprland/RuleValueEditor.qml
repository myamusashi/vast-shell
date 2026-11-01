pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Components.Button
import qs.Core.Configs

Loader {
    id: root

    // Typed editor for one rule match property or effect value. The value is
    // committed on accepted and on focus loss (never while typing), mirroring
    // the option rows.

    property var descriptor
    property var value

    signal       valueCommitted(var value)

    function     canonicalVec2(value: var): string { // qmllint disable
        return Array.isArray(value) ? value.map(item => String(item)).join("\u0001") : "";
    }

    function     clampNumber(value: real): real {
        if (root.descriptor.min !== undefined && value < root.descriptor.min)
            return root.descriptor.min;
        if (root.descriptor.max !== undefined && value > root.descriptor.max)
            return root.descriptor.max;
        return value;
    }

    function     commitNumber(text: string): void {
        const parsed = root.descriptor.type === "int" ? parseInt(text, 10) : parseFloat(text);
        if (isNaN(parsed))
            return;
        root.valueCommitted(root.clampNumber(parsed));
    }

    function     commitVec2(xText: string, yText: string): void {
        // Expression elements are stored as strings: expressions and plain
        // numbers are both accepted by Hyprland's parser.
        const next = [String(xText), String(yText)];
        if (root.canonicalVec2(next) === root.canonicalVec2(root.value))
            return;
        root.valueCommitted(next);
    }

    function     currentEnumLabel(): string {
        const values = root.descriptor.values ?? [];
        const index  = values.indexOf(root.value);
        return root.enumLabel(index >= 0 ? root.value : "");
    }

    function     enumLabel(value: var): string {
        if (value === "" || value === null || value === undefined)
            return qsTr("Default");
        const labels = root.descriptor.labels ?? [];
        const index  = (root.descriptor.values ?? []).indexOf(value);
        return index >= 0 && index < labels.length ? labels[index] : String(value);
    }

    function     vecComponent(index: int): string {
        return Array.isArray(root.value) ? String(root.value[index] ?? "") : "";
    }

    sourceComponent: {
        if (!root.descriptor)
            return emptyEditor;
        if (root.descriptor.type === "bool")
            return boolEditor;
        if (root.descriptor.type === "int" || root.descriptor.type === "float")
            return numberEditor;
        if (root.descriptor.type === "enum")
            return enumEditor;
        if (root.descriptor.type === "exprVec2")
            return exprVec2Editor;
        return stringEditor;
    }
    component EditorField: StyledTextInput {
        autoFocus: false
        toggleButtonVisible: false
    }

    Component {
        id: emptyEditor

        Item {
            implicitHeight: 0
            implicitWidth: 0
        }
    }

    Component {
        id: boolEditor

        StyledSwitch {
            checked: root.value === true
            onToggled: root.valueCommitted(checked)
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
                value: root.value === null || root.value === undefined ? "" : String(root.value)
                when: !numberField.isFocused
            }
        }
    }

    Component {
        id: stringEditor

        EditorField {
            id: stringField

            implicitWidth: 220
            onAccepted: root.valueCommitted(text)
            onIsFocusedChanged: {
                if (!isFocused)
                    root.valueCommitted(text);
            }

            Binding {
                target: stringField
                property: "text"
                value: root.value === null || root.value === undefined ? "" : String(root.value)
                when: !stringField.isFocused
            }
        }
    }

    Component {
        id: enumEditor

        SplitButton {
            id: enumButton

            text: root.currentEnumLabel()
            model: (root.descriptor.values ?? []).map(value => {
                return {
                    text: root.enumLabel(value)
                };
            })
            currentIndex: (root.descriptor.values ?? []).indexOf(root.value)
            showScrollBar: true
            onClicked: enumButton.openMenu()
            onMenuItemActivated: index => root.valueCommitted(root.descriptor.values[index])
        }
    }

    Component {
        id: exprVec2Editor

        RowLayout {
            spacing: Appearance.spacing.small

            EditorField {
                id: xField

                implicitWidth: 130
                placeholderText: qsTr("X")
                onAccepted: root.commitVec2(xField.text, yField.text)
                onIsFocusedChanged: {
                    if (!isFocused)
                        root.commitVec2(xField.text, yField.text);
                }

                Binding {
                    target: xField
                    property: "text"
                    value: root.vecComponent(0)
                    when: !xField.isFocused
                }
            }

            EditorField {
                id: yField

                implicitWidth: 130
                placeholderText: qsTr("Y")
                onAccepted: root.commitVec2(xField.text, yField.text)
                onIsFocusedChanged: {
                    if (!isFocused)
                        root.commitVec2(xField.text, yField.text);
                }

                Binding {
                    target: yField
                    property: "text"
                    value: root.vecComponent(1)
                    when: !yField.isFocused
                }
            }
        }
    }
}
