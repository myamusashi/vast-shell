vast_module(vast-systemusage
    URI Vast.SystemUsage
    PCH_SET large
    SOURCES
        CpuCoresModel.hpp
        CpuCoresModel.cpp
        FilesystemsModel.hpp
        FilesystemsModel.cpp
        ModelDiffHelper.hpp
        GraphicsInfoProbe.hpp
        GraphicsInfoProbe.cpp
        SensorScanner.hpp
        SensorScanner.cpp
        StorageCollector.hpp
        StorageCollector.cpp
        SystemFormatters.hpp
        SystemFormatters.cpp
        SystemStatParsers.hpp
        SystemStatParsers.cpp
        SystemUsageMonitor.hpp
        SystemUsageMonitor.cpp
        WirelessBitrateReader.hpp
        WirelessBitrateReader.cpp
    LIBRARIES
        Qt::DBus
        vast-jobs
)
