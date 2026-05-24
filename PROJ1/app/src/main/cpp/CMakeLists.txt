cmake_minimum_required(VERSION 3.22.1)
project(proj1_native)

add_library(native-lib SHARED
    main.cpp
    engine.cpp
    renderer.cpp)

target_include_directories(native-lib PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

find_library(LOG_LIB log)
find_library(ANDROID_LIB android)
find_library(EGL_LIB EGL)
find_library(GLES3_LIB GLESv3)

target_link_libraries(native-lib
    ${LOG_LIB}
    ${ANDROID_LIB}
    ${EGL_LIB}
    ${GLES3_LIB})
