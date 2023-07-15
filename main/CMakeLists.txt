
set(EXECUTABLE_NAME "mhd")

add_executable(${EXECUTABLE_NAME} src/main.cpp)

target_link_libraries(${EXECUTABLE_NAME} PRIVATE 
bmhd::bmhd_options
bmhd::bmhd_warnings)

target_link_system_libraries(
  ${EXECUTABLE_NAME}
  PRIVATE
  CLI11::CLI11
  fmt::fmt
  spdlog::spdlog
  Eigen3::Eigen
)

target_include_directories(${EXECUTABLE_NAME} PRIVATE include)