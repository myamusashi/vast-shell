pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Vast.Search

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    readonly property var    entries: [
        {
            page: 0,
            pageLabel: "General",
            card: "Window & Focus",
            terms: ["Follow Focus Monitor", "Transparent Mode", "Transparency Alpha", "Album Cover Blur", "Charging Indicator Spread", "Outer Border", "Holidays Calendar"]
        },
        {
            page: 0,
            pageLabel: "General",
            card: "Default Applications",
            terms: ["Terminal", "File Explorer", "Image Viewer", "Video Viewer", "Audio Settings"]
        },
        {
            page: 1,
            pageLabel: "Language",
            card: "Locale Preference",
            terms: ["Current Language"]
        },
        {
            page: 2,
            pageLabel: "Appearance",
            card: "Color System",
            terms: ["Dark Mode", "Static Colors Path", "Material Colors", "Material Scheme"]
        },
        {
            page: 2,
            pageLabel: "Appearance",
            card: "Typography System",
            terms: ["Sans Serif Font", "Monospace Font", "Nerd Font", "Material Icon Font", "Font Size Scale"]
        },
        {
            page: 2,
            pageLabel: "Appearance",
            card: "Icons",
            terms: ["Icon Set", "Icon Font", "Material Symbols", "Refresh Icons"]
        },
        {
            page: 2,
            pageLabel: "Appearance",
            card: "Shapes & Layout",
            terms: ["Corner Roundness", "Element Spacing", "Padding", "Margin"]
        },
        {
            page: 2,
            pageLabel: "Appearance",
            card: "Motion & Animation",
            terms: ["Animation Durations Scale"]
        },
        {
            page: 3,
            pageLabel: "Wallpaper",
            card: "Wallpaper Picker",
            terms: ["Select A Wallpaper Image File", "Pick Wallpaper File", "Search Wallpapers", "Browse Wallpaper", "Static Wallpaper", "Video Wallpaper"]
        },
        {
            page: 3,
            pageLabel: "Wallpaper",
            card: "Image Sourcing",
            terms: ["Enable Wallpaper", "Live Preview", "Directory Path", "Loaded Wallpaper Count"]
        },
        {
            page: 3,
            pageLabel: "Wallpaper",
            card: "Transitions & Performance",
            terms: ["Transition Animation Mode", "Low Performance Priority", "Transition Duration"]
        },
        {
            page: 4,
            pageLabel: "Top Bar",
            card: "Layout & Behavior",
            terms: ["Always Open Bar", "Compact Navigation Bar", "Bar Height"]
        },
        {
            page: 4,
            pageLabel: "Top Bar",
            card: "Workspace Display",
            terms: ["Workspace Indicator Style", "Number of Visible Workspaces"]
        },
        {
            page: 5,
            pageLabel: "Media Player",
            card: "Player Preferences",
            terms: ["Lyrics", "Dynamic Colors From Cover Art", "Auto-switch Active Player", "Slider Type"]
        },
        {
            page: 6,
            pageLabel: "Weather",
            card: "Geographic Data",
            terms: ["Latitude", "Longitude"]
        },
        {
            page: 6,
            pageLabel: "Weather",
            card: "Astronomy API",
            terms: ["WeatherAPI Key"]
        },
        {
            page: 6,
            pageLabel: "Weather",
            card: "Sync & Overview",
            terms: ["Quick Summary Widget", "Weather Reload Time"]
        },
        {
            page: 7,
            pageLabel: "Notification",
            card: "Notification Limits",
            terms: ["Maximum Notifications", "Maximum Notification Age"]
        },
        {
            page: 8,
            pageLabel: "Clipboard",
            card: "General Settings",
            terms: ["Enable Clipboard", "Image Previews", "Vim Keybinds", "Keep Clipboard Open After Copy", "Clipboard Width", "Clipboard Height", "List Entries", "Max Entries"]
        },
        {
            page: 8,
            pageLabel: "Clipboard",
            card: "Preview Dimensions",
            terms: ["Preview Width"]
        },
        {
            page: 9,
            pageLabel: "Capture Video",
            card: "Recording",
            terms: ["Screen Recorder", "Frame Rate", "Bitrate", "Video Codec", "Audio Codec", "Power Mode", "Show Cursor", "Replay Buffer"]
        },
        {
            page: 10,
            pageLabel: "Volume",
            card: "Playback",
            terms: ["Per App Volume", "System Sounds", "Application Volume", "Media Title"]
        },
        {
            page: 10,
            pageLabel: "Volume",
            card: "Output Devices",
            terms: ["Speaker", "Headphone", "Default Output", "Device Volume"]
        },
        {
            page: 10,
            pageLabel: "Volume",
            card: "Input Devices",
            terms: ["Microphone", "Default Input", "Mic Volume"]
        },
        {
            page: 10,
            pageLabel: "Volume",
            card: "Configuration",
            terms: ["Level Meters", "Show Audio Level Meters", "Audio Profile", "Card Profile", "Off", "Pro Audio"]
        },
        {
            page: 11,
            pageLabel: "Privacy Nodes",
            card: "Privacy nodes",
            terms: ["Enable Privacy Indicator", "Privacy Indicator In Dynamic Island", "Show Icon For Privacy Indicator", "Pipewire Privacy"]
        },
        {
            page: 11,
            pageLabel: "Privacy Nodes",
            card: "Privacy nodes block title",
            terms: ["Block Title", "Add Title Blocked", "Remove Title Blocked", "Block Privacy List"]
        },
        {
            page: 14,
            pageLabel: "Network & Internet",
            card: "Hotspot",
            terms: ["Hotspot Sharing", "User Hotspot", "Hotspot Password", "Hotspot Interface", "Bandwidth"]
        },
        {
            page: 14,
            pageLabel: "Network & Internet",
            card: "Wi-Fi",
            terms: ["Enable Wi-Fi"]
        },
        {
            page: 13,
            pageLabel: "Templates",
            card: "Templates",
            terms: ["Template", "Add Template", "Render Now", "Output", "Post hook"]
        },
        {
            page: 15,
            pageLabel: "Bluetooth",
            card: "Adapter",
            terms: ["Bluetooth", "Enable Bluetooth", "Discoverable", "Pairable", "Scanning", "Adapter"]
        },
        {
            page: 15,
            pageLabel: "Bluetooth",
            card: "Paired devices",
            terms: ["Paired", "Connected", "Forget", "Blocked"]
        },
        {
            page: 15,
            pageLabel: "Bluetooth",
            card: "Available devices",
            terms: ["Available", "Pair", "Discover"]
        },
        {
            page: 16,
            pageLabel: "KDE Connect",
            card: "Device Discovery",
            terms: ["Enable Polling", "Poll Interval"]
        },
        {
            page: 16,
            pageLabel: "KDE Connect",
            card: "Local Device",
            terms: ["Device ID"]
        },
        {
            page: 16,
            pageLabel: "KDE Connect",
            card: "Paired Devices",
            terms: ["Paired Devices", "Transfer", "Share File"]
        },
        {
            page: 16,
            pageLabel: "KDE Connect",
            card: "Available Devices",
            terms: ["Available Devices", "Pair"]
        },
        {
            page: 17,
            pageLabel: "Greeter",
            card: "Greeter Wallpaper",
            terms: ["Wallpaper Type", "Upload Wallpaper", "Preview"]
        },
        {
            page: 18,
            pageLabel: "Idle",
            card: "Idle Management",
            terms: ["Enable Idle Detection"]
        },
        {
            page: 18,
            pageLabel: "Idle",
            card: "Timeouts",
            terms: ["Timeout Seconds", "Command On Timeout", "Command On Resume", "Add Timeout"]
        },
        {
            page: 19,
            pageLabel: "Lockscreen",
            card: "Preview",
            terms: ["Lockscreen Preview", "Source"]
        },
        {
            page: 19,
            pageLabel: "Lockscreen",
            card: "Window Privacy",
            terms: ["Blur Windows", "Blur Radius"]
        },
        {
            page: 12,
            pageLabel: "Dock",
            card: "Layout & Behavior",
            terms: ["Enable Dock", "Dock Height", "Icon Size", "Pinned Applications"]
        },
        {
            page: 20,
            pageLabel: "About",
            card: "System Information",
            terms: ["About", "Version", "Operating System", "Kernel", "Architecture", "Processor", "Displays", "Maintainer", "Latest Update"]
        },
        {
            page: 20,
            pageLabel: "About",
            card: "RAM & Storage",
            terms: ["RAM", "Memory", "Storage", "Disk"]
        },
        {
            page: 20,
            pageLabel: "About",
            card: "Battery",
            terms: ["Battery", "Charge"]
        },
        {
            page: 21,
            pageLabel: "Hyprland Monitors",
            card: "Monitor Layout",
            terms: ["Monitor Position", "Drag Monitors", "Monitor Arrangement", "Display Layout"]
        },
        {
            page: 21,
            pageLabel: "Hyprland Monitors",
            card: "Monitors",
            terms: ["Resolution", "Refresh Rate", "Scale", "Transform", "Bit Depth", "Color Preset", "SDR Brightness", "SDR Saturation", "ICC Profile", "Disable Monitor"]
        },
        {
            page: 22,
            pageLabel: "Hyprland General",
            card: "Windows",
            terms: ["Tearing", "Border Size", "Gaps In", "Gaps Out", "Layout", "Resize On Border", "Resize Corner"]
        },
        {
            page: 22,
            pageLabel: "Hyprland General",
            card: "Snapping",
            terms: ["Snap", "Monitor Gap", "Window Gap", "Respect Gaps", "Border Overlap"]
        },
        {
            page: 23,
            pageLabel: "Hyprland Decoration",
            card: "Decoration",
            terms: ["Opacity", "Rounding", "Dim Inactive", "Dim Strength", "Screen Shader"]
        },
        {
            page: 23,
            pageLabel: "Hyprland Decoration",
            card: "Blur",
            terms: ["Blur Size", "Blur Passes", "Noise", "Contrast", "Brightness", "Vibrancy", "Xray", "Blur Variant"]
        },
        {
            page: 23,
            pageLabel: "Hyprland Decoration",
            card: "Blur Acrylic",
            terms: ["Acrylic", "Aberration", "Bulb", "Clarity", "Refraction", "Tint"]
        },
        {
            page: 23,
            pageLabel: "Hyprland Decoration",
            card: "Blur Aurora",
            terms: ["Aurora", "Color1", "Color2", "Intensity", "Speed"]
        },
        {
            page: 23,
            pageLabel: "Hyprland Decoration",
            card: "Blur Drops",
            terms: ["Drops", "Speed"]
        },
        {
            page: 23,
            pageLabel: "Hyprland Decoration",
            card: "Blur Fluid Jar",
            terms: ["Fluid Jar", "Distortion", "Fill Amount", "Mass", "Precision", "Speed", "Turbulence"]
        },
        {
            page: 23,
            pageLabel: "Hyprland Decoration",
            card: "Blur Glass",
            terms: ["Glass", "Refraction", "Roughness", "Size"]
        },
        {
            page: 23,
            pageLabel: "Hyprland Decoration",
            card: "Blur Haze",
            terms: ["Haze", "Intensity", "Iridescence"]
        },
        {
            page: 23,
            pageLabel: "Hyprland Decoration",
            card: "Blur Heat Shimmer",
            terms: ["Heat Shimmer", "Speed"]
        },
        {
            page: 23,
            pageLabel: "Hyprland Decoration",
            card: "Blur Ripple",
            terms: ["Ripple", "Duration", "Radius", "Strength", "Width"]
        },
        {
            page: 23,
            pageLabel: "Hyprland Decoration",
            card: "Blur Water",
            terms: ["Water", "Damping", "Duration", "Radius", "Speed", "Strength"]
        },
        {
            page: 23,
            pageLabel: "Hyprland Decoration",
            card: "Shadow",
            terms: ["Shadow Range", "Shadow Scale", "Shadow Sharp", "Render Power"]
        },
        {
            page: 23,
            pageLabel: "Hyprland Decoration",
            card: "Glow",
            terms: ["Glow", "Glow Color", "Glow Range", "Render Power"]
        },
        {
            page: 23,
            pageLabel: "Hyprland Decoration",
            card: "Motion Blur",
            terms: ["Motion Blur", "Samples"]
        },
        {
            page: 23,
            pageLabel: "Hyprland Decoration",
            card: "Wobble",
            terms: ["Wobble Windows", "Stiffness", "Damping", "Mass", "Intensity"]
        },
        {
            page: 24,
            pageLabel: "Hyprland Input",
            card: "Input",
            terms: ["Keyboard Layout", "Repeat Delay", "Repeat Rate", "Follow Mouse", "Sensitivity", "Scroll Factor", "Natural Scroll", "Numlock"]
        },
        {
            page: 24,
            pageLabel: "Hyprland Input",
            card: "Touchpad",
            terms: ["Tap To Click", "Disable While Typing", "Drag Lock", "Clickfinger Behavior", "Middle Button Emulation"]
        },
        {
            page: 24,
            pageLabel: "Hyprland Input",
            card: "Touch Devices",
            terms: ["Touch Device", "Touch Output", "Touch Transform"]
        },
        {
            page: 24,
            pageLabel: "Hyprland Input",
            card: "Virtual Keyboard",
            terms: ["Virtual Keyboard", "Release Pressed On Close", "Share States"]
        },
        {
            page: 24,
            pageLabel: "Hyprland Input",
            card: "Tablet",
            terms: ["Tablet Output", "Relative Input", "Active Area"]
        },
        {
            page: 24,
            pageLabel: "Hyprland Input",
            card: "Tablet Tools",
            terms: ["Tablet Tool", "Eraser Button", "Pressure Range"]
        },
        {
            page: 25,
            pageLabel: "Hyprland Group",
            card: "Group",
            terms: ["Auto Group", "Drag Into Group", "Insert After Current", "Merge Groups"]
        },
        {
            page: 25,
            pageLabel: "Hyprland Group",
            card: "Group Bar",
            terms: ["Group Bar Height", "Font Size", "Render Titles", "Stacked", "Text Color"]
        },
        {
            page: 26,
            pageLabel: "Hyprland Misc",
            card: "Misc",
            terms: ["Font Family", "VRR", "Swallow", "Focus On Activate", "Splash", "Force Default Wallpaper", "Middle Click Paste", "Disable Autoreload"]
        },
        {
            page: 26,
            pageLabel: "Hyprland Misc",
            card: "Splash",
            terms: ["Splash Color", "Col Splash"]
        },
        {
            page: 27,
            pageLabel: "Hyprland Binds",
            card: "Binds",
            terms: ["Workspace Cycles", "Scroll Event Delay", "Drag Threshold", "Workspace Back And Forth", "Pass Mouse When Bound"]
        },
        {
            page: 28,
            pageLabel: "Hyprland Render",
            card: "Render",
            terms: ["Direct Scanout", "Color Management", "CM Auto HDR", "Use FP16", "Async Commit"]
        },
        {
            page: 29,
            pageLabel: "Hyprland Cursor",
            card: "Cursor",
            terms: ["Cursor Size", "Zoom Factor", "Inactive Timeout", "Hardware Cursors", "Hide On Touch", "Use CPU Buffer"]
        },
        {
            page: 30,
            pageLabel: "Hyprland Debug",
            card: "Debug",
            terms: ["Damage Tracking", "Disable Logs", "Overlay", "VFR", "Error Limit", "Stdout Logs"]
        },
        {
            page: 31,
            pageLabel: "Hyprland Advanced",
            card: "Layers",
            terms: ["Layers Hog Keyboard Focus", "Allow New Top Layers Over Existing Fullscreen"]
        },
        {
            page: 31,
            pageLabel: "Hyprland Advanced",
            card: "Layout",
            terms: ["Single Window Aspect Ratio", "Aspect Ratio Tolerance"]
        },
        {
            page: 31,
            pageLabel: "Hyprland Advanced",
            card: "Xwayland",
            terms: ["Xwayland", "Force Zero Scaling", "Nearest Neighbor", "Create Abstract Socket"]
        },
        {
            page: 31,
            pageLabel: "Hyprland Advanced",
            card: "OpenGL",
            terms: ["Nvidia Anti Flicker", "OpenGL"]
        },
        {
            page: 31,
            pageLabel: "Hyprland Advanced",
            card: "Ecosystem",
            terms: ["Enforce Permissions", "Donation Nag", "Update News"]
        },
        {
            page: 31,
            pageLabel: "Hyprland Advanced",
            card: "Quirks",
            terms: ["Prefer HDR", "Skip Non KMS Dmabuf Formats", "Quirks"]
        },
        {
            page: 31,
            pageLabel: "Hyprland Advanced",
            card: "Input Capture",
            terms: ["Input Capture", "Capture Modifiers", "Enforce Barriers"]
        },
        {
            page: 31,
            pageLabel: "Hyprland Advanced",
            card: "Experimental",
            terms: ["Experimental", "WP CM 1 2"]
        },
        {
            page: 32,
            pageLabel: "Window Rules",
            card: "Rules",
            terms: ["Window Rules", "Float Windows", "Opacity Rules", "Border Color", "Rounding", "Match Class", "Match Title", "Pin Windows", "Fullscreen Rule", "Suppress Events"]
        },
        {
            page: 33,
            pageLabel: "Layer Rules",
            card: "Rules",
            terms: ["Layer Rules", "Layer Blur", "Blur Bar", "Namespace", "Ignore Alpha", "Dim Around", "Blur Popups", "Above Lock", "No Screen Share"]
        },
    ]
    readonly property string query: searchField.text.trim()

    property var             results: []
    property int             selectedIndex: -1

    signal                   activated(int page, string card)

    function                 activate(entry) {
        activated(entry.page, entry.card);
        clear();
    }

    function                 clear() {
        searchField.text = "";
        results          = [];
        selectedIndex    = -1;
    }

    function                 runSearch() {
        if (query.length === 0) {
            results       = [];
            selectedIndex = -1;
            return;
        }

        // fzy scores grow with needle length, so the floor is per query character.
        const minScore = query.length * SearchEngine.appThreshold;
        const scored   = [];

        for (const entry of entries) {
            let best = SearchEngine.score(query, entry.card);
            for (const text of entry.terms) {
                const s = SearchEngine.score(query, text);
                if (s > best)
                    best = s;
            }
            if (best >= minScore)
                scored.push([best, entry]);
        }

        scored.sort((a, b) => b[0] - a[0]);
        results       = scored.slice(0, 8).map(item => item[1]);
        selectedIndex = results.length > 0 ? 0 : -1;
    }

    implicitHeight: searchField.implicitHeight
    z: 2

    DebouncedValue {
        id: searchDebounce

        interval: 200
        value: searchField.text.trim()
        onDebouncedValueChanged: root.runSearch()
    }

    RowLayout {
        id: searchBox

        anchors.fill: parent
        spacing: Appearance.spacing.normal

        Icon {
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.large
            icon: "search"
        }

        MaterialTextField {
            id: searchField

            Layout.fillWidth: true
            placeholderText: qsTr("Search settings…")
            onAccepted: {
                if (root.selectedIndex >= 0 && root.selectedIndex < root.results.length)
                    root.activate(root.results[root.selectedIndex]);
            }
            Keys.onPressed: event => {
                switch (event.key) {
                case Qt.Key_Escape:
                    if (root.query.length > 0 || root.results.length > 0) {
                        event.accepted = true;
                        root.clear();
                    }
                    break;
                case Qt.Key_Down:
                    event.accepted = true;
                    if (root.selectedIndex < root.results.length - 1)
                        root.selectedIndex++;
                    break;
                case Qt.Key_Up:
                    event.accepted = true;
                    if (root.selectedIndex > 0)
                        root.selectedIndex--;
                    break;
                }
            }
        }
    }

    Rectangle {
        id: resultsPopup

        anchors.top: parent.bottom
        anchors.topMargin: Appearance.spacing.small
        border.color: Colours.m3Colors.m3OutlineVariant
        border.width: 1
        color: Colours.m3Colors.m3SurfaceContainerHigh
        implicitHeight: resultsColumn.implicitHeight + (Appearance.margin.normal * 2)
        radius: Appearance.rounding.normal
        visible: root.results.length > 0
        width: parent.width

        ColumnLayout {
            id: resultsColumn

            anchors.fill: parent
            anchors.margins: Appearance.margin.normal
            spacing: Appearance.spacing.smaller

            Repeater {
                model: root.results.length
                delegate: Rectangle {
                    id: resultDelegate

                    required property int index

                    readonly property var resultData: root.results[index]

                    Layout.fillWidth: true
                    color: resultDelegate.index === root.selectedIndex ? Colours.m3Colors.m3SurfaceContainerHighest : "transparent"
                    implicitHeight: resultRow.implicitHeight + (Appearance.margin.normal * 2)
                    radius: Appearance.rounding.small

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: root.activate(resultDelegate.resultData)
                        onEntered: root.selectedIndex = resultDelegate.index
                    }

                    Column {
                        id: resultRow

                        anchors.fill: parent
                        anchors.margins: Appearance.margin.normal
                        spacing: 2

                        HighlightText {
                            width: parent.width
                            elide: Text.ElideRight
                            font.pixelSize: Appearance.fonts.size.normal
                            font.weight: Font.Medium
                            fullText: resultDelegate.resultData?.card ?? ""
                            searchText: root.query
                        }

                        StyledText {
                            width: parent.width
                            color: Colours.m3Colors.m3OnSurfaceVariant
                            elide: Text.ElideRight
                            font.pixelSize: Appearance.fonts.size.small
                            text: resultDelegate.resultData?.pageLabel ?? ""
                        }
                    }
                }
            }
        }
    }
}
