cmake_minimum_required(VERSION 3.5.0)

project(qore-pdf-module)

set(VERSION_MAJOR 1)
set(VERSION_MINOR 0)
set(VERSION_PATCH 0)

set(PROJECT_VERSION "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}")

if (${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.12.0")
    cmake_policy(SET CMP0074 NEW)

    if (${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.18.0")
        cmake_policy(SET CMP0053 NEW)
    endif()
endif()

cmake_policy(SET CMP0042 NEW)

if (UNIX AND NOT APPLE)
    set(LINUX TRUE)
endif()

find_package(Qore 2.0 REQUIRED)
find_package(PkgConfig REQUIRED)

pkg_check_modules(QPDF REQUIRED libqpdf)
if (pkgcfg_lib_QPDF_qpdf)
    # Prefer absolute library path from pkg-config to avoid missing -L paths on macOS.
    set(QPDF_LIBRARIES ${pkgcfg_lib_QPDF_qpdf})
endif()

option(USE_BUNDLED_PODOFO "Use bundled PoDoFo sources" ON)
set(PODOFO_BUNDLED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/third_party/podofo")

if (USE_BUNDLED_PODOFO AND EXISTS "${PODOFO_BUNDLED_DIR}/CMakeLists.txt")
    set(PODOFO_BUILD_LIB_ONLY TRUE CACHE BOOL "" FORCE)
    set(PODOFO_BUILD_TEST FALSE CACHE BOOL "" FORCE)
    set(PODOFO_BUILD_EXAMPLES FALSE CACHE BOOL "" FORCE)
    set(PODOFO_BUILD_UNSUPPORTED_TOOLS FALSE CACHE BOOL "" FORCE)
    set(PODOFO_BUILD_DOC_ONLY FALSE CACHE BOOL "" FORCE)

    add_subdirectory("${PODOFO_BUNDLED_DIR}" third_party/podofo EXCLUDE_FROM_ALL)
    set(PODOFO_INCLUDE_DIRS
        "${PODOFO_BUNDLED_DIR}/src"
        "${CMAKE_CURRENT_BINARY_DIR}/third_party/podofo/src/podofo/podofo/auxiliary"
    )
    set(PODOFO_LIBRARIES podofo::podofo)
    set(PODOFO_CFLAGS "")
else()
    pkg_check_modules(PODOFO REQUIRED libpodofo)
endif()

option(ENABLE_PDFIUM "Enable PDFium rendering/text extraction" ON)
set(PDFIUM_FOUND OFF)

if (ENABLE_PDFIUM)
    find_path(PDFIUM_INCLUDE_DIR NAMES fpdfview.h)
    find_library(PDFIUM_LIBRARY NAMES pdfium)

    if (PDFIUM_INCLUDE_DIR AND PDFIUM_LIBRARY)
        set(PDFIUM_FOUND ON)
    else()
        message(STATUS "PDFium not found; rendering/text extraction disabled")
    endif()
endif()

include(CheckCXXCompilerFlag)
CHECK_CXX_COMPILER_FLAG("-std=c++17" COMPILER_SUPPORTS_CXX17)
if(COMPILER_SUPPORTS_CXX17)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++17")
else()
    message(FATAL_ERROR "The compiler ${CMAKE_CXX_COMPILER} has no C++17 support.")
endif()

set(QPP_SRC
    src/QC_PdfDocument.qpp
    src/QC_PdfPage.qpp
    src/QC_PdfReader.qpp
    src/QC_PdfWriter.qpp
    src/QC_PdfRenderer.qpp
    src/QC_PdfEditor.qpp
)

set(CPP_SRC
    src/pdf-module.cpp
    src/PdfDocument.cpp
    src/PdfReader.cpp
    src/PdfWriter.cpp
    src/PdfRenderer.cpp
    src/PdfEditor.cpp
)

qore_wrap_qpp_value(QPP_SOURCES METALIST QPP_META_SRC ${QPP_SRC})

foreach (it ${QPP_SOURCES})
    GET_FILENAME_COMPONENT(_outfile ${it} NAME_WE)
    set(QPP_DOX ${QPP_DOX} ${CMAKE_CURRENT_BINARY_DIR}/${_outfile}.dox.h)
endforeach()

set(module_name "pdf")

set(QMOD
    qlib/PdfDataProvider
)

set(QORE_DOX_TMPL_SRC
  docs/mainpage.dox.tmpl
  docs/release-notes.doxygen.tmpl
)

add_library(${module_name} MODULE ${CPP_SRC} ${QPP_SOURCES})

include_directories(${CMAKE_SOURCE_DIR}/src)
include_directories(${QPDF_INCLUDE_DIRS})
include_directories(${PODOFO_INCLUDE_DIRS})
if (QPDF_LIBRARY_DIRS)
    link_directories(${QPDF_LIBRARY_DIRS})
endif()
if (PODOFO_LIBRARY_DIRS)
    link_directories(${PODOFO_LIBRARY_DIRS})
endif()

target_include_directories(${module_name} PRIVATE $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>)

add_custom_target(QORE_INC_FILES DEPENDS ${QORE_INC_SRC})
add_dependencies(${module_name} QORE_INC_FILES)

target_link_libraries(${module_name} ${QORE_LIBRARY} ${QPDF_LIBRARIES} ${PODOFO_LIBRARIES})

if (USE_BUNDLED_PODOFO)
    # Keep the bundled PoDoFo next to the module so the loader can find it.
    # $ORIGIN is Linux-only; macOS uses @loader_path for the same purpose.
    if (APPLE)
        set(_rpath_origin "@loader_path")
    else()
        set(_rpath_origin "$ORIGIN")
    endif()
    set_target_properties(${module_name} PROPERTIES
        BUILD_RPATH "${_rpath_origin}"
        INSTALL_RPATH "${_rpath_origin}"
    )
    install(TARGETS podofo_shared
        LIBRARY DESTINATION ${QORE_MODULES_DIR}
    )
endif()

if (PDFIUM_FOUND)
    target_include_directories(${module_name} PRIVATE ${PDFIUM_INCLUDE_DIR})
    target_link_libraries(${module_name} ${PDFIUM_LIBRARY})
    target_compile_definitions(${module_name} PRIVATE HAVE_PDFIUM=1)

    get_filename_component(PDFIUM_LIBRARY_DIR "${PDFIUM_LIBRARY}" DIRECTORY)
    if (PDFIUM_LIBRARY_DIR)
        get_target_property(_pdf_build_rpath ${module_name} BUILD_RPATH)
        if (NOT _pdf_build_rpath OR _pdf_build_rpath MATCHES "-NOTFOUND$")
            set(_pdf_build_rpath "")
        endif()
        get_target_property(_pdf_install_rpath ${module_name} INSTALL_RPATH)
        if (NOT _pdf_install_rpath OR _pdf_install_rpath MATCHES "-NOTFOUND$")
            set(_pdf_install_rpath "")
        endif()
        list(APPEND _pdf_build_rpath "${PDFIUM_LIBRARY_DIR}")
        list(APPEND _pdf_install_rpath "${PDFIUM_LIBRARY_DIR}")
        list(REMOVE_DUPLICATES _pdf_build_rpath)
        list(REMOVE_DUPLICATES _pdf_install_rpath)
        set_target_properties(${module_name} PROPERTIES
            BUILD_RPATH "${_pdf_build_rpath}"
            INSTALL_RPATH "${_pdf_install_rpath}"
        )
    endif()
endif()

string(REPLACE ";" " " QPDF_CFLAGS "${QPDF_CFLAGS}")
string(REPLACE ";" " " PODOFO_CFLAGS "${PODOFO_CFLAGS}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${QPDF_CFLAGS} ${PODOFO_CFLAGS}")

set(MODULE_DOX_INPUT ${CMAKE_CURRENT_BINARY_DIR}/mainpage.dox ${QPP_DOX})
string(REPLACE ";" " " MODULE_DOX_INPUT "${MODULE_DOX_INPUT}")

if (DEFINED ENV{DOXYGEN_EXECUTABLE})
    set(DOXYGEN_EXECUTABLE $ENV{DOXYGEN_EXECUTABLE})
endif()

set(MODULE_DOX_INPUT ${CMAKE_BINARY_DIR})
qore_external_binary_module(${module_name} ${PROJECT_VERSION})

qore_dist(${PROJECT_VERSION})

qore_user_modules("${QMOD}")
qore_external_user_module("qlib/PdfDataProvider" "")

# Reconcile the installed i18n catalog root against the fragments these modules
# currently own.  Installing catalogs is otherwise additive: a fragment installed by
# an earlier generation of these sources survives every later install, is still
# discovered, and makes catalog composition fail as soon as the current generation
# describes the same app differently.
#
# This must come after every call above that installs catalogs, both because those
# calls record the fragment set and because install() rules run in declaration order,
# which is what publishes the manifest after the fragments it describes.  Removals are
# scoped to this project, so fragments Qore and other products install into the same
# shared catalog root are untouched.  Guarded because the helper arrived in Qore 2.3.
if (COMMAND qore_finalize_catalog_install)
    qore_finalize_catalog_install()
endif()

# install qpp metadata files
if (COMMAND qore_install_qpp_metadata)
    qore_install_qpp_metadata(${module_name} ${QPP_META_SRC})
else()
    install(FILES ${QPP_META_SRC}
            DESTINATION ${CMAKE_INSTALL_DATADIR}/qore/metadata)
endif()

qore_config_info()

if (DOXYGEN_FOUND)
    qore_wrap_dox(QORE_DOX_SRC ${QORE_DOX_TMPL_SRC})
    add_custom_target(QORE_MOD_DOX_FILES DEPENDS ${QORE_DOX_SRC})
    add_dependencies(docs-module QORE_MOD_DOX_FILES)
endif()
