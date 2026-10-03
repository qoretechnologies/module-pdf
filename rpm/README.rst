RPM packaging
=============

Copyright 2026 Qore Technologies, s.r.o.

``qore-pdf-module.spec`` supports Fedora, Enterprise Linux and openSUSE using
the Qore 3.0 SDK and its RPM macros. PDFium is mandatory: install
``libpdfium-qore-devel`` from the matching Qore repository before building.
All seven test suites require rendering support and run with debugging enabled.
The runtime package includes source/AOT PdfDataProvider, metadata, resources and
translations. Documentation and ELF debug symbols are separate packages.

PoDoFo 1.0.3 remains private to the module, retaining the reviewed CFF leak and
OpenSSL type fixes described in ``docs/THIRD_PARTY.md``. Its full source and
notices are supplied for relinking; private headers and libraries are not
installed. Image, font, color and cryptographic dependencies use system libraries.
No sources are downloaded by the RPM build.

``rpm/licenses`` supplies full notices without relying on Debian's common-license
paths. The Chromium numerics notice has been decoded from the base64 form
in the imported PoDoFo source, preserving its original copyright and terms.

Prepare a committed source bundle from the qore-packaging checkout::

    python3 tools/packaging.py prepare --repo ../module-pdf --ref COMMIT \
      --name qore-pdf-module --version 1.0.0 --spec qore-pdf-module.spec \
      --exclude packaging/pdfium --exclude third_party/podofo/test \
      --exclude third_party/podofo/tools --exclude third_party/podofo/examples \
      --exclude third_party/podofo/3rdparty/tclap --output work/pdf-source
    python3 tools/build-local.py --source work/pdf-source \
      --image TARGET_SDK_IMAGE --output results/pdf-build --jobs 2

The exclusions match the unused tool/test trees omitted from the Debian source
package. Qualification uses the default tests and documentation, then checks
installed runtime/SDK use outside the source checkout. ``--without tests`` and
``--without docs`` are available for local diagnosis only.
