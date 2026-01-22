# -*- mode: qore; indent-tabs-mode: nil -*-
#! Qore PdfCreateFormFieldDataProvider class definition

/** PdfCreateFormFieldDataProvider.qc Copyright (C) 2026 Qore Technologies, s.r.o.

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
#! Create interactive form fields in a PDF document
/**
    This data provider creates interactive form fields in PDF documents.

    Supported field types (see PdfFormFieldTypes):
    - "text" - Single or multi-line text input
    - "checkbox" - Boolean checkbox
    - "combo" - Dropdown selection box
    - "list" - List box with multiple visible items
    - "radio" - Radio button group
    - "button" - Push button

    @par Example:
    @code{.py}
    hash<auto> response = dp.doRequest(<PdfCreateFormFieldRequest>{
        "input_path": "document.pdf",
        "output_path": "form.pdf",
        "field": <PdfFormFieldSpec>{
            "name": "customer_name",
            "type": "text",
            "page": 0,
            "x": 100.0,
            "y": 700.0,
            "width": 200.0,
            "height": 20.0,
        },
    });
    @endcode
*/
public class PdfCreateFormFieldDataProvider inherits AbstractDataProvider {
    public {
        const ProviderInfo = <DataProviderInfo>{
            "name": "create-form-field",
            "desc": "Create interactive form fields (text, checkbox, combo, list, radio, button) in a PDF document",
            "type": "PdfCreateFormFieldDataProvider",
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
        return AbstractDataProviderType::get(new Type("hash<PdfCreateFormFieldRequest>"));
    }

    private *AbstractDataProviderType getResponseTypeImpl() {
        return AbstractDataProviderType::get(new Type("hash<PdfCreateFormFieldResponse>"));
    }

    private auto doRequestImpl(auto req, *hash<auto> request_options) {
        hash<PdfCreateFormFieldRequest> request = req;

        # Validate required fields
        if (!request.input_path || request.input_path.size() == 0) {
            throw "PDF-ERROR", "input_path is required";
        }
        if (!request.field && !request.fields) {
            throw "PDF-ERROR", "either field or fields must be specified";
        }
        if (!request.output_path && !request.overwrite) {
            throw "PDF-ERROR", "either output_path or overwrite must be specified";
        }

        # Get field specifications
        list<hash<auto>> field_specs = ();
        if (request.field) {
            push field_specs, request.field;
        }
        if (request.fields) {
            field_specs += request.fields;
        }

        # Determine output path
        string output_path = request.output_path ?? request.input_path;

        @debug("creating form fields: input=%y output=%y field_count=%d",
            request.input_path, output_path, field_specs.size());

        PdfEditor editor(request.input_path, request.password);
        list<string> warnings = ();
        int fields_created = 0;

        # Valid field types for this action (excludes signature)
        list<string> valid_field_types = (
            PdfFormFieldType::Text,
            PdfFormFieldType::Checkbox,
            PdfFormFieldType::Combo,
            PdfFormFieldType::List,
            PdfFormFieldType::Radio,
            PdfFormFieldType::Button,
        );

        # Create each field
        foreach hash<auto> spec in (field_specs) {
            if (!spec.name || !spec.type) {
                push warnings, "Skipping field: name and type are required";
                continue;
            }

            # Validate field type
            if (!inlist(spec.type, valid_field_types)) {
                if (spec.type == PdfFormFieldType::Signature) {
                    push warnings, sprintf("Skipping field '%s': use create-signature-field action for signature fields",
                        spec.name);
                } else {
                    push warnings, sprintf("Skipping field '%s': invalid type %y; allowed: %y",
                        spec.name, spec.type, valid_field_types);
                }
                continue;
            }

            try {
                # Build options hash
                hash<auto> field_options;
                if (spec.default_value) {
                    field_options.default_value = spec.default_value;
                }
                if (spec.options) {
                    field_options.options = spec.options;
                }
                if (spec.max_length) {
                    field_options.max_length = spec.max_length;
                }
                if (spec.multiline) {
                    field_options.multiline = spec.multiline;
                }
                if (spec.password) {
                    field_options.password = spec.password;
                }
                if (spec.read_only) {
                    field_options.read_only = spec.read_only;
                }
                if (spec.required) {
                    field_options.required = spec.required;
                }
                if (spec.font_family) {
                    field_options.font_family = spec.font_family;
                }
                if (spec.font_size) {
                    field_options.font_size = spec.font_size;
                }

                @debug("creating field: name=%y type=%y page=%d", spec.name, spec.type, spec.page);

                editor.createFormField(spec.name, spec.type, spec.page,
                    spec.x, spec.y, spec.width, spec.height, field_options);
                fields_created++;
            } catch (hash<ExceptionInfo> ex) {
                push warnings, sprintf("Failed to create field '%s': %s", spec.name, ex.desc);
            }
        }

        # Save the document
        if (output_path == request.input_path) {
            string temp_path = output_path + ".tmp";
            editor.save(temp_path);
            rename(temp_path, output_path);
        } else {
            editor.save(output_path);
        }

        hash<PdfCreateFormFieldResponse> response();
        response.success = True;
        response.output_path = output_path;
        response.fields_created = fields_created;
        response.size = hstat(output_path).size;
        response.warnings = warnings ? warnings : NOTHING;

        @debug("form fields created: count=%d warnings=%d", fields_created, warnings.size());

        return response;
    }
}
}
