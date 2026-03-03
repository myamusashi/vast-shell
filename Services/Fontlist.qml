pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property int fontCount: _fontListModel.count
    property ListModel fontListModel: ListModel {
        id: _fontListModel
    }

    Component.onCompleted: {
        const fonts = Qt.fontFamilies();
        for (let i = 0; i < fonts.length; i++) {
            _fontListModel.append({
                name: fonts[i],
                index: i
            });
        }
    }

    function indexOfFont(familyName) {
        for (let i = 0; i < _fontListModel.count; i++)
            if (_fontListModel.get(i).name === familyName)
                return i;

        return -1;
    }
}
