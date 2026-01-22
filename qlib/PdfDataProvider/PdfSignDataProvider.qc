# -*- mode: qore; indent-tabs-mode: nil -*-
#! Qore PdfSignDataProvider class definition

/** PdfSignDataProvider.qc Copyright (C) 2026 Qore Technologies, s.r.o.

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
#! Sign a PDF document with a digital certificate
/**
    This data provider applies a digital signature to a PDF document using an X.509 certificate
    and private key.

    Prerequisites:
    - The PDF must contain a signature field (use create-signature-field first)
    - A valid X.509 certificate and private key are required (PEM or DER format)

    Supported hash algorithms (see PdfHashAlgorithms):
    - "sha256" (default, recommended)
    - "sha384"
    - "sha512"

    @par Example:
    @code{.py}
    hash<auto> response = dp.doRequest(<PdfSignRequest>{
        "input_path": "document.pdf",
        "output_path": "signed.pdf",
        "field_name": "signature1",
        "certificate_path": "/path/to/cert.pem",
        "private_key_path": "/path/to/key.pem",
        "signer_name": "John Doe",
        "reason": "Document approval",
    });
    @endcode
*/
public class PdfSignDataProvider inherits AbstractDataProvider {
    public {
        const ProviderInfo = <DataProviderInfo>{
            "name": "sign",
            "desc": "Sign a PDF document with an X.509 digital certificate (supports SHA-256/384/512)",
            "type": "PdfSignDataProvider",
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
        return AbstractDataProviderType::get(new Type("hash<PdfSignRequest>"));
    }

    private *AbstractDataProviderType getResponseTypeImpl() {
        return AbstractDataProviderType::get(new Type("hash<PdfSignResponse>"));
    }

    private auto doRequestImpl(auto req, *hash<auto> request_options) {
        hash<PdfSignRequest> request = req;

        # Validate required fields
        if (!request.input_path || request.input_path.size() == 0) {
            throw "PDF-ERROR", "input_path is required";
        }
        if (!request.field_name || request.field_name.size() == 0) {
            throw "PDF-ERROR", "field_name is required";
        }
        if (!request.certificate_data && !request.certificate_path) {
            throw "PDF-ERROR", "either certificate_path or certificate_data is required";
        }
        if (!request.private_key_data && !request.private_key_path) {
            throw "PDF-ERROR", "either private_key_path or private_key_data is required";
        }
        if (!request.output_path && !request.overwrite) {
            throw "PDF-ERROR", "either output_path or overwrite must be specified";
        }

        # Validate hash algorithm if specified
        if (request.hash_algorithm) {
            list<string> valid_algorithms = (
                PdfHashAlgorithm::Sha256,
                PdfHashAlgorithm::Sha384,
                PdfHashAlgorithm::Sha512,
            );
            if (!inlist(request.hash_algorithm, valid_algorithms)) {
                throw "PDF-ERROR", sprintf("invalid hash_algorithm %y; allowed values: %y",
                    request.hash_algorithm, valid_algorithms);
            }
        }

        # Get certificate data
        binary certificate_data;
        if (request.certificate_data) {
            certificate_data = request.certificate_data;
        } else {
            certificate_data = ReadOnlyFile::readBinaryFile(request.certificate_path);
        }

        # Get private key data
        binary private_key_data;
        if (request.private_key_data) {
            private_key_data = request.private_key_data;
        } else {
            private_key_data = ReadOnlyFile::readBinaryFile(request.private_key_path);
        }

        # Determine output path
        string output_path = request.output_path ?? request.input_path;

        @debug("signing PDF: input=%y output=%y field=%y hash=%y",
            request.input_path, output_path, request.field_name,
            request.hash_algorithm ?? PdfHashAlgorithm::Sha256);

        PdfEditor editor(request.input_path, request.password);

        # Build options hash
        hash<auto> sign_options;
        if (request.signer_name) {
            sign_options.signer_name = request.signer_name;
        }
        if (request.reason) {
            sign_options.reason = request.reason;
        }
        if (request.location) {
            sign_options.location = request.location;
        }
        if (request.hash_algorithm) {
            sign_options.hash_algorithm = request.hash_algorithm;
        }

        # Sign the document
        editor.signDocument(request.field_name, certificate_data, private_key_data,
            request.key_password, sign_options);

        # Save the document
        if (output_path == request.input_path) {
            string temp_path = output_path + ".tmp";
            editor.save(temp_path);
            rename(temp_path, output_path);
        } else {
            editor.save(output_path);
        }

        hash<PdfSignResponse> response();
        response.success = True;
        response.output_path = output_path;
        response.field_name = request.field_name;
        response.size = hstat(output_path).size;

        @debug("signing complete: size=%d", response.size);

        return response;
    }
}
}
