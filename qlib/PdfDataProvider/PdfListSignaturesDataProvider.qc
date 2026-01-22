# -*- mode: qore; indent-tabs-mode: nil -*-
#! Qore PdfListSignaturesDataProvider class definition

/** PdfListSignaturesDataProvider.qc Copyright (C) 2026 Qore Technologies, s.r.o.

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
#! List all digital signature fields in a PDF document
/**
    This data provider returns information about all digital signature fields in a PDF document,
    including both signed and unsigned signature fields.

    For each signature field, returns:
    - name: Field name
    - signer_name: Name of signer (if signed)
    - reason: Signing reason (if provided)
    - location: Signing location (if provided)
    - date: Signing date/time (if signed)
    - page: Page index where the field appears

    @par Example:
    @code{.py}
    hash<auto> response = dp.doRequest(<PdfListSignaturesRequest>{
        "input_path": "signed_document.pdf",
    });
    foreach hash<auto> sig in (response.signatures) {
        printf("Signature: %s (signer: %s)\n", sig.name, sig.signer_name ?? "not signed");
    }
    @endcode
*/
public class PdfListSignaturesDataProvider inherits AbstractDataProvider {
    public {
        const ProviderInfo = <DataProviderInfo>{
            "name": "list-signatures",
            "desc": "List all digital signature fields in a PDF document (signed and unsigned)",
            "type": "PdfListSignaturesDataProvider",
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
        return AbstractDataProviderType::get(new Type("hash<PdfListSignaturesRequest>"));
    }

    private *AbstractDataProviderType getResponseTypeImpl() {
        return AbstractDataProviderType::get(new Type("hash<PdfListSignaturesResponse>"));
    }

    private auto doRequestImpl(auto req, *hash<auto> request_options) {
        hash<PdfListSignaturesRequest> request = req;

        # Validate required fields
        if (!request.input_path || request.input_path.size() == 0) {
            throw "PDF-ERROR", "input_path is required";
        }

        @debug("listing signatures: input=%y", request.input_path);

        PdfEditor editor(request.input_path, request.password);
        list<hash<auto>> signatures = editor.getSignatures();

        hash<PdfListSignaturesResponse> response();
        response.success = True;
        response.signatures = signatures;
        response.signature_count = signatures.size();

        @debug("signatures found: count=%d", response.signature_count);

        return response;
    }
}
}
