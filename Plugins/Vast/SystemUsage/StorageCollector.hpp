#pragma once

#include "SystemStatParsers.hpp"

namespace vast {

    class StorageCollector {
      public:
        [[nodiscard]] static sysusage::StorageSummary collect();
    };

} // namespace vast
