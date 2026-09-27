import QtQuick
import Vast.Search

import qs.Core.Utils
import qs.Services

Text {
    id: root

    property string searchText: ""
    property string fullText: ""

    font.family: Fonts.sans
    color: Colours.m3Colors.m3OnSurface
    textFormat: searchText.length > 0 ? Text.RichText : Text.PlainText
    text: searchText.length > 0 ? SearchEngine.highlightedHtml(fullText, searchText, Colours.m3Colors.m3Primary.toString()) : fullText
}
