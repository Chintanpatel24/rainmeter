add_library(rainmeter_common_portable STATIC
    MathParser.cpp
    PathUtil.cpp
    StringUtil.cpp
)

target_include_directories(rainmeter_common_portable
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
)

if(NOT WIN32)
    target_compile_definitions(rainmeter_common_portable PRIVATE _GNU_SOURCE)
endif()

add_executable(rainmeter_common_smoke
    LinuxSmokeTest.cpp
)

target_link_libraries(rainmeter_common_smoke
    PRIVATE
        rainmeter_common_portable
)
