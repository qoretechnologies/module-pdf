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

#include "PdfDocument.h"
#include "pdf-module.h"

#include <qpdf/QPDFObjectHandle.hh>
#include <qpdf/QPDFExc.hh>

static void pdf_error(ExceptionSink* xsink, const char* msg) {
    xsink->raiseException("PDF-ERROR", msg);
}

QoreListNode* QorePdfDocument::collectWarnings(QPDF& qpdf) {
    QoreListNode* warnings = new QoreListNode();
    std::vector<QPDFExc> qpdf_warnings = qpdf.getWarnings();
    for (const auto& w : qpdf_warnings) {
        warnings->push(new QoreStringNode(w.what()), nullptr);
    }
    return warnings;
}

QorePdfDocument::QorePdfDocument(const std::string& path, const std::string& pwd, ExceptionSink* xsink)
        : password(pwd) {
    try {
        qpdf = std::make_unique<QPDF>();
        qpdf->setSuppressWarnings(true);
        qpdf->processFile(path.c_str(), pwd.empty() ? nullptr : pwd.c_str());
        has_doc = true;
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
    }
}

QorePdfDocument::QorePdfDocument(std::unique_ptr<QPDF> doc) : qpdf(std::move(doc)), has_doc(true) {
}

int QorePdfDocument::pageCount(ExceptionSink* xsink) {
    if (!has_doc) {
        pdf_error(xsink, "PDF document is not initialized");
        return 0;
    }

    try {
        QPDFPageDocumentHelper pdh(*qpdf);
        return static_cast<int>(pdh.getAllPages().size());
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
        return 0;
    }
}

QoreHashNode* QorePdfDocument::buildMetadataHash(QPDFObjectHandle info, ExceptionSink* xsink) {
    QoreHashNode* metadata = new QoreHashNode(hashdeclPdfMetadata, xsink);
    if (!info.isDictionary()) {
        return metadata;
    }

    auto add_string = [&](const char* key, const char* field) {
        if (info.hasKey(key)) {
            QPDFObjectHandle value = info.getKey(key);
            if (value.isString()) {
                QoreStringNode* qstr = new QoreStringNode(value.getStringValue().c_str());
                metadata->setKeyValue(field, qstr, xsink);
            }
        }
    };

    add_string("/Title", "title");
    add_string("/Author", "author");
    add_string("/Subject", "subject");
    add_string("/Keywords", "keywords");
    add_string("/Creator", "creator");
    add_string("/Producer", "producer");

    return metadata;
}

QoreHashNode* QorePdfDocument::getMetadata(ExceptionSink* xsink) {
    if (!has_doc) {
        pdf_error(xsink, "PDF document is not initialized");
        return nullptr;
    }

    try {
        QPDFObjectHandle info = qpdf->getTrailer().getKey("/Info");
        return buildMetadataHash(info, xsink);
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
        return nullptr;
    }
}

void QorePdfDocument::applyMetadata(const QoreHashNode* metadata, QPDFObjectHandle& info,
        ExceptionSink* xsink) {
    if (!metadata) {
        return;
    }

    auto set_string = [&](const char* field, const char* key) {
        QoreValue val = metadata->getKeyValue(field);
        if (val.getType() == NT_STRING) {
            info.replaceKey(key, QPDFObjectHandle::newString(val.get<const QoreStringNode>()->c_str()));
        }
    };

    set_string("title", "/Title");
    set_string("author", "/Author");
    set_string("subject", "/Subject");
    set_string("keywords", "/Keywords");
    set_string("creator", "/Creator");
    set_string("producer", "/Producer");

    if (*xsink) {
        pdf_error(xsink, "Failed to set PDF metadata");
    }
}

void QorePdfDocument::setMetadata(const QoreHashNode* metadata, ExceptionSink* xsink) {
    if (!has_doc) {
        pdf_error(xsink, "PDF document is not initialized");
        return;
    }

    try {
        QPDFObjectHandle info = qpdf->getTrailer().getKey("/Info");
        if (!info.isDictionary()) {
            info = QPDFObjectHandle::newDictionary();
        }
        applyMetadata(metadata, info, xsink);
        qpdf->getTrailer().replaceKey("/Info", info);
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
    }
}

void QorePdfDocument::save(const std::string& path, ExceptionSink* xsink) {
    if (!has_doc) {
        pdf_error(xsink, "PDF document is not initialized");
        return;
    }

    try {
        QPDFWriter writer(*qpdf, path.c_str());
        writer.write();
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
    }
}

void QorePdfDocument::rotatePages(const QoreListNode* pages, int degrees, ExceptionSink* xsink) {
    if (!has_doc) {
        pdf_error(xsink, "PDF document is not initialized");
        return;
    }

    if (degrees % 90 != 0) {
        pdf_error(xsink, "Rotation degrees must be a multiple of 90");
        return;
    }

    try {
        QPDFPageDocumentHelper pdh(*qpdf);
        auto all_pages = pdh.getAllPages();
        for (size_t i = 0; i < pages->size(); ++i) {
            QoreValue val = pages->retrieveEntry(i);
            if (val.getType() != NT_INT) {
                pdf_error(xsink, "Page list must contain integers");
                return;
            }
            int index = val.getInt();
            if (index < 0 || static_cast<size_t>(index) >= all_pages.size()) {
                pdf_error(xsink, "Page index out of range");
                return;
            }
            QPDFPageObjectHelper page = all_pages[index];
            QPDFObjectHandle page_obj = page.getObjectHandle();
            page_obj.replaceKey("/Rotate", QPDFObjectHandle::newInteger(degrees));
        }
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
    }
}

QorePdfDocument* QorePdfDocument::merge(const QoreListNode* inputs, const std::string& pwd,
        ExceptionSink* xsink) {
    if (!inputs || inputs->size() == 0) {
        pdf_error(xsink, "Input list cannot be empty");
        return nullptr;
    }

    try {
        auto out_qpdf = std::make_unique<QPDF>();
        out_qpdf->emptyPDF();
        QPDFPageDocumentHelper out_pdh(*out_qpdf);

        for (size_t i = 0; i < inputs->size(); ++i) {
            QoreValue val = inputs->retrieveEntry(i);
            if (val.getType() != NT_STRING) {
                pdf_error(xsink, "Input list must contain strings");
                return nullptr;
            }
            const QoreStringNode* path = val.get<const QoreStringNode>();
            QPDF in_qpdf;
            in_qpdf.setSuppressWarnings(true);
            in_qpdf.processFile(path->c_str(), pwd.empty() ? nullptr : pwd.c_str());
            QPDFPageDocumentHelper in_pdh(in_qpdf);
            for (auto& page : in_pdh.getAllPages()) {
                out_pdh.addPage(page, false);
            }
        }

        return new QorePdfDocument(std::move(out_qpdf));
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
        return nullptr;
    }
}

QoreListNode* QorePdfDocument::getWarnings(ExceptionSink* xsink) {
    if (!has_doc || !qpdf) {
        return new QoreListNode();
    }
    return collectWarnings(*qpdf);
}

QorePdfDocument* QorePdfDocument::mergeWithWarnings(const QoreListNode* inputs, const std::string& pwd,
        QoreListNode*& warnings, ExceptionSink* xsink) {
    if (!inputs || inputs->size() == 0) {
        pdf_error(xsink, "Input list cannot be empty");
        return nullptr;
    }

    warnings = new QoreListNode();

    try {
        auto out_qpdf = std::make_unique<QPDF>();
        out_qpdf->emptyPDF();
        QPDFPageDocumentHelper out_pdh(*out_qpdf);

        for (size_t i = 0; i < inputs->size(); ++i) {
            QoreValue val = inputs->retrieveEntry(i);
            if (val.getType() != NT_STRING) {
                pdf_error(xsink, "Input list must contain strings");
                return nullptr;
            }
            const QoreStringNode* path = val.get<const QoreStringNode>();
            QPDF in_qpdf;
            in_qpdf.setSuppressWarnings(true);
            in_qpdf.processFile(path->c_str(), pwd.empty() ? nullptr : pwd.c_str());

            // Collect warnings from this input
            QoreListNode* input_warnings = collectWarnings(in_qpdf);
            for (size_t j = 0; j < input_warnings->size(); ++j) {
                warnings->push(input_warnings->retrieveEntry(j).refSelf(), xsink);
            }
            input_warnings->deref(xsink);

            QPDFPageDocumentHelper in_pdh(in_qpdf);
            for (auto& page : in_pdh.getAllPages()) {
                out_pdh.addPage(page, false);
            }
        }

        return new QorePdfDocument(std::move(out_qpdf));
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
        return nullptr;
    }
}

QoreListNode* QorePdfDocument::split(const std::string& input, const std::string& output_dir,
        const std::string& prefix, ExceptionSink* xsink) {
    QoreListNode* outputs = new QoreListNode();

    try {
        QPDF in_qpdf;
        in_qpdf.setSuppressWarnings(true);
        in_qpdf.processFile(input.c_str(), nullptr);
        QPDFPageDocumentHelper pdh(in_qpdf);
        auto pages = pdh.getAllPages();

        for (size_t i = 0; i < pages.size(); ++i) {
            QPDF out_qpdf;
            out_qpdf.emptyPDF();
            QPDFPageDocumentHelper out_pdh(out_qpdf);
            out_pdh.addPage(pages[i], false);

            QoreString out_path;
            out_path.sprintf("%s/%s%zu.pdf", output_dir.c_str(), prefix.c_str(), i + 1);

            QPDFWriter writer(out_qpdf, out_path.c_str());
            writer.write();

            outputs->push(new QoreStringNode(out_path.c_str()), xsink);
        }

        return outputs;
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
        return outputs;
    }
}

QoreListNode* QorePdfDocument::splitWithWarnings(const std::string& input, const std::string& output_dir,
        const std::string& prefix, QoreListNode*& warnings, ExceptionSink* xsink) {
    QoreListNode* outputs = new QoreListNode();
    warnings = new QoreListNode();

    try {
        QPDF in_qpdf;
        in_qpdf.setSuppressWarnings(true);
        in_qpdf.processFile(input.c_str(), nullptr);

        // Collect warnings from input
        QoreListNode* input_warnings = collectWarnings(in_qpdf);
        for (size_t j = 0; j < input_warnings->size(); ++j) {
            warnings->push(input_warnings->retrieveEntry(j).refSelf(), xsink);
        }
        input_warnings->deref(xsink);

        QPDFPageDocumentHelper pdh(in_qpdf);
        auto pages = pdh.getAllPages();

        for (size_t i = 0; i < pages.size(); ++i) {
            QPDF out_qpdf;
            out_qpdf.emptyPDF();
            QPDFPageDocumentHelper out_pdh(out_qpdf);
            out_pdh.addPage(pages[i], false);

            QoreString out_path;
            out_path.sprintf("%s/%s%zu.pdf", output_dir.c_str(), prefix.c_str(), i + 1);

            QPDFWriter writer(out_qpdf, out_path.c_str());
            writer.write();

            outputs->push(new QoreStringNode(out_path.c_str()), xsink);
        }

        return outputs;
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
        return outputs;
    }
}
