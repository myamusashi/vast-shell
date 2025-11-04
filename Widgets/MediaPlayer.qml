pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Services.Mpris

import qs.Data
import qs.Helpers
import qs.Components

Scope {
	id: root

	property bool isMediaPlayerOpen: false

	function formatTime(seconds) {
		const hours = Math.floor(seconds / 3600);
		const minutes = Math.floor((seconds % 3600) / 60);
		const secs = Math.floor(seconds % 60);

		if (hours > 0)
			return `${hours}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;

		return `${minutes}:${secs.toString().padStart(2, '0')}`;
	}

	property string url: ""

	function getTrackUrl(): void {
		trackUrl.running = true;
	}

	Process {
		id: trackUrl

		command: ["sh", "-c", "playerctl metadata | grep xesam:url | awk '{print $3}'"]
		running: true
		stdout: StdioCollector {
			onStreamFinished: {
				const res = text.trim();
				root.url = res;
			}
		}
	}

	LazyLoader {
		active: root.isMediaPlayerOpen

		component: PanelWindow {
			anchors {
				top: true
			}
			property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
			property real monitorWidth: monitor.width / monitor.scale
			property real monitorHeight: monitor.height / monitor.scale
			implicitWidth: monitorWidth * 0.25
			implicitHeight: container.implicitHeight
			exclusiveZone: 1

			margins.right: (monitorWidth - implicitWidth) / 2
			margins.left: (monitorWidth - implicitWidth) / 2
			color: "transparent"

			StyledRect {
				id: container

				width: parent.width
				height: contentLayout.implicitHeight + 50  // Add padding
				implicitHeight: height
				color: Colors.colors.surface_container_high
				radius: Appearance.rounding.normal

				RowLayout {
					id: contentLayout
					anchors.fill: parent
					anchors.margins: 10
					spacing: Appearance.spacing.normal

					Rectangle {
						Layout.preferredWidth: 120
						Layout.preferredHeight: 120
						color: "transparent"

						Loader {
							active: true
							anchors.centerIn: parent
							width: 120
							height: 120

							sourceComponent: Item {
								anchors.fill: parent
								Image {
									id: coverArt

									anchors.fill: parent
									source: Player.active ? Player.active.trackArtUrl : ""
									fillMode: Image.PreserveAspectCrop
									visible: Player.active !== null
									cache: false
									asynchronous: true

									layer.enabled: true
									layer.effect: MultiEffect {
										maskEnabled: true
										maskSource: mask
									}
								}

								AnimatedImage {
									id: coverNullArt

									anchors.fill: parent
									visible: Player.active === null
									asynchronous: true
									cache: false
									source: "root:/Assets/kuru.gif"
								}

								Item {
									id: mask

									anchors.fill: parent
									layer.enabled: true
									visible: false

									Rectangle {
										anchors.fill: parent
										color: "white"
										radius: Appearance.rounding.small
									}
								}
							}
						}
					}

					ColumnLayout {
						Layout.fillWidth: true
						Layout.preferredHeight: 0

						Column {
							Layout.fillWidth: true
							Layout.alignment: Qt.AlignLeft
							spacing: 2

							StyledLabel {
								width: parent.width
								text: Player.active ? Player.active.trackTitle : ""
								color: Colors.colors.on_background
								font.pixelSize: Appearance.fonts.large
								wrapMode: Text.NoWrap
								elide: Text.ElideRight
							}

							RowLayout {
								Layout.preferredWidth: 50

								IconImage {
									source: Quickshell.iconPath(Player.active.desktopEntry)
									asynchronous: true
									width: 20
									height: 20

									MouseArea {
										anchors.fill: parent
										hoverEnabled: true
										cursorShape: Qt.PointingHandCursor
										onClicked: Qt.openUrlExternally(root.url)
									}
								}
								StyledText {
									width: parent.width
									text: Player.active ? Player.active.trackArtist : ""
									color: Colors.colors.on_background
									font.pixelSize: Appearance.fonts.small
									wrapMode: Text.NoWrap
									elide: Text.ElideRight
								}
							}
						}

						Item {
							Layout.fillHeight: true
							Layout.minimumHeight: 5
						}

						RowLayout {
							Layout.fillWidth: true
							Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
							spacing: 10

							StyledText {
								id: timeTrack

								text: Player.active == null ? "00:00" : `${root.formatTime(Player.active?.position)} / ${root.formatTime(Player.active?.length)}`
								font.pixelSize: Appearance.fonts.large
								color: Colors.colors.on_background

								Timer {
									running: Player.active !== null && Player.active.playbackState == MprisPlaybackState.Playing
									interval: 100
									repeat: true
									onTriggered: Player.active.positionChanged()
								}
							}

							Item {
								Layout.fillWidth: true
							}

							MatIcon {
								id: pauseButton

								icon: Player.active === null ? "pause_circle" : Player.active.playbackState === MprisPlaybackState.Playing ? "pause_circle" : "play_circle"
								color: {
									if (pauseMouseArea.pressed)
										return Colors.withAlpha(Colors.colors.primary, 0.08);
									else if (pauseMouseArea.containsMouse)
										return Colors.withAlpha(Colors.colors.primary, 0.12);
									else
										return Colors.colors.primary;
								}
								font.pixelSize: Appearance.fonts.extraLarge * 1.5

								MouseArea {
									id: pauseMouseArea

									anchors.fill: parent
									hoverEnabled: true
									cursorShape: Qt.PointingHandCursor
									onClicked: Player.active ? Player.active.togglePlaying() : ""
								}
							}
						}

						RowLayout {
							Layout.fillWidth: true
							Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
							spacing: 10

							MatIcon {
								id: prevButton

								icon: "skip_previous"
								color: {
									if (prevMouseArea.pressed)
										return Colors.withAlpha(Colors.colors.primary, 0.08);
									else if (prevMouseArea.containsMouse)
										return Colors.withAlpha(Colors.colors.primary, 0.12);
									else
										return Colors.colors.primary;
								}
								font.pixelSize: Appearance.fonts.large * 1.8

								MouseArea {
									id: prevMouseArea

									anchors.fill: parent
									hoverEnabled: true
									cursorShape: Qt.PointingHandCursor
									onClicked: Player.active ? Player.active.previous() : {}
								}
							}

							StyledSlide {
								id: barSlide

								value: Player.active === null ? 0 : Player.active.length > 0 ? Player.active.position / Player.active.length : 0

								Layout.fillWidth: true
								valueWidth: 0
								valueHeight: 0

								FrameAnimation {
									running: Player.active && Player.active.playbackState == MprisPlaybackState.Playing
									onTriggered: {
										Player.active.positionChanged();
									}
								}

								onMoved: Player.active ? Player.active.position = value * Player.active.length : {}
							}

							MatIcon {
								id: nextButton

								icon: "skip_next"
								color: {
									if (nextMouseArea.pressed)
										return Colors.withAlpha(Colors.colors.primary, 0.08);
									else if (nextMouseArea.containsMouse)
										return Colors.withAlpha(Colors.colors.primary, 0.12);
									else
										return Colors.colors.primary;
								}
								font.pixelSize: Appearance.fonts.large * 1.8

								MouseArea {
									id: nextMouseArea

									anchors.fill: parent
									hoverEnabled: true
									cursorShape: Qt.PointingHandCursor
									onClicked: Player.active ? Player.active.next() : {}
								}
							}
						}
					}
				}
			}
		}
	}
}
