cmake_minimum_required(VERSION 3.14)

if(APPLE)
	if (NOT CMAKE_OSX_ARCHITECTURES)
		set(CMAKE_OSX_ARCHITECTURES "${CMAKE_HOST_SYSTEM_PROCESSOR}")
	endif()
	if (NOT CMAKE_OSX_DEPLOYMENT_TARGET)
		if ("${CMAKE_OSX_ARCHITECTURES}" STREQUAL "arm64")
			set(CMAKE_OSX_DEPLOYMENT_TARGET "11.0")
		else()
			set(CMAKE_OSX_DEPLOYMENT_TARGET "10.15")
		endif()
	endif()
endif()

project(node_fontmanager)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake")

SET(NODEJS_URL "https://artifacts.electronjs.org/headers/dist" CACHE STRING "Node.JS URL")
SET(NODEJS_NAME "iojs" CACHE STRING "Node.JS Name")
SET(NODEJS_VERSION "v43.2.0" CACHE STRING "Node.JS Version")


include(NodeJS)
include(CPack)

nodejs_init()

# Include N-API wrappers
execute_process(COMMAND node -p "require('node-addon-api').include"
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE NODE_ADDON_API_DIR
        )
string(REPLACE "\n" "" NODE_ADDON_API_DIR ${NODE_ADDON_API_DIR})
string(REPLACE "\"" "" NODE_ADDON_API_DIR ${NODE_ADDON_API_DIR})

# list(APPEND PROJECT_INCLUDE_PATHS ${NODE_ADDON_API_DIR})

# Define NAPI_VERSION
add_definitions(-DNAPI_VERSION=4)

add_nodejs_module(node_fontmanager
	${node_fontmanager_SOURCE_DIR}/src/FontDescriptor.h
	${node_fontmanager_SOURCE_DIR}/src/FontManager.cc
	${NODEJS_SOURCES})

target_link_libraries(node_fontmanager ${NODEJS_LIBRARIES})
target_include_directories(node_fontmanager PUBLIC ${NODEJS_INCLUDE_DIRS} ${NODE_ADDON_API_DIR})

set(node_fontmanager_EXTRAS
	${node_fontmanager_SOURCE_DIR}/main.js
	${node_fontmanager_SOURCE_DIR}/package.json)

if(WIN32)
	target_sources(node_fontmanager
		PUBLIC ${node_fontmanager_SOURCE_DIR}/src/FontManagerWindows.cc)

	target_link_libraries(node_fontmanager Dwrite)

	target_compile_definitions(node_fontmanager
		PRIVATE -D_CRT_SECURE_NO_WARNINGS)
	target_compile_definitions(node_fontmanager PRIVATE -DUNICODE -D_UNICODE)
elseif(APPLE)
	target_sources(node_fontmanager
		PUBLIC ${node_fontmanager_SOURCE_DIR}/src/FontManagerMac.mm)

	find_library(COREFOUNDATION CoreFoundation)
	find_library(CORETEXT CoreText)
	include_directories(${COREFOUNDATION}
		    ${CORETEXT})

	target_link_libraries(node_fontmanager
		${CORETEXT}
		${COREFOUNDATION})
elseif(UNIX)
	target_sources(node_fontmanager
		PUBLIC ${node_fontmanager_SOURCE_DIR}/src/FontManagerLinux.cc)

	target_link_libraries(node_fontmanager fontconfig)
endif()

if(WIN32)
	include(FetchContent)

	# Compare current linked libs with prev
	FetchContent_Declare(deps_checker URL "https://raw.githubusercontent.com/stream-labs/obs-studio-node/staging/dependency_checker/check_dependencies.cmd" DOWNLOAD_NO_EXTRACT true)
	FetchContent_MakeAvailable(deps_checker)

	add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD COMMAND ${deps_checker_SOURCE_DIR}/check_dependencies.cmd $<TARGET_FILE:node_fontmanager> ${CMAKE_CURRENT_BINARY_DIR} ${CMAKE_CURRENT_SOURCE_DIR} $<CONFIG> )
endif()

if(WIN32)
	install(FILES $<TARGET_PDB_FILE:node_fontmanager> DESTINATION . OPTIONAL)
endif()

install(FILES $<TARGET_FILE:node_fontmanager> DESTINATION .)
install(FILES ${node_fontmanager_EXTRAS} DESTINATION .)
