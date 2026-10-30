# Goxel 3D voxels editor - Android / SDL2 build
#
# The desktop builds use SConstruct (`make`).  This CMake project is the
# Android (and optional SDL2 desktop) backend: it builds the whole goxel core
# plus the SDL2 platform layer in src/main_sdl.c, using OpenGL ES 2.0.
#
# Usage (from android/): ./gradlew assembleDebug
# The SDL2 sources are expected in third_party/SDL, see android/fetch-sdl.sh.

cmake_minimum_required(VERSION 3.16)

project(aosgoxel C CXX)

if(NOT ANDROID)
    message(FATAL_ERROR
        "This CMake project is the Android backend only. "
        "Use `make` (SConstruct) to build goxel on the desktop.")
endif()

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED OFF)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED OFF)
set(CMAKE_C_EXTENSIONS ON)     # gnu99
set(CMAKE_CXX_EXTENSIONS ON)   # gnu++17
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# -------------------------------------------------------------------------
# SDL2
# -------------------------------------------------------------------------

set(SDL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/third_party/SDL")
if(NOT EXISTS "${SDL_DIR}/CMakeLists.txt")
    message(FATAL_ERROR
        "SDL2 sources not found in third_party/SDL.\n"
        "Run android/fetch-sdl.sh (or `git clone --depth 1 --branch "
        "release-2.32.8 https://github.com/libsdl-org/SDL third_party/SDL`).")
endif()

set(SDL_SHARED ON  CACHE BOOL "" FORCE)
set(SDL_STATIC OFF CACHE BOOL "" FORCE)
set(SDL_TEST   OFF CACHE BOOL "" FORCE)
set(SDL_TESTS  OFF CACHE BOOL "" FORCE)
set(SDL_INSTALL OFF CACHE BOOL "" FORCE)
set(SDL_DISABLE_INSTALL ON CACHE BOOL "" FORCE)
add_subdirectory("${SDL_DIR}" "${CMAKE_BINARY_DIR}/SDL" EXCLUDE_FROM_ALL)

# -------------------------------------------------------------------------
# Goxel
# -------------------------------------------------------------------------

file(GLOB_RECURSE GOXEL_SOURCES CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/src/*.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp")

# src/main.c is the GLFW/desktop entry point, src/goxel_info.c is a separate
# command line tool.  Everything else is the editor core.
list(FILTER GOXEL_SOURCES EXCLUDE REGEX "/src/main\\.c$")
list(FILTER GOXEL_SOURCES EXCLUDE REGEX "/src/goxel_info\\.c$")

# The SDL library must be called "main" (SDLActivity loads libmain.so).
add_library(main SHARED ${GOXEL_SOURCES})
set_target_properties(main PROPERTIES OUTPUT_NAME "main")

target_include_directories(main PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/src"
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${CMAKE_CURRENT_SOURCE_DIR}/ext_src"
    "${CMAKE_CURRENT_SOURCE_DIR}/ext_src/uthash"
    "${CMAKE_CURRENT_SOURCE_DIR}/ext_src/stb"
    "${CMAKE_CURRENT_SOURCE_DIR}/ext_src/xxhash"
    "${CMAKE_CURRENT_SOURCE_DIR}/ext_src/meshoptimizer"
    "${CMAKE_CURRENT_SOURCE_DIR}/ext_src/libvxl"
    "${CMAKE_CURRENT_SOURCE_DIR}/ext_src/imgui"
    "${CMAKE_CURRENT_SOURCE_DIR}/ext_src/quickjs"
)

# GLES2        - use the OpenGL ES 2.0 renderer path of the core
# GOXEL_MOBILE - mobile gesture/UI behaviour baked into the core
# GOXEL_SDL    - enable the SDL2 platform layer (src/main_sdl.c)
# GOXEL_NO_TINYFILEDIALOGS - no desktop file dialogs on mobile
target_compile_definitions(main PRIVATE
    GLES2=1
    ANDROID=1
    GOXEL_MOBILE=1
    GOXEL_SDL=1
    GOXEL_NO_TINYFILEDIALOGS=1
)

target_compile_options(main PRIVATE
    -include "${CMAKE_CURRENT_SOURCE_DIR}/src/config.h"
    -Wall
    -Wno-unused-parameter
    -Wno-unused-variable
    -Wno-unused-function
    -Wno-unknown-pragmas
    -Wno-narrowing
)

target_link_libraries(main PRIVATE
    SDL2::SDL2
    SDL2::SDL2main
    GLESv2
    EGL
    log
    android
    m
)
