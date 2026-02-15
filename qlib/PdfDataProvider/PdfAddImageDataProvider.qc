# -*- mode: qore; indent-tabs-mode: nil -*-
#! Qore PdfAddImageDataProvider class definition

/** PdfAddImageDataProvider.qc Copyright (C) 2026 Qore Technologies, s.r.o.

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
#! Add image data provider - adds images to PDF pages
public class PdfAddImageDataProvider inherits AbstractDataProvider {
    public {
        const ProviderInfo = <DataProviderInfo>{
            "name": "add-image",
            "desc": "Add images to PDF pages",
            "type": "PdfAddImageDataProvider",
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
        return new PdfAddImageRequestDataType();
    }

    private *AbstractDataProviderType getResponseTypeImpl() {
        return AbstractDataProviderType::get(new Type("hash<PdfAddImageResponse>"));
    }

    private auto doRequestImpl(auto req, *hash<auto> request_options) {
        hash<auto> request = req;

        PdfActionBase::validateOutputRequired(request);

        @debug("adding images: input_path=%y location=%y has_data=%y",
            request.input_path, request.location, exists request.data);

        # Load the document
        PdfEditor editor = PdfActionBase::loadEditor(request);
        int page_count = editor.pageCount();

        # Determine pages to modify
        list<int> pages_to_modify = getTargetPages(request.page_selection, page_count);

        # Get image placements
        list<hash<auto>> placements = ();
        if (request.image) {
            push placements, request.image;
        }
        if (request.placements) {
            placements += request.placements;
        }

        if (!placements) {
            throw "PDF-ERROR", "either image or placements must be specified";
        }

        # Validate image paths exist before processing
        foreach hash<auto> placement in (placements) {
            if (placement.image_path && !is_file(placement.image_path)) {
                throw "PDF-ERROR", sprintf("image file not found: %s", placement.image_path);
            }
            if (!placement.image_path && !placement.image_data) {
                throw "PDF-ERROR", "each placement must have either image_path or image_data";
            }
        }

        # Track modifications
        int images_added = 0;
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
                    drawImageOnPage(editor, page_index, placement, page_width, page_height);
                    images_added++;
                    modified_pages{page_index.toString()} = True;
                } catch (hash<ExceptionInfo> ex) {
                    push warnings, sprintf("Failed to draw image on page %d: %s", page_index, ex.desc);
                }
            }
        }

        # Save the document
        hash<auto> output = PdfActionBase::saveEditorOutput(editor, request);

        hash<PdfAddImageResponse> response();
        response.success = True;
        response += output;
        response.page_count = page_count;
        response.pages_modified = modified_pages.size();
        response.images_added = images_added;
        response.warnings = warnings ? warnings : NOTHING;

        @debug("images added: count=%d pages_modified=%d", images_added, response.pages_modified);

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

    #! Draw an image on a page
    private drawImageOnPage(PdfEditor editor, int page_index, hash<auto> placement,
            float page_width, float page_height) {
        # Get image dimensions
        hash<auto> img_dims;
        if (placement.image_path) {
            img_dims = PdfEditor::getImageDimensions(placement.image_path);
        } else if (placement.image_data) {
            img_dims = PdfEditor::getImageDimensionsFromData(placement.image_data);
        } else {
            throw "PDF-ERROR", "either image_path or image_data must be specified";
        }

        # Calculate target dimensions
        float width = placement.width ?? 0.0;
        float height = placement.height ?? 0.0;
        float scale = placement.scale ?? 1.0;
        bool preserve_aspect = placement.preserve_aspect_ratio ?? True;

        if (width <= 0 && height <= 0) {
            # Use original size scaled
            width = img_dims.width * scale;
            height = img_dims.height * scale;
        } else if (width <= 0 && preserve_aspect) {
            width = (height / img_dims.height) * img_dims.width;
        } else if (height <= 0 && preserve_aspect) {
            height = (width / img_dims.width) * img_dims.height;
        }

        # Apply scale to explicit dimensions
        if (placement.width > 0 || placement.height > 0) {
            width *= scale;
            height *= scale;
        }

        # Convert position
        hash<auto> pos = convertPosition(placement.position, page_width, page_height, width, height);

        # Draw the image
        float rotation = placement.rotation ?? 0.0;
        float opacity = placement.opacity ?? 1.0;

        if (placement.image_path) {
            editor.drawImage(page_index, placement.image_path, pos.x, pos.y, width, height,
                rotation, opacity);
        } else {
            editor.drawImageFromData(page_index, placement.image_data, pos.x, pos.y, width, height,
                rotation, opacity);
        }
    }
}
}
