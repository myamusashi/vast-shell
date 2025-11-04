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

	function toggleDashboard(): void {
		isControlCenterOpen = !isControlCenterOpen;
	}

	GlobalShortcut {
		name: "ControlCenter"
		onPressed: scope.toggleDashboard()
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

						StyledButton {
							id: settingButton

							buttonTitle: "Settings"
							Layout.fillWidth: true
							highlighted: scope.state === 0
							flat: scope.state !== 0
							onClicked: scope.state = 0

							background: Rectangle {
								color: scope.state === 0 ? Colors.colors.primary : Colors.colors.surface_container
								radius: 5
							}

							contentItem: RowLayout {
								id: buttonSettingsContent

								anchors.centerIn: parent
								spacing: 5
								MatIcon {
									icon: "settings"
									color: scope.state === 0 ? Colors.colors.on_primary : Colors.colors.on_surface_variant
									font.pixelSize: Appearance.fonts.extraLarge * root.scaleFactor
								}

								StyledText {
									text: "Settings"
									color: scope.state === 0 ? Colors.colors.on_primary : Colors.colors.on_surface_variant
									font.pixelSize: Appearance.fonts.large * 1.2 * root.scaleFactor
									elide: Text.ElideRight
								}
							}
						}

						StyledButton {
							id: volumeControlButton

							buttonTitle: "Volumes"
							Layout.fillWidth: true
							highlighted: scope.state === 1
							flat: scope.state !== 1
							onClicked: scope.state = 1

							background: Rectangle {
								color: scope.state === 1 ? Colors.colors.primary : Colors.colors.surface_container
								radius: 5
							}

							contentItem: RowLayout {
								id: buttonVolumeControlContent

								anchors.centerIn: parent
								spacing: 5
								MatIcon {
									icon: "speaker"
									color: scope.state === 1 ? Colors.colors.on_primary : Colors.colors.on_surface_variant
									font.pixelSize: Appearance.fonts.extraLarge * root.scaleFactor
								}

								StyledText {
									text: "Volumes"
									color: scope.state === 1 ? Colors.colors.on_primary : Colors.colors.on_surface_variant
									font.pixelSize: Appearance.fonts.large * 1.2 * root.scaleFactor
								}
							}
						}

						StyledButton {
							id: performanceButton

							buttonTitle: "Performance"
							Layout.fillWidth: true
							highlighted: scope.state === 2
							flat: scope.state !== 2
							onClicked: scope.state = 2

							background: Rectangle {
								color: scope.state === 2 ? Colors.colors.primary : Colors.colors.surface_container
								radius: 5
							}

							contentItem: RowLayout {
								id: buttonPerformanceContent

								anchors.centerIn: parent
								spacing: 5
								MatIcon {
									icon: "speed"
									color: scope.state === 2 ? Colors.colors.on_primary : Colors.colors.on_surface_variant
									font.pixelSize: Appearance.fonts.extraLarge * root.scaleFactor
								}

								StyledText {
									text: "Performance"
									color: scope.state === 2 ? Colors.colors.on_primary : Colors.colors.on_surface_variant
									font.pixelSize: Appearance.fonts.large * 1.2 * root.scaleFactor
								}
							}
						}

						StyledButton {
							id: weatherButton

							buttonTitle: "Weather"
							Layout.fillWidth: true
							highlighted: scope.state === 3
							flat: scope.state !== 3
							onClicked: scope.state = 3

							background: Rectangle {
								color: scope.state === 3 ? Colors.colors.primary : Colors.colors.surface_container
								radius: 5
							}

							contentItem: RowLayout {
								id: buttonWeatherContent

								anchors.centerIn: parent
								spacing: 5
								MatIcon {
									icon: "cloud"
									color: scope.state === 3 ? Colors.colors.on_primary : Colors.colors.on_surface_variant
									font.pixelSize: Appearance.fonts.extraLarge * root.scaleFactor
								}

								StyledText {
									text: "Weather"
									color: scope.state === 3 ? Colors.colors.on_primary : Colors.colors.on_surface_variant
									font.pixelSize: Appearance.fonts.large * 1.2 * root.scaleFactor
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

					StyledRect {
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
									id: profile

									Layout.alignment: Qt.AlignCenter
									Layout.preferredWidth: 200
									Layout.leftMargin: 20
									Layout.preferredHeight: profileImage.height + width * 0.4
									color: Colors.colors.surface_container_low
									radius: Appearance.rounding.normal

									Image {
										id: profileImage

										anchors.top: parent.top
										anchors.horizontalCenter: parent.horizontalCenter
										anchors.topMargin: 15
										source: Paths.home + "/.face"
										sourceSize.width: 120
										sourceSize.height: 120
									}

									StyledLabel {
										id: profileUsername

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

					StyledRect {
						color: Colors.colors.surface_container_high
						bottomLeftRadius: Appearance.rounding.normal
						bottomRightRadius: Appearance.rounding.normal

						ScrollView {
							anchors.fill: parent
							contentWidth: availableWidth

							RowLayout {
								anchors.fill: parent
								Layout.margins: 15
								spacing: 20

								ColumnLayout {
									id: volumeControlLayout

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

					StyledRect {
						color: Colors.colors.surface_container_high

						GridLayout {
							anchors.centerIn: parent
							columns: 3
							rowSpacing: Appearance.spacing.large * 2

							Item {
								id: memItem

								Layout.alignment: Qt.AlignCenter
								Layout.preferredWidth: childrenRect.width
								Layout.preferredHeight: childrenRect.height

								ColumnLayout {
									anchors.centerIn: parent
									spacing: Appearance.spacing.normal

									Circular {
										id: mem

										value: Math.round(SysUsage.memUsed / SysUsage.memTotal * 100)
										size: 0
										text: value + "%"
									}

									StyledText {
										id: memText

										Layout.alignment: Qt.AlignHCenter
										text: "RAM usage" + "\n" + scope.memProp + " GB"
										color: Colors.colors.on_surface
									}
								}
							}

							Item {
								id: cpuItem

								Layout.alignment: Qt.AlignVCenter
								Layout.preferredWidth: childrenRect.width
								Layout.preferredHeight: childrenRect.height

								ColumnLayout {
									anchors.centerIn: parent
									spacing: Appearance.spacing.normal

									Circular {
										id: cpu

										Layout.alignment: Qt.AlignHCenter
										value: SysUsage.cpuPerc
										size: 40
										text: value + "%"
									}

									StyledText {
										id: cpuText

										Layout.alignment: Qt.AlignHCenter
										text: "CPU usage"
										color: Colors.colors.on_surface
									}
								}
							}

							Item {
								Layout.alignment: Qt.AlignCenter
								Layout.preferredWidth: childrenRect.width
								Layout.preferredHeight: childrenRect.height

								ColumnLayout {
									anchors.centerIn: parent
									spacing: Appearance.spacing.normal

									Circular {
										id: disk

										value: Math.round(SysUsage.diskUsed / SysUsage.diskTotal * 100)
										text: value + "%"
										size: 0
									}

									StyledText {
										id: diskText

										Layout.alignment: Qt.AlignHCenter
										text: "Disk usage" + "\n" + scope.diskProp + " GB"
										color: Colors.colors.on_surface
									}
								}
							}

							Item {
								Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
								Layout.preferredWidth: 160
								Layout.preferredHeight: childrenRect.height

								ColumnLayout {
									anchors.top: parent.top
									anchors.horizontalCenter: parent.horizontalCenter
									spacing: Appearance.spacing.small
									width: parent.width

									StyledText {
										Layout.alignment: Qt.AlignHCenter
										Layout.fillWidth: true
										horizontalAlignment: Text.AlignHCenter
										text: "Wired Download:\n" + SysUsage.formatSpeed(SysUsage.wiredDownloadSpeed)
										color: Colors.colors.on_surface
									}

									StyledText {
										Layout.alignment: Qt.AlignHCenter
										Layout.fillWidth: true
										horizontalAlignment: Text.AlignHCenter
										text: "Wired Upload:\n" + SysUsage.formatSpeed(SysUsage.wiredUploadSpeed)
										color: Colors.colors.on_surface
									}

									StyledText {
										Layout.alignment: Qt.AlignHCenter
										Layout.fillWidth: true
										horizontalAlignment: Text.AlignHCenter
										text: "Wireless Download:\n" + SysUsage.formatSpeed(SysUsage.wirelessDownloadSpeed)
										color: Colors.colors.on_surface
									}

									StyledText {
										Layout.alignment: Qt.AlignHCenter
										Layout.fillWidth: true
										horizontalAlignment: Text.AlignHCenter
										text: "Wireless Upload:\n" + SysUsage.formatSpeed(SysUsage.wirelessUploadSpeed)
										color: Colors.colors.on_surface
									}
								}
							}

							Item {
								Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
								Layout.preferredWidth: 160
								Layout.preferredHeight: childrenRect.height

								ColumnLayout {
									anchors.top: parent.top
									anchors.horizontalCenter: parent.horizontalCenter
									spacing: Appearance.spacing.small
									width: parent.width

									StyledText {
										Layout.alignment: Qt.AlignHCenter
										Layout.fillWidth: true
										horizontalAlignment: Text.AlignHCenter
										text: "Wired download usage:\n" + SysUsage.formatUsage(SysUsage.totalWiredDownloadUsage)
										color: Colors.colors.on_surface
									}

									StyledText {
										Layout.alignment: Qt.AlignHCenter
										Layout.fillWidth: true
										horizontalAlignment: Text.AlignHCenter
										text: "Wired upload usage:\n" + SysUsage.formatUsage(SysUsage.totalWiredUploadUsage)
										color: Colors.colors.on_surface
									}

									StyledText {
										Layout.alignment: Qt.AlignHCenter
										Layout.fillWidth: true
										horizontalAlignment: Text.AlignHCenter
										text: "Wireless download usage:\n" + SysUsage.formatUsage(SysUsage.totalWirelessDownloadUsage)
										color: Colors.colors.on_surface
									}

									StyledText {
										Layout.alignment: Qt.AlignHCenter
										Layout.fillWidth: true
										horizontalAlignment: Text.AlignHCenter
										text: "Wireless upload usage:\n" + SysUsage.formatUsage(SysUsage.totalWirelessUploadUsage)
										color: Colors.colors.on_surface
									}
								}
							}

							Item {
								Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
								Layout.preferredWidth: 160
								Layout.preferredHeight: childrenRect.height

								ColumnLayout {
									anchors.top: parent.top
									anchors.horizontalCenter: parent.horizontalCenter
									spacing: Appearance.spacing.small
									width: parent.width

									StyledText {
										Layout.alignment: Qt.AlignHCenter
										Layout.fillWidth: true
										horizontalAlignment: Text.AlignHCenter
										text: "Wired interface:\n" + SysUsage.wiredInterface
										color: Colors.colors.on_surface
									}

									StyledText {
										Layout.alignment: Qt.AlignHCenter
										Layout.fillWidth: true
										horizontalAlignment: Text.AlignHCenter
										text: "Wireless interface:\n" + SysUsage.wirelessInterface
										color: Colors.colors.on_surface
									}
								}
							}
						}
					}

					// About Page
					StyledRect {
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
									id: weatherIcon

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

									ColumnLayout {
										Layout.fillWidth: true
										spacing: Appearance.spacing.small

										StyledText {
											Layout.alignment: Qt.AlignHCenter
											text: Weather.tempMinData + "° / " + Weather.tempMaxData + "°"
											color: Colors.colors.on_surface
											font.weight: Font.Bold
											font.pixelSize: Appearance.fonts.small * 1.5
										}
										StyledText {
											Layout.alignment: Qt.AlignHCenter
											text: "Min / Max"
											color: Colors.colors.on_surface_variant
											font.pixelSize: Appearance.fonts.small * 1.2
										}
									}

									ColumnLayout {
										Layout.fillWidth: true
										spacing: 5

										StyledText {
											Layout.alignment: Qt.AlignHCenter
											text: Weather.humidityData + "%"
											color: Colors.colors.on_surface
											font.weight: Font.Bold
											font.pixelSize: Appearance.fonts.small * 1.5
										}
										StyledText {
											Layout.alignment: Qt.AlignHCenter
											text: "Kelembapan"
											color: Colors.colors.on_surface_variant
											font.pixelSize: Appearance.fonts.small * 1.2
										}
									}

									ColumnLayout {
										Layout.fillWidth: true
										spacing: 5

										StyledText {
											Layout.alignment: Qt.AlignHCenter
											text: Weather.windSpeedData + " m/s"
											color: Colors.colors.on_surface
											font.weight: Font.Bold
											font.pixelSize: Appearance.fonts.small * 1.5
										}
										StyledText {
											Layout.alignment: Qt.AlignHCenter
											text: "Angin"
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

	IpcHandler {
		target: "dashboard"
		function toggle(): void {
			scope.toggleDashboard();
		}
	}
}
