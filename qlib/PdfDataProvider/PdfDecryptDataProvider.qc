# -*- mode: qore; indent-tabs-mode: nil -*-
#! Qore PdfDecryptDataProvider class definition

/** PdfDecryptDataProvider.qc Copyright (C) 2026 Qore Technologies, s.r.o.

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
#! Remove encryption from a PDF document
/**
    This data provider removes password protection and encryption from PDF documents.

    The owner password is required to remove encryption. The user password alone
    is not sufficient for decryption.

    @par Example:
    @code{.py}
    hash<auto> response = dp.doRequest(<PdfDecryptRequest>{
        "input_path": "encrypted.pdf",
        "output_path": "decrypted.pdf",
        "password": "owner_password",
    });
    @endcode
*/
public class PdfDecryptDataProvider inherits AbstractDataProvider {
    public {
        const ProviderInfo = <DataProviderInfo>{
            "name": "decrypt",
            "desc": "Remove encryption from a PDF document (requires owner password)",
            "type": "PdfDecryptDataProvider",
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
        return new PdfDecryptRequestDataType();
    }

    private *AbstractDataProviderType getResponseTypeImpl() {
        return AbstractDataProviderType::get(new Type("hash<PdfDecryptResponse>"));
    }

    private auto doRequestImpl(auto req, *hash<auto> request_options) {
        hash<auto> request = req;

        PdfActionBase::validateOutputRequired(request);

        # Validate required fields
        if (!request.password || request.password.size() == 0) {
            throw "PDF-ERROR", "password is required";
        }

        @debug("decrypting PDF: input_path=%y location=%y has_data=%y",
            request.input_path, request.location, exists request.data);

        # Load document with password
        PdfEditor editor = PdfActionBase::loadEditorWithPassword(request, request.password);

        # Remove encryption
        editor.removeEncryption();

        # Save the document
        hash<auto> output = PdfActionBase::saveEditorOutput(editor, request);

        hash<PdfDecryptResponse> response();
        response.success = True;
        response += output;

        @debug("decryption complete: size=%d", response.size);

        return response;
    }
}
}
