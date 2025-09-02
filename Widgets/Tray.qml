import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.Data

Rectangle {
	id: root
	property var parentWindow: null
	property var parentScreen: null
	property real widgetHeight: 30
	readonly property real horizontalPadding: Appearance.spacing.normal
	readonly property int calculatedWidth: SystemTray.items.values.length > 0 ? SystemTray.items.values.length * Appearance.spacing.large + horizontalPadding * 2 : 0

	width: calculatedWidth
	height: widgetHeight
	radius: Appearance.rounding.small
	border.color: Appearance.colors.on_background
	color: Appearance.colors.background
	visible: SystemTray.items.values.length > 0

	Row {
		id: systemTrayRow
		anchors.centerIn: parent
		spacing: 5

		Repeater {
			model: SystemTray.items.values
			delegate: Item {
				property var trayItem: modelData
				property string iconSource: {
					let icon = trayItem && trayItem.icon;
					if (typeof icon === 'string' || icon instanceof String) {
						if (icon.includes("?path=")) {
							const split = icon.split("?path=");
							if (split.length !== 2)
								return icon;
							const name = split[0];
							const path = split[1];
							const fileName = name.substring(name.lastIndexOf("/") + 1);
							return `file://${path}/${fileName}`;
						}
						return icon;
					}
					return "";
				}

				width: 24
				height: 24

				Rectangle {
					anchors.fill: parent
					radius: Appearance.rounding.small
					color: trayItemArea.containsMouse ? Appearance.colors.primary : "transparent"
					Behavior on color {
						enabled: trayItemArea.containsMouse !== undefined
						NumberAnimation {
							duration: Appearance.animation.durations.normal
							easing.type: Easing.BezierSpline
							easing.bezierCurve: Appearance.animation.curves.standard
						}
					}
				}

				IconImage {
					anchors.centerIn: parent
					width: 16
					height: 16
					source: parent.iconSource
					asynchronous: true
					smooth: true
					mipmap: true
				}

				MouseArea {
					id: trayItemArea
					anchors.fill: parent
					acceptedButtons: Qt.LeftButton | Qt.RightButton
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor

					onClicked: mouse => {
						if (!trayItem)
							return;

						if (mouse.button === Qt.LeftButton && !trayItem.onlyMenu) {
							trayItem.activate();
							return;
						}

						if (trayItem.hasMenu) {
							// Cari window Quickshell yang valid dari hierarchy
							var validWindow = root.parentWindow;
							if (!validWindow) {
								// Fallback: cari window dari parent chain
								var item = root.parent;
								while (item && !validWindow) {
									if (item.toString().includes("WlrLayershell")) {
										validWindow = item;
										break;
									}
									item = item.parent;
								}
							}

							if (validWindow) {
								var globalPos = mapToGlobal(0, 0);
								var currentScreen = root.parentScreen || validWindow.screen;
								var screenX = currentScreen ? currentScreen.x : 0;
								var relativeX = globalPos.x - screenX;

								menuAnchor.menu = trayItem.menu;
								menuAnchor.anchor.window = validWindow;
								menuAnchor.anchor.rect = Qt.rect(relativeX, 35 + Appearance.spacing.small, parent.width, 1);
								menuAnchor.open();
							} else {
								console.warn("Cannot find valid Quickshell window for tray menu");
							}
						}
					}
				}
			}
		}
	}

	QsMenuAnchor {
		id: menuAnchor
	}
}
