pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.Components.Button
import qs.Core.Configs
import qs.Services
import qs.Components.Base
import qs.Components.Dialog.FileDialog

import "../Components"

Item {
    id: root

    function revealCard(cardTitle: string): bool {
        return cardRevealer.reveal(cardTitle);
    }

    Layout.fillHeight: true
    Layout.fillWidth: true

    CardRevealer {
        id: cardRevealer

        container: contentColumn
        target: pageFlickable
    }

    Flickable {
        id: pageFlickable

        anchors.fill: parent
        clip: true
        contentHeight: contentColumn.implicitHeight + (Appearance.margin.large * 2)
        contentWidth: parent.width
        ScrollBar.vertical: ScrollBar {}

        ColumnLayout {
            id: contentColumn

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Appearance.margin.large
            spacing: Appearance.spacing.large
            width: parent.width - (Appearance.margin.large * 2)

            StyledText {
                Layout.bottomMargin: Appearance.margin.normal
                color: Colours.m3Colors.m3OnSurface
                font.bold: true
                font.pixelSize: Appearance.fonts.size.extraLarge
                text: qsTr("Appearance & Theming")
            }

            SettingsCard {
                title: qsTr("Color System")

                GridLayout {
                    columns: 3

                    SettingRow {
                        description: qsTr("Use a dark color palette for the entire shell.")
                        label: qsTr("Dark Mode:")

                        StyledSwitch {
                            checked: Configs.colors.isDarkMode
                            onCheckedChanged: Configs.colors.isDarkMode = checked
                        }
                    }

                    SettingRow {
                        description: qsTr("Load colors from a custom JSON file and override the generated palette.")
                        label: qsTr("Use Static Colors:")

                        StyledSwitch {
                            checked: Configs.colors.useStaticColors
                            onCheckedChanged: Configs.colors.useStaticColors = checked
                        }
                    }
                }

                SettingRow {
                    description: qsTr("File path to the custom colors JSON when static colors are enabled.")
                    label: qsTr("Static Colors Path:")

                    StyledTextInput {
                        id: staticColorsPathField

                        implicitWidth: 350
                        text: Configs.colors.staticColorsPath
                        toggleButtonVisible: false
                        onEditingFinished: Configs.colors.staticColorsPath = text

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                staticColorsPathField.forceActiveFocus();
                                staticColorsFileDialog.openFileDialog();
                            }
                        }
                    }

                    FileDialog {
                        id: staticColorsFileDialog

                        nameFilters: ["*.json"]
                        showHidden: true
                        onFileSelected: path => Configs.colors.staticColorsPath = path
                    }
                }

                SettingRow {
                    description: qsTr("Material You color scheme variant for palette generation.")
                    label: qsTr("Material Scheme:")

                    SplitButton {
                        readonly property int selectedIndex: model.findIndex(entry => entry.display === Configs.colors.scheme)

                        currentIndex: selectedIndex
                        icon.name: "format_color_fill"
                        model: ["vibrant", "tonal-spot", "expressive", "monochrome", "rainbow", "fruit-salad", "neutral", "fidelity", "content"].map(name => ({
                                    display: name
                                }))
                        text: model[selectedIndex]?.display ?? Configs.colors.scheme
                        textRole: "display"
                        onMenuItemActivated: index => Configs.colors.scheme = model[index].display
                    }
                }
            }

            SettingsCard {
                title: qsTr("Typography System")

                GridLayout {
                    columns: 2

                    SettingRow {
                        description: qsTr("Primary font for UI text and labels.")
                        label: qsTr("Sans Serif Font:")

                        FontPicker {
                            Layout.preferredWidth: 250
                            searchField: Appearance.fonts.family.sans
                            onConfigChanged: value => Appearance.fonts.family.sans = value
                        }
                    }

                    SettingRow {
                        description: qsTr("Font for code and monospaced text.")
                        label: qsTr("Monospace Font:")

                        FontPicker {
                            Layout.preferredWidth: 250
                            searchField: Appearance.fonts.family.mono
                            onConfigChanged: value => Appearance.fonts.family.mono = value
                        }
                    }

                    SettingRow {
                        description: qsTr("Nerd font used for icon or font text.")
                        label: qsTr("Nerd Font:")

                        FontPicker {
                            Layout.preferredWidth: 250
                            searchField: Appearance.fonts.family.nerd
                            onConfigChanged: value => Appearance.fonts.family.nerd = value
                        }
                    }

                    SettingRow {
                        description: qsTr("Icon font used for Material Symbols throughout the shell.")
                        label: qsTr("Material Icon Font:")

                        FontPicker {
                            Layout.preferredWidth: 250
                            searchField: Appearance.fonts.family.material
                            onConfigChanged: value => Appearance.fonts.family.material = value
                        }
                    }

                    SettingRow {
                        description: qsTr("Global multiplier for all font sizes.")
                        label: qsTr("Font Size Scale:")

                        StyledSlide {
                            Layout.preferredWidth: 200
                            from: 0.1
                            popupDecimals: 1
                            showValuePopup: true
                            snapEnabled: true
                            stepSize: 0.1
                            to: 2.0
                            value: Appearance.fonts.size.scale
                            onMoved: Appearance.fonts.size.scale = value
                        }
                    }
                }
            }

            SettingsCard {
                title: qsTr("Shapes & Layout")

                GridLayout {
                    columns: 2

                    SettingRow {
                        description: qsTr("Corner radius.")
                        label: qsTr("UI Corner Roundness (Normal):")

                        StyledSlide {
                            Layout.preferredWidth: 200
                            from: 0
                            stepSize: 1
                            to: 50
                            value: Appearance.rounding.normal
                            onMoved: Appearance.rounding.normal = value
                        }
                    }

                    SettingRow {
                        description: qsTr("Default spacing between UI elements.")
                        label: qsTr("Element Spacing (Normal):")

                        StyledSlide {
                            Layout.preferredWidth: 200
                            from: 0
                            stepSize: 1
                            to: 50
                            value: Appearance.spacing.normal
                            onMoved: Appearance.spacing.normal = value
                        }
                    }

                    SettingRow {
                        description: qsTr("Inner padding.")
                        label: qsTr("Padding (Normal):")

                        StyledSlide {
                            Layout.preferredWidth: 200
                            from: 0
                            stepSize: 1
                            to: 50
                            value: Appearance.padding.normal
                            onMoved: Appearance.padding.normal = value
                        }
                    }

                    SettingRow {
                        description: qsTr("Outer margin.")
                        label: qsTr("Margin (Normal):")

                        StyledSlide {
                            Layout.preferredWidth: 200
                            from: 0
                            stepSize: 1
                            to: 50
                            value: Appearance.margin.normal
                            onMoved: Appearance.margin.normal = value
                        }
                    }
                }
            }

            SettingsCard {
                title: qsTr("Motion & Animation")

                SettingRow {
                    description: qsTr("Multiplier for all animation durations. Higher is slower.")
                    label: qsTr("Animation Durations Scale:")

                    StyledSlide {
                        Layout.preferredWidth: 200
                        from: 1
                        showValuePopup: true
                        snapEnabled: true
                        stepSize: 1
                        to: 5
                        value: Appearance.animations.durations.scale
                        onMoved: Appearance.animations.durations.scale = value
                    }
                }
            }

            Item {
                Layout.fillHeight: true
                implicitHeight: Appearance.margin.large
            }
        }
    }

    component FilePathRow: RowLayout {
        id: filePathRow

        property string configValue
        property string label
        property var    nameFilters: ["*.json"]

        signal          configChanged(string value)

        Layout.fillWidth: true

        StyledText {
            Layout.fillWidth: true
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.large
            text: filePathRow.label
        }

        StyledTextInput {
            id: pathField

            implicitWidth: 350
            toggleButtonVisible: false
            Component.onCompleted: text = filePathRow.configValue
            onEditingFinished: filePathRow.configChanged(text)

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    pathField.forceActiveFocus();
                    fileDialog.openFileDialog();
                }
            }
        }

        FileDialog {
            id: fileDialog

            nameFilters: filePathRow.nameFilters
            showHidden: true
            onFileSelected: path => filePathRow.configChanged(path)
        }
    }
    component FontPicker: Item {
        id: fontPicker

        property string configValue
        property var    filteredModel: {
            const query  = searchText.toLowerCase();
            const result = [];
            if (!query)
                result.push({
                    name: "",
                    index: -1
                });
            for (let i = 0; i < Fontlist.fontListModel.count; i++) {
                const item = Fontlist.fontListModel.get(i);
                if (!query || item.name.toLowerCase().includes(query))
                    result.push(item);
            }
            return result;
        }
        property alias  searchField: searchField.placeHolderText
        property string searchText: ""

        signal          configChanged(string value)

        implicitHeight: 48
        implicitWidth: 250

        StyledTextInput {
            id: searchField

            anchors.fill: parent
            placeHolderText: qsTr("Search font...")
            toggleButtonVisible: false
            Component.onCompleted: text = fontPicker.configValue
            onActiveFocusChanged: {
                if (activeFocus && !popup.visible)
                    popup.open();
            }
            onTextChanged: {
                fontPicker.searchText = text;
                if (!popup.visible)
                    popup.open();
            }
        }

        Popup {
            id: popup

            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
            implicitHeight: Math.min(listView.contentHeight + 16, 280)
            width: searchField.width
            y: searchField.height + 4
            background: StyledRect {
                color: Colours.m3Colors.m3SurfaceContainerLow
                radius: Appearance.rounding.large

                Elevation {
                    anchors.fill: parent
                    level: 2
                    radius: parent.radius
                    z: -1
                }
            }
            contentItem: ListView {
                id: listView

                cacheBuffer: 0
                clip: true
                model: fontPicker.filteredModel
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: StyledRect {
                        color: Qt.alpha(Colours.m3Colors.m3OnSurface, 0.38)
                        implicitWidth: 4
                        radius: 2
                    }
                }
                delegate: ItemDelegate {
                    id: fontDelegate

                    required property int  index
                    required property var  modelData

                    readonly property bool itemActive: modelData.name === fontPicker.configValue

                    bottomPadding: 0
                    height: 52
                    leftPadding: 16
                    rightPadding: 16
                    topPadding: 0
                    width: listView.width
                    background: StyledRect {
                        color: fontDelegate.itemActive ? Colours.m3Colors.m3TertiaryContainer : fontDelegate.highlighted ? Qt.alpha(Colours.m3Colors.m3OnSurface, 0.08) : "transparent"
                        radius: Appearance.rounding.large
                    }
                    contentItem: StyledText {
                        color: Colours.m3Colors.m3OnSurface
                        elide: Text.ElideRight
                        font.family: fontDelegate.itemActive || fontDelegate.highlighted ? fontDelegate.modelData.name : ""
                        font.pixelSize: Appearance.fonts.size.normal
                        text: fontDelegate.modelData.name || qsTr("System default")
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        fontPicker.configChanged(modelData.name);
                        searchField.text      = modelData.name;
                        fontPicker.searchText = "";
                        popup.close();
                    }
                }
                footer: Item {
                    height: 8
                }
                header: Item {
                    height: 8
                }
            }
        }
    }
}
