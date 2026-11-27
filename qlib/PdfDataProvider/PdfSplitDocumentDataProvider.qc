# -*- mode: qore; indent-tabs-mode: nil -*-
#! Qore PdfSplitDocumentDataProvider class definition

/** PdfSplitDocumentDataProvider.qc Copyright (C) 2026 Qore Technologies, s.r.o.

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
#! Split document data provider
public class PdfSplitDocumentDataProvider inherits AbstractDataProvider {
    public {
        const ProviderInfo = <DataProviderInfo>{
            "name": "split",
            "desc": "Split a PDF into individual pages",
            "type": "PdfSplitDocumentDataProvider",
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
        return new PdfSplitDocumentRequestDataType();
    }

    private *AbstractDataProviderType getResponseTypeImpl() {
        return AbstractDataProviderType::get(new Type("hash<PdfSplitDocumentResponse>"));
    }

    private auto doRequestImpl(auto req, *hash<auto> request_options) {
        hash<auto> request = req;
        # the paths and locations in the request are the caller's input, also for the code that a host-created
        # provider was lent to: refused before anything is read or written if that code is restricted (issue #8)
        PdfActionBase::checkCallerPaths(request, ("input_path", "output_dir"), ("location",));

        if (!request.output_dir || request.output_dir.size() == 0) {
            throw "PDF-ERROR", "output_dir is required";
        }

        @debug("splitting document: input_path=%y location=%y has_data=%y output_dir=%y",
            request.input_path, request.location, exists request.data, request.output_dir);

        *string prefix = request.prefix;
        list<string> outputs;
        PdfDocument doc;
        if (request.input_path) {
            # Load document first to capture warnings
            doc = new PdfDocument(request.input_path);
            outputs = PdfDocument::split(request.input_path, request.output_dir, prefix ? prefix : "page_");
        } else {
            # data and location inputs are split in memory: no temporary file is written (issue #10)
            binary pdf_data;
            if (request.location) {
                pdf_data = FileLocationHandler::getBinaryFileFromLocation(request.location);
            } else if (request.data) {
                pdf_data = request.data;
            } else {
                throw "PDF-ERROR", "one of 'input_path', 'data', or 'location' must be provided";
            }
            doc = new PdfDocument(pdf_data);
            outputs = doc.splitTo(request.output_dir, prefix ? prefix : "page_");
        }

        hash<PdfSplitDocumentResponse> response();
        response.outputs = outputs;
        response.count = outputs.size();
        response.warnings = doc.getWarnings();

        @debug("split complete: pages=%d", response.count);

        return response;
    }
}
}
