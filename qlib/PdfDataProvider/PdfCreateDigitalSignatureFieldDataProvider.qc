# -*- mode: qore; indent-tabs-mode: nil -*-
#! Qore PdfCreateDigitalSignatureFieldDataProvider class definition

/** PdfCreateDigitalSignatureFieldDataProvider.qc Copyright (C) 2026 Qore Technologies, s.r.o.

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
#! Create a digital signature field (placeholder) in a PDF document
/**
    This data provider creates a digital signature field in a PDF document.
    The field serves as a placeholder that can later be signed using the "sign" action.

    The signature field is a visual rectangle on a specific page where the signature
    will appear. Metadata such as signer name, reason, and location can be pre-filled.

    @par Example:
    @code{.py}
    hash<auto> response = dp.doRequest(<PdfCreateDigitalSignatureFieldRequest>{
        "input_path": "document.pdf",
        "output_path": "with_sig_field.pdf",
        "field": <PdfDigitalSignatureFieldSpec>{
            "name": "signature1",
            "page": 0,
            "x": 100.0,
            "y": 100.0,
            "width": 200.0,
            "height": 50.0,
            "signer_name": "John Doe",
            "reason": "Document approval",
        },
    });
    @endcode

    @see sign for signing the created field
*/
public class PdfCreateDigitalSignatureFieldDataProvider inherits AbstractDataProvider {
    public {
        const ProviderInfo = <DataProviderInfo>{
            "name": "create-signature-field",
            "desc": "Create a digital signature field placeholder in a PDF document (use 'sign' action to apply signature)",
            "type": "PdfCreateDigitalSignatureFieldDataProvider",
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
        return new PdfCreateDigitalSignatureFieldRequestDataType();
    }

    private *AbstractDataProviderType getResponseTypeImpl() {
        return AbstractDataProviderType::get(new Type("hash<PdfCreateDigitalSignatureFieldResponse>"));
    }

    private auto doRequestImpl(auto req, *hash<auto> request_options) {
        hash<auto> request = req;

        PdfActionBase::validateOutputRequired(request);

        # Validate required fields
        if (!request.field) {
            throw "PDF-ERROR", "field is required";
        }

        hash<auto> field = request.field;
        if (!field.name || field.name.size() == 0) {
            throw "PDF-ERROR", "field.name is required";
        }
        if (!exists field.page) {
            throw "PDF-ERROR", "field.page is required";
        }

        @debug("creating signature field: input_path=%y location=%y has_data=%y field=%y page=%d",
            request.input_path, request.location, exists request.data, field.name, field.page);

        PdfEditor editor = PdfActionBase::loadEditor(request);
        list<string> warnings = ();

        # Build options hash
        hash<auto> sig_options;
        if (field.signer_name) {
            sig_options.signer_name = field.signer_name;
        }
        if (field.reason) {
            sig_options.reason = field.reason;
        }
        if (field.location) {
            sig_options.location = field.location;
        }

        try {
            editor.createSignatureField(field.name, field.page,
                field.x, field.y, field.width, field.height, sig_options);
        } catch (hash<ExceptionInfo> ex) {
            push warnings, sprintf("Error creating signature field: %s", ex.desc);
        }

        # Save the document
        hash<auto> output = PdfActionBase::saveEditorOutput(editor, request);

        hash<PdfCreateDigitalSignatureFieldResponse> response();
        response.success = True;
        response += output;
        response.field_name = field.name;
        response.warnings = warnings ? warnings : NOTHING;

        @debug("signature field created: size=%d", response.size);

        return response;
    }
}
}
