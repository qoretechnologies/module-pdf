# -*- mode: qore; indent-tabs-mode: nil -*-
#! Qore PdfCreateDocumentDataProvider class definition

/** PdfCreateDocumentDataProvider.qc Copyright (C) 2026 Qore Technologies, s.r.o.

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
#! Create document data provider
public class PdfCreateDocumentDataProvider inherits AbstractDataProvider {
    public {
        const ProviderInfo = <DataProviderInfo>{
            "name": "create",
            "desc": "Create a PDF document",
            "type": "PdfCreateDocumentDataProvider",
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
        return new PdfCreateDocumentRequestDataType();
    }

    private *AbstractDataProviderType getResponseTypeImpl() {
        return AbstractDataProviderType::get(new Type("hash<PdfCreateDocumentResponse>"));
    }

    private auto doRequestImpl(auto req, *hash<auto> request_options) {
        hash<auto> request = req;

        @debug("creating document: output_path=%y output_location=%y",
            request.output_path, request.output_location);

        PdfWriter writer();

        if (request.font_options) {
            writer.setFontOptions(request.font_options);
        }

        if (request.metadata) {
            writer.setMetadata(request.metadata);
        }

        if (request.pages) {
            if (request.pages.size() == 0) {
                throw "PDF-ERROR", "pages cannot be empty";
            }

            foreach hash<PdfCreatePageSpec> page in (request.pages) {
                string type = tolower(page.type);
                float width = 612.0;
                float height = 792.0;

                if (exists page.width) {
                    width = page.width;
                }
                if (exists page.height) {
                    height = page.height;
                }

                if (width <= 0.0 || height <= 0.0) {
                    throw "PDF-ERROR", sprintf("page size must be positive (%.2f x %.2f)", width, height);
                }

                # Validate page type
                list<string> valid_types = (
                    PdfPageType::Blank,
                    PdfPageType::Text,
                );
                if (!inlist(type, valid_types)) {
                    throw "PDF-ERROR", sprintf("invalid page type %y; allowed values: %y",
                        page.type, valid_types);
                }

                if (type == PdfPageType::Blank) {
                    writer.addBlankPage(width, height);
                } else if (type == PdfPageType::Text) {
                    if (!page.text) {
                        throw "PDF-ERROR", "text is required for text pages";
                    }
                    writer.addTextPage(page.text, width, height);
                }
            }
        } else if (request.page_count) {
            int count = request.page_count;
            if (count <= 0) {
                throw "PDF-ERROR", "page_count must be positive";
            }
            for (int i = 0; i < count; ++i) {
                writer.addBlankPage();
            }
        } else {
            throw "PDF-ERROR", "pages or page_count is required";
        }

        binary pdf_data = writer.saveToMemory();
        hash<auto> output = PdfActionBase::makeOutputResponse(pdf_data, request);

        hash<PdfCreateDocumentResponse> response();
        response.success = True;
        response += output;
        response.page_count = writer.pageCount();

        @debug("document created: pages=%d size=%d", response.page_count, response.size);

        return response;
    }
}
}
