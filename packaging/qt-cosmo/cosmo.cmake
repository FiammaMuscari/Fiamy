set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR x86_64)
set(COSMOPOLITAN TRUE)

if(NOT DEFINED COSMOCC_ROOT)
    get_filename_component(_toolchain_dir "${CMAKE_CURRENT_LIST_FILE}" DIRECTORY)
    get_filename_component(_repo_root "${_toolchain_dir}/../.." ABSOLUTE)
    set(COSMOCC_ROOT "${_repo_root}/dist/tools/cosmocc" CACHE PATH "Cosmopolitan toolchain root")
endif()

set(_cosmo_bin "${COSMOCC_ROOT}/bin")

set(CMAKE_C_COMPILER "${_cosmo_bin}/x86_64-unknown-cosmo-cc")
set(CMAKE_CXX_COMPILER "${_cosmo_bin}/x86_64-unknown-cosmo-c++")
set(CMAKE_AR "${_cosmo_bin}/x86_64-linux-cosmo-ar")
set(CMAKE_RANLIB "${_cosmo_bin}/x86_64-linux-cosmo-ranlib")
set(CMAKE_OBJCOPY "${_cosmo_bin}/x86_64-linux-cosmo-objcopy")
set(CMAKE_STRIP "${_cosmo_bin}/x86_64-linux-cosmo-strip")

set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
set(CMAKE_EXECUTABLE_SUFFIX ".com" CACHE STRING "Cosmopolitan executable suffix" FORCE)
set(CMAKE_EXECUTABLE_SUFFIX_C ".com" CACHE STRING "Cosmopolitan C executable suffix" FORCE)
set(CMAKE_EXECUTABLE_SUFFIX_CXX ".com" CACHE STRING "Cosmopolitan C++ executable suffix" FORCE)


set(CMAKE_FIND_ROOT_PATH "${COSMOCC_ROOT}")
if(QT_COSMO_PREFIX)
    list(PREPEND CMAKE_FIND_ROOT_PATH "${QT_COSMO_PREFIX}")
endif()
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

set(CMAKE_FIND_USE_SYSTEM_PACKAGE_REGISTRY FALSE)
set(CMAKE_FIND_USE_PACKAGE_REGISTRY FALSE)
