pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Data
import qs.Helpers
import qs.Components

Scope {
	id: scope

	property bool isControlCenterOpen: false
	property int state: 0
	readonly property int diskProp: SysUsage.diskUsed / 1048576
	readonly property int memProp: SysUsage.memUsed / 1048576

	function toggleControlCenter(): void {
		isControlCenterOpen = !isControlCenterOpen;
	}

	GlobalShortcut {
		name: "ControlCenter"
		onPressed: scope.toggleControlCenter()
	}

	LazyLoader {
		active: scope.isControlCenterOpen

		component: PanelWindow {
			id: root

			anchors {
				top: true
				right: true
			}

			property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
			property real monitorWidth: monitor.width / monitor.scale
			property real monitorHeight: monitor.height / monitor.scale
			property real scaleFactor: Math.min(1.0, monitorWidth / 1920)

			implicitWidth: monitorWidth * 0.3
			implicitHeight: 500
			exclusiveZone: 1
			color: "transparent"

			margins {
				right: (monitorWidth - implicitWidth) / 5.5
			}

			ColumnLayout {
				anchors.fill: parent
				spacing: 0

				StyledRect {
					Layout.fillWidth: true
					Layout.preferredHeight: 60
					topLeftRadius: Appearance.rounding.normal
					topRightRadius: Appearance.rounding.normal
					color: Colors.colors.surface_container

					RowLayout {
						anchors.centerIn: parent
						spacing: 15
						width: parent.width * 0.95

						Repeater {
							id: tabRepeater

							model: [
								{
									title: "Settings",
									icon: "settings",
									index: 0
								},
								{
									title: "Volumes",
									icon: "speaker",
									index: 1
								},
								{
									title: "Performance",
									icon: "speed",
									index: 2
								},
								{
									title: "Weather",
									icon: "cloud",
									index: 3
								}
							]

							StyledButton {
								required property var modelData
								required property int index

								buttonTitle: modelData.title
								Layout.fillWidth: true
								highlighted: scope.state === modelData.index
								flat: scope.state !== modelData.index
								onClicked: scope.state = modelData.index

								background: Rectangle {
									color: scope.state === index ? Colors.colors.primary : Colors.colors.surface_container
									radius: 5
								}

								contentItem: RowLayout {
									anchors.centerIn: parent
									spacing: 5

									MatIcon {
										icon: modelData.icon
										color: scope.state === index ? Colors.colors.on_primary : Colors.colors.on_surface_variant
										font.pixelSize: Appearance.fonts.extraLarge * root.scaleFactor
									}

									StyledText {
										text: modelData.title
										color: scope.state === index ? Colors.colors.on_primary : Colors.colors.on_surface_variant
										font.pixelSize: Appearance.fonts.large * 1.2 * root.scaleFactor
										elide: Text.ElideRight
									}
								}
							}
						}
					}
				}

				StackLayout {
					id: controlCenterStackLayout

					Layout.fillWidth: true
					Layout.fillHeight: true
					currentIndex: scope.state

					// Settings Tab
					Loader {
						active: scope.state === 0
						asynchronous: true

						sourceComponent: StyledRect {
							color: Colors.colors.surface_container_high
							bottomLeftRadius: Appearance.rounding.normal
							bottomRightRadius: Appearance.rounding.normal

							GridLayout {
								anchors.fill: parent
								columns: 2

								ColumnLayout {
									Layout.fillHeight: true
									Layout.preferredWidth: 200
									Layout.topMargin: 20
									Layout.alignment: Qt.AlignLeft | Qt.AlignTop

									StyledRect {
										Layout.alignment: Qt.AlignCenter
										Layout.preferredWidth: 200
										Layout.leftMargin: 20
										Layout.preferredHeight: 175
										color: Colors.colors.surface_container_low
										radius: Appearance.rounding.normal

										Image {
											anchors.top: parent.top
											anchors.horizontalCenter: parent.horizontalCenter
											anchors.topMargin: 15
											source: Paths.home + "/.face"
											sourceSize.width: 120
											sourceSize.height: 120
											asynchronous: true
											cache: true
										}

										StyledLabel {
											text: "Gilang Ramadhan"
											color: Colors.colors.on_surface
											font.pixelSize: Appearance.fonts.large * 1.2
											anchors.bottomMargin: 20
											anchors.bottom: parent.bottom
											anchors.horizontalCenter: parent.horizontalCenter
										}
									}
								}
							}
						}
					}

					// Volumes Tab
					Loader {
						active: scope.state === 1
						asynchronous: true

						sourceComponent: StyledRect {
							color: Colors.colors.surface_container_high
							bottomLeftRadius: Appearance.rounding.normal
							bottomRightRadius: Appearance.rounding.normal

							ScrollView {
								anchors.fill: parent
								contentWidth: availableWidth
								clip: true

								RowLayout {
									anchors.fill: parent
									Layout.margins: 15
									spacing: 20

									ColumnLayout {
										Layout.margins: 10
										Layout.alignment: Qt.AlignTop

										PwNodeLinkTracker {
											id: linkTracker

											node: Pipewire.defaultAudioSink
										}

										MixerEntry {
											node: Pipewire.defaultAudioSink
										}

										Rectangle {
											Layout.fillWidth: true
											color: palette.active.text
											implicitHeight: 1
										}

										Repeater {
											model: linkTracker.linkGroups

											MixerEntry {
												required property PwLinkGroup modelData
												node: modelData.source
											}
										}
									}
								}
							}
						}
					}

					// Performance Tab
					Loader {
						active: scope.state === 2
						asynchronous: true

						sourceComponent: StyledRect {
							color: Colors.colors.surface_container_high

							GridLayout {
								anchors.centerIn: parent
								columns: 3
								rowSpacing: Appearance.spacing.large * 2

								// Memory Usage
								ColumnLayout {
									Layout.alignment: Qt.AlignCenter
									spacing: Appearance.spacing.normal

									Circular {
										value: Math.round(SysUsage.memUsed / SysUsage.memTotal * 100)
										size: 0
										text: value + "%"
									}

									StyledText {
										Layout.alignment: Qt.AlignHCenter
										text: "RAM usage\n" + scope.memProp + " GB"
										color: Colors.colors.on_surface
										horizontalAlignment: Text.AlignHCenter
									}
								}

								// CPU Usage
								ColumnLayout {
									Layout.alignment: Qt.AlignVCenter
									spacing: Appearance.spacing.normal

									Circular {
										Layout.alignment: Qt.AlignHCenter
										value: SysUsage.cpuPerc
										size: 40
										text: value + "%"
									}

									StyledText {
										Layout.alignment: Qt.AlignHCenter
										text: "CPU usage"
										color: Colors.colors.on_surface
									}
								}

								// Disk Usage
								ColumnLayout {
									Layout.alignment: Qt.AlignCenter
									spacing: Appearance.spacing.normal

									Circular {
										value: Math.round(SysUsage.diskUsed / SysUsage.diskTotal * 100)
										text: value + "%"
										size: 0
									}

									StyledText {
										Layout.alignment: Qt.AlignHCenter
										text: "Disk usage\n" + scope.diskProp + " GB"
										color: Colors.colors.on_surface
										horizontalAlignment: Text.AlignHCenter
									}
								}

								// Network Speed
								ColumnLayout {
									Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
									Layout.preferredWidth: 160
									spacing: Appearance.spacing.small

									Repeater {
										model: [
											{
												label: "Wired Download",
												value: SysUsage.formatSpeed(SysUsage.wiredDownloadSpeed)
											},
											{
												label: "Wired Upload",
												value: SysUsage.formatSpeed(SysUsage.wiredUploadSpeed)
											},
											{
												label: "Wireless Download",
												value: SysUsage.formatSpeed(SysUsage.wirelessDownloadSpeed)
											},
											{
												label: "Wireless Upload",
												value: SysUsage.formatSpeed(SysUsage.wirelessUploadSpeed)
											}
										]

										StyledText {
											required property var modelData
											Layout.alignment: Qt.AlignHCenter
											Layout.fillWidth: true
											horizontalAlignment: Text.AlignHCenter
											text: modelData.label + ":\n" + modelData.value
											color: Colors.colors.on_surface
										}
									}
								}

								// Network Usage
								ColumnLayout {
									Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
									Layout.preferredWidth: 160
									spacing: Appearance.spacing.small

									Repeater {
										model: [
											{
												label: "Wired download usage",
												value: SysUsage.formatUsage(SysUsage.totalWiredDownloadUsage)
											},
											{
												label: "Wired upload usage",
												value: SysUsage.formatUsage(SysUsage.totalWiredUploadUsage)
											},
											{
												label: "Wireless download usage",
												value: SysUsage.formatUsage(SysUsage.totalWirelessDownloadUsage)
											},
											{
												label: "Wireless upload usage",
												value: SysUsage.formatUsage(SysUsage.totalWirelessUploadUsage)
											}
										]

										StyledText {
											required property var modelData
											Layout.alignment: Qt.AlignHCenter
											Layout.fillWidth: true
											horizontalAlignment: Text.AlignHCenter
											text: modelData.label + ":\n" + modelData.value
											color: Colors.colors.on_surface
										}
									}
								}

								// Network Interfaces
								ColumnLayout {
									Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
									Layout.preferredWidth: 160
									spacing: Appearance.spacing.small

									Repeater {
										model: [
											{
												label: "Wired interface",
												value: SysUsage.wiredInterface
											},
											{
												label: "Wireless interface",
												value: SysUsage.wirelessInterface
											}
										]

										StyledText {
											required property var modelData
											Layout.alignment: Qt.AlignHCenter
											Layout.fillWidth: true
											horizontalAlignment: Text.AlignHCenter
											text: modelData.label + ":\n" + modelData.value
											color: Colors.colors.on_surface
										}
									}
								}
							}
						}
					}

					// Weather Tab
					Loader {
						active: scope.state === 3
						asynchronous: true

						sourceComponent: StyledRect {
							color: Colors.colors.surface_container_high

							ColumnLayout {
								anchors.fill: parent
								anchors.margins: Appearance.margin.normal
								spacing: Appearance.spacing.normal

								StyledText {
									Layout.alignment: Qt.AlignHCenter
									text: Weather.cityData
									color: Colors.colors.on_surface
									font.pixelSize: Appearance.fonts.large * 1.2
									font.weight: Font.Bold
								}

								RowLayout {
									Layout.fillWidth: false
									Layout.alignment: Qt.AlignHCenter
									Layout.topMargin: 10
									Layout.bottomMargin: 10
									spacing: Appearance.spacing.normal

									MatIcon {
										Layout.alignment: Qt.AlignHCenter
										font.pixelSize: Appearance.fonts.extraLarge * 4
										color: Colors.colors.primary
										icon: "air"
									}

									StyledText {
										Layout.alignment: Qt.AlignVCenter
										text: Weather.tempData + "°C"
										color: Colors.colors.primary
										font.pixelSize: Appearance.fonts.extraLarge * 2.5
										font.weight: Font.Light
									}
								}

								StyledText {
									Layout.alignment: Qt.AlignHCenter
									text: Weather.weatherDescriptionData.charAt(0).toUpperCase() + Weather.weatherDescriptionData.slice(1)
									color: Colors.colors.on_surface_variant
									font.pixelSize: Appearance.fonts.normal * 1.5
									wrapMode: Text.WordWrap
									horizontalAlignment: Text.AlignHCenter
								}

								Item {
									Layout.fillWidth: true
								}

								StyledRect {
									Layout.fillWidth: true
									Layout.preferredHeight: 80
									color: "transparent"

									RowLayout {
										anchors.centerIn: parent
										spacing: Appearance.spacing.large * 5

										Repeater {
											model: [
												{
													value: Weather.tempMinData + "° / " + Weather.tempMaxData + "°",
													label: "Min / Max"
												},
												{
													value: Weather.humidityData + "%",
													label: "Kelembapan"
												},
												{
													value: Weather.windSpeedData + " m/s",
													label: "Angin"
												}
											]

											ColumnLayout {
												required property var modelData
												Layout.fillWidth: true
												spacing: 5

												StyledText {
													Layout.alignment: Qt.AlignHCenter
													text: modelData.value
													color: Colors.colors.on_surface
													font.weight: Font.Bold
													font.pixelSize: Appearance.fonts.small * 1.5
												}

												StyledText {
													Layout.alignment: Qt.AlignHCenter
													text: modelData.label
													color: Colors.colors.on_surface_variant
													font.pixelSize: Appearance.fonts.small * 1.2
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
		}
	}

	IpcHandler {
		target: "controlCenter"
		function toggle(): void {
			scope.toggleControlCenter();
		}
	}
}
