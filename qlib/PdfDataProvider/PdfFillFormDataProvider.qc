# -*- mode: qore; indent-tabs-mode: nil -*-
#! Qore PdfFillFormDataProvider class definition

/** PdfFillFormDataProvider.qc Copyright (C) 2026 Qore Technologies, s.r.o.

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
#! Fill form fields in a PDF document
/**
    This data provider fills interactive form fields in a PDF document with specified values.

    The data hash maps field names to values:
    - For text fields: string value
    - For checkbox fields: boolean value
    - For combo/list fields: string value (selected option) or int (selected index)

    Optionally, fields can be "flattened" after filling, converting them to static content
    that cannot be edited.

    @par Example:
    @code{.py}
    hash<auto> response = dp.doRequest(<PdfFillFormRequest>{
        "input_path": "form.pdf",
        "output_path": "filled_form.pdf",
        "form_data": {
            "customer_name": "John Doe",
            "email": "john@example.com",
            "agree_terms": True,
        },
        "flatten": True,
    });
    @endcode
*/
public class PdfFillFormDataProvider inherits AbstractDataProvider {
    public {
        const ProviderInfo = <DataProviderInfo>{
            "name": "fill-form",
            "desc": "Fill form field values in a PDF document (text, checkbox, combo fields)",
            "type": "PdfFillFormDataProvider",
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
        return new PdfFillFormRequestDataType();
    }

    private *AbstractDataProviderType getResponseTypeImpl() {
        return AbstractDataProviderType::get(new Type("hash<PdfFillFormResponse>"));
    }

    private auto doRequestImpl(auto req, *hash<auto> request_options) {
        hash<auto> request = req;

        PdfActionBase::validateOutputRequired(request);

        # Validate required fields
        if (!request.form_data || request.form_data.size() == 0) {
            throw "PDF-ERROR", "form_data is required and must contain at least one field";
        }

        @debug("filling form: input_path=%y location=%y has_data=%y field_count=%d flatten=%y",
            request.input_path, request.location, exists request.data,
            request.form_data.size(), request.flatten ?? False);

        PdfEditor editor = PdfActionBase::loadEditor(request);
        list<string> warnings = ();
        int fields_filled = 0;

        # Fill each field
        HashIterator it(request.form_data);
        while (it.next()) {
            string field_name = it.getKey();
            auto value = it.getValue();
            try {
                @debug("setting field: name=%y value=%y", field_name, value);
                editor.setFormFieldValue(field_name, value);
                fields_filled++;
            } catch (hash<ExceptionInfo> ex) {
                push warnings, sprintf("Failed to fill field '%s': %s", field_name, ex.desc);
            }
        }

        # Flatten if requested
        if (request.flatten) {
            @debug("flattening form fields");
            editor.flattenFormFields();
        }

        # Save the document
        hash<auto> output = PdfActionBase::saveEditorOutput(editor, request);

        hash<PdfFillFormResponse> response();
        response.success = True;
        response += output;
        response.fields_filled = fields_filled;
        response.warnings = warnings ? warnings : NOTHING;

        @debug("form filled: fields=%d warnings=%d", fields_filled, warnings.size());

        return response;
    }
}
}
