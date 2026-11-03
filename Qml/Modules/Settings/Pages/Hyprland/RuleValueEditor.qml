pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Components.Button
import qs.Core.Configs

Loader {
    id: root

    property var descriptor
    property var value

    signal       valueCommitted(var value)

    function     canonicalVec2(value: var): string {
        return Array.isArray(value) ? value.map(item => String(item)).join("\u0001") : "";
    }

    function     clampNumber(value: real): real {
        if (descriptor.min !== undefined && value < descriptor.min)
            return descriptor.min;
        if (descriptor.max !== undefined && value > descriptor.max)
            return descriptor.max;
        return value;
    }

    function     commitNumber(text: string): void {
        const parsed = descriptor.type === "int" ? parseInt(text, 10) : parseFloat(text);
        if (isNaN(parsed)) {
            writeEditorText(value);
            return;
        }
        const clamped = clampNumber(parsed);
        valueCommitted(clamped);
        writeEditorText(clamped);
    }

    function     commitVec2(xText: string, yText: string): void {
        const next = [String(xText), String(yText)];
        if (canonicalVec2(next) === canonicalVec2(value))
            return;
        valueCommitted(next);
        writeEditorText(next);
    }

    function     currentEnumLabel(): string {
        const values = descriptor.values ?? [];
        const index  = values.indexOf(value);
        return enumLabel(index >= 0 ? value : "");
    }

    function     enumLabel(value: var): string {
        if (value === "" || value === null || value === undefined)
            return qsTr("Default");
        const labels = descriptor.labels ?? [];
        const index  = (descriptor.values ?? []).indexOf(value);
        return index >= 0 && index < labels.length ? labels[index] : String(value);
    }

    function     writeEditorText(displayValue: var): void {
        const layout = item;
        if (layout === null)
            return;
        if (layout instanceof MaterialTextField) {
            if (!layout.activeFocus) // qmllint disable missing-property
                layout.text = displayValue === null || displayValue === undefined ? "" : String(displayValue); // qmllint disable missing-property
            return;
        }
        const fields = layout.children.filter(child => child instanceof MaterialTextField); // qmllint disable missing-property
        if (fields.length !== 2)
            return;
        if (!fields[0].activeFocus)
            fields[0].text = Array.isArray(displayValue) ? String(displayValue[0] ?? "") : "";
        if (!fields[1].activeFocus)
            fields[1].text = Array.isArray(displayValue) ? String(displayValue[1] ?? "") : "";
    }

    sourceComponent: {
        if (!descriptor)
            return emptyEditor;
        if (descriptor.type === "bool")
            return boolEditor;
        if (descriptor.type === "int" || descriptor.type === "float")
            return numberEditor;
        if (descriptor.type === "enum")
            return enumEditor;
        if (descriptor.type === "exprVec2")
            return exprVec2Editor;
        return stringEditor;
    }
    onItemChanged: writeEditorText(value)
    onValueChanged: writeEditorText(value)
    component EditorField: MaterialTextField {}

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
            onActiveFocusChanged: {
                if (!activeFocus)
                    root.commitNumber(text);
            }
        }
    }

    Component {
        id: stringEditor

        EditorField {
            id: stringField

            implicitWidth: 220
            onAccepted: root.valueCommitted(text)
            onActiveFocusChanged: {
                if (!activeFocus) {
                    root.valueCommitted(text);
                    root.writeEditorText(text);
                }
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
            id: vec2Row

            function commitFields(): void {
                root.commitVec2(xField.text, yField.text);
            }

            spacing: Appearance.spacing.small

            EditorField {
                id: xField

                implicitWidth: 130
                placeholderText: qsTr("X")
                onTextEdited: vec2Row.commitFields()
                onAccepted: vec2Row.commitFields()
                onActiveFocusChanged: {
                    if (!activeFocus)
                        vec2Row.commitFields();
                }
            }

            EditorField {
                id: yField

                implicitWidth: 130
                placeholderText: qsTr("Y")
                onTextEdited: vec2Row.commitFields()
                onAccepted: vec2Row.commitFields()
                onActiveFocusChanged: {
                    if (!activeFocus)
                        vec2Row.commitFields();
                }
            }
        }
    }
}
