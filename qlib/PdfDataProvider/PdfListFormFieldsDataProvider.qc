# -*- mode: qore; indent-tabs-mode: nil -*-
#! Qore PdfListFormFieldsDataProvider class definition

/** PdfListFormFieldsDataProvider.qc Copyright (C) 2026 Qore Technologies, s.r.o.

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
#! List all form fields in a PDF document
/**
    This data provider returns detailed information about all form fields in a PDF document.

    For each field, returns:
    - name: Full hierarchical field name
    - type: Field type (text, checkbox, combo, list, radio, button, signature)
    - value: Current value (if applicable)
    - read_only, required: Field flags
    - page: Page index where the field appears
    - rect: Bounding rectangle coordinates

    @par Example:
    @code{.py}
    hash<auto> response = dp.doRequest(<PdfListFormFieldsRequest>{
        "input_path": "form.pdf",
    });
    foreach hash<auto> field in (response.fields) {
        printf("Field: %s (type: %s)\n", field.name, field.type);
    }
    @endcode

    @see PdfFormFieldTypes for allowed field type values
*/
public class PdfListFormFieldsDataProvider inherits AbstractDataProvider {
    public {
        const ProviderInfo = <DataProviderInfo>{
            "name": "list-form-fields",
            "desc": "List all form fields in a PDF document with their properties and current values",
            "type": "PdfListFormFieldsDataProvider",
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
        return AbstractDataProviderType::get(new Type("hash<PdfListFormFieldsRequest>"));
    }

    private *AbstractDataProviderType getResponseTypeImpl() {
        return AbstractDataProviderType::get(new Type("hash<PdfListFormFieldsResponse>"));
    }

    private auto doRequestImpl(auto req, *hash<auto> request_options) {
        hash<PdfListFormFieldsRequest> request = req;

        # Validate required fields
        if (!request.input_path || request.input_path.size() == 0) {
            throw "PDF-ERROR", "input_path is required";
        }

        @debug("listing form fields: input=%y", request.input_path);

        PdfEditor editor(request.input_path, request.password);
        list<hash<auto>> fields = editor.getFormFields();

        hash<PdfListFormFieldsResponse> response();
        response.success = True;
        response.fields = fields;
        response.field_count = fields.size();

        @debug("form fields found: count=%d", response.field_count);

        return response;
    }
}
}
