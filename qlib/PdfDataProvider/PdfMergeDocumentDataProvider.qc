# -*- mode: qore; indent-tabs-mode: nil -*-
#! Qore PdfMergeDocumentDataProvider class definition

/** PdfMergeDocumentDataProvider.qc Copyright (C) 2026 Qore Technologies, s.r.o.

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
#! Merge documents data provider
public class PdfMergeDocumentDataProvider inherits AbstractDataProvider {
    public {
        const ProviderInfo = <DataProviderInfo>{
            "name": "merge",
            "desc": "Merge multiple PDFs into a single document",
            "type": "PdfMergeDocumentDataProvider",
            "supports_request": True,
        };
    }

    private {
        *hash<auto> opts;
    }

    constructor(*hash<auto> opts) {
        self.opts = opts;
    }

    string getName() {
        return ProviderInfo.name;
    }

    private hash<DataProviderInfo> getStaticInfoImpl() {
        return ProviderInfo;
    }

    private *AbstractDataProviderType getRequestTypeImpl() {
        return AbstractDataProviderType::get(new Type("hash<PdfMergeDocumentRequest>"));
    }

    private *AbstractDataProviderType getResponseTypeImpl() {
        return AbstractDataProviderType::get(new Type("hash<PdfMergeDocumentResponse>"));
    }

    private auto doRequestImpl(auto req, *hash<auto> request_options) {
        hash<PdfMergeDocumentRequest> request = req;

        if (!request.inputs || request.inputs.size() == 0) {
            throw "PDF-ERROR", "inputs must contain at least one PDF";
        }

        if (!request.output_path || request.output_path.size() == 0) {
            throw "PDF-ERROR", "output_path is required";
        }

        PdfDocument merged = PdfDocument::merge(request.inputs, request.password);
        merged.save(request.output_path);

        hash<PdfMergeDocumentResponse> response();
        response.success = True;
        response.output_path = request.output_path;
        response.page_count = merged.pageCount();
        response.size = hstat(request.output_path).size;
        response.warnings = merged.getWarnings();

        return response;
    }
}
}
