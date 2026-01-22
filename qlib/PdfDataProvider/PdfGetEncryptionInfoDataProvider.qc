# -*- mode: qore; indent-tabs-mode: nil -*-
#! Qore PdfGetEncryptionInfoDataProvider class definition

/** PdfGetEncryptionInfoDataProvider.qc Copyright (C) 2026 Qore Technologies, s.r.o.

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
#! Get encryption information from a PDF document
/**
    This data provider returns encryption details about a PDF document including:
    - encrypted: Whether the document is encrypted
    - algorithm: Encryption algorithm (if encrypted)
    - key_length: Key length in bits (if encrypted)
    - permissions: Document permission flags (if encrypted)
    - metadata_encrypted: Whether metadata is also encrypted

    @par Supported algorithms (see PdfEncryptionAlgorithms):
    - "rc4-40" - 40-bit RC4 (legacy)
    - "rc4-128" - 128-bit RC4 (legacy)
    - "aes-128" - 128-bit AES
    - "aes-256" - 256-bit AES

    @par Example:
    @code{.py}
    hash<auto> response = dp.doRequest(<PdfGetEncryptionInfoRequest>{
        "input_path": "document.pdf",
    });
    if (response.encrypted) {
        printf("Encrypted with: %s (%d-bit key)\n", response.algorithm, response.key_length);
    }
    @endcode
*/
public class PdfGetEncryptionInfoDataProvider inherits AbstractDataProvider {
    public {
        const ProviderInfo = <DataProviderInfo>{
            "name": "get-encryption-info",
            "desc": "Get encryption information from a PDF (algorithm, key length, permissions)",
            "type": "PdfGetEncryptionInfoDataProvider",
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
        return AbstractDataProviderType::get(new Type("hash<PdfGetEncryptionInfoRequest>"));
    }

    private *AbstractDataProviderType getResponseTypeImpl() {
        return AbstractDataProviderType::get(new Type("hash<PdfEncryptionInfo>"));
    }

    private auto doRequestImpl(auto req, *hash<auto> request_options) {
        hash<PdfGetEncryptionInfoRequest> request = req;

        # Validate required fields
        if (!request.input_path || request.input_path.size() == 0) {
            throw "PDF-ERROR", "input_path is required";
        }

        @debug("getting encryption info: input=%y", request.input_path);

        # Use static method to get encryption info
        hash<auto> info = PdfEditor::getEncryptionInfo(request.input_path, request.password);

        @debug("encryption info: encrypted=%y algorithm=%y", info.encrypted, info.algorithm);

        return info;
    }
}
}
