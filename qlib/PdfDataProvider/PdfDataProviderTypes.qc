# -*- mode: qore; indent-tabs-mode: nil -*-
#! Qore PdfDataProvider type definitions

/** PdfDataProviderTypes.qc Copyright (C) 2026 Qore Technologies, s.r.o.

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
    DEALINGS IN THE SOFTWARE.
*/

#! Contains all public definitions in the PdfDataProvider module
public namespace PdfDataProvider {
#! Page specification for PDF creation
public hashdecl PdfCreatePageSpec {
    #! Page type: "blank" or "text"
    string type;

    #! Page text (required for "text" pages)
    *string text;

    #! Page width in points
    *float width;

    #! Page height in points
    *float height;
}

#! Request type for creating a PDF document
public hashdecl PdfCreateDocumentRequest {
    #! Output file path
    string output_path;

    #! Number of blank pages (used if pages is not set)
    *int page_count;

    #! Page specifications (blank or text pages)
    *list<hash<PdfCreatePageSpec>> pages;

    #! Optional metadata
    *hash<Qore::Pdf::PdfMetadata> metadata;

    #! Optional font options
    *hash<Qore::Pdf::PdfFontOptions> font_options;
}

#! Response type for creating a PDF document
public hashdecl PdfCreateDocumentResponse {
    #! True if successful
    bool success;

    #! Output file path
    string output_path;

    #! Number of pages created
    int page_count;

    #! Output file size in bytes
    int size;
}

#! Request type for reading PDF document info
public hashdecl PdfDocumentInfoRequest {
    #! Input file path
    string input_path;

    #! Optional password
    *string password;
}

#! Response type for PDF document info
public hashdecl PdfDocumentInfoResponse {
    #! Number of pages
    int page_count;

    #! Document metadata
    hash<Qore::Pdf::PdfMetadata> metadata;

    #! Warnings encountered while reading the document
    *list<string> warnings;
}

#! Request type for setting metadata
public hashdecl PdfSetMetadataRequest {
    #! Input file path
    string input_path;

    #! Metadata fields to set
    hash<Qore::Pdf::PdfMetadata> metadata;

    #! Output file path (optional if overwrite is true)
    *string output_path;

    #! Overwrite the input file if true
    *bool overwrite;

    #! Optional password
    *string password;
}

#! Response type for setting metadata
public hashdecl PdfSetMetadataResponse {
    #! True if successful
    bool success;

    #! Output file path
    string output_path;

    #! Number of pages
    int page_count;

    #! Warnings encountered while processing the document
    *list<string> warnings;
}

#! Request type for merging documents
public hashdecl PdfMergeDocumentRequest {
    #! Input file paths
    list<string> inputs;

    #! Output file path
    string output_path;

    #! Optional password for input files
    *string password;
}

#! Response type for merging documents
public hashdecl PdfMergeDocumentResponse {
    #! True if successful
    bool success;

    #! Output file path
    string output_path;

    #! Number of pages in the merged document
    int page_count;

    #! Output file size in bytes
    int size;

    #! Warnings encountered while processing input documents
    *list<string> warnings;
}

#! Request type for splitting a document
public hashdecl PdfSplitDocumentRequest {
    #! Input file path
    string input_path;

    #! Output directory
    string output_dir;

    #! Output filename prefix
    *string prefix;
}

#! Response type for splitting a document
public hashdecl PdfSplitDocumentResponse {
    #! Output files
    list<string> outputs;

    #! Number of pages written
    int count;

    #! Warnings encountered while processing the document
    *list<string> warnings;
}

#! Request type for rotating pages
public hashdecl PdfRotatePagesRequest {
    #! Input file path
    string input_path;

    #! Output file path (optional if overwrite is true)
    *string output_path;

    #! Overwrite the input file if true
    *bool overwrite;

    #! Page indices to rotate (zero-based)
    list<int> pages;

    #! Rotation degrees (multiple of 90)
    int degrees;

    #! Optional password
    *string password;
}

#! Response type for rotating pages
public hashdecl PdfRotatePagesResponse {
    #! True if successful
    bool success;

    #! Output file path
    string output_path;

    #! Number of pages
    int page_count;

    #! Warnings encountered while processing the document
    *list<string> warnings;
}

#! Request type for rendering a page
public hashdecl PdfRenderPageRequest {
    #! Input file path
    string input_path;

    #! Page index (zero-based)
    int page_index;

    #! DPI resolution
    *int dpi;

    #! Optional output file path for raw BGRA data
    *string output_path;
}

#! Response type for rendering a page
public hashdecl PdfRenderPageResponse {
    #! Width in pixels
    int width;

    #! Height in pixels
    int height;

    #! Bytes per row
    int stride;

    #! Pixel format (BGRA)
    string format;

    #! Raw pixel data (omitted if output_path is set)
    *binary data;

    #! Output file path (if written)
    *string output_path;

    #! Output data size in bytes
    int size;
}

#! Request type for extracting text
public hashdecl PdfExtractTextRequest {
    #! Input file path
    string input_path;

    #! Page index (zero-based)
    int page_index;
}

#! Response type for extracting text
public hashdecl PdfExtractTextResponse {
    #! Extracted text
    string text;
}
}
