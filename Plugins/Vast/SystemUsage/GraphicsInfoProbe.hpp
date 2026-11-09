#pragma once

#include "SystemStatParsers.hpp"

#include <qbytearray.h>
#include <qobject.h>
#include <qprocess.h>
#include <qstring.h>
#include <qtimer.h>
#include <qtmetamacros.h>

#include <cstdint>

namespace vast {

    class GraphicsInfoProbe final : public QObject {
        Q_OBJECT

      public:
        explicit GraphicsInfoProbe(QObject* parent = nullptr, int probeTimeoutMilliseconds = 3000, QString driDirectory = QStringLiteral("/dev/dri"));
        ~GraphicsInfoProbe() override                          = default;
        GraphicsInfoProbe(const GraphicsInfoProbe&)            = delete;
        GraphicsInfoProbe& operator=(const GraphicsInfoProbe&) = delete;
        GraphicsInfoProbe(GraphicsInfoProbe&&)                 = delete;
        GraphicsInfoProbe& operator=(GraphicsInfoProbe&&)      = delete;

        void               startProbe();

        [[nodiscard]] bool isLoaded() const noexcept {
            return mLoaded;
        }

      Q_SIGNALS:
        void finished(const vast::sysusage::GraphicsSummary& summary);

      private:
        enum class ProbeStep : std::uint8_t {
            Vulkan,
            OpenGl,
            VaApi,
            Done
        };

        bool       mLoaded{false};
        bool       mRunning{false};
        QTimer*    mProcessTimeout{nullptr};
        QProcess*  mActiveProcess{nullptr};
        QString    mDriDirectory;
        QByteArray mVulkanOutput;
        QByteArray mOpenGlOutput;
        QByteArray mVaApiOutput;
        ProbeStep  mProbeStep{ProbeStep::Vulkan};
        bool       mOpenGlFallbackTried{false};

        void       startNextTool();
        void       launchTool(const QString& program, const QStringList& arguments);
        void       onProcessFinished(QProcess* process);
        void       finishProbe();
    };

} // namespace vast
