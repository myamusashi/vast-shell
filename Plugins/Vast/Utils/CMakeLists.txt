vast_module(vast-utils
    URI Vast.Utils
    PCH_SET large
    SOURCES
        BluetoothAgentAdaptor.hpp
        BluetoothAgentAdaptor.cpp
        BluetoothAgentManager.hpp
        BluetoothAgentManager.cpp
        ColorMaterial.hpp
        ColorMaterial.cpp
        ColorPreview.hpp
        ColorPreview.cpp
        ColorUtils.cpp
        ColorUtils.hpp
        PaletteAnimator.cpp
        PaletteAnimator.hpp
        Utils.hpp
        Utils.cpp
    LIBRARIES
        Qt::DBus
        material-color-utilities
        vast-materialcolor
        vast-jobs
)
