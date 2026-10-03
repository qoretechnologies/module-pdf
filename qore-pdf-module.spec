# Copyright (C) 2026 Qore Technologies, s.r.o.
# SPDX-License-Identifier: MIT
%global source_date_epoch_from_changelog 1
%global use_source_date_epoch_as_buildtime 1
%if v"%{rpmversion}" >= v"4.20"
%global build_mtime_policy clamp_to_source_date_epoch
%else
%global clamp_mtime_to_source_date_epoch 1
%endif
%bcond_without tests
%bcond_without docs
%global _find_debuginfo_dwz_opts %{nil}
Name: qore-pdf-module
Version: 1.0.0
Release: 1%{?dist}
Summary: PDF documents, rendering and data providers for Qore
License: MIT AND LGPL-2.0-or-later AND Apache-2.0 AND BSD-3-Clause AND BSL-1.0 AND Unicode-DFS-2015
URL: https://github.com/qoretechnologies/module-pdf
Source0: %{name}-%{version}.tar.xz
Provides: bundled(podofo) = 1.0.3
BuildRequires: cmake >= 3.23
BuildRequires: make
BuildRequires: gcc-c++
BuildRequires: pkgconfig(libqpdf)
BuildRequires: pkgconfig(pdfium-qore) >= 148.0.7778
BuildRequires: pkgconfig(freetype2)
BuildRequires: pkgconfig(openssl)
BuildRequires: pkgconfig(libxml-2.0)
BuildRequires: pkgconfig(fontconfig)
BuildRequires: pkgconfig(libpng)
# Match the JPEG ABI used by openSUSE QPDF and TIFF.
%if 0%{?suse_version}
BuildRequires: libjpeg8-devel
%else
BuildRequires: pkgconfig(libjpeg)
%endif
BuildRequires: pkgconfig(libtiff-4)
BuildRequires: pkgconfig(zlib)
BuildRequires: pkgconfig(lcms2)
BuildRequires: qore-devel >= 3.0.0~
BuildRequires: qore-rpm-macros >= 3.0.0~
%if %{with tests}
BuildRequires: python3
BuildRequires: qpdf
BuildRequires: openssl
BuildRequires: qore-misc-tools >= 3.0.0~
%if 0%{?suse_version}
BuildRequires: dejavu-fonts
%else
BuildRequires: dejavu-sans-fonts
%endif
%endif
%if %{with docs}
BuildRequires: doxygen
%if 0%{?suse_version}
BuildRequires: util-linux
%else
BuildRequires: util-linux-core
%endif
%endif
%{?qore_enable_aot_post}

%description
PDF creation, reading, editing, rendering, text extraction, forms, encryption
and signatures. Includes the native module, source and compiled PdfDataProvider,
compiler metadata, provider resources and translations. PoDoFo is linked
privately; PDFium rendering support is required.

%if %{with docs}
%package doc
Summary: Qore PDF API references and examples
BuildArch: noarch
%description doc
HTML API references and examples for the PDF native module and PdfDataProvider.
%endif

%prep
%autosetup

%build
%{?set_build_flags}
. %{_rpmconfigdir}/qore/module-env.sh
qore_set_source_prefix_maps "%{qore_debug_source_dir}"
cmake -S . -B build -G 'Unix Makefiles' \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS_RELEASE=-DNDEBUG \
  -DCMAKE_INSTALL_PREFIX=%{_prefix} -DCMAKE_INSTALL_LIBDIR=%{_lib} \
  -DCMAKE_SKIP_RPATH=ON -DCMAKE_SKIP_INSTALL_RPATH=ON \
  -DCMAKE_IGNORE_PREFIX_PATH=/usr/local \
  -DQore_DIR=%{_libdir}/cmake/Qore -DQORE_EXECUTABLE=/usr/bin/qore \
  -DQORE_QPP_EXECUTABLE=/usr/bin/qpp -DQORE_QCC_EXECUTABLE=/usr/bin/qcc \
  -DUSE_BUNDLED_PODOFO=ON -DPODOFO_WANT_LCMS2=ON \
  -DENABLE_PDFIUM=ON -DREQUIRE_PDFIUM=ON \
  -DQORE_BUILD_AOT_MODULES=ON -DQORE_AOT_LINK_SOURCE_MODULES=OFF \
  -DQORE_AOT_MODULE_OPT_LEVEL=3 -DQORE_GENERATE_JAVA_BINDINGS=OFF \
  -DQORE_QM_METADATA_ENV:STRING="QORE_MODULE_DIR=$PWD/build:$PWD/build/qlib-qmod:$PWD/qlib:$QORE_MODULE_DIR;QORE_MODULE_DIR_ONLY=1;QORE_INCLUDE_DIR=;LD_LIBRARY_PATH=" \
  -DCMAKE_DISABLE_FIND_PACKAGE_Doxygen=%{!?with_docs:ON}%{?with_docs:OFF}
cmake --build build -- %{?_smp_mflags}
%if %{with docs}
cmake --build build --target docs -- %{?_smp_mflags}
%endif

%install
DESTDIR=%{buildroot} cmake --install build
%qore_install_aot_sources qlib
find %{buildroot}%{_libdir}/qore-modules -type f -name '*.qmod' -exec chmod 755 {} +
%if %{with docs}
install -d %{buildroot}%{_docdir}/%{name}-doc
cp -a build/docs %{buildroot}%{_docdir}/%{name}-doc/
cp -a test %{buildroot}%{_docdir}/%{name}-doc/examples
# Installed examples use the packaged interpreter, independent of PATH.
sed -i '1s|^#!/usr/bin/env qore$|#!/usr/bin/qore|' \
  %{buildroot}%{_docdir}/%{name}-doc/examples/*.qtest
hardlink -t -O %{buildroot}%{_docdir}/%{name}-doc
%endif

%check
%if %{with tests}
. %{_rpmconfigdir}/qore/module-env.sh
export QORE_MODULE_DIR="$PWD/build:$PWD/build/qlib-qmod:$QORE_MODULE_DIR"
export QORE_PDF_REQUIRE_PDFIUM=1
python3 -B -W error debian/tests/test_aot_metadata.py
python3 -B -W error test/test_uninstall.py
cmake --build build --target pdf-content-xobject-test -- %{?_smp_mflags}
build/pdf-content-xobject-test
for suite in test/*.qtest; do
  timeout 300 /usr/bin/qore -b --enable-debug \
    -l "$PWD/build/pdf-api-$(/usr/bin/qore --latest-module-api).qmod" \
    -l "$PWD/build/qlib-qmod/PdfDataProvider/PdfDataProvider.qmod" "$suite" -v
done
qore-data-provider-i18n --no-color --check-source-tree --require-standard-locales \
  --require-complete-locales --output "$PWD/qlib"
%endif

%files
%license LICENSE rpm/licenses/* third_party/podofo/COPYING
%doc README.md docs/THIRD_PARTY.md
%{_libdir}/qore-modules/*
%{_datadir}/qore-modules/*
%{_datadir}/qore/metadata/*
%{_datadir}/qore/i18n/
%if %{with docs}
%files doc
%license LICENSE rpm/licenses/*
%doc %{_docdir}/%{name}-doc/
%endif

%changelog
* Sat Oct 03 2026 David Nichols <david@qore.org> - 1.0.0-1
- Package PDF bindings, compiled provider, metadata and translations.
- Require PDFium rendering and run every offline module suite with debugging.
- Retain private PoDoFo sources and complete redistribution notices.
