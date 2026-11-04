pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import qs.Components.Base
import qs.Components.Button
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

WrapperRectangle {
    id: root

    readonly property var  holidayEntries: Configs.generals.showHolidays && root.selectedDate ? HolidayModel.getHolidaysForDate(root.selectedDate) : []
    readonly property bool isDayEmpty: holidayEntries.length === 0 && todosForDate.length === 0
    readonly property var  todosForDate: {
        const isoDate = TodoModel.isoDate(root.selectedDate);
        return TodoModel.todos.filter(todo => todo && todo.date === isoDate);
    }

    property bool          addingTodo: false
    property string        pendingTodoText: ""
    property var           selectedDate: new Date()

    function               addTodo(): void {
        TodoModel.add(root.pendingTodoText, root.selectedDate);
        root.pendingTodoText = "";
        root.addingTodo      = false;
    }

    Layout.fillHeight: true
    Layout.fillWidth: true
    color: Qt.alpha(Colours.m3Colors.m3Primary, 0.1)
    margin: Appearance.margin.normal
    radius: Appearance.rounding.normal
    onAddingTodoChanged: {
        if (!addingTodo)
            pendingTodoText = "";
        GlobalStates.isAddTodoListOpen = addingTodo;
    }

    ColumnLayout {
        id: content

        spacing: Appearance.spacing.normal

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                Layout.fillWidth: true
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large
                text: Qt.formatDate(root.selectedDate, "d, MMMM yyyy")
                visible: !root.addingTodo
            }

            Loader {
                Layout.fillWidth: true
                active: root.addingTodo
                visible: active
                sourceComponent: MaterialTextField {
                    placeholderText: qsTr("Add todo…")
                    text: root.pendingTodoText
                    Component.onCompleted: forceActiveFocus()
                    Keys.onEscapePressed: root.addingTodo = false
                    onAccepted: root.addTodo()
                    onTextEdited: root.pendingTodoText = text
                }
            }

            FloatingButton {
                Layout.alignment: Qt.AlignVCenter
                backgroundRadius: Appearance.rounding.normal
                icon.color: Colours.m3Colors.m3OnSurface
                icon.name: "add"
                size: "small"
                onClicked: {
                    if (root.addingTodo) {
                        root.addTodo();
                        return;
                    }
                    root.addingTodo = true;
                }
            }
        }

        Loader {
            Layout.fillWidth: true
            active: root.holidayEntries.length > 0
            visible: active
            sourceComponent: ColumnLayout {
                spacing: Appearance.spacing.small

                Repeater {
                    model: root.holidayEntries
                    delegate: StyledRect {
                        id: holidayItem

                        required property var    modelData

                        readonly property string label: modelData.type ? `${modelData.name} (${modelData.type})` : modelData.name

                        Layout.fillWidth: true
                        color: Colours.m3Colors.m3SurfaceContainerHigh
                        implicitHeight: holidayLabel.implicitHeight + Appearance.margin.small * 2
                        radius: Appearance.rounding.small

                        StyledText {
                            id: holidayLabel

                            anchors.fill: parent
                            anchors.margins: Appearance.margin.small
                            color: Colours.m3Colors.m3OnSurface
                            text: holidayItem.label
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }

        Loader {
            active: root.isDayEmpty
            visible: active
            sourceComponent: RowLayout {

                Icon {
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.larger
                    icon: "calendar"
                }

                StyledText {
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    text: qsTr("No events")
                }
            }
        }

        ListView {
            id: todoList

            Layout.fillHeight: true
            Layout.fillWidth: true
            cacheBuffer: 120
            clip: true
            spacing: Appearance.spacing.small
            model: ScriptModel {
                objectProp: "id"
                values: root.todosForDate
            }
            delegate: RowLayout {
                id: todoRow

                required property var modelData

                property bool         editing: false

                onEditingChanged: GlobalStates.isEditTodoListOpen = editing
                spacing: Appearance.spacing.small
                width: todoList.width

                Icon {
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.large
                    icon: todoRow.modelData.done ? "check_box" : "check_box_outline_blank"

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: TodoModel.toggle(todoRow.modelData.id)
                    }
                }

                Loader {
                    Layout.fillWidth: true
                    sourceComponent: todoRow.editing ? editComponent : textComponent

                    Component {
                        id: textComponent

                        StyledText {
                            color: todoRow.modelData.done ? Qt.alpha(Colours.m3Colors.m3OnSurface, 0.5) : Colours.m3Colors.m3OnSurface
                            font.pixelSize: Appearance.fonts.size.normal
                            text: todoRow.modelData.text
                            wrapMode: Text.WordWrap
                        }
                    }

                    Component {
                        id: editComponent

                        MaterialTextField {
                            placeholderText: qsTr("Edit todo…")
                            text: todoRow.modelData.text
                            Keys.onEscapePressed: todoRow.editing = false
                            onAccepted: {
                                TodoModel.update(todoRow.modelData.id, text);
                                todoRow.editing = false;
                            }
                        }
                    }
                }

                FloatingButton {
                    Layout.alignment: Qt.AlignVCenter
                    backgroundRadius: Appearance.rounding.normal
                    icon.color: Colours.m3Colors.m3OnSurface
                    icon.name: "edit"
                    size: "small"
                    onClicked: todoRow.editing = true
                }

                FloatingButton {
                    Layout.alignment: Qt.AlignVCenter
                    backgroundRadius: Appearance.rounding.normal
                    icon.color: Colours.m3Colors.m3OnSurface
                    icon.name: "delete"
                    size: "small"
                    onClicked: TodoModel.remove(todoRow.modelData.id)
                }
            }
        }
    }
}
