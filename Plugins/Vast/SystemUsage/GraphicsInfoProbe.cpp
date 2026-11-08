#include "GraphicsInfoProbe.hpp"
#include "../Jobs/JobExecutor.hpp"

#include <qbytearray.h>
#include <qdir.h>
#include <qfileinfo.h>
#include <qprocess.h>
#include <qstringlist.h>

namespace vast {

    namespace {

        [[nodiscard]] QString findDriDevice() {
            if (QFileInfo::exists(QStringLiteral("/dev/dri/renderD128"))) {
                return QStringLiteral("/dev/dri/renderD128");
            }
            const QDir driDir(QStringLiteral("/dev/dri"));
            const auto renders = driDir.entryList(QStringList{QStringLiteral("renderD*")}, QDir::System | QDir::Files, QDir::Name);
            if (!renders.isEmpty()) {
                return driDir.absoluteFilePath(renders.first());
            }
            const auto cards = driDir.entryList(QStringList{QStringLiteral("card*")}, QDir::System | QDir::Files, QDir::Name);
            if (!cards.isEmpty()) {
                return driDir.absoluteFilePath(cards.first());
            }
            return {};
        }

    } // namespace

    GraphicsInfoProbe::GraphicsInfoProbe(QObject* parent) : QObject(parent) {}

    void GraphicsInfoProbe::startProbe() {
        if (mLoaded.load() || mRunning.exchange(true))
            return;

        JobExecutor::instance().post([this]() { executeProbe(); });
    }

    void GraphicsInfoProbe::executeProbe() {
        // 1. Run vulkaninfo --summary
        QByteArray vulkanOutput;
        {
            QProcess process;
            process.start(QStringLiteral("vulkaninfo"), {QStringLiteral("--summary")});
            if (process.waitForFinished(3000)) {
                vulkanOutput = process.readAllStandardOutput();
            }
        }

        // 2. Run eglinfo -B <device>, fallback to glxinfo -B
        QByteArray    openglOutput;
        const QString driDevice = findDriDevice();
        if (!driDevice.isEmpty()) {
            QProcess process;
            process.start(QStringLiteral("eglinfo"), {QStringLiteral("-B"), driDevice});
            if (process.waitForFinished(3000) && process.exitCode() == 0) {
                openglOutput = process.readAllStandardOutput();
            }
        }
        if (openglOutput.isEmpty()) {
            QProcess process;
            process.start(QStringLiteral("glxinfo"), {QStringLiteral("-B")});
            if (process.waitForFinished(3000)) {
                openglOutput = process.readAllStandardOutput();
            }
        }

        // 3. Run vainfo (reads both stdout and stderr)
        QByteArray vaApiOutput;
        {
            QProcess process;
            process.start(QStringLiteral("vainfo"), {});
            if (process.waitForFinished(3000)) {
                vaApiOutput = process.readAllStandardOutput() + process.readAllStandardError();
            }
        }

        auto summary = sysusage::parseGraphicsOutputs(vulkanOutput, openglOutput, vaApiOutput);

        QMetaObject::invokeMethod(
            this,
            [this, summary = std::move(summary)]() mutable {
                mLoaded.store(true);
                mRunning.store(false);
                emit finished(summary);
            },
            Qt::QueuedConnection);
    }

} // namespace vast
