# -*- mode: qore; indent-tabs-mode: nil -*-
#! Qore PdfGetFormDataDataProvider class definition

/** PdfGetFormDataDataProvider.qc Copyright (C) 2026 Qore Technologies, s.r.o.

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
#! Get form field values from a PDF document
/**
    This data provider extracts the current values from form fields in a PDF document.

    Returns a hash mapping field names to their current values:
    - Text fields: string value
    - Checkbox fields: boolean value
    - Combo/list fields: string value (selected option)

    Optionally, a list of specific field names can be provided to limit the results.

    @par Example:
    @code{.py}
    hash<auto> response = dp.doRequest(<PdfGetFormDataRequest>{
        "input_path": "form.pdf",
        "fields": ("customer_name", "email"),  # Optional: get only specific fields
    });
    # response.data = {"customer_name": "John", "email": "john@example.com"}
    @endcode
*/
public class PdfGetFormDataDataProvider inherits AbstractDataProvider {
    public {
        const ProviderInfo = <DataProviderInfo>{
            "name": "get-form-data",
            "desc": "Get form field values from a PDF document as a name-value hash",
            "type": "PdfGetFormDataDataProvider",
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
        return AbstractDataProviderType::get(new Type("hash<PdfGetFormDataRequest>"));
    }

    private *AbstractDataProviderType getResponseTypeImpl() {
        return AbstractDataProviderType::get(new Type("hash<PdfGetFormDataResponse>"));
    }

    private auto doRequestImpl(auto req, *hash<auto> request_options) {
        hash<PdfGetFormDataRequest> request = req;

        # Validate required fields
        if (!request.input_path || request.input_path.size() == 0) {
            throw "PDF-ERROR", "input_path is required";
        }

        @debug("getting form data: input=%y fields=%y",
            request.input_path, request.fields ?? "all");

        PdfEditor editor(request.input_path, request.password);
        list<hash<auto>> all_fields = editor.getFormFields();

        hash<auto> data;
        foreach hash<auto> field in (all_fields) {
            # Skip if specific fields requested and this isn't in the list
            if (request.fields && !inlist(field.name, request.fields)) {
                continue;
            }

            # Get the value for this field
            auto value = editor.getFormFieldValue(field.name);
            data{field.name} = value;
        }

        hash<PdfGetFormDataResponse> response();
        response.success = True;
        response.data = data;
        response.field_count = data.size();

        @debug("form data retrieved: field_count=%d", response.field_count);

        return response;
    }
}
}
