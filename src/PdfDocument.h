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

#ifndef QORE_PDF_DOCUMENT_H
#define QORE_PDF_DOCUMENT_H

#include <qore/Qore.h>

#include <qpdf/QPDF.hh>
#include <qpdf/QPDFPageDocumentHelper.hh>
#include <qpdf/QPDFPageObjectHelper.hh>
#include <qpdf/QPDFWriter.hh>

#include <memory>
#include <string>
#include <vector>

class QorePdfDocument : public AbstractPrivateData {
public:
    QorePdfDocument(const std::string& path, const std::string& password, ExceptionSink* xsink);
    QorePdfDocument(const BinaryNode* data, const std::string& password, ExceptionSink* xsink);
    QorePdfDocument(std::unique_ptr<QPDF> doc);

    int pageCount(ExceptionSink* xsink);
    QoreHashNode* getMetadata(ExceptionSink* xsink);
    void setMetadata(const QoreHashNode* metadata, ExceptionSink* xsink);
    void save(const std::string& path, ExceptionSink* xsink);
    BinaryNode* toData(ExceptionSink* xsink);
    void rotatePages(const QoreListNode* pages, int degrees, ExceptionSink* xsink);

    //! Returns any warnings generated during document operations
    QoreListNode* getWarnings(ExceptionSink* xsink);

    static QorePdfDocument* merge(const QoreListNode* inputs, const std::string& password,
            ExceptionSink* xsink);
    static QorePdfDocument* mergeWithWarnings(const QoreListNode* inputs, const std::string& password,
            QoreListNode*& warnings, ExceptionSink* xsink);
    static QoreListNode* split(const std::string& input, const std::string& output_dir,
            const std::string& prefix, ExceptionSink* xsink);
    static QoreListNode* splitWithWarnings(const std::string& input, const std::string& output_dir,
            const std::string& prefix, QoreListNode*& warnings, ExceptionSink* xsink);

    //! Helper to convert QPDF warnings to a Qore list
    static QoreListNode* collectWarnings(QPDF& qpdf);

private:
    std::unique_ptr<QPDF> qpdf;
    SimpleRefHolder<BinaryNode> binary_data;
    std::string password;
    bool has_doc = false;

    QoreHashNode* buildMetadataHash(QPDFObjectHandle info, ExceptionSink* xsink);
    void applyMetadata(const QoreHashNode* metadata, QPDFObjectHandle& info, ExceptionSink* xsink);
};

#endif
