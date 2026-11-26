# LM4BSD BEGIN ADDITION — Private dependencies for the OpenBSD source build and port.
set(LM_OPENBSD_DISTFILES "${CMAKE_BINARY_DIR}/_deps/openbsd-distfiles" CACHE PATH
  "Directory containing the OpenBSD dependency sources and grammar archives")
set(LM_TREE_SITTER_DOWNLOAD_DIR "${LM_OPENBSD_DISTFILES}" CACHE PATH
  "Folder of the Tree-sitter grammar source archives")

function(lm_openbsd_distfile filename sha256 url)
  set(path "${LM_OPENBSD_DISTFILES}/${filename}")
  if(EXISTS "${path}")
    file(SHA256 "${path}" actual)
    if(NOT actual STREQUAL sha256)
      message(FATAL_ERROR "Incorrect SHA-256 for ${path}. Remove it or replace it with the verified source.")
    endif()
  elseif(FETCHCONTENT_FULLY_DISCONNECTED)
    message(FATAL_ERROR "Missing offline dependency: ${path}")
  else()
    file(MAKE_DIRECTORY "${LM_OPENBSD_DISTFILES}")
    # Only a complete file with the pinned hash becomes visible in the cache.
    string(RANDOM LENGTH 12 suffix)
    set(temp "${path}.${suffix}.tmp")
    message(STATUS "Downloading ${filename}")
    file(DOWNLOAD "${url}" "${temp}" TLS_VERIFY ON STATUS status)
    list(GET status 0 code)
    if(code EQUAL 0)
      file(SHA256 "${temp}" actual)
    endif()
    if(NOT code EQUAL 0 OR NOT actual STREQUAL sha256)
      file(REMOVE "${temp}")
      message(FATAL_ERROR "Could not obtain verified ${filename} from ${url}: ${status}. The expected SHA-256 is ${sha256}.")
    endif()
    file(RENAME "${temp}" "${path}")
  endif()
endfunction()

set(openbsd_pins "${CMAKE_CURRENT_LIST_DIR}/distfiles.list")
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${openbsd_pins}")
file(STRINGS "${openbsd_pins}" openbsd_distfiles REGEX "^[a-z]")
foreach(entry IN LISTS openbsd_distfiles)
  separate_arguments(fields UNIX_COMMAND "${entry}")
  lm_openbsd_distfile(${fields})
endforeach()

# Scope Poco's static/unbundled build options to this dependency. EXCLUDE_FROM_ALL
# keeps Poco's package, headers and private archive out of cmake --install.
function(lm_openbsd_poco)
  set(archive "${LM_OPENBSD_DISTFILES}/poco-1.15.4.tar.gz")
  set(source "${CMAKE_BINARY_DIR}/_deps/poco-6a5667f432e1c5fe5591025ab03a2f8df37116b4")
  set(patch_file "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/poco-openbsd.patch")
  set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${patch_file}")
  file(SHA256 "${patch_file}" patch_sha)
  if(NOT EXISTS "${source}/.libremerge-${patch_sha}")
    file(REMOVE_RECURSE "${source}")
    file(ARCHIVE_EXTRACT INPUT "${archive}" DESTINATION "${CMAKE_BINARY_DIR}/_deps")
    execute_process(COMMAND patch -s -p1 -i "${patch_file}" WORKING_DIRECTORY "${source}"
      COMMAND_ERROR_IS_FATAL ANY)
    file(TOUCH "${source}/.libremerge-${patch_sha}")
  endif()
  set(BUILD_SHARED_LIBS OFF)
  set(POCO_MINIMAL_BUILD ON)
  set(POCO_UNBUNDLED ON)
  set(ENABLE_FASTLOGGER OFF)
  add_subdirectory("${source}" "${CMAKE_BINARY_DIR}/_deps/poco-build" EXCLUDE_FROM_ALL)
endfunction()
lm_openbsd_poco()

# These variables also satisfy the engine's find_program/find_file checks.
add_executable(libremerge-lemon "${LM_OPENBSD_DISTFILES}/lemon-3.54.1.c")
set(LEMON_EXECUTABLE libremerge-lemon)
set(LEMON_TEMPLATE "${LM_OPENBSD_DISTFILES}/lempar-3.54.1.c")
include(GNUInstallDirs)
install(FILES "${CMAKE_CURRENT_LIST_DIR}/openbsd-dependencies.txt"
  DESTINATION "${CMAKE_INSTALL_DATADIR}/doc/libremerge")
# LM4BSD END
