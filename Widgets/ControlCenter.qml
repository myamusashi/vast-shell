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

	readonly property bool batCharging: UPower.displayDevice.state == UPowerDeviceState.Charging
	readonly property string batIcon: {
		if (batPercentage > 0.95)
			return "battery_android_full";
		if (batPercentage > 0.85)
			return "battery_android_6";
		if (batPercentage > 0.65)
			return "battery_android_5";
		if (batPercentage > 0.55)
			return "battery_android_4";
		if (batPercentage > 0.45)
			return "battery_android_3";
		if (batPercentage > 0.35)
			return "battery_android_2";
		if (batPercentage > 0.15)
			return "battery_android_1";
		if (batPercentage > 0.05)
			return "battery_android_0";
		return "battery_android_0";
	}
	readonly property list<string> batIcons: ["battery_android_full"    // 96-100%
		, "battery_android_6",
		// 86-95%
		"battery_android_5",
		// 66-85%
		"battery_android_4",
		// 56-65%
		"battery_android_3",
		// 46-55%
		"battery_android_2",
		// 36-45%
		"battery_android_1",
		// 16-35%
		"battery_android_0",
		// 6-15%
		"battery_android_0",
		// 6-15%
		"battery_android_0",
		// 6-15%
		"battery_android_alert"
		// 0-5% (only when not charging)
	]
	readonly property real batPercentage: UPower.displayDevice.percentage
	readonly property string chargeIcon: batIcons[10 - chargeIconIndex]
	property int chargeIconIndex: 0

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
								id: settingButton

								required property var modelData
								required property int index

								buttonTitle: modelData.title
								Layout.fillWidth: true
								highlighted: scope.state === modelData.index
								flat: scope.state !== modelData.index
								onClicked: scope.state = modelData.index

								background: Rectangle {
									color: scope.state === settingButton.index ? Colors.colors.primary : Colors.colors.surface_container
									radius: Appearance.rounding.small
								}

								contentItem: RowLayout {
									anchors.centerIn: parent
									spacing: Appearance.spacing.small

									MatIcon {
										icon: settingButton.modelData.icon
										color: scope.state === settingButton.index ? Colors.colors.on_primary : Colors.colors.on_surface_variant
										font.pixelSize: Appearance.fonts.large * root.scaleFactor + 10
									}

									StyledText {
										text: settingButton.modelData.title
										color: scope.state === settingButton.index ? Colors.colors.on_primary : Colors.colors.on_surface_variant
										font.pixelSize: Appearance.fonts.large * root.scaleFactor
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

					Loader {
						active: scope.state === 0
						asynchronous: true

						sourceComponent: StyledRect {
							color: Colors.colors.surface_container_high

							GridLayout {
								anchors.fill: parent
								columns: 2

								ColumnLayout {
									Layout.fillHeight: true
									Layout.preferredWidth: 220
									Layout.margins: 15
									Layout.alignment: Qt.AlignLeft | Qt.AlignTop
									spacing: Appearance.spacing.small

									StyledRect {
										Layout.preferredWidth: 250
										Layout.preferredHeight: 140
										color: Colors.colors.surface_container_low
										radius: Appearance.rounding.normal

										ColumnLayout {
											anchors.fill: parent
											anchors.rightMargin: 10
											anchors.leftMargin: 10
											anchors.bottomMargin: 10
											spacing: Appearance.spacing.small

											Item {
												Layout.fillWidth: true
												Layout.preferredHeight: 60

												MatIcon {
													id: batteryIcon
													anchors.centerIn: parent
													icon: scope.batCharging ? scope.chargeIcon : scope.batIcon
													color: scope.batCharging ? Colors.colors.on_primary : Colors.colors.on_surface_variant
													font.pixelSize: Appearance.fonts.extraLarge * 3
												}

												RowLayout {
													anchors.centerIn: parent
													spacing: 4

													MatIcon {
														icon: "bolt"
														color: Colors.colors.primary
														visible: scope.batCharging
														font.pixelSize: Appearance.fonts.medium
													}

													StyledText {
														text: (UPower.displayDevice.percentage * 100).toFixed(0)
														color: Colors.colors.surface
														font.pixelSize: Appearance.fonts.large
														font.bold: true
													}
												}
											}

											GridLayout {
												Layout.fillWidth: true
												rows: 2

												ColumnLayout {
													Layout.fillWidth: true
													spacing: Appearance.spacing.small

													RowLayout {
														Layout.fillWidth: true
														spacing: Appearance.spacing.small

														StyledText {
															text: "Current capacity:"
															color: Colors.colors.on_background
															font.pixelSize: Appearance.fonts.small
														}

														Item {
															Layout.fillWidth: true
														}

														StyledText {
															text: UPower.displayDevice.energy.toFixed(2) + " Wh"
															color: Colors.colors.on_background
															font.pixelSize: Appearance.fonts.small
															font.bold: true
														}
													}

													RowLayout {
														Layout.fillWidth: true
														spacing: Appearance.spacing.small

														StyledText {
															text: "Full capacity:"
															color: Colors.colors.on_background
															font.pixelSize: Appearance.fonts.small
														}

														Item {
															Layout.fillWidth: true
														}

														StyledText {
															text: UPower.displayDevice.energyCapacity.toFixed(2) + " Wh"
															color: Colors.colors.on_background
															font.pixelSize: Appearance.fonts.small
															font.bold: true
														}
													}

													RowLayout {
														Layout.fillWidth: true
														spacing: Appearance.spacing.small

														StyledText {
															text: "Battery Health:"
															color: Colors.colors.on_background
															font.pixelSize: Appearance.fonts.small
														}

														Item {
															Layout.fillWidth: true
														}

														StyledText {
															text: ((UPower.displayDevice.energy / UPower.displayDevice.energyCapacity) * 100).toFixed(1) + "%"
															color: {
																var health = (UPower.displayDevice.energy / UPower.displayDevice.energyCapacity) * 100;
																return health > 80 ? Colors.colors.primary : health > 50 ? Colors.colors.secondary : Colors.colors.error;
															}
															font.pixelSize: Appearance.fonts.small
															font.bold: true
														}
													}
												}
											}
										}

										Timer {
											interval: 600
											repeat: true
											running: scope.batCharging
											triggeredOnStart: true
											onTriggered: {
												scope.chargeIconIndex = (scope.chargeIconIndex % 10) + 1;
											}
										}
									}
								}
							}
						}
					}

					Loader {
						active: scope.state === 1
						asynchronous: true

						sourceComponent: StyledRect {
							color: Colors.colors.surface_container_high

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

					Loader {
						active: scope.state === 2
						asynchronous: true

						sourceComponent: StyledRect {
							color: Colors.colors.surface_container_high

							GridLayout {
								anchors.centerIn: parent
								columns: 3
								rowSpacing: Appearance.spacing.large * 2

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
									font.pixelSize: Appearance.fonts.extraLarge
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
										icon: Weather.weatherIconData
									}

									StyledText {
										Layout.alignment: Qt.AlignVCenter
										text: Weather.tempData + "°C"
										color: Colors.colors.primary
										font.pixelSize: Appearance.fonts.extraLarge * 2.5
										font.weight: Font.Bold
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
												id: weatherPage

												required property var modelData
												Layout.fillWidth: true
												spacing: 5

												StyledText {
													Layout.alignment: Qt.AlignHCenter
													text: weatherPage.modelData.value
													color: Colors.colors.on_surface
													font.weight: Font.Bold
													font.pixelSize: Appearance.fonts.small * 1.5
												}

												StyledText {
													Layout.alignment: Qt.AlignHCenter
													text: weatherPage.modelData.label
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
