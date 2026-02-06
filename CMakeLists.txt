cmake_minimum_required(VERSION 3.16)
project(Fiamy VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.10 REQUIRED COMPONENTS
    Core
    Gui
    Qml
    Quick
    QuickControls2
    Multimedia
)

qt_standard_project_setup()

set(SRC
    main.cpp
    audiocaptureanalyzer.cpp
    youtubedownloader.cpp
)

set(HEADERS
    audiocaptureanalyzer.h
    youtubedownloader.h
)

set(QML_FILES
    Main.qml
    components/ActionButtons.qml
    components/AudioVisualizer.qml
    components/BookmarkPlayer.qml
    components/PlayerCard.qml
    components/PlayerControls.qml
    components/ProgressBar.qml
    components/SongInfo.qml
    components/VisualizerBar.qml
    components/VisualizerBars.qml
    components/VolumeControl.qml
    components/YoutubeQueueInput.qml
    components/QueueDrawer.qml
)

set(RESOURCE_FILES
    pink.png
    pink.ico
)

file(GLOB THIRD_PARTY_HEADERS "${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/*.h")

source_group(TREE "${CMAKE_CURRENT_SOURCE_DIR}/thirdparty" PREFIX "ThirdParty" FILES ${THIRD_PARTY_HEADERS})

qt_add_executable(Fiamy
    ${SRC}
    ${HEADERS}
    ${THIRD_PARTY_HEADERS}
)

if(WIN32)
    set_target_properties(Fiamy PROPERTIES
        WIN32_EXECUTABLE TRUE
    )

    # Crear archivo .rc para el ícono
    set(ICON_RC "${CMAKE_CURRENT_BINARY_DIR}/icon.rc")
    file(WRITE ${ICON_RC} "IDI_ICON1 ICON DISCARDABLE \"${CMAKE_CURRENT_SOURCE_DIR}/pink.ico\"\n")

    target_sources(Fiamy PRIVATE ${ICON_RC})
endif()

target_include_directories(Fiamy PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty
)

qt_add_qml_module(Fiamy
    URI Fiamy
    VERSION 1.0
    QML_FILES
        ${QML_FILES}
)

qt_add_resources(Fiamy "resources"
    PREFIX "/"
    FILES
        ${RESOURCE_FILES}
)

add_library(miniaudio INTERFACE)
target_include_directories(miniaudio INTERFACE
    ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty
)

target_link_libraries(Fiamy PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Multimedia
    miniaudio
)

if(WIN32)
    # Solo copiar si existe (opcional para desarrollo)
    if(EXISTS "${CMAKE_SOURCE_DIR}/yt-dlp.exe")
        add_custom_command(TARGET Fiamy POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${CMAKE_SOURCE_DIR}/yt-dlp.exe"
                "$<TARGET_FILE_DIR:Fiamy>/yt-dlp.exe"
            COMMENT "Copiando yt-dlp.exe al directorio de salida"
        )
    else()
        message(STATUS "yt-dlp.exe no encontrado - se descargará automáticamente al ejecutar")
    endif()
endif()
