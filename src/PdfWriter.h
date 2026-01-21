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

#ifndef QORE_PDF_WRITER_H
#define QORE_PDF_WRITER_H

#include <qore/Qore.h>
#include <podofo/podofo.h>

#include <string>

class QorePdfWriter : public AbstractPrivateData {
public:
    QorePdfWriter();

    int pageCount() const;
    void addBlankPage(double width, double height, ExceptionSink* xsink);
    void addTextPage(const std::string& text, double width, double height, ExceptionSink* xsink);
    void setMetadata(const QoreHashNode* metadata, ExceptionSink* xsink);
    void setFontOptions(const QoreHashNode* opts, ExceptionSink* xsink);
    void save(const std::string& path, ExceptionSink* xsink);

private:
    PoDoFo::PdfMemDocument doc;
    bool embed_fonts = true;
    bool subset_fonts = true;
    bool prefer_non_cid = false;
};

#endif
