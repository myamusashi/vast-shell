import QtQuick
import Vast.Search

import qs.Core.Utils
import qs.Services

Text {
    id: root

    property string fullText: ""
    property string searchText: ""

    color: Colours.m3Colors.m3OnSurface
    font.family: Fonts.sans
    text: searchText.length > 0 ? SearchEngine.highlightedHtml(fullText, searchText, Colours.m3Colors.m3Primary.toString()) : fullText
    textFormat: searchText.length > 0 ? Text.RichText : Text.PlainText
}
