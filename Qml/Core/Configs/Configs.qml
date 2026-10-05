pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Vast.Translation

import qs.Core.Utils
import qs.Services

Singleton {
    id: root

    property alias appearance: adapter.appearance
    property alias audio: adapter.audio
    property alias bar: adapter.bar
    property alias captureScreenVideo: adapter.captureScreenVideo
    property alias clipboard: adapter.clipboard
    property alias colors: adapter.colors
    property alias generals: adapter.generals
    property alias idle: adapter.idle
    property alias kdeConnect: adapter.kdeConnect
    property alias language: adapter.language
    property alias mediaPlayer: adapter.mediaPlayer
    property alias notification: adapter.notification
    property alias privacy: adapter.privacy
    property alias search: adapter.search
    property alias wallpaper: adapter.wallpaper
    property alias weather: adapter.weather

    Connections {
        function onLanguageChanged() {
            TranslationManager.loadTranslation(root.language.language, Paths.translateFilePath);
        }

        target: root.language
    }
    FileView {
        path: Paths.shellDir + "/configurations.json"
        watchChanges: true

        onAdapterUpdated: writeAdapter()
        onFileChanged: reload()
        onLoadFailed: err => {
            if (err !== FileViewError.FileNotFound) {
                console.log("Failed to read config files");
                ToastService.show(qsTr("Failed to read config files"), qsTr("Configuration"), "configure", 3000);
            }
        }
        onLoaded: TranslationManager.loadTranslation(root.language.language, Paths.translateFilePath)
        onSaveFailed: err => {
            console.log("Failed to save config", FileViewError.toString(err));
            ToastService.show(qsTr("Failed to save config: %1").arg(FileViewError.toString(err)), qsTr("Configuration"), "configure", 3000);
        }

        JsonAdapter { // qmllint disable
            id: adapter

            property AppearanceConfig appearance: AppearanceConfig {
            }
            property AudioConfig audio: AudioConfig {
            }
            property BarConfig bar: BarConfig {
            }
            property CaptureScreenVideoConfig captureScreenVideo: CaptureScreenVideoConfig {
            }
            property ClipboardConfig clipboard: ClipboardConfig {
            }
            property ColorSystemConfig colors: ColorSystemConfig {
            }
            property GeneralConfig generals: GeneralConfig {
            }
            property IdleConfig idle: IdleConfig {
            }
            property KDEConnectConfig kdeConnect: KDEConnectConfig {
            }
            property LocalizationConfig language: LocalizationConfig {
            }
            property MediaPlayerConfig mediaPlayer: MediaPlayerConfig {
            }
            property NotificationConfig notification: NotificationConfig {
            }
            property PrivacyIndicatorConfig privacy: PrivacyIndicatorConfig {
            }
            property SearchConfig search: SearchConfig {
            }
            property WallpaperConfig wallpaper: WallpaperConfig {
            }
            property WeatherConfig weather: WeatherConfig {
            }
        }
    }
}
