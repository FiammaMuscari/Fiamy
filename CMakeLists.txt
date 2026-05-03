cmake_minimum_required(VERSION 3.16)
project(Fiamy VERSION 1.0.2 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(FIAMY_MIN_QT_VERSION "6.8" CACHE STRING "Minimum Qt version required to build Fiamy")

set(FIAMY_QT_COMPONENTS
    Core
    Gui
    QmlIntegration
    Qml
    QmlModels
    QmlWorkerScript
    QmlMeta
    Quick
    QuickTemplates2
    QuickControls2
    Multimedia
)

if(COSMOPOLITAN)
    list(APPEND FIAMY_QT_COMPONENTS
        Widgets
        QmlPrivate
        QmlModelsPrivate
        QmlWorkerScriptPrivate
        QmlMetaPrivate
        QmlCore
        QmlCorePrivate
        GuiPrivate
        MultimediaQuickPrivate
        QuickPrivate
        QuickLayouts
        QuickControls2Impl
        QuickTemplates2Private
        QuickControls2BasicStyleImpl
        QuickControls2Basic
        QuickControls2FusionStyleImpl
        QuickControls2Fusion
        QuickControls2MaterialStyleImpl
        QuickControls2Material
        QuickControls2ImagineStyleImpl
        QuickControls2Imagine
        QuickControls2UniversalStyleImpl
        QuickControls2Universal
        QuickControls2FluentWinUI3StyleImpl
        LabsPlatform
    )
endif()

find_package(Qt6 ${FIAMY_MIN_QT_VERSION} REQUIRED COMPONENTS ${FIAMY_QT_COMPONENTS})

if(COSMOPOLITAN)
    find_package(Qt6QmlTools REQUIRED CONFIG
        PATHS /opt/homebrew
        NO_DEFAULT_PATH
        NO_CMAKE_FIND_ROOT_PATH
    )
    find_package(Qt6ShaderTools REQUIRED CONFIG
        PATHS /opt/homebrew/Cellar/qtshadertools/6.10.2 /opt/homebrew
        NO_DEFAULT_PATH
        NO_CMAKE_FIND_ROOT_PATH
    )
endif()
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
    components/BookMarkPlayer.qml
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

set(FIAMY_EMBED_YT_DLP_DEFAULT OFF)
if(COSMOPOLITAN)
    set(FIAMY_EMBED_YT_DLP_DEFAULT ON)
endif()
set(FIAMY_EMBED_YT_DLP "${FIAMY_EMBED_YT_DLP_DEFAULT}" CACHE BOOL
    "Embed standalone yt-dlp binaries for Windows, macOS, and Linux into the Cosmopolitan executable")
set(FIAMY_YT_DLP_ASSET_DIR "${CMAKE_CURRENT_BINARY_DIR}/yt-dlp-assets" CACHE PATH
    "Directory used to cache yt-dlp binaries embedded in Cosmopolitan builds")
set(FIAMY_YT_DLP_LINUX_PATH "" CACHE FILEPATH "Optional pre-downloaded yt-dlp Linux binary")
set(FIAMY_YT_DLP_LINUX_AARCH64_PATH "" CACHE FILEPATH "Optional pre-downloaded yt-dlp Linux aarch64 binary")
set(FIAMY_YT_DLP_MACOS_PATH "" CACHE FILEPATH "Optional pre-downloaded yt-dlp macOS binary")
set(FIAMY_YT_DLP_WINDOWS_PATH "" CACHE FILEPATH "Optional pre-downloaded yt-dlp Windows binary")

function(fiamy_prepare_embedded_ytdlp output_var label file_name download_url override_path)
    if(override_path)
        if(NOT EXISTS "${override_path}")
            message(FATAL_ERROR "Configured ${label} yt-dlp binary does not exist: ${override_path}")
        endif()
        set(${output_var} "${override_path}" PARENT_SCOPE)
        return()
    endif()

    file(MAKE_DIRECTORY "${FIAMY_YT_DLP_ASSET_DIR}")
    set(download_path "${FIAMY_YT_DLP_ASSET_DIR}/${file_name}")
    if(NOT EXISTS "${download_path}")
        message(STATUS "Downloading ${label} yt-dlp for embedded resource")
        file(DOWNLOAD
            "${download_url}"
            "${download_path}"
            STATUS download_status
            TLS_VERIFY ON
        )
        list(GET download_status 0 download_code)
        list(GET download_status 1 download_message)
        if(NOT download_code EQUAL 0)
            file(REMOVE "${download_path}")
            message(FATAL_ERROR
                "Failed to download ${label} yt-dlp: ${download_message} (${download_code})")
        endif()
    endif()

    set(${output_var} "${download_path}" PARENT_SCOPE)
endfunction()

set(FIAMY_EMBEDDED_YT_DLP_FILES)
if(FIAMY_EMBED_YT_DLP)
    fiamy_prepare_embedded_ytdlp(
        FIAMY_EMBEDDED_YT_DLP_LINUX
        "Linux x86_64"
        "yt-dlp_linux"
        "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux"
        "${FIAMY_YT_DLP_LINUX_PATH}"
    )
    fiamy_prepare_embedded_ytdlp(
        FIAMY_EMBEDDED_YT_DLP_LINUX_AARCH64
        "Linux aarch64"
        "yt-dlp_linux_aarch64"
        "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux_aarch64"
        "${FIAMY_YT_DLP_LINUX_AARCH64_PATH}"
    )
    fiamy_prepare_embedded_ytdlp(
        FIAMY_EMBEDDED_YT_DLP_MACOS
        "macOS"
        "yt-dlp_macos"
        "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos"
        "${FIAMY_YT_DLP_MACOS_PATH}"
    )
    fiamy_prepare_embedded_ytdlp(
        FIAMY_EMBEDDED_YT_DLP_WINDOWS
        "Windows"
        "yt-dlp.exe"
        "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"
        "${FIAMY_YT_DLP_WINDOWS_PATH}"
    )

    list(APPEND FIAMY_EMBEDDED_YT_DLP_FILES
        "${FIAMY_EMBEDDED_YT_DLP_LINUX}"
        "${FIAMY_EMBEDDED_YT_DLP_LINUX_AARCH64}"
        "${FIAMY_EMBEDDED_YT_DLP_MACOS}"
        "${FIAMY_EMBEDDED_YT_DLP_WINDOWS}"
    )
endif()

file(GLOB THIRD_PARTY_HEADERS "${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/*.h")
source_group(TREE "${CMAKE_CURRENT_SOURCE_DIR}/thirdparty" PREFIX "ThirdParty" FILES ${THIRD_PARTY_HEADERS})

qt_add_executable(Fiamy
    ${SRC}
    ${HEADERS}
    ${THIRD_PARTY_HEADERS}
)

set_target_properties(Fiamy PROPERTIES
    OUTPUT_NAME "fiamy"
)

if(APPLE)
    set(FIAMY_MACOS_ICON "" CACHE FILEPATH "Optional .icns icon to use for the macOS app bundle")

    set_target_properties(Fiamy PROPERTIES
        MACOSX_BUNDLE TRUE
        OUTPUT_NAME "Fiamy"
        MACOSX_BUNDLE_BUNDLE_NAME "Fiamy"
        MACOSX_BUNDLE_DISPLAY_NAME "Fiamy"
        MACOSX_BUNDLE_GUI_IDENTIFIER "com.fiammamuscari.fiamy"
        MACOSX_BUNDLE_SHORT_VERSION_STRING "${PROJECT_VERSION}"
        MACOSX_BUNDLE_BUNDLE_VERSION "${PROJECT_VERSION}"
        MACOSX_BUNDLE_COPYRIGHT "Copyright FiammaMuscari"
    )

    if(FIAMY_MACOS_ICON AND EXISTS "${FIAMY_MACOS_ICON}")
        get_filename_component(FIAMY_MACOS_ICON_NAME "${FIAMY_MACOS_ICON}" NAME)
        set_target_properties(Fiamy PROPERTIES
            MACOSX_BUNDLE_ICON_FILE "${FIAMY_MACOS_ICON_NAME}"
        )
        set_source_files_properties("${FIAMY_MACOS_ICON}" PROPERTIES
            MACOSX_PACKAGE_LOCATION "Resources"
        )
        target_sources(Fiamy PRIVATE "${FIAMY_MACOS_ICON}")
    endif()
endif()

if(WIN32)
    set_target_properties(Fiamy PROPERTIES
        WIN32_EXECUTABLE TRUE
    )
    set(ICON_RC "${CMAKE_CURRENT_BINARY_DIR}/icon.rc")
    file(WRITE ${ICON_RC} "IDI_ICON1 ICON DISCARDABLE \"${CMAKE_CURRENT_SOURCE_DIR}/pink.ico\"\n")
    target_sources(Fiamy PRIVATE ${ICON_RC})
endif()

target_include_directories(Fiamy PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty
)

set(FIAMY_QML_MODULE_OPTIONS
    NO_IMPORT_SCAN
)
if(COSMOPOLITAN)
    list(APPEND FIAMY_QML_MODULE_OPTIONS
        NO_CACHEGEN
    )
endif()

# 🔥 En Debug: NO empaquetar QML en recursos, usar archivos directos
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    message(STATUS "🔥 Modo DEBUG: Hot reload habilitado")
    add_compile_definitions(QT_QML_DEBUG)

    qt_add_qml_module(Fiamy
        URI Fiamy
        VERSION 1.0
        ${FIAMY_QML_MODULE_OPTIONS}
        QML_FILES ${QML_FILES}
        NO_RESOURCE_TARGET_PATH
    )

    # Copiar archivos QML al directorio de build
    foreach(QML_FILE ${QML_FILES})
        get_filename_component(QML_FILE_DIR ${QML_FILE} DIRECTORY)
        add_custom_command(TARGET Fiamy POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${CMAKE_CURRENT_SOURCE_DIR}/${QML_FILE}"
                "$<TARGET_FILE_DIR:Fiamy>/${QML_FILE}"
            COMMENT "Copiando ${QML_FILE} para hot reload"
        )
        # Crear directorios si no existen
        if(QML_FILE_DIR)
            add_custom_command(TARGET Fiamy POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E make_directory
                    "$<TARGET_FILE_DIR:Fiamy>/${QML_FILE_DIR}"
            )
        endif()
    endforeach()
else()
    # En Release: empaquetar normalmente en recursos
    message(STATUS "📦 Modo RELEASE: QML empaquetado en recursos")
    qt_add_qml_module(Fiamy
        URI Fiamy
        VERSION 1.0
        ${FIAMY_QML_MODULE_OPTIONS}
        QML_FILES ${QML_FILES}
    )
endif()

# Qt's QML import scanner walks the target source root. Keep local build and
# experiment outputs out of that scan, otherwise checked-out Qt sources under
# dist/ can be mistaken for application imports during packaging.
file(GLOB FIAMY_GENERATED_SCAN_DIRS
    LIST_DIRECTORIES true
    "${CMAKE_CURRENT_SOURCE_DIR}/build*"
    "${CMAKE_CURRENT_SOURCE_DIR}/dist"
)
set(FIAMY_QML_IMPORT_SCANNER_EXTRA_ARGS)
foreach(FIAMY_GENERATED_SCAN_DIR IN LISTS FIAMY_GENERATED_SCAN_DIRS)
    if(IS_DIRECTORY "${FIAMY_GENERATED_SCAN_DIR}")
        file(RELATIVE_PATH FIAMY_GENERATED_SCAN_DIR_REL
            "${CMAKE_CURRENT_SOURCE_DIR}"
            "${FIAMY_GENERATED_SCAN_DIR}"
        )
        list(APPEND FIAMY_QML_IMPORT_SCANNER_EXTRA_ARGS
            -exclude "${FIAMY_GENERATED_SCAN_DIR_REL}"
        )
    endif()
endforeach()
if(FIAMY_QML_IMPORT_SCANNER_EXTRA_ARGS)
    set_property(TARGET Fiamy PROPERTY
        QT_QML_IMPORT_SCANNER_EXTRA_ARGS ${FIAMY_QML_IMPORT_SCANNER_EXTRA_ARGS}
    )
endif()

qt_add_resources(Fiamy "resources"
    PREFIX "/"
    FILES ${RESOURCE_FILES}
)
if(FIAMY_EMBEDDED_YT_DLP_FILES)
    set(FIAMY_EMBEDDED_YT_DLP_ASM "${CMAKE_CURRENT_BINARY_DIR}/embedded_ytdlp.S")
    file(WRITE "${FIAMY_EMBEDDED_YT_DLP_ASM}" ".section .rodata\n")

    function(fiamy_append_embedded_ytdlp_asm symbol path)
        set(escaped_path "${path}")
        string(REPLACE "\\" "\\\\" escaped_path "${escaped_path}")
        string(REPLACE "\"" "\\\"" escaped_path "${escaped_path}")
        file(APPEND "${FIAMY_EMBEDDED_YT_DLP_ASM}"
            ".balign 16\n"
            ".globl ${symbol}_start\n"
            ".globl ${symbol}_end\n"
            "${symbol}_start:\n"
            ".incbin \"${escaped_path}\"\n"
            "${symbol}_end:\n"
        )
    endfunction()

    fiamy_append_embedded_ytdlp_asm(fiamy_embedded_ytdlp_linux "${FIAMY_EMBEDDED_YT_DLP_LINUX}")
    fiamy_append_embedded_ytdlp_asm(fiamy_embedded_ytdlp_linux_aarch64 "${FIAMY_EMBEDDED_YT_DLP_LINUX_AARCH64}")
    fiamy_append_embedded_ytdlp_asm(fiamy_embedded_ytdlp_macos "${FIAMY_EMBEDDED_YT_DLP_MACOS}")
    fiamy_append_embedded_ytdlp_asm(fiamy_embedded_ytdlp_windows "${FIAMY_EMBEDDED_YT_DLP_WINDOWS}")

    if(NOT COSMOPOLITAN)
        message(FATAL_ERROR "FIAMY_EMBED_YT_DLP currently requires the Cosmopolitan build")
    endif()

    set(FIAMY_COSMO_BIN_DIR "${CMAKE_CURRENT_SOURCE_DIR}/dist/tools/cosmocc/bin")
    set(FIAMY_EMBEDDED_YT_DLP_OBJ "${CMAKE_CURRENT_BINARY_DIR}/embedded_ytdlp.o")
    set(FIAMY_EMBEDDED_YT_DLP_AARCH64_OBJ
        "${CMAKE_CURRENT_BINARY_DIR}/.aarch64/embedded_ytdlp.o")
    add_custom_command(
        OUTPUT
            "${FIAMY_EMBEDDED_YT_DLP_OBJ}"
            "${FIAMY_EMBEDDED_YT_DLP_AARCH64_OBJ}"
        COMMAND "${CMAKE_COMMAND}" -E make_directory "${CMAKE_CURRENT_BINARY_DIR}/.aarch64"
        COMMAND "${FIAMY_COSMO_BIN_DIR}/x86_64-linux-cosmo-as"
            -o "${FIAMY_EMBEDDED_YT_DLP_OBJ}"
            "${FIAMY_EMBEDDED_YT_DLP_ASM}"
        COMMAND "${FIAMY_COSMO_BIN_DIR}/aarch64-linux-cosmo-as"
            -o "${FIAMY_EMBEDDED_YT_DLP_AARCH64_OBJ}"
            "${FIAMY_EMBEDDED_YT_DLP_ASM}"
        DEPENDS
            "${FIAMY_EMBEDDED_YT_DLP_ASM}"
            ${FIAMY_EMBEDDED_YT_DLP_FILES}
        COMMENT "Embedding yt-dlp binaries"
        VERBATIM
    )
    add_custom_target(fiamy_embedded_ytdlp_obj
        DEPENDS "${FIAMY_EMBEDDED_YT_DLP_OBJ}" "${FIAMY_EMBEDDED_YT_DLP_AARCH64_OBJ}")
    add_dependencies(Fiamy fiamy_embedded_ytdlp_obj)
    set_source_files_properties("${FIAMY_EMBEDDED_YT_DLP_OBJ}"
        PROPERTIES EXTERNAL_OBJECT TRUE GENERATED TRUE)
    target_sources(Fiamy PRIVATE "${FIAMY_EMBEDDED_YT_DLP_OBJ}")
    target_compile_definitions(Fiamy PRIVATE FIAMY_EMBEDDED_YT_DLP=1)
endif()

add_library(miniaudio INTERFACE)
target_include_directories(miniaudio INTERFACE
    ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty
)

target_link_libraries(Fiamy PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::QmlIntegration
    Qt6::Qml
    Qt6::QmlModels
    Qt6::QmlWorkerScript
    Qt6::QmlMeta
    Qt6::Quick
    Qt6::QuickTemplates2
    Qt6::QuickControls2
    Qt6::Multimedia
    miniaudio
)

if(COSMOPOLITAN)
    if(NOT QT_COSMO_PREFIX)
        message(FATAL_ERROR "Set QT_COSMO_PREFIX to the Qt Cosmopolitan install prefix.")
    endif()

    find_package(Qt6QCosmoNativeIntegrationPlugin CONFIG REQUIRED
        PATHS "${QT_COSMO_PREFIX}/lib/cmake/Qt6Gui"
        NO_DEFAULT_PATH
    )
    find_package(Qt6QFFmpegMediaPlugin CONFIG REQUIRED
        PATHS "${QT_COSMO_PREFIX}/lib/cmake/Qt6Multimedia"
        NO_DEFAULT_PATH
    )

    file(GLOB qt_qml_plugin_configs CONFIGURE_DEPENDS
        "${QT_COSMO_PREFIX}/lib/cmake/Qt6Qml/QmlPlugins/*Config.cmake"
    )
    foreach(qt_qml_plugin_config IN LISTS qt_qml_plugin_configs)
        get_filename_component(qt_qml_plugin_package "${qt_qml_plugin_config}" NAME_WE)
        string(REGEX REPLACE "Config$" "" qt_qml_plugin_package "${qt_qml_plugin_package}")
        find_package(${qt_qml_plugin_package} CONFIG QUIET
            PATHS "${QT_COSMO_PREFIX}/lib/cmake/Qt6Qml/QmlPlugins"
            NO_DEFAULT_PATH
        )
    endforeach()

    target_link_libraries(Fiamy PRIVATE
        Qt6::Widgets
        Qt6::QmlPrivate
        Qt6::QmlModelsPrivate
        Qt6::QmlWorkerScriptPrivate
        Qt6::QmlMetaPrivate
        Qt6::QmlCore
        Qt6::QmlCorePrivate
        Qt6::GuiPrivate
        Qt6::MultimediaQuickPrivate
        Qt6::QuickPrivate
        Qt6::QuickLayouts
        Qt6::QuickControls2Impl
        Qt6::QuickTemplates2Private
        Qt6::QuickControls2BasicStyleImpl
        Qt6::QuickControls2Basic
        Qt6::QuickControls2FusionStyleImpl
        Qt6::QuickControls2Fusion
        Qt6::QuickControls2MaterialStyleImpl
        Qt6::QuickControls2Material
        Qt6::QuickControls2ImagineStyleImpl
        Qt6::QuickControls2Imagine
        Qt6::QuickControls2UniversalStyleImpl
        Qt6::QuickControls2Universal
        Qt6::QuickControls2FluentWinUI3StyleImpl
        Qt6::LabsPlatform
        Qt6::qmlplugin
        Qt6::qtqmlcoreplugin
        Qt6::modelsplugin
        Qt6::workerscriptplugin
        Qt6::qtquick2plugin
        Qt6::quickwindow
        Qt6::qquicklayoutsplugin
        Qt6::qtquicktemplates2plugin
        Qt6::qtquickcontrols2plugin
        Qt6::qtquickcontrols2implplugin
        Qt6::qtquickcontrols2basicstyleplugin
        Qt6::qtquickcontrols2basicstyleimplplugin
        Qt6::quickmultimedia
        Qt6::LabsPlatformplugin
    )
    target_link_options(Fiamy PRIVATE LINKER:--allow-multiple-definition)

    qt_import_plugins(Fiamy
        EXCLUDE_BY_TYPE
            platforms
        INCLUDE
            Qt6::QCosmoNativeIntegrationPlugin
            Qt6::QFFmpegMediaPlugin
    )
endif()

if(WIN32)
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

if(UNIX AND NOT APPLE)
    include(GNUInstallDirs)

    set(FIAMY_LINUX_DESKTOP_TEMPLATE "${CMAKE_CURRENT_SOURCE_DIR}/platform/linux/fiamy.desktop.in")
    set(FIAMY_LINUX_DESKTOP_FILE "${CMAKE_CURRENT_BINARY_DIR}/fiamy.desktop")
    configure_file("${FIAMY_LINUX_DESKTOP_TEMPLATE}" "${FIAMY_LINUX_DESKTOP_FILE}" @ONLY)

    install(TARGETS Fiamy RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
    qt_generate_deploy_app_script(
        TARGET Fiamy
        OUTPUT_SCRIPT FiamyDeployScript
        NO_UNSUPPORTED_PLATFORM_ERROR
    )
    install(SCRIPT "${FiamyDeployScript}")
    install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/pink.png"
        DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/256x256/apps"
        RENAME fiamy.png
    )
    install(FILES "${FIAMY_LINUX_DESKTOP_FILE}"
        DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/applications"
    )

    set(FIAMY_BUNDLED_YT_DLP "" CACHE FILEPATH "Optional standalone yt-dlp executable to bundle with Linux packages")
    find_program(FIAMY_YT_DLP_EXECUTABLE yt-dlp)

    if(FIAMY_BUNDLED_YT_DLP AND EXISTS "${FIAMY_BUNDLED_YT_DLP}")
        install(PROGRAMS "${FIAMY_BUNDLED_YT_DLP}"
            DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/fiamy"
            RENAME yt-dlp
        )
        message(STATUS "Bundling standalone yt-dlp from ${FIAMY_BUNDLED_YT_DLP}")
    elseif(FIAMY_YT_DLP_EXECUTABLE)
        install(PROGRAMS "${FIAMY_YT_DLP_EXECUTABLE}"
            DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/fiamy"
            RENAME yt-dlp
        )
        message(STATUS "Bundling yt-dlp from ${FIAMY_YT_DLP_EXECUTABLE}")
    else()
        message(STATUS "yt-dlp no encontrado en PATH - Linux usará el auto-descargador en tiempo de ejecución")
    endif()

    set(CPACK_GENERATOR "DEB")
    set(CPACK_PACKAGE_NAME "fiamy")
    set(CPACK_PACKAGE_VENDOR "FiammaMuscari")
    set(CPACK_PACKAGE_CONTACT "fiammamuscari@gmail.com")
    set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Fiamy MP3 and YouTube player")
    set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
    set(CPACK_DEBIAN_PACKAGE_MAINTAINER "fiammamuscari")
    set(CPACK_DEBIAN_PACKAGE_SECTION "multimedia")
    set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
    set(CPACK_DEBIAN_FILE_NAME "DEB-DEFAULT")

    set(FIAMY_DEB_DISTRO_TAG "" CACHE STRING "Optional distro suffix for generated DEB names, e.g. trixie")
    if(FIAMY_DEB_DISTRO_TAG)
        string(REGEX REPLACE "[^A-Za-z0-9.+-]" "-" FIAMY_DEB_DISTRO_TAG_SAFE "${FIAMY_DEB_DISTRO_TAG}")
        set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}_${PROJECT_VERSION}_${FIAMY_DEB_DISTRO_TAG_SAFE}_${CMAKE_SYSTEM_PROCESSOR}")
    endif()

    include(CPack)
endif()
