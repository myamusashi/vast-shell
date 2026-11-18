pragma ComponentBehavior: Bound

import QtQuick

import qs.Components.Dialog
import qs.Core.Configs
import qs.Services

DialogBox {
    id: root

    activeAsync: PolAgent.agent?.isActive
    cardPaddingHeight: 32

    // Compact card proportions for the auth prompt.
    cardPaddingWidth: 48
    contentMaxWidth: 420
    contentMinWidth: 360
    contentSpacing: Appearance.spacing.normal
    needKeyboardFocus: true
    body: Body {
        id: bodyPolkit

        Connections {

            function onAccepted() {
                bodyPolkit.submit();
            }

            function onActiveChanged() {
                if (!root.active)
                    return;

                bodyPolkit.passwordInput.forceActiveFocus();
            }

            function onRejected() {
                bodyPolkit.cancel();
            }

            target: root
        }
    }
    header: Header {}
}
