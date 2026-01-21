# -*- mode: qore; indent-tabs-mode: nil -*-
#! @file PdfDataProvider.qc provides the PdfDataProvider class definition

/** PdfDataProvider.qc Copyright (C) 2026 Qore Technologies, s.r.o.

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
/** @brief Root data provider for PDF operations

    This is the root data provider that provides access to PDF document operations through
    child providers:
    - @ref PdfDocumentDataProvider "document" - Document manipulation operations
    - @ref PdfRenderDataProvider "render" - Rendering and text extraction (requires PDFium)

    @par Data Provider Path
    Data providers are accessed through paths like: pdf{}/document/create
*/
public class PdfDataProvider inherits AbstractDataProvider {
    public {
        const ProviderInfo = <DataProviderInfo>{
            "name": "pdf",
            "desc": "PDF data provider root",
            "type": "PdfDataProvider",
            "supports_request": False,
        };
    }

    private {
        #! Child map without render (always available)
        const BaseChildMap = {
            "document": "PdfDataProvider::PdfDocumentDataProvider",
        };
        *hash<auto> opts;
        #! Actual child map (computed based on PDFium availability)
        hash<string, string> childMap;
    }

    constructor(*hash<auto> opts) {
        self.opts = opts;
        # Start with base child map
        childMap = BaseChildMap;
        # Add render provider only if PDFium is available
        if (PdfRenderer::isAvailable()) {
            childMap{"render"} = "PdfDataProvider::PdfRenderDataProvider";
        }
    }

    string getName() {
        return ProviderInfo.name;
    }

    private hash<DataProviderInfo> getStaticInfoImpl() {
        return ProviderInfo;
    }

    private *AbstractDataProvider getChildProviderImpl(string name) {
        *string cls_name = childMap{name};
        if (!cls_name) {
            return NOTHING;
        }
        Class cls = Class::forName(cls_name);
        return cls.newObject(opts);
    }

    private *list<string> getChildProviderNamesImpl() {
        return childMap.keys();
    }
}
}
