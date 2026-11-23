pragma ComponentBehavior: Bound

import qs.Services.Hyprland

HyprlandRulesPage {
    emptyText: qsTr("No window rules yet.")
    overviewText: qsTr("Rules apply top to bottom and the last matching rule wins. Click a rule to expand and edit its match properties and effects.")
    pageTitle: qsTr("Window Rules")
    schema: WindowRuleSchema
    searchPlaceholder: qsTr("Filter by name, class, title, or effect...")
    services: WindowRuleServices
}
