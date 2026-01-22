/* -*- mode: c++; indent-tabs-mode: nil -*- */
/** @file pdf-module.cpp pdf module implementation */
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

#include "pdf-module.h"
#include "QC_PdfDocument.h"
#include "QC_PdfReader.h"
#include "QC_PdfWriter.h"
#include "QC_PdfRenderer.h"
#include "QC_PdfPage.h"
#include "QC_PdfEditor.h"

static QoreStringNode* pdf_module_init();
static void pdf_module_ns_init(QoreNamespace* rns, QoreNamespace* qns);
static void pdf_module_delete();

DLLEXPORT char qore_module_name[] = "pdf";
DLLEXPORT char qore_module_version[] = "1.0.0";
DLLEXPORT char qore_module_description[] = "Qore PDF module";
DLLEXPORT char qore_module_author[] = "Qore Technologies, s.r.o.";
DLLEXPORT char qore_module_url[] = "https://github.com/qoretechnologies/module-pdf";
DLLEXPORT int qore_module_api_major = QORE_MODULE_API_MAJOR;
DLLEXPORT int qore_module_api_minor = QORE_MODULE_API_MINOR;
DLLEXPORT qore_module_init_t qore_module_init = pdf_module_init;
DLLEXPORT qore_module_ns_init_t qore_module_ns_init = pdf_module_ns_init;
DLLEXPORT qore_module_delete_t qore_module_delete = pdf_module_delete;
DLLEXPORT qore_license_t qore_module_license = QL_MIT;
DLLEXPORT char qore_module_license_str[] = "MIT";

const TypedHashDecl* hashdeclPdfMetadata = nullptr;
const TypedHashDecl* hashdeclPdfRenderResult = nullptr;
const TypedHashDecl* hashdeclPdfFontOptions = nullptr;
const TypedHashDecl* hashdeclPdfPosition = nullptr;
const TypedHashDecl* hashdeclPdfColor = nullptr;
const TypedHashDecl* hashdeclPdfTextStyle = nullptr;
const TypedHashDecl* hashdeclPdfFontSpec = nullptr;

QoreNamespace PdfNs("Qore::Pdf");

static QoreStringNode* pdf_module_init() {
    hashdeclPdfMetadata = init_hashdecl_PdfMetadata(PdfNs);
    hashdeclPdfRenderResult = init_hashdecl_PdfRenderResult(PdfNs);
    hashdeclPdfFontOptions = init_hashdecl_PdfFontOptions(PdfNs);
    hashdeclPdfFontSpec = init_hashdecl_PdfFontSpec(PdfNs);
    hashdeclPdfPosition = init_hashdecl_PdfPosition(PdfNs);
    hashdeclPdfColor = init_hashdecl_PdfColor(PdfNs);
    hashdeclPdfTextStyle = init_hashdecl_PdfTextStyle(PdfNs);

    PdfNs.addSystemClass(initPdfDocumentClass(PdfNs));
    PdfNs.addSystemClass(initPdfPageClass(PdfNs));
    PdfNs.addSystemClass(initPdfReaderClass(PdfNs));
    PdfNs.addSystemClass(initPdfWriterClass(PdfNs));
    PdfNs.addSystemClass(initPdfRendererClass(PdfNs));
    PdfNs.addSystemClass(initPdfEditorClass(PdfNs));

    return nullptr;
}

static void pdf_module_ns_init(QoreNamespace* rns, QoreNamespace* qns) {
    qns->addNamespace(PdfNs.copy());
}

static void pdf_module_delete() {
}
