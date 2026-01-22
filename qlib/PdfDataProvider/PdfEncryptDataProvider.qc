# -*- mode: qore; indent-tabs-mode: nil -*-
#! Qore PdfEncryptDataProvider class definition

/** PdfEncryptDataProvider.qc Copyright (C) 2026 Qore Technologies, s.r.o.

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
#! Encrypt a PDF document with password protection
/**
    This data provider encrypts PDF documents using industry-standard encryption algorithms.

    Supported algorithms (see PdfEncryptionAlgorithms):
    - "aes-256" (recommended, default) - 256-bit AES encryption (PDF 2.0)
    - "aes-128" - 128-bit AES encryption (PDF 1.6)
    - "rc4-128" - 128-bit RC4 encryption (PDF 1.4, legacy)
    - "rc4-40" - 40-bit RC4 encryption (PDF 1.3, legacy)

    @par Example:
    @code{.py}
    hash<auto> response = dp.doRequest(<PdfEncryptRequest>{
        "input_path": "document.pdf",
        "output_path": "encrypted.pdf",
        "owner_password": "secret123",
        "algorithm": "aes-256",
    });
    @endcode
*/
public class PdfEncryptDataProvider inherits AbstractDataProvider {
    public {
        const ProviderInfo = <DataProviderInfo>{
            "name": "encrypt",
            "desc": "Encrypt a PDF document with password protection and optional permission restrictions",
            "type": "PdfEncryptDataProvider",
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
        return AbstractDataProviderType::get(new Type("hash<PdfEncryptRequest>"));
    }

    private *AbstractDataProviderType getResponseTypeImpl() {
        return AbstractDataProviderType::get(new Type("hash<PdfEncryptResponse>"));
    }

    private auto doRequestImpl(auto req, *hash<auto> request_options) {
        hash<PdfEncryptRequest> request = req;

        # Validate required fields
        if (!request.input_path || request.input_path.size() == 0) {
            throw "PDF-ERROR", "input_path is required";
        }
        if (!request.owner_password || request.owner_password.size() == 0) {
            throw "PDF-ERROR", "owner_password is required";
        }
        if (!request.output_path && !request.overwrite) {
            throw "PDF-ERROR", "either output_path or overwrite must be specified";
        }

        # Validate and get algorithm (default to "aes-256")
        string algorithm = request.algorithm ?? PdfEncryptionAlgorithm::Aes256;
        list<string> valid_algorithms = (
            PdfEncryptionAlgorithm::Rc4_40,
            PdfEncryptionAlgorithm::Rc4_128,
            PdfEncryptionAlgorithm::Aes128,
            PdfEncryptionAlgorithm::Aes256,
        );
        if (!inlist(algorithm, valid_algorithms)) {
            throw "PDF-ERROR", sprintf("invalid algorithm %y; allowed values: %y", algorithm, valid_algorithms);
        }

        # Determine output path
        string output_path = request.output_path ?? request.input_path;

        @debug("encrypting PDF: input=%y output=%y algorithm=%y", request.input_path, output_path, algorithm);

        # Load document (with password if already encrypted)
        PdfEditor editor(request.input_path, request.input_password);

        # Set encryption
        editor.setEncryption(request.owner_password, request.user_password,
            request.permissions, algorithm);

        # Save the document
        if (output_path == request.input_path) {
            string temp_path = output_path + ".tmp";
            editor.save(temp_path);
            rename(temp_path, output_path);
        } else {
            editor.save(output_path);
        }

        hash<PdfEncryptResponse> response();
        response.success = True;
        response.output_path = output_path;
        response.algorithm = algorithm;
        response.size = hstat(output_path).size;

        @debug("encryption complete: size=%d", response.size);

        return response;
    }
}
}
