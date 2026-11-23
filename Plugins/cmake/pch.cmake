option(VAST_NO_PCH "Disable precompiled headers" OFF)

if(NOT VAST_NO_PCH)
    file(GENERATE
        OUTPUT ${CMAKE_BINARY_DIR}/pchstub.cpp
        CONTENT "// intentionally empty"
    )
endif()

function(vast_pch arg_TARGET)
    if(VAST_NO_PCH)
        return()
    endif()

    cmake_parse_arguments(PARSE_ARGV 1 arg "" "SET" "")

    set(PCH_TARGET "vast-pchset-common")
    if( arg_SET AND TARGET "vast-pchset-${arg_SET}" )
        set(PCH_TARGET "vast-pchset-${arg_SET}")
    endif()

    target_include_directories(${arg_TARGET} SYSTEM PRIVATE
        $<TARGET_PROPERTY:${PCH_TARGET},INTERFACE_INCLUDE_DIRECTORIES>
    )
    target_precompile_headers(${arg_TARGET} REUSE_FROM "${PCH_TARGET}")
endfunction()

function(vast_add_pchset arg_SETNAME)
    if(VAST_NO_PCH)
        return()
    endif()

    cmake_parse_arguments(PARSE_ARGV 1 arg "" "" "HEADERS;DEPENDENCIES")

    set(LIBNAME "vast-pchset-${arg_SETNAME}")

    add_library(${LIBNAME} STATIC EXCLUDE_FROM_ALL ${CMAKE_BINARY_DIR}/pchstub.cpp)
    set_target_properties(${LIBNAME} PROPERTIES AUTOMOC OFF)
    target_link_libraries(${LIBNAME} PRIVATE Qt::Core)
    foreach(dep IN LISTS arg_DEPENDENCIES)
        target_include_directories(${LIBNAME} SYSTEM PUBLIC
            $<TARGET_PROPERTY:${dep},INTERFACE_INCLUDE_DIRECTORIES>
        )
    endforeach()
    target_precompile_headers(${LIBNAME} PUBLIC ${arg_HEADERS})
endfunction()

set(VAST_COMMON_PCH_SET
    <algorithm>
    <array>
    <cmath>
    <cstddef>
    <cstdint>
    <functional>
    <map>
    <memory>
    <optional>
    <span>
    <string>
    <utility>
    <vector>
    <qabstractitemmodel.h>
    <qbytearray.h>
    <qchar.h>
    <qcolor.h>
    <qcontainerfwd.h>
    <qdatetime.h>
    <qdebug.h>
    <qdir.h>
    <qfile.h>
    <qfileinfo.h>
    <qhash.h>
    <qhashfunctions.h>
    <qimage.h>
    <qiodevice.h>
    <qjsondocument.h>
    <qjsonobject.h>
    <qlatin1stringview.h>
    <qlist.h>
    <qlogging.h>
    <qmap.h>
    <qmetatype.h>
    <qnamespace.h>
    <qnumeric.h>
    <qobject.h>
    <qobjectdefs.h>
    <qpointer.h>
    <qqmlengine.h>
    <qqmlintegration.h>
    <QtQml/qqmlextensionplugin.h>
    <qregularexpression.h>
    <qstring.h>
    <qstringlist.h>
    <qstringview.h>
    <qthreadpool.h>
    <qtimer.h>
    <qtmetamacros.h>
    <QtCore/qtsymbolmacros.h>
    <qtypes.h>
    <qurl.h>
    <qvariant.h>
)

set(VAST_LARGE_PCH_SET ${VAST_COMMON_PCH_SET})

set(VAST_PCHSET_DEPS
    Qt::Core
    Qt::Gui
    Qt::Qml
    Qt::Quick
)

vast_add_pchset(common
    DEPENDENCIES ${VAST_PCHSET_DEPS}
    HEADERS ${VAST_COMMON_PCH_SET}
)
