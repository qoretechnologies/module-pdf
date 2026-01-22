# -*- mode: qore; indent-tabs-mode: nil -*-
#! Qore PdfAddSignatureFieldDataProvider class definition

/** PdfAddSignatureFieldDataProvider.qc Copyright (C) 2026 Qore Technologies, s.r.o.

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
#! Add signature field data provider - adds signature placeholders to PDF pages
public class PdfAddSignatureFieldDataProvider inherits AbstractDataProvider {
    public {
        const ProviderInfo = <DataProviderInfo>{
            "name": "add-signature-field",
            "desc": "Add signature placeholders to PDF pages",
            "type": "PdfAddSignatureFieldDataProvider",
            "supports_request": True,
        };

        # Default settings
        const DefaultMaxWidth = 150.0;
        const DefaultMaxHeight = 50.0;
        const DefaultMargin = 36.0; # 0.5 inch
        const DefaultLineWidth = 0.5;
        const DefaultLineColor = <Qore::Pdf::PdfColor>{"gray": 0.0}; # Black
        const DefaultLabelFontSize = 10.0;
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
        return AbstractDataProviderType::get(new Type("hash<PdfAddSignatureFieldRequest>"));
    }

    private *AbstractDataProviderType getResponseTypeImpl() {
        return AbstractDataProviderType::get(new Type("hash<PdfAddSignatureFieldResponse>"));
    }

    private auto doRequestImpl(auto req, *hash<auto> request_options) {
        hash<PdfAddSignatureFieldRequest> request = req;

        if (!request.input_path || request.input_path.size() == 0) {
            throw "PDF-ERROR", "input_path is required";
        }

        if (!request.signature) {
            throw "PDF-ERROR", "signature specification is required";
        }

        # Determine output path
        string output_path;
        if (request.output_path) {
            output_path = request.output_path;
        } else if (request.overwrite) {
            output_path = request.input_path;
        } else {
            throw "PDF-ERROR", "either output_path or overwrite must be specified";
        }

        @debug("adding signature field: input=%y output=%y", request.input_path, output_path);

        # Load the document
        PdfEditor editor(request.input_path, request.password);
        int page_count = editor.pageCount();

        # Determine pages to modify (default: last page for signatures)
        list<int> pages_to_modify;
        if (request.page_selection) {
            pages_to_modify = getTargetPages(request.page_selection, page_count);
        } else {
            # Default: last page
            pages_to_modify = (page_count - 1,);
        }

        # Track modifications
        int fields_added = 0;
        list<string> warnings = ();

        # Process each page
        foreach int page_index in (pages_to_modify) {
            if (page_index < 0 || page_index >= page_count) {
                push warnings, sprintf("Skipping invalid page index %d", page_index);
                continue;
            }

            hash<auto> page_dims = editor.getPageDimensions(page_index);
            float page_width = page_dims.width;
            float page_height = page_dims.height;

            try {
                drawSignatureField(editor, page_index, request.signature, page_width, page_height);
                fields_added++;
            } catch (hash<ExceptionInfo> ex) {
                push warnings, sprintf("Failed to add signature field on page %d: %s", page_index, ex.desc);
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

        hash<PdfAddSignatureFieldResponse> response();
        response.success = True;
        response.output_path = output_path;
        response.page_count = page_count;
        response.fields_added = fields_added;
        response.size = hstat(output_path).size;
        response.warnings = warnings ? warnings : NOTHING;

        @debug("signature field added: fields=%d warnings=%d", fields_added, warnings.size());

        return response;
    }

    #! Get list of target pages based on page selection
    private list<int> getTargetPages(*hash<auto> selection, int page_count) {
        if (!selection) {
            # Default: last page
            return (page_count - 1,);
        }

        if (selection.all) {
            return range(page_count);
        }

        if (selection.pages) {
            return selection.pages;
        }

        if (exists selection.from_page || exists selection.to_page) {
            int from_page = selection.from_page ?? 0;
            int to_page = selection.to_page ?? (page_count - 1);
            return range(from_page, to_page + 1);
        }

        # Default: last page
        return (page_count - 1,);
    }

    #! Draw a signature field on a page
    private drawSignatureField(PdfEditor editor, int page_index, hash<auto> sig,
            float page_width, float page_height) {
        float max_width = sig.max_width ?? DefaultMaxWidth;
        float max_height = sig.max_height ?? DefaultMaxHeight;

        # Calculate position
        float x;
        float y;
        if (sig.position) {
            hash<auto> pos = convertPosition(sig.position, page_width, page_height, max_width, max_height);
            x = pos.x;
            y = pos.y;
        } else {
            # Default: bottom-right with margin
            x = page_width - max_width - DefaultMargin;
            y = DefaultMargin;
        }

        bool has_image = sig.image_path || sig.image_data;
        bool draw_line = sig.draw_line ?? !has_image;

        # Draw signature image if provided
        if (has_image) {
            # Get image dimensions
            hash<auto> img_dims;
            if (sig.image_path) {
                img_dims = PdfEditor::getImageDimensions(sig.image_path);
            } else {
                img_dims = PdfEditor::getImageDimensionsFromData(sig.image_data);
            }

            # Scale to fit within max dimensions while preserving aspect ratio
            float scale = 1.0;
            if (img_dims.width > max_width) {
                scale = max_width / img_dims.width;
            }
            if (img_dims.height * scale > max_height) {
                scale = max_height / img_dims.height;
            }

            float width = img_dims.width * scale;
            float height = img_dims.height * scale;

            # Center the image in the signature area
            float img_x = x + (max_width - width) / 2.0;
            float img_y = y + (max_height - height) / 2.0;

            if (sig.image_path) {
                editor.drawImage(page_index, sig.image_path, img_x, img_y, width, height, 0.0, 1.0);
            } else {
                editor.drawImageFromData(page_index, sig.image_data, img_x, img_y, width, height, 0.0, 1.0);
            }
        }

        # Draw signature line if requested
        if (draw_line) {
            float line_width = sig.line_width ?? DefaultLineWidth;
            hash<Qore::Pdf::PdfColor> line_color = sig.line_color ?? DefaultLineColor;

            # Create a line style
            hash<Qore::Pdf::PdfTextStyle> line_style();
            line_style.color = line_color;
            line_style.render_mode = "stroke";
            line_style.stroke_color = line_color;
            line_style.stroke_width = line_width;

            # Draw underscores to create a line effect
            # Note: This is a workaround since we don't have a direct line drawing API
            # A better approach would be to add a drawLine method to PdfEditor
            float line_y = y + 5.0; # Slight offset from bottom
            string line_chars = "_______________________________________________";
            editor.drawText(page_index, line_chars, x, line_y, line_style, 0.0, 1.0);
        }

        # Draw label if provided
        if (sig.label) {
            hash<Qore::Pdf::PdfTextStyle> label_style();

            # Font
            hash<Qore::Pdf::PdfFontSpec> font();
            if (sig.label_font) {
                font = sig.label_font;
            }
            if (!font.size) {
                font.size = DefaultLabelFontSize;
            }
            label_style.font = font;

            # Color
            if (sig.label_color) {
                label_style.color = sig.label_color;
            } else {
                label_style.color = DefaultLineColor;
            }

            # Position label below the signature area
            float label_y = y - font.size - 2.0;
            editor.drawText(page_index, sig.label, x, label_y, label_style, 0.0, 1.0);
        }
    }

    #! Convert position to PDF coordinates
    private hash<auto> convertPosition(*hash<auto> pos, float page_width, float page_height,
            float obj_width = 0.0, float obj_height = 0.0) {
        # Default to bottom-right with margin if position not provided
        if (!pos) {
            return {
                "x": page_width - obj_width - DefaultMargin,
                "y": DefaultMargin,
            };
        }

        float x = pos.x ?? 0.0;
        float y = pos.y ?? 0.0;

        # Validate position_mode if specified
        if (pos.position_mode) {
            list<string> valid_modes = (
                PdfPositionMode::Absolute,
                PdfPositionMode::Percentage,
            );
            if (!inlist(pos.position_mode, valid_modes)) {
                throw "PDF-ERROR", sprintf("invalid position_mode %y; allowed values: %y",
                    pos.position_mode, valid_modes);
            }
        }

        # Handle percentage mode
        if (pos.position_mode == PdfPositionMode::Percentage) {
            x = (x / 100.0) * page_width;
            y = (y / 100.0) * page_height;
        }

        # Validate preset if specified
        if (pos.preset) {
            list<string> valid_presets = (
                PdfPresetPosition::Center,
                PdfPresetPosition::TopLeft,
                PdfPresetPosition::TopRight,
                PdfPresetPosition::BottomLeft,
                PdfPresetPosition::BottomRight,
            );
            if (!inlist(pos.preset, valid_presets)) {
                throw "PDF-ERROR", sprintf("invalid preset position %y; allowed values: %y",
                    pos.preset, valid_presets);
            }

            # Handle preset positions
            switch (pos.preset) {
                case PdfPresetPosition::Center:
                    x = (page_width - obj_width) / 2.0;
                    y = (page_height - obj_height) / 2.0;
                    return {"x": x, "y": y};
                case PdfPresetPosition::TopLeft:
                    x = DefaultMargin;
                    y = page_height - obj_height - DefaultMargin;
                    return {"x": x, "y": y};
                case PdfPresetPosition::TopRight:
                    x = page_width - obj_width - DefaultMargin;
                    y = page_height - obj_height - DefaultMargin;
                    return {"x": x, "y": y};
                case PdfPresetPosition::BottomLeft:
                    x = DefaultMargin;
                    y = DefaultMargin;
                    return {"x": x, "y": y};
                case PdfPresetPosition::BottomRight:
                    x = page_width - obj_width - DefaultMargin;
                    y = DefaultMargin;
                    return {"x": x, "y": y};
            }
        }

        # Validate origin if specified
        string origin = pos.origin ?? PdfPositionOrigin::TopLeft;
        list<string> valid_origins = (
            PdfPositionOrigin::TopLeft,
            PdfPositionOrigin::BottomLeft,
        );
        if (!inlist(origin, valid_origins)) {
            throw "PDF-ERROR", sprintf("invalid origin %y; allowed values: %y",
                origin, valid_origins);
        }

        # Convert top-left origin (default) to bottom-left (PDF native)
        if (origin == PdfPositionOrigin::TopLeft) {
            y = page_height - y - obj_height;
        }

        return {"x": x, "y": y};
    }
}
}
