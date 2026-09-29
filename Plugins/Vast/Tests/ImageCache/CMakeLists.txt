#   tst_imagecacheindex  ImageCacheIndex
#   tst_imagecache       ImageCache end to end
#
# Qt6::Quick is required by tst_imagecache, which registers its own
# QQuickImageProvider to drive saveProviderImage. ImageCacheIndex takes an
# injected directory, so the suite never touches the real notification index.

add_executable(tst_imagecacheindex
    tst_imagecacheindex.cpp
)

target_link_libraries(tst_imagecacheindex PRIVATE
    Qt6::Core
    Qt6::Qml
    Qt6::Test
    vast-imagecache
)

add_executable(tst_imagecache
    tst_imagecache.cpp
)

target_link_libraries(tst_imagecache PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::Test
    vast-imagecache
)

foreach(target IN ITEMS tst_imagecacheindex tst_imagecache)
    add_test(NAME ${target} COMMAND ${target} ${VAST_TEST_ARGS})
endforeach()
