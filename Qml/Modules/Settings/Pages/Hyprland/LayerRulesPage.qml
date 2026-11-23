pragma ComponentBehavior: Bound

import qs.Services.Hyprland

HyprlandRulesPage {
    emptyText: qsTr("No layer rules yet.")
    overviewText: qsTr("Rules apply top to bottom and the last matching rule wins. Only the namespace can be matched; click a rule to expand and edit it.")
    pageTitle: qsTr("Layer Rules")
    schema: LayerRuleSchema
    searchPlaceholder: qsTr("Filter by name, namespace, or effect...")
    services: LayerRuleServices
}
