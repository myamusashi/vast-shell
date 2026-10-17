pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
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
    property var           selectedDate: new Date()

    function               addTodo(): void {
        TodoModel.add(newTodoInput.text, root.selectedDate);
        newTodoInput.text = "";
        root.addingTodo   = false;
    }

    Layout.fillHeight: true
    Layout.fillWidth: true
    onAddingTodoChanged: GlobalStates.isAddTodoListOpen = addingTodo
    color: Qt.alpha(Colours.m3Colors.m3Primary, 0.1)
    margin: Appearance.margin.normal
    radius: Appearance.rounding.normal

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

            StyledTextInput {
                id: newTodoInput

                Layout.fillWidth: true
                Layout.preferredHeight: 36
                passwordMode: false
                placeHolderText: qsTr("Add todo…")
                toggleButtonVisible: false
                visible: root.addingTodo
                Keys.onEscapePressed: root.addingTodo = false
                onAccepted: root.addTodo()
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
                    newTodoInput.forceActiveFocus();
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small
            visible: root.holidayEntries.length > 0

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

        RowLayout {
            visible: root.isDayEmpty

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

        ListView {
            id: todoList

            Layout.fillHeight: true
            Layout.fillWidth: true
            clip: true
            model: root.todosForDate
            spacing: Appearance.spacing.small
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

                        StyledTextInput {
                            passwordMode: false
                            placeHolderText: qsTr("Edit todo…")
                            toggleButtonVisible: false
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
