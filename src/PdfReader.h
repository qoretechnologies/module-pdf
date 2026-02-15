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

#ifndef QORE_PDF_READER_H
#define QORE_PDF_READER_H

#include "PdfDocument.h"

#include <string>

class QorePdfReader : public AbstractPrivateData {
public:
    QorePdfReader(const std::string& path, const std::string& password, ExceptionSink* xsink)
            : doc(path, password, xsink) {
    }

    QorePdfReader(const BinaryNode* data, const std::string& password, ExceptionSink* xsink)
            : doc(data, password, xsink) {
    }

    int pageCount(ExceptionSink* xsink) {
        return doc.pageCount(xsink);
    }

    QoreHashNode* getMetadata(ExceptionSink* xsink) {
        return doc.getMetadata(xsink);
    }

private:
    QorePdfDocument doc;
};

#endif
