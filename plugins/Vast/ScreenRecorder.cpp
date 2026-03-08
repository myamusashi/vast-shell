#include "ScreenRecorder.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QDateTime>
#include <QStandardPaths>
#include <QDebug>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QTimer>

#include <csignal>
#include <sys/types.h>
#include <sys/wait.h>

ScreenRecorder::ScreenRecorder(QObject* parent) : QObject(parent), m_isRecording(false), m_recordingPid(-1), m_recordingProcess(nullptr) {
    QString home    = QDir::homePath();
    m_screenshotDir = home + "/Pictures/screenshot";
    m_videoDir      = home + "/Videos/Shell";
    m_thumbnailDir  = home + "/.cache/thumbnails/normal";

    ensureDirectories();
    checkActiveRecording();
}

ScreenRecorder::~ScreenRecorder() {}

void ScreenRecorder::ensureDirectories() const {
    QDir().mkpath(m_screenshotDir);
    QDir().mkpath(m_videoDir);
    QDir().mkpath(m_thumbnailDir);
}

bool ScreenRecorder::isRecording() const {
    return m_isRecording;
}
QString ScreenRecorder::currentOutputFile() const {
    return m_currentOutputFile;
}

QString ScreenRecorder::audioDevice() const {
    return m_audioDevice;
}
void ScreenRecorder::setAudioDevice(const QString& device) {
    if (m_audioDevice != device) {
        m_audioDevice = device;
        emit audioDeviceChanged();
    }
}

QString ScreenRecorder::videoCodec() const {
    return m_videoCodec;
}
void ScreenRecorder::setVideoCodec(const QString& codec) {
    if (m_videoCodec != codec) {
        m_videoCodec = codec;
        emit videoCodecChanged();
    }
}

QString ScreenRecorder::audioCodec() const {
    return m_audioCodec;
}
void ScreenRecorder::setAudioCodec(const QString& codec) {
    if (m_audioCodec != codec) {
        m_audioCodec = codec;
        emit audioCodecChanged();
    }
}

QString ScreenRecorder::driDevice() const {
    return m_driDevice;
}
void ScreenRecorder::setDriDevice(const QString& device) {
    if (m_driDevice != device) {
        m_driDevice = device;
        emit driDeviceChanged();
    }
}

QString ScreenRecorder::encodeResolution() const {
    return m_encodeResolution;
}
void ScreenRecorder::setEncodeResolution(const QString& resolution) {
    if (m_encodeResolution != resolution) {
        m_encodeResolution = resolution;
        emit encodeResolutionChanged();
    }
}

QString ScreenRecorder::lowPower() const {
    return m_lowPower;
}
void ScreenRecorder::setLowPower(const QString& power) {
    if (m_lowPower != power) {
        m_lowPower = power;
        emit lowPowerChanged();
    }
}

QString ScreenRecorder::bitrate() const {
    return m_bitrate;
}
void ScreenRecorder::setBitrate(const QString& bitrate) {
    if (m_bitrate != bitrate) {
        m_bitrate = bitrate;
        emit bitrateChanged();
    }
}

int ScreenRecorder::maxFps() const {
    return m_maxFps;
}
void ScreenRecorder::setMaxFps(int fps) {
    if (m_maxFps != fps) {
        m_maxFps = fps;
        emit maxFpsChanged();
    }
}

bool ScreenRecorder::historyMode() const {
    return m_historyMode;
}
void ScreenRecorder::setHistoryMode(bool history) {
    if (m_historyMode != history) {
        m_historyMode = history;
        emit historyModeChanged();
    }
}

bool ScreenRecorder::includeAudio() const {
    return m_includeAudio;
}
void ScreenRecorder::setIncludeAudio(bool audio) {
    if (m_includeAudio != audio) {
        m_includeAudio = audio;
        emit includeAudioChanged();
    }
}

bool ScreenRecorder::showCursor() const {
    return m_showCursor;
}
void ScreenRecorder::setShowCursor(bool cursor) {
    if (m_showCursor != cursor) {
        m_showCursor = cursor;
        emit showCursorChanged();
    }
}

QString ScreenRecorder::generateTimestamp() const {
    return QDateTime::currentDateTime().toString("yyyy-MM-dd_HH-mm-ss");
}

QString ScreenRecorder::screenshotPath() const {
    return m_screenshotDir + "/" + generateTimestamp() + ".png";
}

QString ScreenRecorder::videoPath() const {
    return m_videoDir + "/" + generateTimestamp() + ".mp4";
}

void ScreenRecorder::notify(const QString& summary, const QString& body, const QString& urgency, const QString& icon, const QString& app, const QStringList& actions,
                            bool wait) const {
    QStringList args;
    args << "-a" << app;
    if (!urgency.isEmpty() && urgency != "normal")
        args << "-u" << urgency;
    if (!icon.isEmpty())
        args << "-i" << icon;
    for (const QString& action : actions) {
        args << "--action" << action;
    }
    if (wait)
        args << "--wait";
    args << summary << body;

    QProcess* process = new QProcess(const_cast<ScreenRecorder*>(this));
    connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), process, &QProcess::deleteLater);
    process->start("notify-send", args);
}

QStringList ScreenRecorder::getMonitors() const {
    QProcess process;
    process.start("hyprctl", QStringList() << "monitors" << "-j");
    process.waitForFinished();

    QJsonDocument doc = QJsonDocument::fromJson(process.readAllStandardOutput());
    QJsonArray    arr = doc.array();
    QStringList   monitors;
    for (int i = 0; i < arr.size(); ++i) {
        monitors << arr[i].toObject()["name"].toString();
    }
    return monitors;
}

void ScreenRecorder::checkActiveRecording() {
    if (QFile::exists(m_pidFile) && QFile::exists(m_videoFile)) {
        QFile pidFile(m_pidFile);
        if (pidFile.open(QIODevice::ReadOnly)) {
            QString pidStr = pidFile.readAll().trimmed();
            int     pid    = pidStr.toInt();

            if (pid > 0 && kill(pid, 0) == 0) {
                m_recordingPid = pid;
                m_isRecording  = true;

                QFile videoFile(m_videoFile);
                if (videoFile.open(QIODevice::ReadOnly)) {
                    m_currentOutputFile = videoFile.readAll().trimmed();
                }

                emit isRecordingChanged();
                emit currentOutputFileChanged();
                qDebug() << "Adopted active recording, PID:" << pid << "File:" << m_currentOutputFile;
            } else {
                QFile::remove(m_pidFile);
                QFile::remove(m_videoFile);
            }
        }
    }
}

void ScreenRecorder::startRecording(const QString& geometry, const QString& output) {
    if (m_isRecording) {
        notify("Recording Active", "A recording is already in progress.", "critical", "dialog-warning", "Screen Record");
        return;
    }

    m_currentOutputFile = videoPath();

    QStringList baseArgs;
    baseArgs << "--capture-backend" << "ext-image-copy-capture";

    if (!m_videoCodec.isEmpty() && m_videoCodec != "auto")
        baseArgs << "--codec" << m_videoCodec;
    if (!m_audioCodec.isEmpty() && m_audioCodec != "auto")
        baseArgs << "--audio-codec" << m_audioCodec;
    if (!m_encodeResolution.isEmpty())
        baseArgs << "--encode-resolution" << m_encodeResolution;
    if (!m_driDevice.isEmpty())
        baseArgs << "--dri-device" << m_driDevice;
    if (!m_lowPower.isEmpty() && m_lowPower != "auto")
        baseArgs << "--low-power" << m_lowPower;

    baseArgs << "--max-fps" << QString::number(m_maxFps);
    baseArgs << "--bitrate" << m_bitrate;

    if (!m_showCursor)
        baseArgs << "--no-cursor";
    if (m_historyMode)
        baseArgs << "--history" << "30"; // Example: 30 seconds

    if (m_includeAudio) {
        baseArgs << "--audio";
        if (!m_audioDevice.isEmpty()) {
            baseArgs << "--audio-device" << m_audioDevice;
        }
    }

    if (!geometry.isEmpty()) {
        baseArgs << "-g" << geometry;
    } else if (!output.isEmpty()) {
        baseArgs << "-o" << output;
    }

    baseArgs << "-f" << m_currentOutputFile;

    m_recordingProcess = new QProcess(this);
    connect(m_recordingProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, &ScreenRecorder::handleRecordingFinished);

    m_recordingProcess->start("wl-screenrec", baseArgs);
    if (!m_recordingProcess->waitForStarted()) {
        qWarning() << "Error starting wl-screenrec:" << m_recordingProcess->errorString();
        delete m_recordingProcess;
        m_recordingProcess = nullptr;
        return;
    }

    m_recordingPid = m_recordingProcess->processId();
    m_isRecording  = true;

    QFile pidFile(m_pidFile);
    if (pidFile.open(QIODevice::WriteOnly))
        pidFile.write(QString::number(m_recordingPid).toUtf8());
    QFile vidFile(m_videoFile);
    if (vidFile.open(QIODevice::WriteOnly))
        vidFile.write(m_currentOutputFile.toUtf8());

    emit isRecordingChanged();
    emit currentOutputFileChanged();

    notify("Recording Started", "Press the same keybind again to stop recording.", "normal", "", "screenrecord");
}

void ScreenRecorder::recordSelection(const QString& geometry) {
    if (m_isRecording) {
        stopRecording();
        return;
    }

    startRecording(geometry, "");
}

void ScreenRecorder::stopRecording() {
    if (!m_isRecording || m_recordingPid <= 0) {
        notify("Recording Failed", "No active recording found.", "critical", "dialog-error", "Screen Record");
        return;
    }

    kill(m_recordingPid, SIGINT);

    QTimer::singleShot(10000, this, [this]() {
        if (m_isRecording)
            kill(m_recordingPid, SIGKILL);
    });
}

void ScreenRecorder::saveHistory() {
    if (m_isRecording && m_historyMode && m_recordingPid > 0) {
        kill(m_recordingPid, SIGUSR1);
        notify("Replay Saved", "History buffer written to disk.", "normal", "", "screenrecord");
    }
}

void ScreenRecorder::handleRecordingFinished(int exitCode, QProcess::ExitStatus exitStatus) {
    Q_UNUSED(exitCode);
    Q_UNUSED(exitStatus);

    m_isRecording  = false;
    m_recordingPid = -1;
    if (m_recordingProcess) {
        m_recordingProcess->deleteLater();
        m_recordingProcess = nullptr;
    }

    QFile::remove(m_pidFile);
    QFile::remove(m_videoFile);

    QString vid = m_currentOutputFile;
    m_currentOutputFile.clear();
    emit isRecordingChanged();
    emit currentOutputFileChanged();

    finishRecording(vid);
}

void ScreenRecorder::finishRecording(const QString& vid) {
    QFileInfo fi(vid);
    QString   thumb = m_thumbnailDir + "/" + fi.baseName() + ".png";

    QProcess* ffprobe = new QProcess(this);
    connect(ffprobe, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, [this, ffprobe, vid, thumb](int exitCode, QProcess::ExitStatus) {
        bool   ok;
        double duration = QString(ffprobe->readAllStandardOutput()).trimmed().toDouble(&ok);
        ffprobe->deleteLater();

        if (exitCode != 0 || !ok || duration < 1.0) {
            notify("Recording Stopped", "Video saved to " + vid, "normal", "video-x-generic", "screenrecord");
            gotoLink(vid, "", false);
            return;
        }

        double    ts        = duration / 2.0;
        int       h         = static_cast<int>(ts / 3600);
        int       m         = static_cast<int>(fmod(ts, 3600) / 60);
        int       s         = static_cast<int>(fmod(ts, 60));
        QString   formatted = QString::asprintf("%02d:%02d:%02d", h, m, s);

        QProcess* ffmpeg = new QProcess(this);
        connect(ffmpeg, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, [this, ffmpeg, vid, thumb](int ffmpegExitCode, QProcess::ExitStatus) {
            ffmpeg->deleteLater();
            if (ffmpegExitCode == 0 && QFile::exists(thumb)) {
                notify("Recording Stopped", "Video saved to " + vid, "normal", thumb, "screenrecord");
                gotoLink(vid, thumb, false);
            } else {
                notify("Recording Stopped", "Video saved to " + vid, "normal", "video-x-generic", "screenrecord");
                gotoLink(vid, "", false);
            }
        });
        ffmpeg->start("ffmpeg",
                      QStringList() << "-ss" << formatted << "-i" << vid << "-vframes" << "1" << "-q:v" << "2" << "-vf" << "scale=256:-1" << thumb << "-y" << "-v" << "error");
    });

    ffprobe->start("ffprobe", QStringList() << "-v" << "error" << "-show_entries" << "format=duration" << "-of" << "default=noprint_wrappers=1:nokey=1" << vid);
}

void ScreenRecorder::gotoLink(const QString& file, const QString& thumb, bool showNotification) const {
    if (!QFile::exists(file))
        return;

    if (showNotification) {
        QString     icon = QFile::exists(thumb) ? thumb : "";

        QProcess*   notifyProc = new QProcess(const_cast<ScreenRecorder*>(this));
        QStringList args;
        args << "-a" << "screengrab" << "-i" << icon << "--action" << "default=open link" << "--wait" << "Capture Saved" << file;

        connect(notifyProc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), [notifyProc, file](int, QProcess::ExitStatus) {
            QString action = QString(notifyProc->readAllStandardOutput()).trimmed();
            notifyProc->deleteLater();

            if (action == "default") {
                QProcess::startDetached("xdg-open", QStringList() << file);
            }
        });
        notifyProc->start("notify-send", args);
    } else {
        QProcess::startDetached("xdg-open", QStringList() << file);
    }
}

void ScreenRecorder::copyToClipboard(const QString& img) const {
    QFile* file = new QFile(img);
    if (!file->open(QIODevice::ReadOnly)) {
        delete file;
        return;
    }

    QProcess* process = new QProcess(const_cast<ScreenRecorder*>(this));
    connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), [process, file](int, QProcess::ExitStatus) {
        process->deleteLater();
        file->deleteLater();
    });

    process->start("wl-copy", QStringList());
    process->write(file->readAll());
    process->closeWriteChannel();
}

void ScreenRecorder::screenshotWindow() {
    QTimer::singleShot(200, this, [this]() {
        QString   img = screenshotPath();

        QProcess* process = new QProcess(this);
        connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, [this, process, img](int, QProcess::ExitStatus) {
            QString out = QString(process->readAllStandardError() + process->readAllStandardOutput());
            process->deleteLater();

            if (!out.contains("selection cancelled")) {
                copyToClipboard(img);
                gotoLink(img, img, true);
            } else {
                notify("Screenshot Failed", "Failed to take screenshot.", "critical", "dialog-error", "Screen Capture");
            }
        });

        QStringList args;
        args << "-m" << "window" << "-d" << "-s" << "-o" << m_screenshotDir << "-f" << QFileInfo(img).fileName();
        process->start("hyprshot", args);
    });
}

void ScreenRecorder::screenshotSelection() {
    QTimer::singleShot(500, this, [this]() {
        QString   img     = screenshotPath();
        QProcess* process = new QProcess(this);
        connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, [this, process, img](int, QProcess::ExitStatus) {
            QString out = process->readAllStandardError() + process->readAllStandardOutput();
            process->deleteLater();
            if (!out.contains("selection cancelled")) {
                copyToClipboard(img);
                gotoLink(img, img, true);
            } else {
                notify("Screenshot Failed", "Selection cancelled.", "critical", "dialog-error", "Screen Capture");
            }
        });
        process->start("hyprshot", QStringList() << "-m" << "region" << "-d" << "-s" << "-o" << m_screenshotDir << "-f" << QFileInfo(img).fileName());
    });
}

void ScreenRecorder::screenshotOutput(const QString& out) {
    QTimer::singleShot(200, this, [this, out]() {
        QStringList monitors = getMonitors();
        if (monitors.isEmpty()) {
            notify("Screenshot Failed", "No monitors found.", "critical", "dialog-error", "Screen Capture");
            return;
        }

        QString target = monitors.first();
        if (!out.isEmpty() && monitors.contains(out)) {
            target = out;
        }

        QString   img = screenshotPath();

        QProcess* grim = new QProcess(this);
        connect(grim, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, [this, grim, img, target](int grimExitCode, QProcess::ExitStatus) {
            grim->deleteLater();
            if (grimExitCode == 0 && QFile::exists(img)) {
                copyToClipboard(img);
                gotoLink(img, img, true);
            } else {
                notify("Screenshot Failed", "Failed to take screenshot on " + target + ".", "critical", "dialog-error", "Screen Capture");
            }
        });
        grim->start("grim", QStringList() << "-c" << "-o" << target << img);
    });
}
