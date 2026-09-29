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
#include <chrono>
#include <cmath>
#include <limits>
#include <memory>
#include <mutex>
#include <type_traits>

#ifdef HAVE_PDFIUM
#include "fpdfview.h"
#include "fpdf_text.h"
#include "fpdf_progressive.h"
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

#ifdef HAVE_PDFIUM
// PDFium requires every API call, including initialization/destruction, to be
// serialized. Keep this lock until all per-call PDFium objects are destroyed.
static std::timed_mutex pdfium_mutex;
class PdfiumLibraryGuard {
public:
    explicit PdfiumLibraryGuard(ExceptionSink* xsink) : lock(pdfium_mutex, std::defer_lock) {
        do {
            if (qore_check_cancel(xsink, "waiting for PDFium")) {
                return;
            }
        } while (!lock.try_lock_for(std::chrono::milliseconds(100)));
        FPDF_LIBRARY_CONFIG config{};
        config.version = 2;
        FPDF_InitLibraryWithConfig(&config);
        initialized = true;
    }
    ~PdfiumLibraryGuard() {
        if (initialized) {
            FPDF_DestroyLibrary();
        }
    }
    PdfiumLibraryGuard(const PdfiumLibraryGuard&) = delete;
    PdfiumLibraryGuard& operator=(const PdfiumLibraryGuard&) = delete;
private:
    std::unique_lock<std::timed_mutex> lock;
    bool initialized = false;
};

using PdfiumPageGuard = std::unique_ptr<std::remove_pointer_t<FPDF_PAGE>, decltype(&FPDF_ClosePage)>;
using PdfiumBitmapGuard = std::unique_ptr<std::remove_pointer_t<FPDF_BITMAP>, decltype(&FPDFBitmap_Destroy)>;
using PdfiumTextGuard = std::unique_ptr<std::remove_pointer_t<FPDF_TEXTPAGE>, decltype(&FPDFText_ClosePage)>;

class PdfiumRenderGuard {
public:
    explicit PdfiumRenderGuard(FPDF_PAGE page) : page(page) {
    }
    ~PdfiumRenderGuard() {
        FPDF_RenderPage_Close(page);
    }
private:
    FPDF_PAGE page;
};

static FPDF_BOOL pdfium_pause(IFSDK_PAUSE* pause) {
    auto* xsink = static_cast<ExceptionSink*>(pause->user);
    return *xsink || qore_check_cancel(xsink, "PDF render page");
}

// RAII wrapper for FPDF_DOCUMENT
class PdfiumDocGuard {
public:
    PdfiumDocGuard(FPDF_DOCUMENT d) : doc(d) {}
    ~PdfiumDocGuard() { if (doc) { FPDF_CloseDocument(doc); } }
    operator FPDF_DOCUMENT() const { return doc; }
    explicit operator bool() const { return doc != nullptr; }
    PdfiumDocGuard(const PdfiumDocGuard&) = delete;
    PdfiumDocGuard& operator=(const PdfiumDocGuard&) = delete;
private:
    FPDF_DOCUMENT doc;
};

// Internal helper: render a page from an already-loaded document
static QoreHashNode* renderPageFromDoc(FPDF_DOCUMENT doc, int page_index, int dpi,
        ExceptionSink* xsink) {
    int page_count = FPDF_GetPageCount(doc);
    if (page_index >= page_count) {
        pdf_error(xsink, "Page index out of range");
        return nullptr;
    }

    PdfiumPageGuard page(FPDF_LoadPage(doc, page_index), &FPDF_ClosePage);
    if (!page) {
        pdf_error(xsink, "Failed to load PDF page");
        return nullptr;
    }

    double width = FPDF_GetPageWidth(page.get()) * dpi / 72.0;
    double height = FPDF_GetPageHeight(page.get()) * dpi / 72.0;
    // Validate before converting floating-point dimensions or allocating. PDFium
    // uses signed int dimensions/stride and bounds the bitmap allocation to int.
    constexpr int max_size = std::numeric_limits<int>::max();
    if (!std::isfinite(width) || !std::isfinite(height) || width < 1 || height < 1
            || width > max_size / 4 || height > max_size || width * height > max_size / 4) {
        pdf_error(xsink, "Rendered bitmap dimensions are outside the supported range");
        return nullptr;
    }
    int width_px = static_cast<int>(width);
    int height_px = static_cast<int>(height);
    PdfiumBitmapGuard bitmap(FPDFBitmap_Create(width_px, height_px, 1), &FPDFBitmap_Destroy);
    if (!bitmap) {
        pdf_error(xsink, "Failed to allocate rendered bitmap");
        return nullptr;
    }
    FPDFBitmap_FillRect(bitmap.get(), 0, 0, width_px, height_px, 0xFFFFFFFF);
    IFSDK_PAUSE pause{1, &pdfium_pause, xsink};
    int status = FPDF_RenderPageBitmap_Start(bitmap.get(), page.get(), 0, 0, width_px, height_px, 0, 0, &pause);
    PdfiumRenderGuard rendering(page.get());
    while (status == FPDF_RENDER_TOBECONTINUED && !*xsink) {
        if (qore_check_cancel(xsink, "PDF render page")) {
            return nullptr;
        }
        status = FPDF_RenderPage_Continue(page.get(), &pause);
    }
    if (*xsink) {
        return nullptr;
    }
    if (status != FPDF_RENDER_DONE) {
        pdf_error(xsink, "Failed to render PDF page");
        return nullptr;
    }

    int stride = FPDFBitmap_GetStride(bitmap.get());
    const void* buffer = FPDFBitmap_GetBuffer(bitmap.get());
    if (!buffer || stride <= 0 || height_px > max_size / stride) {
        pdf_error(xsink, "Invalid rendered bitmap buffer");
        return nullptr;
    }
    size_t size = static_cast<size_t>(stride) * height_px;
    SimpleRefHolder<BinaryNode> data(new BinaryNode);
    if (data->preallocate(size)) {
        pdf_error(xsink, "Failed to allocate memory for render data");
        return nullptr;
    }
    if (data->writeTo(0, buffer, size)) {
        pdf_error(xsink, "Failed to copy rendered bitmap data");
        return nullptr;
    }
    ReferenceHolder<QoreHashNode> result(new QoreHashNode(hashdeclPdfRenderResult, xsink), xsink);
    if (*xsink) {
        return nullptr;
    }
    result->setKeyValue("width", width_px, xsink);
    if (*xsink) {
        return nullptr;
    }
    result->setKeyValue("height", height_px, xsink);
    if (*xsink) {
        return nullptr;
    }
    result->setKeyValue("stride", stride, xsink);
    if (*xsink) {
        return nullptr;
    }
    result->setKeyValue("format", new QoreStringNode("BGRA"), xsink);
    if (*xsink) {
        return nullptr;
    }
    result->setKeyValue("data", data.release(), xsink);
    if (*xsink) {
        return nullptr;
    }
    return result.release();
}

// Internal helper: extract text from an already-loaded document
static QoreStringNode* extractTextFromDoc(FPDF_DOCUMENT doc, int page_index, ExceptionSink* xsink) {
    int page_count = FPDF_GetPageCount(doc);
    if (page_index >= page_count) {
        pdf_error(xsink, "Page index out of range");
        return nullptr;
    }

    PdfiumPageGuard page(FPDF_LoadPage(doc, page_index), &FPDF_ClosePage);
    if (!page) {
        pdf_error(xsink, "Failed to load PDF page");
        return nullptr;
    }

    PdfiumTextGuard text_page(FPDFText_LoadPage(page.get()), &FPDFText_ClosePage);
    if (!text_page) {
        pdf_error(xsink, "Failed to load PDF text page");
        return nullptr;
    }
    if (qore_check_cancel(xsink, "PDF extract text")) {
        return nullptr;
    }
    int count = FPDFText_CountChars(text_page.get());
    if (count < 0 || count == std::numeric_limits<int>::max()) {
        pdf_error(xsink, "PDF text length is outside the supported range");
        return nullptr;
    }
    if (count == 0) {
        return new QoreStringNode("");
    }

    std::vector<unsigned short> buffer(static_cast<size_t>(count) + 1);
    int written = FPDFText_GetText(text_page.get(), 0, count, buffer.data());
    if (written <= 0) {
        pdf_error(xsink, "Failed to extract text");
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
        return nullptr;
    }

    return str.release();
}
#endif

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

    QoreSandboxManagerHelper smh;
    if (smh && !smh->checkFilesystemAccess(path.c_str(), QSEC_READ, xsink)) {
        return nullptr;
    }
    if (qore_check_cancel(xsink, "PDF render page")) {
        return nullptr;
    }

    PdfiumLibraryGuard lib(xsink);
    if (*xsink) {
        return nullptr;
    }
    PdfiumDocGuard doc(FPDF_LoadDocument(path.c_str(), nullptr));
    if (!doc) {
        pdf_error(xsink, "Failed to load PDF document");
        return nullptr;
    }

    return renderPageFromDoc(doc, page_index, dpi, xsink);
#endif
}

QoreHashNode* QorePdfRenderer::renderPageFromData(const BinaryNode* data, int page_index, int dpi,
        ExceptionSink* xsink) {
#ifndef HAVE_PDFIUM
    pdf_error(xsink, "PDFium support is not available");
    return nullptr;
#else
    if (!data || data->size() == 0) {
        pdf_error(xsink, "binary data is empty");
        return nullptr;
    }
    if (page_index < 0) {
        pdf_error(xsink, "Page index must be non-negative");
        return nullptr;
    }
    if (dpi <= 0) {
        pdf_error(xsink, "DPI must be positive");
        return nullptr;
    }

    PdfiumLibraryGuard lib(xsink);
    if (*xsink) {
        return nullptr;
    }
    PdfiumDocGuard doc(FPDF_LoadMemDocument64(data->getPtr(), data->size(), nullptr));
    if (!doc) {
        pdf_error(xsink, "Failed to load PDF document from memory");
        return nullptr;
    }

    return renderPageFromDoc(doc, page_index, dpi, xsink);
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

    QoreSandboxManagerHelper smh;
    if (smh && !smh->checkFilesystemAccess(path.c_str(), QSEC_READ, xsink)) {
        return nullptr;
    }
    if (qore_check_cancel(xsink, "PDF extract text")) {
        return nullptr;
    }

    PdfiumLibraryGuard lib(xsink);
    if (*xsink) {
        return nullptr;
    }
    PdfiumDocGuard doc(FPDF_LoadDocument(path.c_str(), nullptr));
    if (!doc) {
        pdf_error(xsink, "Failed to load PDF document");
        return nullptr;
    }

    return extractTextFromDoc(doc, page_index, xsink);
#endif
}

QoreStringNode* QorePdfRenderer::extractTextFromData(const BinaryNode* data, int page_index,
        ExceptionSink* xsink) {
#ifndef HAVE_PDFIUM
    pdf_error(xsink, "PDFium support is not available");
    return nullptr;
#else
    if (!data || data->size() == 0) {
        pdf_error(xsink, "binary data is empty");
        return nullptr;
    }
    if (page_index < 0) {
        pdf_error(xsink, "Page index must be non-negative");
        return nullptr;
    }

    PdfiumLibraryGuard lib(xsink);
    if (*xsink) {
        return nullptr;
    }
    PdfiumDocGuard doc(FPDF_LoadMemDocument64(data->getPtr(), data->size(), nullptr));
    if (!doc) {
        pdf_error(xsink, "Failed to load PDF document from memory");
        return nullptr;
    }

    return extractTextFromDoc(doc, page_index, xsink);
#endif
}
