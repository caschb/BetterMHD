cmake_minimum_required(VERSION 3.21)

if (NOT DEFINED CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 20)
endif()

set(CMAKE_CXX_EXTENSIONS OFF)

project(
  BetterMHD
  VERSION 0.0.1
  DESCRIPTION "MHD simulation"
  LANGUAGES CXX
)
include(cmake/PreventInSourceBuilds.cmake)
include(ProjectOptions.cmake)

bmhd_setup_options()

bmhd_global_options()

include(Dependencies.cmake)
bmhd_setup_dependencies()

bmhd_local_options()

set(CMAKE_CXX_VISIBILITY_PRESET hidden)

set(GIT_SHA
    "Unknown"
    CACHE STRING "SHA this build was generated from")
string(
  SUBSTRING "${GIT_SHA}"
            0
            8
            GIT_SHORT_SHA)

target_compile_features(bmhd_options INTERFACE cxx_std_${CMAKE_CXX_STANDARD})

add_library(bmhd::bmhd_options ALIAS bmhd_options)
add_library(bmhd::bmhd_warnings ALIAS bmhd_warnings)

add_subdirectory(main)

# if(NOT PROJECT_IS_TOP_LEVEL)
#   return()
# endif()

# # Adding the tests:
# include(CTest)

# if(BUILD_TESTING)
#   message(AUTHOR_WARNING "Building Tests.")
#   add_subdirectory(test)
# endif()

# if(MSVC)
#   get_all_installable_targets(all_targets)
#   message("all_targets=${all_targets}")
#   set_target_properties(${all_targets} PROPERTIES VS_DEBUGGER_ENVIRONMENT "PATH=$(VC_ExecutablePath_x64);%PATH%")
# endif()

# # set the startup project for the "play" button in MSVC
# set_property(DIRECTORY PROPERTY VS_STARTUP_PROJECT intro)

# if(CMAKE_SKIP_INSTALL_RULES)
#   return()
# endif()