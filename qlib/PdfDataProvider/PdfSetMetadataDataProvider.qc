# -*- mode: qore; indent-tabs-mode: nil -*-
#! Qore PdfSetMetadataDataProvider class definition

/** PdfSetMetadataDataProvider.qc Copyright (C) 2026 Qore Technologies, s.r.o.

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
#! Update metadata data provider
public class PdfSetMetadataDataProvider inherits AbstractDataProvider {
    public {
        const ProviderInfo = <DataProviderInfo>{
            "name": "metadata",
            "desc": "Update PDF metadata",
            "type": "PdfSetMetadataDataProvider",
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
        return new PdfSetMetadataRequestDataType();
    }

    private *AbstractDataProviderType getResponseTypeImpl() {
        return AbstractDataProviderType::get(new Type("hash<PdfSetMetadataResponse>"));
    }

    private auto doRequestImpl(auto req, *hash<auto> request_options) {
        hash<auto> request = req;

        if (!request.metadata) {
            throw "PDF-ERROR", "metadata is required";
        }

        PdfActionBase::validateOutputRequired(request);

        @debug("setting metadata: input_path=%y location=%y has_data=%y",
            request.input_path, request.location, exists request.data);

        PdfDocument doc = PdfActionBase::loadDocument(request);
        doc.setMetadata(request.metadata);

        binary pdf_data = doc.toData();
        hash<auto> output = PdfActionBase::makeOutputResponse(pdf_data, request);

        hash<PdfSetMetadataResponse> response();
        response.success = True;
        response += output;
        response.page_count = doc.pageCount();
        response.warnings = doc.getWarnings();

        @debug("metadata set: pages=%d", response.page_count);

        return response;
    }
}
}
