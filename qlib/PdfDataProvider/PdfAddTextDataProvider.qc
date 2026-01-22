# -*- mode: qore; indent-tabs-mode: nil -*-
#! Qore PdfAddTextDataProvider class definition

/** PdfAddTextDataProvider.qc Copyright (C) 2026 Qore Technologies, s.r.o.

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
#! Add text data provider - adds styled text to PDF pages
public class PdfAddTextDataProvider inherits AbstractDataProvider {
    public {
        const ProviderInfo = <DataProviderInfo>{
            "name": "add-text",
            "desc": "Add styled text to PDF pages",
            "type": "PdfAddTextDataProvider",
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
        return AbstractDataProviderType::get(new Type("hash<PdfAddTextRequest>"));
    }

    private *AbstractDataProviderType getResponseTypeImpl() {
        return AbstractDataProviderType::get(new Type("hash<PdfAddTextResponse>"));
    }

    private auto doRequestImpl(auto req, *hash<auto> request_options) {
        hash<PdfAddTextRequest> request = req;

        if (!request.input_path || request.input_path.size() == 0) {
            throw "PDF-ERROR", "input_path is required";
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

        @debug("adding text: input=%y output=%y", request.input_path, output_path);

        # Load the document
        PdfEditor editor(request.input_path, request.password);
        int page_count = editor.pageCount();

        # Set font options if provided
        if (request.font_options) {
            editor.setFontOptions(request.font_options);
        }

        # Determine pages to modify
        list<int> pages_to_modify = getTargetPages(request.page_selection, page_count);

        # Get text placements
        list<hash<auto>> placements = ();
        if (request.text) {
            push placements, request.text;
        }
        if (request.placements) {
            placements += request.placements;
        }

        if (!placements) {
            throw "PDF-ERROR", "either text or placements must be specified";
        }

        # Track modifications
        int text_blocks_added = 0;
        hash<string, bool> modified_pages;
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

            foreach hash<auto> placement in (placements) {
                try {
                    drawTextOnPage(editor, page_index, placement, page_width, page_height);
                    text_blocks_added++;
                    modified_pages{page_index.toString()} = True;
                } catch (hash<ExceptionInfo> ex) {
                    push warnings, sprintf("Failed to draw text on page %d: %s", page_index, ex.desc);
                }
            }
        }

        # Save the document
        if (output_path == request.input_path) {
            # Save to temporary file then rename
            string temp_path = output_path + ".tmp";
            editor.save(temp_path);
            rename(temp_path, output_path);
        } else {
            editor.save(output_path);
        }

        hash<PdfAddTextResponse> response();
        response.success = True;
        response.output_path = output_path;
        response.page_count = page_count;
        response.pages_modified = modified_pages.size();
        response.text_blocks_added = text_blocks_added;
        response.size = hstat(output_path).size;
        response.warnings = warnings ? warnings : NOTHING;

        @debug("text added: count=%d pages_modified=%d", text_blocks_added, response.pages_modified);

        return response;
    }

    #! Get list of target pages based on page selection
    private list<int> getTargetPages(*hash<auto> selection, int page_count) {
        if (!selection) {
            # Default: first page
            return (0,);
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

        # Default: first page
        return (0,);
    }

    #! Convert position to PDF coordinates (bottom-left origin)
    private hash<auto> convertPosition(*hash<auto> pos, float page_width, float page_height,
            float obj_width = 0.0, float obj_height = 0.0) {
        # Default to top-left (0, 0) if position not provided
        if (!pos) {
            # Convert top-left origin to bottom-left (PDF native)
            return {"x": 0.0, "y": page_height - obj_height};
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
                PdfPresetPosition::TopCenter,
                PdfPresetPosition::BottomCenter,
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
                    x = 0.0;
                    y = page_height - obj_height;
                    return {"x": x, "y": y};
                case PdfPresetPosition::TopRight:
                    x = page_width - obj_width;
                    y = page_height - obj_height;
                    return {"x": x, "y": y};
                case PdfPresetPosition::BottomLeft:
                    x = 0.0;
                    y = 0.0;
                    return {"x": x, "y": y};
                case PdfPresetPosition::BottomRight:
                    x = page_width - obj_width;
                    y = 0.0;
                    return {"x": x, "y": y};
                case PdfPresetPosition::TopCenter:
                    x = (page_width - obj_width) / 2.0;
                    y = page_height - obj_height;
                    return {"x": x, "y": y};
                case PdfPresetPosition::BottomCenter:
                    x = (page_width - obj_width) / 2.0;
                    y = 0.0;
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

    #! Draw text on a page
    private drawTextOnPage(PdfEditor editor, int page_index, hash<auto> placement,
            float page_width, float page_height) {
        if (!placement.text) {
            throw "PDF-ERROR", "text is required in placement";
        }

        # Validate text style fields if specified
        if (placement.style) {
            # Validate align
            if (placement.style.align) {
                list<string> valid_align = (
                    PdfTextAlignment::Left,
                    PdfTextAlignment::Center,
                    PdfTextAlignment::Right,
                );
                if (!inlist(placement.style.align, valid_align)) {
                    throw "PDF-ERROR", sprintf("invalid text alignment %y; allowed values: %y",
                        placement.style.align, valid_align);
                }
            }
            # Validate valign
            if (placement.style.valign) {
                list<string> valid_valign = (
                    PdfVerticalAlignment::Top,
                    PdfVerticalAlignment::Middle,
                    PdfVerticalAlignment::Bottom,
                );
                if (!inlist(placement.style.valign, valid_valign)) {
                    throw "PDF-ERROR", sprintf("invalid vertical alignment %y; allowed values: %y",
                        placement.style.valign, valid_valign);
                }
            }
            # Validate render_mode
            if (placement.style.render_mode) {
                list<string> valid_render = (
                    PdfRenderMode::Fill,
                    PdfRenderMode::Stroke,
                    PdfRenderMode::FillStroke,
                );
                if (!inlist(placement.style.render_mode, valid_render)) {
                    throw "PDF-ERROR", sprintf("invalid render mode %y; allowed values: %y",
                        placement.style.render_mode, valid_render);
                }
            }
        }

        # Estimate text height based on font size (rough approximation)
        float font_size = 12.0;
        if (placement.style && placement.style.font && placement.style.font.size) {
            font_size = placement.style.font.size;
        }
        float text_height = font_size * 1.2; # Line height approximation

        # Convert position
        hash<auto> pos = convertPosition(placement.position, page_width, page_height, 0.0, text_height);

        # Draw the text
        float rotation = placement.rotation ?? 0.0;
        float opacity = placement.opacity ?? 1.0;

        # Cast style to the expected type
        *hash<Qore::Pdf::PdfTextStyle> style = placement.style
            ? cast<hash<Qore::Pdf::PdfTextStyle>>(placement.style)
            : NOTHING;
        editor.drawText(page_index, placement.text, pos.x, pos.y, style, rotation, opacity);
    }
}
}
