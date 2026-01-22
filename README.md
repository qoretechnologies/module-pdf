# Qore PDF Module

## Introduction

The `pdf` module provides PDF creation, reading, editing, and rendering support
for Qore using QPDF and PoDoFo, with optional PDFium integration for rendering
and text extraction.

## Requirements

- Qore 2.0+
- CMake 3.5+
- C++17 compiler
- QPDF (required)
- PoDoFo (required; bundled by default)
- PDFium (optional; required in Qorus CI)

## OS Packages

The bundled PoDoFo build requires common graphics/font libraries. Install these
packages before building. PDFium is optional; there is no MacPorts PDFium port.

Ubuntu:

```bash
sudo apt-get update
sudo apt-get install -y \
  cmake pkg-config qpdf libqpdf-dev libfreetype-dev \
  libssl-dev libxml2-dev libfontconfig1-dev libpng-dev \
  libjpeg-turbo8-dev libtiff-dev zlib1g-dev
```

PDFium (optional): not packaged in standard Ubuntu repos; provide a prebuilt
`libpdfium` and pass `-DENABLE_PDFIUM=ON -DPDFIUM_INCLUDE_DIR=... -DPDFIUM_LIBRARY=...`,
or use `-DENABLE_PDFIUM=OFF`.

Alpine:

```bash
sudo apk add --no-cache \
  cmake pkgconfig qpdf qpdf-dev freetype-dev \
  openssl-dev libxml2-dev fontconfig-dev libpng-dev \
  libjpeg-turbo-dev tiff-dev zlib-dev
```

PDFium (optional): not in Alpine repos; provide a prebuilt `libpdfium` and pass
`-DENABLE_PDFIUM=ON -DPDFIUM_INCLUDE_DIR=... -DPDFIUM_LIBRARY=...`,
or use `-DENABLE_PDFIUM=OFF`.

Fedora:

```bash
sudo dnf install -y \
  cmake pkgconf-pkg-config qpdf qpdf-devel freetype-devel \
  openssl-devel libxml2-devel fontconfig-devel libpng-devel \
  libjpeg-turbo-devel libtiff-devel zlib-devel
```

MacPorts (no PDFium port available):

```bash
sudo port install \
  cmake pkgconfig qpdf freetype openssl3 libxml2 fontconfig libpng \
  libjpeg-turbo tiff zlib
```

## Building

```bash
mkdir build
cd build
cmake ..
make
make install
```

To use the system PoDoFo instead of the bundled source:

```bash
cmake .. -DUSE_BUNDLED_PODOFO=OFF
```

To disable PDFium features:

```bash
cmake .. -DENABLE_PDFIUM=OFF
```

## Quick Start

```qore
#!/usr/bin/qore

%requires pdf

# Create a PDF with two blank pages
PdfWriter writer();
writer.addBlankPage();
writer.addBlankPage();
writer.save("example.pdf");

# Read metadata and page count
PdfReader reader("example.pdf");
int pages = reader.pageCount();

# Merge PDFs
PdfDocument merged = PdfDocument::merge(("example.pdf", "example.pdf"));
merged.save("merged.pdf");
```

## Adding Images and Text

The `PdfEditor` class allows adding images and styled text to existing PDFs:

```qore
%requires pdf

# Add an image to a PDF
PdfEditor editor("document.pdf");
editor.drawImage(0, "logo.png", 100.0, 700.0, 200.0, 100.0);
editor.save("with_logo.pdf");

# Add styled text
hash<auto> style = {
    "font": {"family": "Helvetica", "size": 24.0, "bold": True},
    "color": {"hex": "#FF0000"},
};
editor.drawText(0, "Hello World", 100.0, 500.0, style);
editor.save("with_text.pdf");
```

## Data Provider

The module includes a PDF data provider for integration with Qore's data
provider framework.

```qore
%requires PdfDataProvider

AbstractDataProvider dp = DataProvider::getFactoryObjectFromStringEx("pdf{}/document/merge");

hash<auto> result = dp.doRequest({
    "output_path": "merged.pdf",
    "inputs": ("a.pdf", "b.pdf"),
});
```

Example `qdp` actions:

```bash
# Document operations
qdp 'pdf{}/document/create' output_path=out.pdf,page_count=2
qdp 'pdf{}/document/metadata' input_path=in.pdf,output_path=out.pdf,metadata='{"title":"Updated"}'
qdp 'pdf{}/document/rotate' input_path=in.pdf,output_path=rotated.pdf,pages='(0)',degrees=90
qdp 'pdf{}/document/merge' inputs='("a.pdf","b.pdf")',output_path=merged.pdf

# Add images to pages
qdp 'pdf{}/document/add-image' input_path=in.pdf,output_path=out.pdf,image='{"image_path":"logo.png","position":{"preset":"center"}}'

# Add styled text
qdp 'pdf{}/document/add-text' input_path=in.pdf,output_path=out.pdf,text='{"text":"Hello","position":{"x":100,"y":100}}'

# Add watermarks (text or image)
qdp 'pdf{}/document/add-watermark' input_path=in.pdf,output_path=out.pdf,watermark='{"type":"text","text":"DRAFT","opacity":0.3}'

# Add signature fields
qdp 'pdf{}/document/add-signature-field' input_path=in.pdf,output_path=out.pdf,signature='{"label":"Signature"}'
```

## License

MIT License - see [LICENSE](LICENSE) for details.

This project bundles PoDoFo (LGPL-2.0-or-later). See
`third_party/podofo/COPYING` for details.

## Copyright

Copyright 2026 Qore Technologies, s.r.o.
