# -*- mode: qore; indent-tabs-mode: nil -*-
#! Qore PdfExtractTextDataProvider class definition

/** PdfExtractTextDataProvider.qc Copyright (C) 2026 Qore Technologies, s.r.o.

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
#! Extract text data provider
public class PdfExtractTextDataProvider inherits AbstractDataProvider {
    public {
        const ProviderInfo = <DataProviderInfo>{
            "name": "extract-text",
            "desc": "Extract text from a PDF page using PDFium",
            "type": "PdfExtractTextDataProvider",
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
        return new PdfExtractTextRequestDataType();
    }

    private *AbstractDataProviderType getResponseTypeImpl() {
        return AbstractDataProviderType::get(new Type("hash<PdfExtractTextResponse>"));
    }

    private auto doRequestImpl(auto req, *hash<auto> request_options) {
        hash<auto> request = req;

        if (!PdfRenderer::isAvailable()) {
            throw "PDF-ERROR", "PDFium support is not available";
        }

        if (request.page_index < 0) {
            throw "PDF-ERROR", "page_index must be non-negative";
        }

        @debug("extracting text: input_path=%y location=%y has_data=%y page=%d",
            request.input_path, request.location, exists request.data, request.page_index);

        string text;
        if (request.input_path) {
            text = PdfRenderer::extractText(request.input_path, request.page_index);
        } else {
            binary pdf_data = PdfActionBase::getRendererData(request);
            text = PdfRenderer::extractTextFromData(pdf_data, request.page_index);
        }

        hash<PdfExtractTextResponse> response();
        response.text = text;

        @debug("text extracted: length=%d", text.size());

        return response;
    }
}
}
