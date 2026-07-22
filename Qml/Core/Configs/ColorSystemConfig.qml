import Quickshell.Io

import qs.Core.Utils

JsonObject {
    property bool isDarkMode: true
    property bool useStaticColors: false
    property bool useMatugenColor: false
    property string staticColorsPath: Paths.shellDir + "/colors.json"
    property string matugenConfigPathForLightColor: Paths.shellDir + "/light-colors.json"
    property string matugenConfigPathForDarkColor: Paths.shellDir + "/dark-colors.json"
}
