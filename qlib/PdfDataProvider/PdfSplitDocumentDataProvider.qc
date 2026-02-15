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

        if (!request.output_dir || request.output_dir.size() == 0) {
            throw "PDF-ERROR", "output_dir is required";
        }

        @debug("splitting document: input_path=%y location=%y has_data=%y output_dir=%y",
            request.input_path, request.location, exists request.data, request.output_dir);

        # For binary/location input, write to temp file first since split uses file paths
        string input_path;
        *string temp_path;
        if (request.input_path) {
            input_path = request.input_path;
        } else {
            binary pdf_data;
            if (request.location) {
                pdf_data = FileLocationHandler::getBinaryFileFromLocation(request.location);
            } else if (request.data) {
                pdf_data = request.data;
            } else {
                throw "PDF-ERROR", "one of 'input_path', 'data', or 'location' must be provided";
            }
            temp_path = sprintf("%s/.pdf_split_tmp_%d.pdf", request.output_dir, getpid());
            PdfActionBase::writeBinaryFile(temp_path, pdf_data);
            input_path = temp_path;
        }

        on_exit {
            if (temp_path && is_file(temp_path)) {
                unlink(temp_path);
            }
        }

        # Load document first to capture warnings
        PdfDocument doc(input_path);

        *string prefix = request.prefix;
        list<string> outputs = PdfDocument::split(input_path, request.output_dir,
            prefix ? prefix : "page_");

        hash<PdfSplitDocumentResponse> response();
        response.outputs = outputs;
        response.count = outputs.size();
        response.warnings = doc.getWarnings();

        @debug("split complete: pages=%d", response.count);

        return response;
    }
}
}
