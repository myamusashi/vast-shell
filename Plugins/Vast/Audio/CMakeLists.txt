pkg_check_modules(PIPEWIRE REQUIRED IMPORTED_TARGET libpipewire-0.3)

vast_module(vast-audio
    URI Vast.Audio
    SOURCES
        AudioProfilesModel.hpp
        AudioProfilesModel.cpp
        AudioProfilesWatcher.hpp
        AudioProfilesWatcher.cpp
        AudioProfileFormat.hpp
        AudioDevicesModel.hpp
        AudioDevicesModel.cpp
        AudioDevicesWatcher.hpp
        AudioDevicesWatcher.cpp
        AudioCard.hpp
        AudioCard.cpp
        AudioCardsModel.hpp
        AudioCardsModel.cpp
    LIBRARIES
        PkgConfig::PIPEWIRE
)
