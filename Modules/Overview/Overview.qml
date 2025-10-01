pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland

import qs.Data

Scope {
	GlobalShortcut {
		name: "overview"
		onPressed: lazyloader.active = !lazyloader.active
	}

	Connections {
		target: Hyprland

		function onRawEvent() {
			Hyprland.refreshMonitors();
			Hyprland.refreshWorkspaces();
			Hyprland.refreshToplevels();
		}
	}

	LazyLoader {
		id: lazyloader

		active: false

		PanelWindow {
			id: root

			property real scaleFactor: 0.2

			implicitWidth: contentGrid.implicitWidth + 24
			implicitHeight: contentGrid.implicitHeight + 24
			WlrLayershell.layer: WlrLayer.Overlay

			FileView {
				id: wallid
				path: Qt.resolvedUrl(Quickshell.env("HOME") + "/.cache/wall/path.txt")

				watchChanges: true
				onFileChanged: reload()
			}

			property string imgsrc: wallid.text()

			Rectangle {
				anchors.fill: parent
				color: Appearance.colors.withAlpha(Appearance.colors.background, 0.9)
				border.color: Appearance.colors.outline
				border.width: 2
			}

			GridLayout {
				id: contentGrid
				rows: 2
				columns: 4
				rowSpacing: 12
				columnSpacing: 12
				anchors.centerIn: parent

				Repeater {
					model: 8

					delegate: Rectangle {
						id: workspaceContainer

						required property int index
						property HyprlandWorkspace workspace: Hyprland.workspaces.values.find(w => w.id === index + 1) ?? null
						property HyprlandMonitor monitor: Hyprland.monitors.values[0]

						property bool hasFullscreen: !!(workspace?.toplevels?.values.some(t => t.wayland?.fullscreen))
						property bool hasMaximized: !!(workspace?.toplevels?.values.some(t => t.wayland?.maximized))
						property int reservedX: hasFullscreen ? 0 : monitor.lastIpcObject?.reserved?.[0]
						property int reservedY: hasFullscreen ? 0 : monitor.lastIpcObject?.reserved?.[1]

						implicitWidth: (monitor.width - reservedX) * root.scaleFactor * 0.9
						implicitHeight: (monitor.height - reservedY) * root.scaleFactor * 0.9

						color: "transparent"
						border.width: 2
						border.color: hasMaximized ? Appearance.colors.on_error : color

						Image {
							anchors.fill: parent

							antialiasing: false
							asynchronous: true
							mipmap: true
							smooth: true

							source: root.imgsrc.trim()

							z: -1
						}

						DropArea {
							anchors.fill: parent

							onEntered: drag => drag.source.isCaught = true
							onExited: drag.source.isCaught = false

							onDropped: drag => {
								const toplevel = drag.source;

								if (toplevel.modelData.workspace !== workspaceContainer.workspace) {
									const address = toplevel.modelData.address;

									Hyprland.dispatch(`movetoworkspacesilent ${workspaceContainer.index + 1}, address:0x${address}`);
									Hyprland.dispatch(`movewindowpixel exact ${toplevel.initX} ${toplevel.initY}, address:0x${address}`);
								}
							}
						}

						MouseArea {
							anchors.fill: parent
							onClicked: Hyprland.dispatch(`workspace ${workspaceContainer.index + 1}`)
						}

						Repeater {
							model: workspaceContainer.workspace?.toplevels

							delegate: ScreencopyView {
								id: toplevel

								required property HyprlandToplevel modelData
								property Toplevel waylandHandle: modelData?.wayland
								property var toplevelData: modelData.lastIpcObject

								captureSource: waylandHandle
								live: true

								anchors.centerIn: parent

								width: sourceSize.width * root.scaleFactor * 0.9 - 5
								height: sourceSize.height * root.scaleFactor * 0.9 - 5

								x: (toplevelData.at?.[0] - workspaceContainer.reservedX) * root.scaleFactor * 0
								y: (toplevelData.at?.[1] - workspaceContainer.reservedY) * root.scaleFactor * 0
								z: (waylandHandle.fullscreen || waylandHandle.maximized) ? 2 : toplevelData.floating

								IconImage {
									source: Quickshell.iconPath(DesktopEntries.heuristicLookup(toplevel.toplevelData?.class)?.icon, "image-missing")
									implicitSize: 48
									anchors.centerIn: parent
								}

								MouseArea {
									acceptedButtons: Qt.LeftButton | Qt.RightButton
									anchors.fill: parent

									onClicked: mouse => {
										if (mouse.button === Qt.LeftButton)
											toplevel.waylandHandle.activate();
										else if (mouse.button === Qt.RightButton)
											toplevel.waylandHandle.close();
									}
								}
							}
						}
					}
				}
			}
		}
	}
}
