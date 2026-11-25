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

    Supply \c required_fields to request strict validation. Required text fields need a nonblank string and
    checkboxes need a boolean. Choice fields accept a listed label or a zero-based index. Optional fields may
    be omitted. A failed required mapping raises \c PDF-FORM-VALIDATION-ERROR before flattening or publishing.
    Its exception argument contains \c field_outcomes keyed by field name, as does a successful strict response.
    Outcomes have a \c required flag and a \c status of \c filled, \c missing_field, \c missing_value,
    \c invalid_value or \c write_failed. Optional failures are also returned as warnings.

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

    #! Normalize a strict mapping before calling the native editor, which otherwise coerces values
    private static auto strictValue(hash<auto> field, auto value, bool required) {
        if (field.read_only) {
            throw "PDF-FORM-VALUE-ERROR", "the field is read-only";
        }
        switch (field.type) {
            case "text":
                if (value.typeCode() == NT_STRING && (!required || trim(value).size())
                        && value.find(chr(0)) < 0 && (!field.max_length || value.length() <= field.max_length)) {
                    return value;
                }
                throw "PDF-FORM-VALUE-ERROR", "expected text within the field length limit and nonblank if required";
            case "checkbox":
                if (value.typeCode() == NT_BOOLEAN) {
                    return value;
                }
                throw "PDF-FORM-VALUE-ERROR", "expected a boolean";
            case "combo":
            case "list":
                if (value.typeCode() == NT_INT && value >= 0 && value < field.options.size()) {
                    return value;
                }
                if (value.typeCode() == NT_STRING) {
                    foreach string option in (field.options) {
                        if (option == value) {
                            return $#;
                        }
                    }
                }
                throw "PDF-FORM-VALUE-ERROR", "expected a listed option or an index in range";
            default:
                throw "PDF-FORM-VALUE-ERROR", sprintf("cannot fill field type %s", field.type);
        }
    }

    private static hash<string, hash<PdfFormFieldOutcome>> fillStrict(PdfEditor editor, hash<auto> values,
            list<string> required_fields, reference<int> filled, reference<list<string>> warnings) {
        hash<string, hash<auto>> fields = map {$1.name: $1}, editor.getFormFields();
        hash<string, bool> required = map {$1: True}, required_fields;
        hash<string, hash<PdfFormFieldOutcome>> outcomes;
        list<string> failed;
        foreach string name in ((keys values) + (keys (required - keys values))) {
            bool mandatory = required{name} ?? False;
            hash<PdfFormFieldOutcome> outcome();
            outcome.required = mandatory;
            if (!fields.hasKey(name)) {
                outcome += {"status": "missing_field", "message": "field is absent from the template"};
            } else if (!exists values{name}) {
                outcome += {"status": "missing_value", "message": "field has no mapped value"};
            } else {
                try {
                    auto value = strictValue(fields{name}, values{name}, mandatory);
                    editor.setFormFieldValue(name, value);
                    outcome.status = "filled";
                    ++filled;
                } catch (hash<ExceptionInfo> ex) {
                    outcome.status = ex.err == "PDF-FORM-VALUE-ERROR" ? "invalid_value" : "write_failed";
                    outcome.message = ex.desc;
                }
            }
            outcomes{name} = outcome;
            if (outcome.status != "filled") {
                if (mandatory) {
                    failed += name;
                } else {
                    warnings += sprintf("Failed to fill field '%s': %s", name, outcome.message);
                }
            }
        }
        if (failed) {
            throw "PDF-FORM-VALIDATION-ERROR", "required fields could not be filled: " + failed.join(", "),
                {"field_outcomes": outcomes};
        }
        return outcomes;
    }

    private auto doRequestImpl(auto req, *hash<auto> request_options) {
        hash<auto> request = req;

        PdfActionBase::validateOutputRequired(request);

        # Validate required fields
        if (!request.required_fields && (!request.form_data || !request.form_data.size())) {
            throw "PDF-ERROR", "form_data is required and must contain at least one field";
        }

        @debug("filling form: input_path=%y location=%y has_data=%y field_count=%d flatten=%y",
            request.input_path, request.location, exists request.data,
            request.form_data.size(), request.flatten ?? False);

        PdfEditor editor = PdfActionBase::loadEditor(request);
        list<string> warnings = ();
        int fields_filled = 0;

        *hash<string, hash<PdfFormFieldOutcome>> outcomes;
        if (exists request.required_fields) {
            outcomes = fillStrict(editor, request.form_data, request.required_fields, \fields_filled, \warnings);
        } else {
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
        if (exists outcomes) {
            response.field_outcomes = outcomes;
        }
        response.fields_filled = fields_filled;
        response.warnings = warnings ? warnings : NOTHING;

        @debug("form filled: fields=%d warnings=%d", fields_filled, warnings.size());

        return response;
    }
}
}
