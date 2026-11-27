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

#ifndef QORE_PDF_MODULE_H
#define QORE_PDF_MODULE_H

#include <qore/Qore.h>
#include <qore/QoreSandboxManager.h>

extern const TypedHashDecl* hashdeclPdfMetadata;
extern const TypedHashDecl* hashdeclPdfRenderResult;
extern const TypedHashDecl* hashdeclPdfFontOptions;
extern const TypedHashDecl* hashdeclPdfPosition;
extern const TypedHashDecl* hashdeclPdfColor;
extern const TypedHashDecl* hashdeclPdfTextStyle;
extern const TypedHashDecl* hashdeclPdfFontSpec;

DLLLOCAL TypedHashDecl* init_hashdecl_PdfMetadata(QoreNamespace& ns);
DLLLOCAL TypedHashDecl* init_hashdecl_PdfRenderResult(QoreNamespace& ns);
DLLLOCAL TypedHashDecl* init_hashdecl_PdfFontOptions(QoreNamespace& ns);
DLLLOCAL TypedHashDecl* init_hashdecl_PdfPosition(QoreNamespace& ns);
DLLLOCAL TypedHashDecl* init_hashdecl_PdfColor(QoreNamespace& ns);
DLLLOCAL TypedHashDecl* init_hashdecl_PdfTextStyle(QoreNamespace& ns);
DLLLOCAL TypedHashDecl* init_hashdecl_PdfFontSpec(QoreNamespace& ns);

#ifdef QORE_HAVE_CALLER_AMBIENT_PREDICATES
//! the paths that a lent object gives are decided with the code that it was lent to
#define PDF_LENT_PATH_CHECKS_VAL true
#else
#define PDF_LENT_PATH_CHECKS_VAL false
#endif

//! Refuses a file path that the calling code gives if that code is restricted from the file system
/** A method of an object that unrestricted code (the host) created and lent to restricted code runs with the file
    system lent (a capability frame): the code that the object was lent to decides
    (qore_caller_lent_to_restricts_domain(); module-pdf#12).  With a %Qore without that function
    (\c QORE_HAVE_CALLER_AMBIENT_PREDICATES is not defined), only the calling code decides
    (qore_caller_restricts_domain()) if \a always is true, and nothing is checked otherwise: the methods with the
    \c FILESYSTEM functional domain are refused for restricted calling code when they are called

    @param what the argument or option with the path, for the exception
    @param always true for a path that a method without the \c FILESYSTEM functional domain takes (such as the
    \c font_path of a font)
    @param xsink raises \c PERMISSION-DENIED if the path is refused

    @return 0 if the path can be used, -1 if \c PERMISSION-DENIED was raised
*/
DLLLOCAL int pdf_check_caller_path(const char* what, bool always, ExceptionSink* xsink);

#endif
