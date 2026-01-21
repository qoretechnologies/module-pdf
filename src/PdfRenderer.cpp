/* -*- mode: c++; indent-tabs-mode: nil -*- */
/*
    Qore pdf module

    Copyright (C) 2026 Qore Technologies, s.r.o.

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

#include "PdfRenderer.h"
#include "pdf-module.h"

#include <cstdlib>
#include <cstring>
#include <vector>

#ifdef HAVE_PDFIUM
#include "fpdfview.h"
#include "fpdf_text.h"
#endif

static void pdf_error(ExceptionSink* xsink, const char* msg) {
    xsink->raiseException("PDF-ERROR", msg);
}

bool QorePdfRenderer::isAvailable() {
#ifdef HAVE_PDFIUM
    return true;
#else
    return false;
#endif
}

QoreHashNode* QorePdfRenderer::renderPage(const std::string& path, int page_index, int dpi,
        ExceptionSink* xsink) {
#ifndef HAVE_PDFIUM
    pdf_error(xsink, "PDFium support is not available");
    return nullptr;
#else
    if (page_index < 0) {
        pdf_error(xsink, "Page index must be non-negative");
        return nullptr;
    }
    if (dpi <= 0) {
        pdf_error(xsink, "DPI must be positive");
        return nullptr;
    }

    FPDF_LIBRARY_CONFIG config;
    memset(&config, 0, sizeof(config));
    config.version = 2;
    FPDF_InitLibraryWithConfig(&config);

    FPDF_DOCUMENT doc = FPDF_LoadDocument(path.c_str(), nullptr);
    if (!doc) {
        pdf_error(xsink, "Failed to load PDF document");
        FPDF_DestroyLibrary();
        return nullptr;
    }

    int page_count = FPDF_GetPageCount(doc);
    if (page_index >= page_count) {
        pdf_error(xsink, "Page index out of range");
        FPDF_CloseDocument(doc);
        FPDF_DestroyLibrary();
        return nullptr;
    }

    FPDF_PAGE page = FPDF_LoadPage(doc, page_index);
    if (!page) {
        pdf_error(xsink, "Failed to load PDF page");
        FPDF_CloseDocument(doc);
        FPDF_DestroyLibrary();
        return nullptr;
    }

    double width_pt = FPDF_GetPageWidth(page);
    double height_pt = FPDF_GetPageHeight(page);
    int width_px = static_cast<int>(width_pt * dpi / 72.0);
    int height_px = static_cast<int>(height_pt * dpi / 72.0);

    FPDF_BITMAP bitmap = FPDFBitmap_Create(width_px, height_px, 1);
    FPDFBitmap_FillRect(bitmap, 0, 0, width_px, height_px, 0xFFFFFFFF);
    FPDF_RenderPageBitmap(bitmap, page, 0, 0, width_px, height_px, 0, 0);

    int stride = FPDFBitmap_GetStride(bitmap);
    void* buffer = FPDFBitmap_GetBuffer(bitmap);
    int size = stride * height_px;

    QoreHashNode* result = new QoreHashNode(hashdeclPdfRenderResult, xsink);
    result->setKeyValue("width", width_px, xsink);
    result->setKeyValue("height", height_px, xsink);
    result->setKeyValue("stride", stride, xsink);
    result->setKeyValue("format", new QoreStringNode("BGRA"), xsink);
    void* copy = malloc(size);
    if (!copy) {
        pdf_error(xsink, "Failed to allocate memory for render data");
        FPDFBitmap_Destroy(bitmap);
        FPDF_ClosePage(page);
        FPDF_CloseDocument(doc);
        FPDF_DestroyLibrary();
        return nullptr;
    }
    memcpy(copy, buffer, size);
    result->setKeyValue("data", new BinaryNode(copy, size), xsink);

    FPDFBitmap_Destroy(bitmap);
    FPDF_ClosePage(page);
    FPDF_CloseDocument(doc);
    FPDF_DestroyLibrary();

    return result;
#endif
}

QoreStringNode* QorePdfRenderer::extractText(const std::string& path, int page_index, ExceptionSink* xsink) {
#ifndef HAVE_PDFIUM
    pdf_error(xsink, "PDFium support is not available");
    return nullptr;
#else
    if (page_index < 0) {
        pdf_error(xsink, "Page index must be non-negative");
        return nullptr;
    }

    FPDF_LIBRARY_CONFIG config;
    memset(&config, 0, sizeof(config));
    config.version = 2;
    FPDF_InitLibraryWithConfig(&config);

    FPDF_DOCUMENT doc = FPDF_LoadDocument(path.c_str(), nullptr);
    if (!doc) {
        pdf_error(xsink, "Failed to load PDF document");
        FPDF_DestroyLibrary();
        return nullptr;
    }

    int page_count = FPDF_GetPageCount(doc);
    if (page_index >= page_count) {
        pdf_error(xsink, "Page index out of range");
        FPDF_CloseDocument(doc);
        FPDF_DestroyLibrary();
        return nullptr;
    }

    FPDF_PAGE page = FPDF_LoadPage(doc, page_index);
    if (!page) {
        pdf_error(xsink, "Failed to load PDF page");
        FPDF_CloseDocument(doc);
        FPDF_DestroyLibrary();
        return nullptr;
    }

    FPDF_TEXTPAGE text_page = FPDFText_LoadPage(page);
    int count = FPDFText_CountChars(text_page);
    if (count <= 0) {
        FPDFText_ClosePage(text_page);
        FPDF_ClosePage(page);
        FPDF_CloseDocument(doc);
        FPDF_DestroyLibrary();
        return new QoreStringNode("");
    }

    std::vector<unsigned short> buffer(static_cast<size_t>(count) + 1);
    int written = FPDFText_GetText(text_page, 0, count, buffer.data());
    if (written < 0) {
        pdf_error(xsink, "Failed to extract text");
        FPDFText_ClosePage(text_page);
        FPDF_ClosePage(page);
        FPDF_CloseDocument(doc);
        FPDF_DestroyLibrary();
        return nullptr;
    }
    size_t max_index = buffer.size() - 1;
    size_t safe_written = static_cast<size_t>(written);
    if (safe_written > max_index) {
        safe_written = max_index;
    }
    buffer[safe_written] = 0;

    size_t char_count = safe_written;
    if (safe_written > 0 && buffer[safe_written - 1] == 0) {
        char_count = safe_written - 1;
    }
    size_t byte_len = char_count * 2;
    SimpleRefHolder<QoreStringNode> raw(
        new QoreStringNode(reinterpret_cast<const char*>(buffer.data()), byte_len, QCS_UTF16LE));
    SimpleRefHolder<QoreStringNode> str(raw->convertEncoding(QCS_UTF8, xsink));
    if (*xsink) {
        FPDFText_ClosePage(text_page);
        FPDF_ClosePage(page);
        FPDF_CloseDocument(doc);
        FPDF_DestroyLibrary();
        return nullptr;
    }

    FPDFText_ClosePage(text_page);
    FPDF_ClosePage(page);
    FPDF_CloseDocument(doc);
    FPDF_DestroyLibrary();

    return str.release();
#endif
}
