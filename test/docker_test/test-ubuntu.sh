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

echo "export QORE_UID=999" >> ${ENV_FILE}
echo "export QORE_GID=999" >> ${ENV_FILE}

. ${ENV_FILE}

export MAKE_JOBS=4

# install additional dependencies for testing
apt-get update
apt-get install -y qpdf libqpdf-dev libfreetype-dev

# locate PDFium prebuilt
PDFIUM_INCLUDE_DIR=/usr/include
PDFIUM_LIBRARY=
libdirs=()
if command -v dpkg-architecture >/dev/null 2>&1; then
    libdirs+=("/usr/lib/$(dpkg-architecture -qDEB_HOST_MULTIARCH)")
fi
libdirs+=("/usr/lib/x86_64-linux-gnu" "/usr/lib/aarch64-linux-gnu")
for libdir in "${libdirs[@]}"; do
    if [ -f "${libdir}/libpdfium.so" ]; then
        PDFIUM_LIBRARY="${libdir}/libpdfium.so"
        break
    elif [ -f "${libdir}/libpdfium.a" ]; then
        PDFIUM_LIBRARY="${libdir}/libpdfium.a"
        break
    fi
done
if [ -z "${PDFIUM_LIBRARY}" ]; then
    if [ -f /usr/lib64/libpdfium.so ]; then
        PDFIUM_LIBRARY=/usr/lib64/libpdfium.so
    elif [ -f /usr/lib/libpdfium.so ]; then
        PDFIUM_LIBRARY=/usr/lib/libpdfium.so
    elif [ -f /usr/lib64/libpdfium.a ]; then
        PDFIUM_LIBRARY=/usr/lib64/libpdfium.a
    elif [ -f /usr/lib/libpdfium.a ]; then
        PDFIUM_LIBRARY=/usr/lib/libpdfium.a
    fi
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
    -DPDFIUM_INCLUDE_DIR=${PDFIUM_INCLUDE_DIR} \
    -DPDFIUM_LIBRARY=${PDFIUM_LIBRARY}
make -j${MAKE_JOBS}
make install

# add Qore user and group
groupadd -o -g ${QORE_GID} qore
useradd -o -m -d /home/qore -u ${QORE_UID} -g ${QORE_GID} qore

# own everything by the qore user
chown -R qore:qore ${MODULE_SRC_DIR}

# run the tests
export QORE_MODULE_DIR=${MODULE_SRC_DIR}/qlib:${QORE_MODULE_DIR}
cd ${MODULE_SRC_DIR}
for test in test/*.qtest; do
    gosu qore:qore qore --enable-debug $test -vv
done
