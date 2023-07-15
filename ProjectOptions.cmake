include(cmake/SystemLink.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)

macro(bmhd_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)
    set(SUPPORTS_UBSAN ON)
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    set(SUPPORTS_ASAN ON)
  endif()
endmacro()

macro(bmhd_setup_options)
  option(bmhd_ENABLE_HARDENING "Enable hardening" ON)
  option(bmhd_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    bmhd_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    bmhd_ENABLE_HARDENING
    OFF)

  bmhd_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR bmhd_PACKAGING_MAINTAINER_MODE)
    option(bmhd_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(bmhd_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(bmhd_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(bmhd_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(bmhd_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(bmhd_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(bmhd_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(bmhd_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(bmhd_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(bmhd_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(bmhd_ENABLE_PCH "Enable precompiled headers" OFF)
    option(bmhd_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(bmhd_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(bmhd_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(bmhd_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(bmhd_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(bmhd_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(bmhd_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(bmhd_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(bmhd_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(bmhd_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(bmhd_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(bmhd_ENABLE_PCH "Enable precompiled headers" OFF)
    option(bmhd_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      bmhd_WARNINGS_AS_ERRORS
      bmhd_ENABLE_USER_LINKER
      bmhd_ENABLE_SANITIZER_ADDRESS
      bmhd_ENABLE_SANITIZER_LEAK
      bmhd_ENABLE_SANITIZER_UNDEFINED
      bmhd_ENABLE_SANITIZER_THREAD
      bmhd_ENABLE_SANITIZER_MEMORY
      bmhd_ENABLE_UNITY_BUILD
      bmhd_ENABLE_CLANG_TIDY
      bmhd_ENABLE_CPPCHECK
      bmhd_ENABLE_COVERAGE
      bmhd_ENABLE_PCH
      bmhd_ENABLE_CACHE)
  endif()

endmacro()

macro(bmhd_global_options)
  bmhd_supports_sanitizers()

  if(bmhd_ENABLE_HARDENING AND bmhd_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR bmhd_ENABLE_SANITIZER_UNDEFINED
       OR bmhd_ENABLE_SANITIZER_ADDRESS
       OR bmhd_ENABLE_SANITIZER_THREAD
       OR bmhd_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    bmhd_enable_hardening(bmhd_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(bmhd_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(bmhd_warnings INTERFACE)
  add_library(bmhd_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  bmhd_set_project_warnings(
    bmhd_warnings
    ${bmhd_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(bmhd_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    configure_linker(bmhd_options)
  endif()

  include(cmake/Sanitizers.cmake)
  bmhd_enable_sanitizers(
    bmhd_options
    ${bmhd_ENABLE_SANITIZER_ADDRESS}
    ${bmhd_ENABLE_SANITIZER_LEAK}
    ${bmhd_ENABLE_SANITIZER_UNDEFINED}
    ${bmhd_ENABLE_SANITIZER_THREAD}
    ${bmhd_ENABLE_SANITIZER_MEMORY})

  set_target_properties(bmhd_options PROPERTIES UNITY_BUILD ${bmhd_ENABLE_UNITY_BUILD})

  if(bmhd_ENABLE_PCH)
    target_precompile_headers(
      bmhd_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(bmhd_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    bmhd_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(bmhd_ENABLE_CLANG_TIDY)
    bmhd_enable_clang_tidy(bmhd_options ${bmhd_WARNINGS_AS_ERRORS})
  endif()

  if(bmhd_ENABLE_CPPCHECK)
    bmhd_enable_cppcheck(${bmhd_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(bmhd_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    bmhd_enable_coverage(bmhd_options)
  endif()

  if(bmhd_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(bmhd_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(bmhd_ENABLE_HARDENING AND NOT bmhd_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR bmhd_ENABLE_SANITIZER_UNDEFINED
       OR bmhd_ENABLE_SANITIZER_ADDRESS
       OR bmhd_ENABLE_SANITIZER_THREAD
       OR bmhd_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    bmhd_enable_hardening(bmhd_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()