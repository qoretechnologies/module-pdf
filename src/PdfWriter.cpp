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

#include "PdfWriter.h"
#include "pdf-module.h"

#include <vector>

static void pdf_error(ExceptionSink* xsink, const char* msg) {
    xsink->raiseException("PDF-ERROR", msg);
}

QorePdfWriter::QorePdfWriter() {
}

int QorePdfWriter::pageCount() const {
    return static_cast<int>(doc.GetPages().GetCount());
}

void QorePdfWriter::addBlankPage(double width, double height, ExceptionSink* xsink) {
    if (width <= 0 || height <= 0) {
        pdf_error(xsink, "Page width and height must be positive");
        return;
    }
    try {
        PoDoFo::Rect rect(0.0, 0.0, width, height);
        doc.GetPages().CreatePage(rect);
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
    }
}

void QorePdfWriter::addTextPage(const std::string& text, double width, double height,
        ExceptionSink* xsink) {
    if (width <= 0 || height <= 0) {
        pdf_error(xsink, "Page width and height must be positive");
        return;
    }
    try {
        PoDoFo::Rect rect(0.0, 0.0, width, height);
        PoDoFo::PdfPage& page = doc.GetPages().CreatePage(rect);
        PoDoFo::PdfPainter painter;
        painter.SetCanvas(page);

        PoDoFo::PdfFontCreateParams font_params;
        if (!embed_fonts) {
            font_params.Flags = font_params.Flags | PoDoFo::PdfFontCreateFlags::DontEmbed;
        }
        if (!subset_fonts) {
            font_params.Flags = font_params.Flags | PoDoFo::PdfFontCreateFlags::DontSubset;
        }
        if (prefer_non_cid) {
            font_params.Flags = font_params.Flags | PoDoFo::PdfFontCreateFlags::PreferNonCID;
        }
        PoDoFo::PdfFont& font = doc.GetFonts().GetStandard14Font(PoDoFo::PdfStandard14FontType::Helvetica,
            font_params);
        painter.TextState.SetFont(font, 12.0);
        painter.DrawText(text, 40.0, height - 60.0);
        painter.FinishDrawing();
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
    }
}

void QorePdfWriter::setMetadata(const QoreHashNode* metadata, ExceptionSink* xsink) {
    if (!metadata) {
        return;
    }

    PoDoFo::PdfMetadata& meta = doc.GetMetadata();
    QoreValue val;

    val = metadata->getKeyValue("title");
    if (val.getType() == NT_STRING) {
        PoDoFo::PdfString str(val.get<const QoreStringNode>()->c_str());
        meta.SetTitle(str);
    }

    val = metadata->getKeyValue("author");
    if (val.getType() == NT_STRING) {
        PoDoFo::PdfString str(val.get<const QoreStringNode>()->c_str());
        meta.SetAuthor(str);
    }

    val = metadata->getKeyValue("subject");
    if (val.getType() == NT_STRING) {
        PoDoFo::PdfString str(val.get<const QoreStringNode>()->c_str());
        meta.SetSubject(str);
    }

    val = metadata->getKeyValue("keywords");
    if (val.getType() == NT_STRING) {
        PoDoFo::PdfString str(val.get<const QoreStringNode>()->c_str());
        std::vector<std::string> keywords;
        keywords.push_back(std::string(str.GetString()));
        meta.SetKeywords(std::move(keywords));
    }

    val = metadata->getKeyValue("creator");
    if (val.getType() == NT_STRING) {
        PoDoFo::PdfString str(val.get<const QoreStringNode>()->c_str());
        meta.SetCreator(str);
    }

    val = metadata->getKeyValue("producer");
    if (val.getType() == NT_STRING) {
        PoDoFo::PdfString str(val.get<const QoreStringNode>()->c_str());
        meta.SetProducer(str);
    }

    if (*xsink) {
        pdf_error(xsink, "Failed to set PDF metadata");
    }
}

void QorePdfWriter::setFontOptions(const QoreHashNode* opts, ExceptionSink* xsink) {
    if (!opts) {
        return;
    }

    QoreValue val = opts->getKeyValue("embed");
    if (val.getType() == NT_BOOLEAN) {
        embed_fonts = val.getAsBool();
    }

    val = opts->getKeyValue("subset");
    if (val.getType() == NT_BOOLEAN) {
        subset_fonts = val.getAsBool();
    }

    val = opts->getKeyValue("prefer_non_cid");
    if (val.getType() == NT_BOOLEAN) {
        prefer_non_cid = val.getAsBool();
    }

    if (*xsink) {
        pdf_error(xsink, "Failed to update font options");
    }
}

void QorePdfWriter::save(const std::string& path, ExceptionSink* xsink) {
    QoreSandboxManagerHelper smh;
    if (smh && !smh->checkFilesystemAccess(path.c_str(), QSEC_WRITE | QSEC_CREATE, xsink)) {
        return;
    }
    if (qore_check_io_interrupt(xsink, "PDF writer save")) {
        return;
    }

    try {
        doc.Save(path.c_str());
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
    }
}

BinaryNode* QorePdfWriter::saveToMemory(ExceptionSink* xsink) {
    if (qore_check_io_interrupt(xsink, "PDF writer save to memory")) {
        return nullptr;
    }

    try {
        PoDoFo::charbuff buffer;
        PoDoFo::BufferStreamDevice device(buffer);
        doc.Save(device);

        SimpleRefHolder<BinaryNode> result(new BinaryNode);
        result->append(buffer.data(), buffer.size());
        return result.release();
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
        return nullptr;
    }
}
