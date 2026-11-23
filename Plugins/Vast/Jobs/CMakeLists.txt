qt_add_library(vast-jobs STATIC
    JobExecutor.hpp
    JobExecutor.cpp
)

vast_pch(vast-jobs)
target_link_libraries(vast-jobs PUBLIC Qt::Core)
