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
qdp 'pdf{}/document/create' output_path=out.pdf,page_count=2
qdp 'pdf{}/document/metadata' input_path=in.pdf,output_path=out.pdf,metadata='{"title":"Updated"}'
qdp 'pdf{}/document/rotate' input_path=in.pdf,output_path=rotated.pdf,pages='(0)',degrees=90
qdp 'pdf{}/document/merge' inputs='("a.pdf","b.pdf")',output_path=merged.pdf
```

## License

MIT License - see [LICENSE](LICENSE) for details.

This project bundles PoDoFo (LGPL-2.0-or-later). See
`third_party/podofo/COPYING` for details.

## Copyright

Copyright 2026 Qore Technologies, s.r.o.
