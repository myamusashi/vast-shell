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
        KdeConnectShare.hpp
        KdeConnectShare.cpp
        Read.hpp
        Read.cpp
        Write.hpp
        Write.cpp
    LIBRARIES
        Qt::DBus
        material-color-utilities
        vast-materialcolor
        vast-jobs
)
