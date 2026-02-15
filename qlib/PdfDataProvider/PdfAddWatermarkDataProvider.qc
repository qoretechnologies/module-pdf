# -*- mode: qore; indent-tabs-mode: nil -*-
#! Qore PdfAddWatermarkDataProvider class definition

/** PdfAddWatermarkDataProvider.qc Copyright (C) 2026 Qore Technologies, s.r.o.

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
#! Add watermark data provider - adds text or image watermarks to PDF pages
public class PdfAddWatermarkDataProvider inherits AbstractDataProvider {
    public {
        const ProviderInfo = <DataProviderInfo>{
            "name": "add-watermark",
            "desc": "Add text or image watermarks to PDF pages",
            "type": "PdfAddWatermarkDataProvider",
            "supports_request": True,
        };

        # Default watermark settings
        const DefaultTextOpacity = 0.3;
        const DefaultTextRotation = -45.0;
        const DefaultFontSize = 48.0;
        const DefaultColor = <Qore::Pdf::PdfColor>{"gray": 0.7};
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
        return new PdfAddWatermarkRequestDataType();
    }

    private *AbstractDataProviderType getResponseTypeImpl() {
        return AbstractDataProviderType::get(new Type("hash<PdfAddWatermarkResponse>"));
    }

    private auto doRequestImpl(auto req, *hash<auto> request_options) {
        hash<auto> request = req;

        PdfActionBase::validateOutputRequired(request);

        if (!request.watermark) {
            throw "PDF-ERROR", "watermark specification is required";
        }

        # Validate watermark type
        string wm_type = request.watermark.type ?? PdfWatermarkType::Text;
        list<string> valid_types = (
            PdfWatermarkType::Text,
            PdfWatermarkType::Image,
        );
        if (!inlist(wm_type, valid_types)) {
            throw "PDF-ERROR", sprintf("invalid watermark type %y; allowed values: %y",
                wm_type, valid_types);
        }

        if (wm_type == PdfWatermarkType::Text && !request.watermark.text) {
            throw "PDF-ERROR", "text is required for text watermarks";
        }

        if (wm_type == PdfWatermarkType::Image && !request.watermark.image_path && !request.watermark.image_data) {
            throw "PDF-ERROR", "image_path or image_data is required for image watermarks";
        }

        # Validate watermark position
        if (request.watermark.position) {
            list<string> valid_positions = (
                PdfWatermarkPosition::Center,
                PdfWatermarkPosition::Tile,
            );
            if (!inlist(request.watermark.position, valid_positions)) {
                throw "PDF-ERROR", sprintf("invalid watermark position %y; allowed values: %y",
                    request.watermark.position, valid_positions);
            }
        }

        # Validate watermark layer
        if (request.watermark.layer) {
            list<string> valid_layers = (
                PdfWatermarkLayer::Foreground,
                PdfWatermarkLayer::Background,
            );
            if (!inlist(request.watermark.layer, valid_layers)) {
                throw "PDF-ERROR", sprintf("invalid watermark layer %y; allowed values: %y",
                    request.watermark.layer, valid_layers);
            }
        }

        @debug("adding watermark: input_path=%y location=%y has_data=%y type=%y",
            request.input_path, request.location, exists request.data, wm_type);

        # Load the document
        PdfEditor editor = PdfActionBase::loadEditor(request);
        int page_count = editor.pageCount();

        # Determine pages to modify (default: all pages for watermarks)
        list<int> pages_to_modify;
        if (request.page_selection) {
            pages_to_modify = getTargetPages(request.page_selection, page_count);
        } else {
            pages_to_modify = range(page_count);
        }

        # Track modifications
        int pages_watermarked = 0;
        list<string> warnings = ();

        # Check layer setting - background layer requires complex PDF manipulation
        # that is not yet fully implemented
        string layer = request.watermark.layer ?? PdfWatermarkLayer::Foreground;
        if (layer == PdfWatermarkLayer::Background) {
            push warnings, "Background layer watermarks are not fully supported; "
                "watermark will be drawn as foreground with reduced opacity";
        }

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
                if (wm_type == PdfWatermarkType::Text) {
                    drawTextWatermark(editor, page_index, request.watermark, page_width, page_height);
                } else {
                    drawImageWatermark(editor, page_index, request.watermark, page_width, page_height);
                }
                pages_watermarked++;
            } catch (hash<ExceptionInfo> ex) {
                push warnings, sprintf("Failed to add watermark on page %d: %s", page_index, ex.desc);
            }
        }

        # Save the document
        hash<auto> output = PdfActionBase::saveEditorOutput(editor, request);

        hash<PdfAddWatermarkResponse> response();
        response.success = True;
        response += output;
        response.page_count = page_count;
        response.pages_watermarked = pages_watermarked;
        response.warnings = warnings ? warnings : NOTHING;

        @debug("watermarks added: pages_watermarked=%d warnings=%d", pages_watermarked, warnings.size());

        return response;
    }

    #! Get list of target pages based on page selection
    private list<int> getTargetPages(*hash<auto> selection, int page_count) {
        if (!selection) {
            return range(page_count);
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

        return range(page_count);
    }

    #! Draw a text watermark on a page
    private drawTextWatermark(PdfEditor editor, int page_index, hash<auto> wm,
            float page_width, float page_height) {
        float opacity = wm.opacity ?? DefaultTextOpacity;
        float rotation = wm.rotation ?? DefaultTextRotation;
        string position = wm.position ?? PdfWatermarkPosition::Center;

        # Build text style
        hash<Qore::Pdf::PdfTextStyle> style();

        # Font
        hash<Qore::Pdf::PdfFontSpec> font();
        if (wm.font) {
            font = wm.font;
        }
        if (!font.size) {
            font.size = DefaultFontSize;
        }
        style.font = font;

        # Color
        if (wm.color) {
            style.color = wm.color;
        } else {
            style.color = DefaultColor;
        }

        if (position == PdfWatermarkPosition::Tile) {
            # Tiled watermark
            float spacing_x = wm.tile_spacing_x ?? 200.0;
            float spacing_y = wm.tile_spacing_y ?? 200.0;

            for (float y = spacing_y / 2; y < page_height; y += spacing_y) {
                for (float x = spacing_x / 2; x < page_width; x += spacing_x) {
                    editor.drawText(page_index, wm.text, x, y, style, rotation, opacity);
                }
            }
        } else {
            # Centered watermark (default)
            float x = page_width / 2.0;
            float y = page_height / 2.0;
            editor.drawText(page_index, wm.text, x, y, style, rotation, opacity);
        }
    }

    #! Draw an image watermark on a page
    private drawImageWatermark(PdfEditor editor, int page_index, hash<auto> wm,
            float page_width, float page_height) {
        float opacity = wm.opacity ?? DefaultTextOpacity;
        float rotation = wm.rotation ?? 0.0;
        float scale = wm.scale ?? 1.0;
        string position = wm.position ?? PdfWatermarkPosition::Center;

        # Get image dimensions
        hash<auto> img_dims;
        if (wm.image_path) {
            img_dims = PdfEditor::getImageDimensions(wm.image_path);
        } else {
            img_dims = PdfEditor::getImageDimensionsFromData(wm.image_data);
        }

        float width = img_dims.width * scale;
        float height = img_dims.height * scale;

        if (position == PdfWatermarkPosition::Tile) {
            # Tiled watermark
            float spacing_x = wm.tile_spacing_x ?? (width + 50.0);
            float spacing_y = wm.tile_spacing_y ?? (height + 50.0);

            for (float y = 0.0; y < page_height; y += spacing_y) {
                for (float x = 0.0; x < page_width; x += spacing_x) {
                    if (wm.image_path) {
                        editor.drawImage(page_index, wm.image_path, x, y, width, height, rotation, opacity);
                    } else {
                        editor.drawImageFromData(page_index, wm.image_data, x, y, width, height, rotation, opacity);
                    }
                }
            }
        } else {
            # Centered watermark (default)
            float x = (page_width - width) / 2.0;
            float y = (page_height - height) / 2.0;

            if (wm.image_path) {
                editor.drawImage(page_index, wm.image_path, x, y, width, height, rotation, opacity);
            } else {
                editor.drawImageFromData(page_index, wm.image_data, x, y, width, height, rotation, opacity);
            }
        }
    }
}
}
