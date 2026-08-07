#!/bin/bash

set -e
set -x

ENV_FILE=/tmp/env.sh

. ${ENV_FILE}

# setup MODULE_SRC_DIR env var
cwd=`pwd`
if [ -z "${MODULE_SRC_DIR}" ]; then
    if [ -e "$cwd/src/PdfDocument.cpp" ]; then
        MODULE_SRC_DIR=$cwd
    else
        MODULE_SRC_DIR=$WORKDIR/module-pdf
    fi
fi
echo "export MODULE_SRC_DIR=${MODULE_SRC_DIR}" >> ${ENV_FILE}

echo "export QORE_UID=1000" >> ${ENV_FILE}
echo "export QORE_GID=1000" >> ${ENV_FILE}

. ${ENV_FILE}

export MAKE_JOBS=4

# install additional dependencies for testing
apk add --no-cache qpdf qpdf-dev freetype-dev

# locate PDFium prebuilt
PDFIUM_ROOT=${PDFIUM_ROOT:-/opt/pdfium}
PDFIUM_INCLUDE_DIR=${PDFIUM_INCLUDE_DIR:-${PDFIUM_ROOT}/include}
PDFIUM_LIBRARY=${PDFIUM_LIBRARY:-}
if [ -z "${PDFIUM_LIBRARY}" ]; then
    if [ -f "${PDFIUM_ROOT}/lib/libpdfium.so" ]; then
        PDFIUM_LIBRARY="${PDFIUM_ROOT}/lib/libpdfium.so"
    elif [ -f "${PDFIUM_ROOT}/lib/libpdfium.a" ]; then
        PDFIUM_LIBRARY="${PDFIUM_ROOT}/lib/libpdfium.a"
    elif [ -f /usr/lib/libpdfium.so ]; then
        PDFIUM_LIBRARY=/usr/lib/libpdfium.so
    elif [ -f /usr/lib/libpdfium.a ]; then
        PDFIUM_LIBRARY=/usr/lib/libpdfium.a
    fi
fi
if [ ! -d "${PDFIUM_INCLUDE_DIR}" ]; then
    echo "PDFium include directory not found: ${PDFIUM_INCLUDE_DIR}" >&2
    exit 1
fi
if [ ! -f "${PDFIUM_LIBRARY}" ]; then
    echo "PDFium library not found in image" >&2
    exit 1
fi

# build module and install
echo && echo "-- building module --"
mkdir -p ${MODULE_SRC_DIR}/build
cd ${MODULE_SRC_DIR}/build
cmake .. -DCMAKE_BUILD_TYPE=debug -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
    -DENABLE_PDFIUM=ON \
    -DPDFIUM_INCLUDE_DIR="${PDFIUM_INCLUDE_DIR}" \
    -DPDFIUM_LIBRARY="${PDFIUM_LIBRARY}"
make -j${MAKE_JOBS}
make install

# Verify that source-owned provider presentation catalogs match this checkout.
${MODULE_SRC_DIR}/test/docker_test/check-i18n.sh

# add Qore user and group
if ! grep -q "^qore:x:${QORE_GID}" /etc/group; then
    addgroup -g ${QORE_GID} qore
fi
if ! grep -q "^qore:x:${QORE_UID}" /etc/passwd; then
    adduser -u ${QORE_UID} -D -G qore -h /home/qore -s /bin/bash qore
fi

# own everything by the qore user
chown -R qore:qore ${MODULE_SRC_DIR}

# run the tests
export QORE_MODULE_DIR=${MODULE_SRC_DIR}/qlib:${QORE_MODULE_DIR}
cd ${MODULE_SRC_DIR}
for test in test/*.qtest; do
    gosu qore:qore qore --enable-debug $test -vv
done
