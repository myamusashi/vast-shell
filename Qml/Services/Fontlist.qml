pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property int fontCount: fontListModel.count
    property ListModel fontListModel: ListModel {
        id: fontListModel
    }

    function indexOfFont(familyName) {
        for (let i = 0; i < fontListModel.count; i++)
            if (fontListModel.get(i).name === familyName)
                return i;

        return -1;
    }

    Component.onCompleted: {
        const fonts = Qt.fontFamilies();
        for (let i = 0; i < fonts.length; i++) {
            fontListModel.append({
                name: fonts[i],
                index: i
            });
        }
    }
}
