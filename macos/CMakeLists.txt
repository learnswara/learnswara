cmake_minimum_required(VERSION 3.10)
project(soundtouch_macos)

# Include the shared CMakeLists
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../android/app/src/main/cpp ${CMAKE_CURRENT_BINARY_DIR}/soundtouch) 