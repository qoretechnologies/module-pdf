# -*- mode: qore; indent-tabs-mode: nil -*-
#! Qore PdfRenderPageDataProvider class definition

/** PdfRenderPageDataProvider.qc Copyright (C) 2026 Qore Technologies, s.r.o.

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
#! Render page data provider
public class PdfRenderPageDataProvider inherits AbstractDataProvider {
    public {
        const ProviderInfo = <DataProviderInfo>{
            "name": "page",
            "desc": "Render a PDF page using PDFium",
            "type": "PdfRenderPageDataProvider",
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
        return new PdfRenderPageRequestDataType();
    }

    private *AbstractDataProviderType getResponseTypeImpl() {
        return AbstractDataProviderType::get(new Type("hash<PdfRenderPageResponse>"));
    }

    private auto doRequestImpl(auto req, *hash<auto> request_options) {
        hash<auto> request = req;

        if (!PdfRenderer::isAvailable()) {
            throw "PDF-ERROR", "PDFium support is not available";
        }

        if (request.page_index < 0) {
            throw "PDF-ERROR", "page_index must be non-negative";
        }

        int dpi = 150;
        if (request.dpi) {
            dpi = request.dpi;
        }
        if (dpi <= 0) {
            throw "PDF-ERROR", "dpi must be positive";
        }

        @debug("rendering page: input_path=%y location=%y has_data=%y page=%d dpi=%d",
            request.input_path, request.location, exists request.data, request.page_index, dpi);

        hash<PdfRenderResult> result;
        if (request.input_path) {
            result = PdfRenderer::renderPage(request.input_path, request.page_index, dpi);
        } else {
            binary pdf_data = PdfActionBase::getRendererData(request);
            result = PdfRenderer::renderPageFromData(pdf_data, request.page_index, dpi);
        }

        *string output_path = request.output_path;
        if (output_path) {
            File file = new File();
            file.open(output_path, O_CREAT | O_WRONLY | O_TRUNC, 0644);
            file.write(result.data);
            file.close();
        }

        hash<PdfRenderPageResponse> response();
        response.width = result.width;
        response.height = result.height;
        response.stride = result.stride;
        response.format = result.format;
        if (output_path) {
            response.output_path = output_path;
            response.size = hstat(output_path).size;
        } else {
            response.data = result.data;
            response.size = result.data.size();
        }

        @debug("render complete: %dx%d size=%d", response.width, response.height, response.size);

        return response;
    }
}
}
