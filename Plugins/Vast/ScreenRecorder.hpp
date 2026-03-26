#pragma once

#include <QObject>
#include <QString>
#include <QProcess>
#include <QQmlEngine>

class ScreenRecorder : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool isRecording READ isRecording NOTIFY isRecordingChanged)
    Q_PROPERTY(QString currentOutputFile READ currentOutputFile NOTIFY currentOutputFileChanged)

    Q_PROPERTY(QString audioDevice READ audioDevice WRITE setAudioDevice NOTIFY audioDeviceChanged)
    Q_PROPERTY(QString videoCodec READ videoCodec WRITE setVideoCodec NOTIFY videoCodecChanged)
    Q_PROPERTY(QString audioCodec READ audioCodec WRITE setAudioCodec NOTIFY audioCodecChanged)
    Q_PROPERTY(QString driDevice READ driDevice WRITE setDriDevice NOTIFY driDeviceChanged)
    Q_PROPERTY(QString encodeResolution READ encodeResolution WRITE setEncodeResolution NOTIFY encodeResolutionChanged)
    Q_PROPERTY(QString lowPower READ lowPower WRITE setLowPower NOTIFY lowPowerChanged)
    Q_PROPERTY(QString bitrate READ bitrate WRITE setBitrate NOTIFY bitrateChanged)
    Q_PROPERTY(int maxFps READ maxFps WRITE setMaxFps NOTIFY maxFpsChanged)
    Q_PROPERTY(bool historyMode READ historyMode WRITE setHistoryMode NOTIFY historyModeChanged)
    Q_PROPERTY(bool includeAudio READ includeAudio WRITE setIncludeAudio NOTIFY includeAudioChanged)
    Q_PROPERTY(bool showCursor READ showCursor WRITE setShowCursor NOTIFY showCursorChanged)

  public:
    explicit ScreenRecorder(QObject* parent = nullptr);
    ~ScreenRecorder() override;

    [[nodiscard]] bool    isRecording() const;
    [[nodiscard]] QString currentOutputFile() const;

    [[nodiscard]] QString audioDevice() const;
    void                  setAudioDevice(const QString& device);

    [[nodiscard]] QString videoCodec() const;
    void                  setVideoCodec(const QString& codec);

    [[nodiscard]] QString audioCodec() const;
    void                  setAudioCodec(const QString& codec);

    [[nodiscard]] QString driDevice() const;
    void                  setDriDevice(const QString& device);

    [[nodiscard]] QString encodeResolution() const;
    void                  setEncodeResolution(const QString& resolution);

    [[nodiscard]] QString lowPower() const;
    void                  setLowPower(const QString& power);

    [[nodiscard]] QString bitrate() const;
    void                  setBitrate(const QString& bitrate);

    [[nodiscard]] int     maxFps() const;
    void                  setMaxFps(int fps);

    [[nodiscard]] bool    historyMode() const;
    void                  setHistoryMode(bool history);

    [[nodiscard]] bool    includeAudio() const;
    void                  setIncludeAudio(bool audio);

    [[nodiscard]] bool    showCursor() const;
    void                  setShowCursor(bool cursor);

    Q_INVOKABLE void      createThumbnail(const QString& videoPath, const QString& outputDir);

    Q_INVOKABLE void      startRecording(const QString& geometry = QString(), const QString& output = QString());
    Q_INVOKABLE void      recordSelection(const QString& geometry);
    Q_INVOKABLE void      stopRecording();
    Q_INVOKABLE void      saveHistory();

    Q_INVOKABLE void      screenshotWindow();
    Q_INVOKABLE void      screenshotSelection();
    Q_INVOKABLE void      screenshotOutput(const QString& out = QString());

  signals:
    void isRecordingChanged();
    void currentOutputFileChanged();
    void audioDeviceChanged();
    void videoCodecChanged();
    void audioCodecChanged();
    void driDeviceChanged();
    void encodeResolutionChanged();
    void lowPowerChanged();
    void bitrateChanged();
    void maxFpsChanged();
    void historyModeChanged();
    void includeAudioChanged();
    void showCursorChanged();
    void thumbnailReady(const QString& videoPath, const QString& thumbnailPath);

  private:
    void handleRecordingFinished(int exitCode, QProcess::ExitStatus exitStatus);

  private:
    void          checkActiveRecording();
    QString       generateTimestamp() const;
    QString       screenshotPath() const;
    QString       videoPath() const;
    void          ensureDirectories() const;
    QStringList   getMonitors() const;
    void          notify(const QString& summary, const QString& body, const QString& urgency = "normal", const QString& icon = "", const QString& app = "screengrab",
                         const QStringList& actions = QStringList(), bool wait = false) const;
    void          gotoLink(const QString& file, const QString& thumb, bool showNotification) const;
    void          copyToClipboard(const QString& img) const;
    void          finishRecording(const QString& vid);

    bool          m_isRecording{false};
    QString       m_currentOutputFile;
    int           m_recordingPid{-1};
    QProcess*     m_recordingProcess{nullptr};

    QString       m_audioDevice;
    QString       m_videoCodec;
    QString       m_audioCodec;
    QString       m_driDevice;
    QString       m_encodeResolution;
    QString       m_lowPower{"auto"};
    QString       m_bitrate{"5 MB"};
    int           m_maxFps{60};
    bool          m_historyMode{false};
    bool          m_includeAudio{false};
    bool          m_showCursor{true};

    QString       m_screenshotDir;
    QString       m_videoDir;
    QString       m_thumbnailDir;

    const QString m_pidFile{"/tmp/wl-screenrec.pid"};
    const QString m_videoFile{"/tmp/wl-screenrec.video"};
};
