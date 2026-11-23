pkg_check_modules(DDCUTIL REQUIRED IMPORTED_TARGET ddcutil)

vast_module(vast-brightness
    URI Vast.Brightness
    SOURCES
        BrightnessManager.hpp
        BrightnessManager.cpp
        BrightnessProfileStore.hpp
        BrightnessProfileStore.cpp
    LIBRARIES
        PkgConfig::DDCUTIL
        vast-jobs
)
