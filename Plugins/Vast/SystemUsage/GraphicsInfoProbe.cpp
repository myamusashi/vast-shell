#include "GraphicsInfoProbe.hpp"

#include <qdir.h>
#include <qfileinfo.h>
#include <qstringlist.h>

#include <utility>

namespace vast {

    namespace {

        [[nodiscard]] QString findDriDevice(const QString& driDirectory) {
            QString renderDefault = driDirectory + QStringLiteral("/renderD128");
            if (QFileInfo::exists(renderDefault)) {
                return renderDefault;
            }
            const QDir driDir(driDirectory);
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

    GraphicsInfoProbe::GraphicsInfoProbe(QObject* parent, int probeTimeoutMilliseconds, QString driDirectory) :
        QObject(parent), mProcessTimeout(new QTimer(this)), mDriDirectory(std::move(driDirectory)) {
        mProcessTimeout->setSingleShot(true);
        mProcessTimeout->setInterval(probeTimeoutMilliseconds);
        connect(mProcessTimeout, &QTimer::timeout, this, [this]() {
            if (mActiveProcess)
                mActiveProcess->kill();
        });
    }

    void GraphicsInfoProbe::startProbe() {
        if (mLoaded || mRunning)
            return;

        mRunning             = true;
        mProbeStep           = ProbeStep::Vulkan;
        mOpenGlFallbackTried = false;
        startNextTool();
    }

    void GraphicsInfoProbe::startNextTool() {
        if (mProbeStep == ProbeStep::Done) {
            finishProbe();
            return;
        }

        if (mProbeStep == ProbeStep::Vulkan) {
            launchTool(QStringLiteral("vulkaninfo"), {QStringLiteral("--summary")});
            return;
        }
        if (mProbeStep == ProbeStep::OpenGl) {
            const QString driDevice = findDriDevice(mDriDirectory);
            if (!driDevice.isEmpty()) {
                launchTool(QStringLiteral("eglinfo"), {QStringLiteral("-B"), driDevice});
            } else {
                // No DRI device available: skip eglinfo, go straight to glxinfo
                mOpenGlFallbackTried = true;
                launchTool(QStringLiteral("glxinfo"), {QStringLiteral("-B")});
            }
            return;
        }
        launchTool(QStringLiteral("vainfo"), {});
    }

    void GraphicsInfoProbe::launchTool(const QString& program, const QStringList& arguments) {
        mActiveProcess = new QProcess(this);
        connect(mActiveProcess, &QProcess::finished, this, [this, process = mActiveProcess]() { onProcessFinished(process); });
        connect(mActiveProcess, &QProcess::errorOccurred, this, [this, process = mActiveProcess](QProcess::ProcessError error) {
            if (error == QProcess::FailedToStart)
                onProcessFinished(process);
        });
        mProcessTimeout->start();
        mActiveProcess->start(program, arguments);
    }

    void GraphicsInfoProbe::onProcessFinished(QProcess* process) {
        if (process != mActiveProcess)
            return;

        mProcessTimeout->stop();
        const bool normalExit = (mActiveProcess->exitStatus() == QProcess::NormalExit) && (mActiveProcess->exitCode() == 0);

        if (mProbeStep == ProbeStep::Vulkan) {
            const QByteArray output = mActiveProcess->readAllStandardOutput();
            if (!output.isEmpty())
                mVulkanOutput = output;
        } else if (mProbeStep == ProbeStep::OpenGl) {
            const QByteArray output = mActiveProcess->readAllStandardOutput();
            if (!mOpenGlFallbackTried) {
                if (normalExit && !output.isEmpty()) {
                    mOpenGlOutput = output;
                } else {
                    mOpenGlFallbackTried = true;
                    mActiveProcess->deleteLater();
                    mActiveProcess = nullptr;
                    launchTool(QStringLiteral("glxinfo"), {QStringLiteral("-B")});
                    return;
                }
            } else if (!output.isEmpty()) {
                mOpenGlOutput = output;
            }
        } else if (mProbeStep == ProbeStep::VaApi) {
            const QByteArray output = mActiveProcess->readAllStandardOutput() + mActiveProcess->readAllStandardError();
            if (!output.isEmpty())
                mVaApiOutput = output;
        }

        mActiveProcess->deleteLater();
        mActiveProcess = nullptr;

        if (mProbeStep == ProbeStep::Vulkan)
            mProbeStep = ProbeStep::OpenGl;
        else if (mProbeStep == ProbeStep::OpenGl)
            mProbeStep = ProbeStep::VaApi;
        else
            mProbeStep = ProbeStep::Done;

        startNextTool();
    }

    void GraphicsInfoProbe::finishProbe() {
        auto summary = sysusage::parseGraphicsOutputs(mVulkanOutput, mOpenGlOutput, mVaApiOutput);
        mLoaded      = true;
        mRunning     = false;
        QTimer::singleShot(0, this, [this, summary = std::move(summary)]() { Q_EMIT finished(summary); });
    }

} // namespace vast
