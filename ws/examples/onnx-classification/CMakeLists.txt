cmake_minimum_required(VERSION 3.22)
project(onnx-classification C CXX)
find_package(OpenCV REQUIRED)

string(APPEND CMAKE_CXX_FLAGS " -Wall -Wextra")
string(APPEND CMAKE_C_FLAGS " -Wall -Wextra")
set(ONNXRUNTIME_ROOTDIR "/onnxruntime")
set(CMAKE_CXX_STANDARD 17)


add_executable(${PROJECT_NAME} 
    src/main.cpp
)

target_include_directories(${PROJECT_NAME} PRIVATE ${OpenCV_INCLUDE_DIRS} "${PROJECT_SOURCE_DIR}/include")
target_link_libraries(${PROJECT_NAME} ${OpenCV_LIBRARIES})

set(ONNXRUNTIME_INCLUDE_DIRS /onnxruntime/include)
set(ONNXRUNTIME_LIBRARY_DIRS /onnxruntime/lib)

target_include_directories(${PROJECT_NAME} PRIVATE ${ONNXRUNTIME_INCLUDE_DIRS})
target_link_libraries(${PROJECT_NAME} ${ONNXRUNTIME_LIBRARY_DIRS}/libonnxruntime.so)