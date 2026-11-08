#pragma once

#include "SystemStatParsers.hpp"

#include <qobject.h>
#include <qtmetamacros.h>

#include <atomic>

namespace vast {

    class GraphicsInfoProbe final : public QObject {
        Q_OBJECT

      public:
        explicit GraphicsInfoProbe(QObject* parent = nullptr);
        ~GraphicsInfoProbe() override                          = default;
        GraphicsInfoProbe(const GraphicsInfoProbe&)            = delete;
        GraphicsInfoProbe& operator=(const GraphicsInfoProbe&) = delete;
        GraphicsInfoProbe(GraphicsInfoProbe&&)                 = delete;
        GraphicsInfoProbe& operator=(GraphicsInfoProbe&&)      = delete;

        void               startProbe();

        [[nodiscard]] bool isLoaded() const noexcept {
            return mLoaded;
        }

      signals:
        void finished(const vast::sysusage::GraphicsSummary& summary);

      private:
        std::atomic<bool> mLoaded{false};
        std::atomic<bool> mRunning{false};

        void              executeProbe();
    };

} // namespace vast
