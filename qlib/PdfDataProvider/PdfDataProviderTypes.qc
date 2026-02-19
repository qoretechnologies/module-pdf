# -*- mode: qore; indent-tabs-mode: nil -*-
#! Qore PdfDataProvider type definitions

/** PdfDataProviderTypes.qc Copyright (C) 2026 Qore Technologies, s.r.o.

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

# ========== Enums for Discrete Values ==========

#! Page types for PDF creation
public enum PdfPageType : string {
    #! Empty page with no content
    Blank = "blank",
    #! Page with text content
    Text = "text",
}

#! Form field types for PDF forms
public enum PdfFormFieldType : string {
    #! Single or multi-line text input field
    Text = "text",
    #! Boolean checkbox field
    Checkbox = "checkbox",
    #! Dropdown selection box (combo box)
    Combo = "combo",
    #! List box with multiple visible items
    List = "list",
    #! Radio button group
    Radio = "radio",
    #! Push button
    Button = "button",
    #! Digital signature field
    Signature = "signature",
}

#! PDF encryption algorithms
/**
    @note Rc4_40 and Rc4_128 are legacy algorithms and should be avoided for new documents.
    Aes256 is the recommended algorithm for maximum security.
*/
public enum PdfEncryptionAlgorithm : string {
    #! 40-bit RC4 encryption (PDF 1.3, legacy - not recommended)
    Rc4_40 = "rc4-40",
    #! 128-bit RC4 encryption (PDF 1.4, legacy - not recommended)
    Rc4_128 = "rc4-128",
    #! 128-bit AES encryption (PDF 1.6)
    Aes128 = "aes-128",
    #! 256-bit AES encryption (PDF 2.0, recommended)
    Aes256 = "aes-256",
}

#! Hash algorithms for digital signatures
public enum PdfHashAlgorithm : string {
    #! SHA-256 hash algorithm (recommended)
    Sha256 = "sha256",
    #! SHA-384 hash algorithm
    Sha384 = "sha384",
    #! SHA-512 hash algorithm
    Sha512 = "sha512",
}

#! Watermark content types
public enum PdfWatermarkType : string {
    #! Text-based watermark
    Text = "text",
    #! Image-based watermark
    Image = "image",
}

#! Watermark position modes
public enum PdfWatermarkPosition : string {
    #! Single watermark centered on each page
    Center = "center",
    #! Tiled watermarks covering the entire page
    Tile = "tile",
}

#! Watermark layer placement
public enum PdfWatermarkLayer : string {
    #! Draw watermark over existing content
    Foreground = "foreground",
    #! Draw watermark behind existing content
    Background = "background",
}

#! Preset positions for element placement
public enum PdfPresetPosition : string {
    #! Center of page
    Center = "center",
    #! Top-left corner
    TopLeft = "top-left",
    #! Top-right corner
    TopRight = "top-right",
    #! Bottom-left corner
    BottomLeft = "bottom-left",
    #! Bottom-right corner
    BottomRight = "bottom-right",
    #! Top center
    TopCenter = "top-center",
    #! Bottom center
    BottomCenter = "bottom-center",
}

#! Position coordinate modes
public enum PdfPositionMode : string {
    #! Absolute coordinates in points (default)
    Absolute = "absolute",
    #! Percentage of page dimensions (0-100)
    Percentage = "percentage",
}

#! Position origin for coordinate system
public enum PdfPositionOrigin : string {
    #! Origin at top-left corner, Y increases downward (default)
    TopLeft = "top-left",
    #! Origin at bottom-left corner, Y increases upward (PDF native)
    BottomLeft = "bottom-left",
}

#! Horizontal text alignment
public enum PdfTextAlignment : string {
    #! Align text to the left (default)
    Left = "left",
    #! Center text horizontally
    Center = "center",
    #! Align text to the right
    Right = "right",
}

#! Vertical text alignment
public enum PdfVerticalAlignment : string {
    #! Align text to the top (default)
    Top = "top",
    #! Center text vertically
    Middle = "middle",
    #! Align text to the bottom
    Bottom = "bottom",
}

#! Text rendering modes
public enum PdfRenderMode : string {
    #! Fill text with color (default)
    Fill = "fill",
    #! Stroke text outline only
    Stroke = "stroke",
    #! Fill and stroke text
    FillStroke = "fill_stroke",
}

#! Common named colors
public enum PdfNamedColor : string {
    #! Black color
    Black = "black",
    #! White color
    White = "white",
    #! Red color
    Red = "red",
    #! Green color
    Green = "green",
    #! Blue color
    Blue = "blue",
    #! Yellow color
    Yellow = "yellow",
    #! Cyan color
    Cyan = "cyan",
    #! Magenta color
    Magenta = "magenta",
    #! Gray color
    Gray = "gray",
    #! Light gray color
    LightGray = "lightgray",
    #! Dark gray color
    DarkGray = "darkgray",
    #! Orange color
    Orange = "orange",
    #! Purple color
    Purple = "purple",
    #! Brown color
    Brown = "brown",
    #! Pink color
    Pink = "pink",
}

# ========== Common Field Constants ==========

#! Common input fields for actions that read a single PDF (input_path, data, or location - required group)
const PdfInputFields = {
    "input_path": {
        "type": StringOrNothingType,
        "display_name": "Input File Path",
        "short_desc": "Path to input PDF file",
        "desc": "File path to read the input PDF from. One of 'input_path', 'data', or "
            "'location' must be provided.",
        "example_value": "/path/to/document.pdf",
    },
    "data": {
        "type": BinaryOrNothingType,
        "display_name": "Input PDF Data",
        "short_desc": "Binary PDF data",
        "desc": "Binary data of the input PDF. One of 'input_path', 'data', or 'location' "
            "must be provided.",
    },
    "location": {
        "type": StringOrNothingType,
        "display_name": "Input Location",
        "short_desc": "Location of input PDF",
        "desc": "A file location string as supported by the "
            "[FileLocationHandler](https://docs.qore.org/current/modules/FileLocationHandler/html/index.html) "
            "module (e.g. `file:///path/to/document.pdf`, `https://example.com/doc.pdf`). "
            "One of 'input_path', 'data', or 'location' must be provided.",
        "example_value": "file:///path/to/document.pdf",
    },
};

#! Common password field
const PdfPasswordField = {
    "password": {
        "type": StringOrNothingType,
        "display_name": "Password",
        "short_desc": "Optional PDF password",
        "desc": "Optional password for encrypted PDFs",
    },
};

#! Common output fields for actions that produce a PDF
const PdfOutputFields = {
    "output_path": {
        "type": StringOrNothingType,
        "display_name": "Output File Path",
        "short_desc": "Path to write the output PDF to",
        "desc": "File path to write the processed output PDF to. If neither 'output_path' nor "
            "'output_location' is provided, the PDF data is returned in the response only.",
        "example_value": "/path/to/output.pdf",
    },
    "output_location": {
        "type": StringOrNothingType,
        "display_name": "Output Location",
        "short_desc": "Location to write the output PDF to",
        "desc": "A file location string as supported by the "
            "[FileLocationHandler](https://docs.qore.org/current/modules/FileLocationHandler/html/index.html) "
            "module (e.g. `file:///path/to/output.pdf`, `sftp://host/path/output.pdf`). "
            "If neither 'output_path' nor 'output_location' is provided, the PDF data is returned "
            "in the response only.",
        "example_value": "file:///path/to/output.pdf",
    },
    "return_data": {
        "type": BoolOrNothingType,
        "display_name": "Return Data",
        "short_desc": "Whether to include PDF data in the response",
        "desc": "Whether to include binary PDF data in the response hash. Defaults to `True` when "
            "no output path or location is specified, `False` when an output destination is provided.",
    },
    "overwrite": {
        "type": BoolOrNothingType,
        "display_name": "Overwrite",
        "short_desc": "Overwrite the input file",
        "desc": "If `true` and `output_path` is not specified, the input file will be overwritten "
            "(only applicable when `input_path` is used).",
    },
};

#! Common output response fields for actions that produce a PDF
const PdfOutputResponseFields = {
    "data": {
        "type": BinaryOrNothingType,
        "display_name": "Output PDF Data",
        "short_desc": "The processed PDF data",
        "desc": "Binary data of the processed PDF. Only included when `return_data` is `true` "
            "(default when no output destination is specified).",
    },
    "output_path": {
        "type": StringOrNothingType,
        "display_name": "Output File Path",
        "short_desc": "Path the output PDF was written to",
        "desc": "File path where the output PDF was written, if 'output_path' was specified in "
            "the request",
    },
    "output_location": {
        "type": StringOrNothingType,
        "display_name": "Output Location",
        "short_desc": "Location the output PDF was written to",
        "desc": "File location where the output PDF was written, if 'output_location' was "
            "specified in the request",
    },
    "size": {
        "type": IntType,
        "display_name": "Size",
        "short_desc": "Output data size in bytes",
        "desc": "Size of the output PDF data in bytes",
    },
};

# ========== Page Creation Types ==========

#! Page specification for PDF creation
/**
    Defines a single page to create in a new PDF document.
*/
public hashdecl PdfCreatePageSpec {
    #! Page type: "blank" or "text"
    /** @see PdfPageType for symbolic constants
    */
    string type;

    #! Page text (required for "text" pages)
    *string text;

    #! Page width in points
    *float width;

    #! Page height in points
    *float height;
}

#! Request type for creating a PDF document
public hashdecl PdfCreateDocumentRequest {
    #! Output file path
    *string output_path;

    #! Output location (FileLocationHandler string)
    *string output_location;

    #! Whether to return binary PDF data in response
    *bool return_data;

    #! Number of blank pages (used if pages is not set)
    *int page_count;

    #! Page specifications (blank or text pages)
    *list<hash<PdfCreatePageSpec>> pages;

    #! Optional metadata
    *hash<Qore::Pdf::PdfMetadata> metadata;

    #! Optional font options
    *hash<Qore::Pdf::PdfFontOptions> font_options;
}

#! Response type for creating a PDF document
public hashdecl PdfCreateDocumentResponse {
    #! True if successful
    bool success;

    #! Output file path
    *string output_path;

    #! Output location
    *string output_location;

    #! Binary PDF data (when return_data is true)
    *binary data;

    #! Number of pages created
    int page_count;

    #! Output file size in bytes
    int size;
}

#! Request type for reading PDF document info
public hashdecl PdfDocumentInfoRequest {
    #! Input file path
    *string input_path;

    #! Binary PDF data
    *binary data;

    #! Input location (FileLocationHandler string)
    *string location;

    #! Optional password
    *string password;
}

#! Response type for PDF document info
public hashdecl PdfDocumentInfoResponse {
    #! Number of pages
    int page_count;

    #! Document metadata
    hash<Qore::Pdf::PdfMetadata> metadata;

    #! Warnings encountered while reading the document
    *list<string> warnings;
}

#! Request type for setting metadata
public hashdecl PdfSetMetadataRequest {
    #! Input file path
    *string input_path;

    #! Binary PDF data
    *binary data;

    #! Input location (FileLocationHandler string)
    *string location;

    #! Metadata fields to set
    hash<Qore::Pdf::PdfMetadata> metadata;

    #! Output file path (optional if overwrite is true)
    *string output_path;

    #! Output location (FileLocationHandler string)
    *string output_location;

    #! Whether to return binary PDF data in response
    *bool return_data;

    #! Overwrite the input file if true
    *bool overwrite;

    #! Optional password
    *string password;
}

#! Response type for setting metadata
public hashdecl PdfSetMetadataResponse {
    #! True if successful
    bool success;

    #! Output file path
    *string output_path;

    #! Output location
    *string output_location;

    #! Binary PDF data (when return_data is true)
    *binary data;

    #! Number of pages
    int page_count;

    #! Output data size in bytes
    int size;

    #! Warnings encountered while processing the document
    *list<string> warnings;
}

#! Request type for merging documents
public hashdecl PdfMergeDocumentRequest {
    #! Input file paths
    list<string> inputs;

    #! Output file path
    *string output_path;

    #! Output location (FileLocationHandler string)
    *string output_location;

    #! Whether to return binary PDF data in response
    *bool return_data;

    #! Optional password for input files
    *string password;
}

#! Response type for merging documents
public hashdecl PdfMergeDocumentResponse {
    #! True if successful
    bool success;

    #! Output file path
    *string output_path;

    #! Output location
    *string output_location;

    #! Binary PDF data (when return_data is true)
    *binary data;

    #! Number of pages in the merged document
    int page_count;

    #! Output file size in bytes
    int size;

    #! Warnings encountered while processing input documents
    *list<string> warnings;
}

#! Request type for splitting a document
public hashdecl PdfSplitDocumentRequest {
    #! Input file path
    *string input_path;

    #! Binary PDF data
    *binary data;

    #! Input location (FileLocationHandler string)
    *string location;

    #! Output directory
    string output_dir;

    #! Output filename prefix
    *string prefix;
}

#! Response type for splitting a document
public hashdecl PdfSplitDocumentResponse {
    #! Output files
    list<string> outputs;

    #! Number of pages written
    int count;

    #! Warnings encountered while processing the document
    *list<string> warnings;
}

#! Request type for rotating pages
public hashdecl PdfRotatePagesRequest {
    #! Input file path
    *string input_path;

    #! Binary PDF data
    *binary data;

    #! Input location (FileLocationHandler string)
    *string location;

    #! Output file path (optional if overwrite is true)
    *string output_path;

    #! Output location (FileLocationHandler string)
    *string output_location;

    #! Whether to return binary PDF data in response
    *bool return_data;

    #! Overwrite the input file if true
    *bool overwrite;

    #! Page indices to rotate (zero-based)
    list<int> pages;

    #! Rotation degrees (multiple of 90)
    int degrees;

    #! Optional password
    *string password;
}

#! Response type for rotating pages
public hashdecl PdfRotatePagesResponse {
    #! True if successful
    bool success;

    #! Output file path
    *string output_path;

    #! Output location
    *string output_location;

    #! Binary PDF data (when return_data is true)
    *binary data;

    #! Number of pages
    int page_count;

    #! Output data size in bytes
    int size;

    #! Warnings encountered while processing the document
    *list<string> warnings;
}

#! Request type for rendering a page
public hashdecl PdfRenderPageRequest {
    #! Input file path
    *string input_path;

    #! Binary PDF data
    *binary data;

    #! Input location (FileLocationHandler string)
    *string location;

    #! Page index (zero-based)
    int page_index;

    #! DPI resolution
    *int dpi;

    #! Optional output file path for raw BGRA data
    *string output_path;
}

#! Response type for rendering a page
public hashdecl PdfRenderPageResponse {
    #! Width in pixels
    int width;

    #! Height in pixels
    int height;

    #! Bytes per row
    int stride;

    #! Pixel format (BGRA)
    string format;

    #! Raw pixel data (omitted if output_path is set)
    *binary data;

    #! Output file path (if written)
    *string output_path;

    #! Output data size in bytes
    int size;
}

#! Request type for extracting text
public hashdecl PdfExtractTextRequest {
    #! Input file path
    *string input_path;

    #! Binary PDF data
    *binary data;

    #! Input location (FileLocationHandler string)
    *string location;

    #! Page index (zero-based)
    int page_index;
}

#! Response type for extracting text
public hashdecl PdfExtractTextResponse {
    #! Extracted text
    string text;
}

#! Page selection specification for PDF operations
/**
    Specifies which pages to target for an operation.
*/
public hashdecl PdfPageSelection {
    #! Specific page indices (zero-based)
    *list<int> pages;

    #! Apply to all pages
    *bool all;

    #! Range start (zero-based)
    *int from_page;

    #! Range end (zero-based, inclusive)
    *int to_page;
}

#! Image placement specification for adding images to PDFs
/**
    Defines how an image should be placed on a PDF page.
*/
public hashdecl PdfImagePlacement {
    #! Path to image file (PNG, JPEG)
    *string image_path;

    #! Binary image data (alternative to image_path)
    *binary image_data;

    #! Position on page
    *hash<Qore::Pdf::PdfPosition> position;

    #! Target width in points (0 = auto)
    *float width;

    #! Target height in points (0 = auto)
    *float height;

    #! Scale factor (default: 1.0)
    *float scale;

    #! Preserve aspect ratio (default: true)
    *bool preserve_aspect_ratio;

    #! Rotation in degrees (0, 90, 180, 270)
    *int rotation;

    #! Opacity 0.0-1.0 (default: 1.0)
    *float opacity;
}

#! Request type for adding images to a PDF
public hashdecl PdfAddImageRequest {
    #! Input PDF file path
    *string input_path;

    #! Binary PDF data
    *binary data;

    #! Input location (FileLocationHandler string)
    *string location;

    #! Output file path (optional if overwrite is true)
    *string output_path;

    #! Output location (FileLocationHandler string)
    *string output_location;

    #! Whether to return binary PDF data in response
    *bool return_data;

    #! Overwrite the input file if true
    *bool overwrite;

    #! Page selection (default: first page)
    *hash<auto> page_selection;

    #! Single image placement
    *hash<auto> image;

    #! Multiple image placements
    *list<hash<auto>> placements;

    #! Optional password for encrypted PDFs
    *string password;
}

#! Response type for adding images to a PDF
public hashdecl PdfAddImageResponse {
    #! True if successful
    bool success;

    #! Output file path
    *string output_path;

    #! Output location
    *string output_location;

    #! Binary PDF data (when return_data is true)
    *binary data;

    #! Number of pages in the document
    int page_count;

    #! Number of pages modified
    int pages_modified;

    #! Number of images added
    int images_added;

    #! Output file size in bytes
    int size;

    #! Warnings encountered
    *list<string> warnings;
}

#! Text placement specification for adding text to PDFs
/**
    Defines how text should be placed on a PDF page.
*/
public hashdecl PdfTextPlacement {
    #! Text string to draw
    string text;

    #! Position on page
    *hash<Qore::Pdf::PdfPosition> position;

    #! Text style
    *hash<Qore::Pdf::PdfTextStyle> style;

    #! Maximum width for text wrapping
    /** @note Not yet implemented - text wrapping is not currently supported */
    *float max_width;

    #! Maximum height (clip if exceeded)
    /** @note Not yet implemented - text clipping is not currently supported */
    *float max_height;

    #! Rotation in degrees
    *float rotation;

    #! Opacity 0.0-1.0 (default: 1.0)
    *float opacity;
}

#! Request type for adding text to a PDF
public hashdecl PdfAddTextRequest {
    #! Input PDF file path
    *string input_path;

    #! Binary PDF data
    *binary data;

    #! Input location (FileLocationHandler string)
    *string location;

    #! Output file path (optional if overwrite is true)
    *string output_path;

    #! Output location (FileLocationHandler string)
    *string output_location;

    #! Whether to return binary PDF data in response
    *bool return_data;

    #! Overwrite the input file if true
    *bool overwrite;

    #! Page selection (default: first page)
    *hash<auto> page_selection;

    #! Single text block
    *hash<auto> text;

    #! Multiple text blocks
    *list<hash<auto>> placements;

    #! Optional password for encrypted PDFs
    *string password;

    #! Optional font options
    *hash<Qore::Pdf::PdfFontOptions> font_options;
}

#! Response type for adding text to a PDF
public hashdecl PdfAddTextResponse {
    #! True if successful
    bool success;

    #! Output file path
    *string output_path;

    #! Output location
    *string output_location;

    #! Binary PDF data (when return_data is true)
    *binary data;

    #! Number of pages in the document
    int page_count;

    #! Number of pages modified
    int pages_modified;

    #! Number of text blocks added
    int text_blocks_added;

    #! Output file size in bytes
    int size;

    #! Warnings encountered
    *list<string> warnings;
}

#! Watermark specification for adding watermarks to PDFs
/**
    Defines watermark properties for text or image watermarks.

    For text watermarks, set type="text" and provide the text property.
    For image watermarks, set type="image" and provide image_path or image_data.
*/
public hashdecl PdfWatermarkSpec {
    #! Watermark type: "text" or "image" (required)
    /** @see PdfWatermarkType for symbolic constants
    */
    string type;

    #! Text content for text watermarks
    /** Required when type="text".
    */
    *string text;

    #! Path to image file for image watermarks (PNG, JPEG)
    /** Required when type="image" (unless image_data is provided).
    */
    *string image_path;

    #! Binary image data for image watermarks
    /** Alternative to image_path for type="image".
    */
    *binary image_data;

    #! Font specification for text watermarks
    /** Default: Helvetica 48pt
    */
    *hash<Qore::Pdf::PdfFontSpec> font;

    #! Color for text watermarks
    /** Default: light gray (RGB: 0.8, 0.8, 0.8)
    */
    *hash<Qore::Pdf::PdfColor> color;

    #! Opacity from 0.0 (transparent) to 1.0 (opaque)
    /** Default: 0.3
    */
    *float opacity;

    #! Rotation angle in degrees
    /** Default: -45 (diagonal from bottom-left to top-right)
    */
    *float rotation;

    #! Scale factor for watermark size
    *float scale;

    #! Watermark position mode: "center" (default) or "tile"
    /** @see PdfWatermarkPosition for symbolic constants
    */
    *string position;

    #! Horizontal spacing between tiled watermarks (in points)
    /** Only used when position="tile".
    */
    *float tile_spacing_x;

    #! Vertical spacing between tiled watermarks (in points)
    /** Only used when position="tile".
    */
    *float tile_spacing_y;

    #! Watermark layer: "foreground" or "background" (default)
    /** @see PdfWatermarkLayer for symbolic constants
    */
    *string layer;
}

#! Request type for adding watermarks to a PDF
public hashdecl PdfAddWatermarkRequest {
    #! Input PDF file path
    *string input_path;

    #! Binary PDF data
    *binary data;

    #! Input location (FileLocationHandler string)
    *string location;

    #! Output file path (optional if overwrite is true)
    *string output_path;

    #! Output location (FileLocationHandler string)
    *string output_location;

    #! Whether to return binary PDF data in response
    *bool return_data;

    #! Overwrite the input file if true
    *bool overwrite;

    #! Page selection (default: all pages)
    *hash<auto> page_selection;

    #! Watermark specification
    hash<auto> watermark;

    #! Optional password for encrypted PDFs
    *string password;
}

#! Response type for adding watermarks to a PDF
public hashdecl PdfAddWatermarkResponse {
    #! True if successful
    bool success;

    #! Output file path
    *string output_path;

    #! Output location
    *string output_location;

    #! Binary PDF data (when return_data is true)
    *binary data;

    #! Number of pages in the document
    int page_count;

    #! Number of pages watermarked
    int pages_watermarked;

    #! Output file size in bytes
    int size;

    #! Warnings encountered
    *list<string> warnings;
}

#! Signature field specification for adding signature placeholders
/**
    Defines properties for a signature field placement.
*/
public hashdecl PdfSignatureFieldSpec {
    #! Optional signature image path
    *string image_path;

    #! Optional signature image data
    *binary image_data;

    #! Position on page (default: bottom-right with margin)
    *hash<Qore::Pdf::PdfPosition> position;

    #! Maximum width (default: 150)
    *float max_width;

    #! Maximum height (default: 50)
    *float max_height;

    #! Label text below signature
    *string label;

    #! Label font specification
    *hash<Qore::Pdf::PdfFontSpec> label_font;

    #! Label color
    *hash<Qore::Pdf::PdfColor> label_color;

    #! Draw signature line (default: true if no image)
    *bool draw_line;

    #! Line color
    *hash<Qore::Pdf::PdfColor> line_color;

    #! Line width in points
    *float line_width;
}

#! Request type for adding signature fields to a PDF
public hashdecl PdfAddSignatureFieldRequest {
    #! Input PDF file path
    *string input_path;

    #! Binary PDF data
    *binary data;

    #! Input location (FileLocationHandler string)
    *string location;

    #! Output file path (optional if overwrite is true)
    *string output_path;

    #! Output location (FileLocationHandler string)
    *string output_location;

    #! Whether to return binary PDF data in response
    *bool return_data;

    #! Overwrite the input file if true
    *bool overwrite;

    #! Page selection (default: last page)
    *hash<auto> page_selection;

    #! Signature field specification
    hash<auto> signature;

    #! Optional password for encrypted PDFs
    *string password;
}

#! Response type for adding signature fields to a PDF
public hashdecl PdfAddSignatureFieldResponse {
    #! True if successful
    bool success;

    #! Output file path
    *string output_path;

    #! Output location
    *string output_location;

    #! Binary PDF data (when return_data is true)
    *binary data;

    #! Number of pages in the document
    int page_count;

    #! Number of signature fields added
    int fields_added;

    #! Output file size in bytes
    int size;

    #! Warnings encountered
    *list<string> warnings;
}

# ========== Form Field Types ==========

#! Rectangle specification for form field bounds
public hashdecl PdfRectangle {
    #! X coordinate
    float x;

    #! Y coordinate
    float y;

    #! Width
    float width;

    #! Height
    float height;
}

#! Form field information
/**
    Contains detailed information about a form field in a PDF document.
*/
public hashdecl PdfFormFieldInfo {
    #! Full hierarchical field name (e.g., "form1.address.city")
    string name;

    #! Field type: "text", "checkbox", "combo", "list", "radio", "button", "signature"
    /** @see PdfFormFieldType for symbolic constants
    */
    string type;

    #! Current value (for text fields)
    *string value;

    #! Checked state (for checkboxes)
    *bool checked;

    #! Selected index (for combo/list)
    *int selected_index;

    #! Available options (for combo/list)
    *list<string> options;

    #! Whether the field is read-only
    bool read_only;

    #! Whether the field is required
    bool required;

    #! Page index where field appears (zero-based)
    *int page;

    #! Bounding rectangle
    *hash<PdfRectangle> rect;
}

#! Request type for listing form fields
public hashdecl PdfListFormFieldsRequest {
    #! Input file path
    *string input_path;

    #! Binary PDF data
    *binary data;

    #! Input location (FileLocationHandler string)
    *string location;

    #! Optional password for encrypted PDFs
    *string password;
}

#! Response type for listing form fields
public hashdecl PdfListFormFieldsResponse {
    #! True if successful
    bool success;

    #! List of form fields (see PdfFormFieldInfo for field structure)
    list<hash<auto>> fields;

    #! Number of fields found
    int field_count;
}

#! Request type for getting form data
public hashdecl PdfGetFormDataRequest {
    #! Input file path
    *string input_path;

    #! Binary PDF data
    *binary data;

    #! Input location (FileLocationHandler string)
    *string location;

    #! Optional password for encrypted PDFs
    *string password;

    #! Specific fields to get (default: all)
    *list<string> fields;
}

#! Response type for getting form data
public hashdecl PdfGetFormDataResponse {
    #! True if successful
    bool success;

    #! Field name to value mapping
    hash<auto> data;

    #! Number of fields returned
    int field_count;
}

#! Request type for filling form fields
public hashdecl PdfFillFormRequest {
    #! Input file path
    *string input_path;

    #! Binary PDF data
    *binary data;

    #! Input location (FileLocationHandler string)
    *string location;

    #! Output file path (optional if overwrite is true)
    *string output_path;

    #! Output location (FileLocationHandler string)
    *string output_location;

    #! Whether to return binary PDF data in response
    *bool return_data;

    #! Overwrite the input file if true
    *bool overwrite;

    #! Optional password for encrypted PDFs
    *string password;

    #! Field name to value mapping
    hash<auto> form_data;

    #! Convert fields to static content after filling
    *bool flatten;
}

#! Response type for filling form fields
public hashdecl PdfFillFormResponse {
    #! True if successful
    bool success;

    #! Output file path
    *string output_path;

    #! Output location
    *string output_location;

    #! Binary PDF data (when return_data is true)
    *binary data;

    #! Number of fields filled
    int fields_filled;

    #! Output file size in bytes
    int size;

    #! Warnings encountered
    *list<string> warnings;
}

#! Form field specification for creating new fields
/**
    Defines the properties for creating a new form field in a PDF document.
*/
public hashdecl PdfFormFieldSpec {
    #! Field name (required)
    /** Must be unique within the document. Dots ('.') in names are not supported by PoDoFo.
    */
    string name;

    #! Field type: "text", "checkbox", "combo", "list", "radio", "button"
    /** @see PdfFormFieldType for symbolic constants
        @note Signature fields should be created using the create-signature-field action instead.
    */
    string type;

    #! Page index (zero-based, required)
    int page;

    #! X coordinate
    float x;

    #! Y coordinate
    float y;

    #! Field width
    float width;

    #! Field height
    float height;

    #! Default value
    *string default_value;

    #! Options for combo/list fields
    *list<string> options;

    #! Maximum length for text fields
    *int max_length;

    #! Allow multiline text
    *bool multiline;

    #! Password field (obscure text)
    *bool password;

    #! Read-only field
    *bool read_only;

    #! Required field
    *bool required;

    #! Font family name
    *string font_family;

    #! Font size in points
    *float font_size;
}

#! Request type for creating form fields
public hashdecl PdfCreateFormFieldRequest {
    #! Input file path
    *string input_path;

    #! Binary PDF data
    *binary data;

    #! Input location (FileLocationHandler string)
    *string location;

    #! Output file path (optional if overwrite is true)
    *string output_path;

    #! Output location (FileLocationHandler string)
    *string output_location;

    #! Whether to return binary PDF data in response
    *bool return_data;

    #! Overwrite the input file if true
    *bool overwrite;

    #! Optional password for encrypted PDFs
    *string password;

    #! Single field specification
    *hash<PdfFormFieldSpec> field;

    #! Multiple field specifications
    *list<hash<PdfFormFieldSpec>> fields;
}

#! Response type for creating form fields
public hashdecl PdfCreateFormFieldResponse {
    #! True if successful
    bool success;

    #! Output file path
    *string output_path;

    #! Output location
    *string output_location;

    #! Binary PDF data (when return_data is true)
    *binary data;

    #! Number of fields created
    int fields_created;

    #! Output file size in bytes
    int size;

    #! Warnings encountered
    *list<string> warnings;
}

# ========== Encryption Types ==========

#! PDF document permissions
public hashdecl PdfPermissions {
    #! Allow printing (default: true)
    *bool print;

    #! Allow editing (default: true)
    *bool edit;

    #! Allow copying (default: true)
    *bool copy;

    #! Allow annotation editing (default: true)
    *bool edit_notes;

    #! Allow form filling (default: true)
    *bool fill_and_sign;

    #! Allow accessibility extraction (default: true)
    *bool accessible;

    #! Allow page manipulation (default: true)
    *bool doc_assembly;

    #! Allow high-quality printing (default: true)
    *bool high_print;
}

#! Request type for encrypting a PDF
/**
    Encrypt a PDF document with password protection and optional permission restrictions.

    The owner password provides full access to the document, while the optional user password
    provides restricted access based on the specified permissions.
*/
public hashdecl PdfEncryptRequest {
    #! Input file path
    *string input_path;

    #! Binary PDF data
    *binary data;

    #! Input location (FileLocationHandler string)
    *string location;

    #! Output file path (optional if overwrite is true)
    *string output_path;

    #! Output location (FileLocationHandler string)
    *string output_location;

    #! Whether to return binary PDF data in response
    *bool return_data;

    #! Overwrite the input file if true
    /** If true and output_path is not specified, the input file will be overwritten.
    */
    *bool overwrite;

    #! Optional password if input is already encrypted
    *string input_password;

    #! Owner password (required)
    /** The owner password provides full access to the document including the ability
        to change permissions and remove encryption.
    */
    string owner_password;

    #! User password (optional)
    /** If set, users must provide this password to open the document.
        Their access will be restricted based on the permissions settings.
    */
    *string user_password;

    #! Encryption algorithm: "rc4-40", "rc4-128", "aes-128", "aes-256" (default)
    /** Default: "aes-256" (recommended for maximum security)
        @see PdfEncryptionAlgorithm for symbolic constants
        @note RC4 algorithms are legacy and should only be used for compatibility
        with older PDF readers.
    */
    *string algorithm;

    #! Document permissions
    /** Specifies which operations are allowed when the document is opened with the user password.
    */
    *hash<PdfPermissions> permissions;
}

#! Response type for encrypting a PDF
public hashdecl PdfEncryptResponse {
    #! True if successful
    bool success;

    #! Output file path
    *string output_path;

    #! Output location
    *string output_location;

    #! Binary PDF data (when return_data is true)
    *binary data;

    #! Algorithm used
    string algorithm;

    #! Output file size in bytes
    int size;
}

#! Request type for decrypting a PDF
public hashdecl PdfDecryptRequest {
    #! Input file path
    *string input_path;

    #! Binary PDF data
    *binary data;

    #! Input location (FileLocationHandler string)
    *string location;

    #! Output file path (optional if overwrite is true)
    *string output_path;

    #! Output location (FileLocationHandler string)
    *string output_location;

    #! Whether to return binary PDF data in response
    *bool return_data;

    #! Overwrite the input file if true
    *bool overwrite;

    #! Owner password required for decryption
    string password;
}

#! Response type for decrypting a PDF
public hashdecl PdfDecryptResponse {
    #! True if successful
    bool success;

    #! Output file path
    *string output_path;

    #! Output location
    *string output_location;

    #! Binary PDF data (when return_data is true)
    *binary data;

    #! Output file size in bytes
    int size;
}

#! Request type for getting encryption info
public hashdecl PdfGetEncryptionInfoRequest {
    #! Input file path
    *string input_path;

    #! Binary PDF data
    *binary data;

    #! Input location (FileLocationHandler string)
    *string location;

    #! Optional password
    *string password;
}

#! PDF encryption information
public hashdecl PdfEncryptionInfo {
    #! Whether the document is encrypted
    bool encrypted;

    #! Encryption algorithm if encrypted
    *string algorithm;

    #! Key length in bits if encrypted
    *int key_length;

    #! Document permissions if encrypted
    *hash<PdfPermissions> permissions;

    #! Whether metadata is encrypted
    *bool metadata_encrypted;
}

# ========== Digital Signature Types ==========

#! Digital signature field specification
public hashdecl PdfDigitalSignatureFieldSpec {
    #! Field name
    string name;

    #! Page index (zero-based)
    int page;

    #! X coordinate
    float x;

    #! Y coordinate
    float y;

    #! Field width
    float width;

    #! Field height
    float height;

    #! Signer name
    *string signer_name;

    #! Reason for signing
    *string reason;

    #! Signing location
    *string location;
}

#! Request type for creating a digital signature field
public hashdecl PdfCreateDigitalSignatureFieldRequest {
    #! Input file path
    *string input_path;

    #! Binary PDF data
    *binary data;

    #! Input location (FileLocationHandler string)
    *string location;

    #! Output file path (optional if overwrite is true)
    *string output_path;

    #! Output location (FileLocationHandler string)
    *string output_location;

    #! Whether to return binary PDF data in response
    *bool return_data;

    #! Overwrite the input file if true
    *bool overwrite;

    #! Optional password for encrypted PDFs
    *string password;

    #! Signature field specification
    hash<PdfDigitalSignatureFieldSpec> field;
}

#! Response type for creating a digital signature field
public hashdecl PdfCreateDigitalSignatureFieldResponse {
    #! True if successful
    bool success;

    #! Output file path
    *string output_path;

    #! Output location
    *string output_location;

    #! Binary PDF data (when return_data is true)
    *binary data;

    #! Field name created
    string field_name;

    #! Output file size in bytes
    int size;

    #! Warnings encountered
    *list<string> warnings;
}

#! Request type for signing a PDF
/**
    Sign a PDF document using a digital certificate and private key.

    Either certificate_path or certificate_data must be provided.
    Either private_key_path or private_key_data must be provided.
*/
public hashdecl PdfSignRequest {
    #! Input file path
    *string input_path;

    #! Binary PDF data
    *binary data;

    #! Input location (FileLocationHandler string)
    *string input_location;

    #! Output file path (optional if overwrite is true)
    *string output_path;

    #! Output location (FileLocationHandler string)
    *string output_location;

    #! Whether to return binary PDF data in response
    *bool return_data;

    #! Overwrite the input file if true
    *bool overwrite;

    #! Optional password for encrypted PDFs
    *string password;

    #! Signature field name to sign (required)
    /** The field must exist in the document. Use create-signature-field to create one first.
    */
    string field_name;

    #! Path to X.509 certificate file (DER or PEM format)
    /** Either certificate_path or certificate_data must be provided.
    */
    *string certificate_path;

    #! Certificate as binary data (DER or PEM format)
    /** Either certificate_path or certificate_data must be provided.
    */
    *binary certificate_data;

    #! Path to private key file (DER or PEM format)
    /** Either private_key_path or private_key_data must be provided.
    */
    *string private_key_path;

    #! Private key as binary data (DER or PEM format)
    /** Either private_key_path or private_key_data must be provided.
    */
    *binary private_key_data;

    #! Password for encrypted private key (if applicable)
    *string key_password;

    #! Signer name for display in the signature
    *string signer_name;

    #! Reason for signing
    *string reason;

    #! Signing location
    *string location;

    #! Hash algorithm: "sha256" (default), "sha384", "sha512"
    /** Default: "sha256" (recommended)
        @see PdfHashAlgorithm for symbolic constants
    */
    *string hash_algorithm;
}

#! Response type for signing a PDF
public hashdecl PdfSignResponse {
    #! True if successful
    bool success;

    #! Output file path
    *string output_path;

    #! Output location
    *string output_location;

    #! Binary PDF data (when return_data is true)
    *binary data;

    #! Field name signed
    string field_name;

    #! Output file size in bytes
    int size;
}

#! Signature information
public hashdecl PdfSignatureInfo {
    #! Field name
    string name;

    #! Signer name
    *string signer_name;

    #! Signing reason
    *string reason;

    #! Signing location
    *string location;

    #! Signing date/time
    *date date;

    #! Page index where signature appears
    *int page;
}

#! Request type for listing signatures
public hashdecl PdfListSignaturesRequest {
    #! Input file path
    *string input_path;

    #! Binary PDF data
    *binary data;

    #! Input location (FileLocationHandler string)
    *string location;

    #! Optional password for encrypted PDFs
    *string password;
}

#! Response type for listing signatures
public hashdecl PdfListSignaturesResponse {
    #! True if successful
    bool success;

    #! List of signatures (see PdfSignatureInfo for field structure)
    list<hash<auto>> signatures;

    #! Number of signatures found
    int signature_count;
}

# ========== HashDataType Request Classes ==========

#! Document info request type with required input group
public class PdfDocumentInfoRequestDataType inherits HashDataType {
    constructor() {
        addQoreFields(PdfInputFields);
        addQoreFields(PdfPasswordField);
        setRequiredGroups((("input_path", "data", "location"),));
    }
}

#! Set metadata request type with required input group
public class PdfSetMetadataRequestDataType inherits HashDataType {
    constructor() {
        addQoreFields(PdfInputFields);
        addQoreFields({
            "metadata": {
                "type": new Type("hash<Qore::Pdf::PdfMetadata>"),
                "display_name": "Metadata",
                "short_desc": "Metadata fields to set",
                "desc": "Document metadata fields to set (`title`, `author`, `subject`, `keywords`, `creator`, `producer`)",
            },
        });
        addQoreFields(PdfOutputFields);
        addQoreFields(PdfPasswordField);
        setRequiredGroups((("input_path", "data", "location"),));
    }
}

#! Merge request type
public class PdfMergeDocumentRequestDataType inherits HashDataType {
    constructor() {
        addQoreFields({
            "inputs": {
                "type": new Type("list<string>"),
                "display_name": "Input Paths",
                "short_desc": "List of input PDF file paths",
                "desc": "List of PDF file paths to merge into a single document",
            },
        });
        addQoreFields(PdfOutputFields - "overwrite");
        addQoreFields(PdfPasswordField);
    }
}

#! Split request type with required input group
public class PdfSplitDocumentRequestDataType inherits HashDataType {
    constructor() {
        addQoreFields(PdfInputFields);
        addQoreFields({
            "output_dir": {
                "type": StringType,
                "display_name": "Output Directory",
                "short_desc": "Output directory for split pages",
                "desc": "Directory to write the split single-page PDF files to",
            },
            "prefix": {
                "type": StringType,
                "display_name": "Filename Prefix",
                "short_desc": "Output filename prefix",
                "desc": "Prefix for output filenames",
                "default_value": "page_",
            },
        });
        setRequiredGroups((("input_path", "data", "location"),));
    }
}

#! Rotate pages request type with required input group
public class PdfRotatePagesRequestDataType inherits HashDataType {
    constructor() {
        addQoreFields(PdfInputFields);
        addQoreFields(PdfOutputFields);
        addQoreFields({
            "pages": {
                "type": new Type("list<int>"),
                "display_name": "Pages",
                "short_desc": "Page indices to rotate (zero-based)",
                "desc": "List of zero-based page indices to rotate",
            },
            "degrees": {
                "type": IntType,
                "display_name": "Degrees",
                "short_desc": "Rotation in degrees",
                "desc": "Rotation angle in degrees (must be a multiple of 90)",
            },
        });
        addQoreFields(PdfPasswordField);
        setRequiredGroups((("input_path", "data", "location"),));
    }
}

#! Add image request type with required input group
public class PdfAddImageRequestDataType inherits HashDataType {
    constructor() {
        addQoreFields(PdfInputFields);
        addQoreFields(PdfOutputFields);
        addQoreFields({
            "page_selection": {
                "type": AutoHashOrNothingType,
                "display_name": "Page Selection",
                "short_desc": "Pages to modify",
                "desc": "Page selection specification (default: first page)",
            },
            "image": {
                "type": AutoHashOrNothingType,
                "display_name": "Image",
                "short_desc": "Single image placement",
                "desc": "Single image placement specification",
            },
            "placements": {
                "type": new Type("*list<hash<auto>>"),
                "display_name": "Placements",
                "short_desc": "Multiple image placements",
                "desc": "List of image placement specifications",
            },
        });
        addQoreFields(PdfPasswordField);
        setRequiredGroups((("input_path", "data", "location"),));
    }
}

#! Add text request type with required input group
public class PdfAddTextRequestDataType inherits HashDataType {
    constructor() {
        addQoreFields(PdfInputFields);
        addQoreFields(PdfOutputFields);
        addQoreFields({
            "page_selection": {
                "type": AutoHashOrNothingType,
                "display_name": "Page Selection",
                "short_desc": "Pages to modify",
                "desc": "Page selection specification (default: first page)",
            },
            "text": {
                "type": AutoHashOrNothingType,
                "display_name": "Text",
                "short_desc": "Single text block",
                "desc": "Single text placement specification",
            },
            "placements": {
                "type": new Type("*list<hash<auto>>"),
                "display_name": "Placements",
                "short_desc": "Multiple text blocks",
                "desc": "List of text placement specifications",
            },
            "font_options": {
                "type": new Type("*hash<Qore::Pdf::PdfFontOptions>"),
                "display_name": "Font Options",
                "short_desc": "Font embedding options",
                "desc": "Optional font embedding and subsetting options",
            },
        });
        addQoreFields(PdfPasswordField);
        setRequiredGroups((("input_path", "data", "location"),));
    }
}

#! Add watermark request type with required input group
public class PdfAddWatermarkRequestDataType inherits HashDataType {
    constructor() {
        addQoreFields(PdfInputFields);
        addQoreFields(PdfOutputFields);
        addQoreFields({
            "page_selection": {
                "type": AutoHashOrNothingType,
                "display_name": "Page Selection",
                "short_desc": "Pages to watermark",
                "desc": "Page selection specification (default: all pages)",
            },
            "watermark": {
                "type": AutoHashType,
                "display_name": "Watermark",
                "short_desc": "Watermark specification",
                "desc": "Watermark properties (type, text/image, opacity, rotation, etc.)",
            },
        });
        addQoreFields(PdfPasswordField);
        setRequiredGroups((("input_path", "data", "location"),));
    }
}

#! Add signature field request type with required input group
public class PdfAddSignatureFieldRequestDataType inherits HashDataType {
    constructor() {
        addQoreFields(PdfInputFields);
        addQoreFields(PdfOutputFields);
        addQoreFields({
            "page_selection": {
                "type": AutoHashOrNothingType,
                "display_name": "Page Selection",
                "short_desc": "Pages to add signature to",
                "desc": "Page selection specification (default: last page)",
            },
            "signature": {
                "type": AutoHashType,
                "display_name": "Signature",
                "short_desc": "Signature field specification",
                "desc": "Signature field properties (image, position, label, etc.)",
            },
        });
        addQoreFields(PdfPasswordField);
        setRequiredGroups((("input_path", "data", "location"),));
    }
}

#! List form fields request type with required input group
public class PdfListFormFieldsRequestDataType inherits HashDataType {
    constructor() {
        addQoreFields(PdfInputFields);
        addQoreFields(PdfPasswordField);
        setRequiredGroups((("input_path", "data", "location"),));
    }
}

#! Get form data request type with required input group
public class PdfGetFormDataRequestDataType inherits HashDataType {
    constructor() {
        addQoreFields(PdfInputFields);
        addQoreFields(PdfPasswordField);
        addQoreFields({
            "fields": {
                "type": new Type("*list<string>"),
                "display_name": "Fields",
                "short_desc": "Specific fields to get",
                "desc": "List of specific field names to get (default: all fields)",
            },
        });
        setRequiredGroups((("input_path", "data", "location"),));
    }
}

#! Fill form request type with required input group
public class PdfFillFormRequestDataType inherits HashDataType {
    constructor() {
        addQoreFields(PdfInputFields);
        addQoreFields(PdfOutputFields);
        addQoreFields(PdfPasswordField);
        addQoreFields({
            "form_data": {
                "type": AutoHashType,
                "display_name": "Form Data",
                "short_desc": "Field name to value mapping",
                "desc": "Hash mapping form field names to their values",
            },
            "flatten": {
                "type": BoolOrNothingType,
                "display_name": "Flatten",
                "short_desc": "Convert fields to static content",
                "desc": "Convert fields to static content after filling",
            },
        });
        setRequiredGroups((("input_path", "data", "location"),));
    }
}

#! Create form field request type with required input group
public class PdfCreateFormFieldRequestDataType inherits HashDataType {
    constructor() {
        addQoreFields(PdfInputFields);
        addQoreFields(PdfOutputFields);
        addQoreFields(PdfPasswordField);
        addQoreFields({
            "field": {
                "type": new Type("*hash<PdfFormFieldSpec>"),
                "display_name": "Field",
                "short_desc": "Single field specification",
                "desc": "Single form field specification",
            },
            "fields": {
                "type": new Type("*list<hash<PdfFormFieldSpec>>"),
                "display_name": "Fields",
                "short_desc": "Multiple field specifications",
                "desc": "List of form field specifications",
            },
        });
        setRequiredGroups((("input_path", "data", "location"),));
    }
}

#! Encrypt request type with required input group
public class PdfEncryptRequestDataType inherits HashDataType {
    constructor() {
        addQoreFields(PdfInputFields);
        addQoreFields(PdfOutputFields);
        addQoreFields({
            "input_password": {
                "type": StringOrNothingType,
                "display_name": "Input Password",
                "short_desc": "Password if input is already encrypted",
                "desc": "Optional password if the input document is already encrypted",
            },
            "owner_password": {
                "type": StringType,
                "display_name": "Owner Password",
                "short_desc": "Owner password for encryption",
                "desc": "The owner password provides full access to the document",
            },
            "user_password": {
                "type": StringOrNothingType,
                "display_name": "User Password",
                "short_desc": "User password for restricted access",
                "desc": "Optional user password for restricted access",
            },
            "algorithm": {
                "type": StringType,
                "display_name": "Algorithm",
                "short_desc": "Encryption algorithm",
                "desc": "Encryption algorithm",
                "default_value": PdfEncryptionAlgorithm::Aes256,
                "allowed_values": (
                    <AllowedValueInfo>{"value": PdfEncryptionAlgorithm::Aes256, "desc": "256-bit AES (recommended)"},
                    <AllowedValueInfo>{"value": PdfEncryptionAlgorithm::Aes128, "desc": "128-bit AES"},
                    <AllowedValueInfo>{"value": PdfEncryptionAlgorithm::Rc4_128, "desc": "128-bit RC4 (legacy)"},
                    <AllowedValueInfo>{"value": PdfEncryptionAlgorithm::Rc4_40, "desc": "40-bit RC4 (legacy)"},
                ),
            },
            "permissions": {
                "type": new Type("*hash<PdfPermissions>"),
                "display_name": "Permissions",
                "short_desc": "Document permissions",
                "desc": "Document permission restrictions for user password access",
            },
        });
        setRequiredGroups((("input_path", "data", "location"),));
    }
}

#! Decrypt request type with required input group
public class PdfDecryptRequestDataType inherits HashDataType {
    constructor() {
        addQoreFields(PdfInputFields);
        addQoreFields(PdfOutputFields);
        addQoreFields({
            "password": {
                "type": StringType,
                "display_name": "Password",
                "short_desc": "Owner password for decryption",
                "desc": "Owner password required for decryption",
            },
        });
        setRequiredGroups((("input_path", "data", "location"),));
    }
}

#! Get encryption info request type with required input group
public class PdfGetEncryptionInfoRequestDataType inherits HashDataType {
    constructor() {
        addQoreFields(PdfInputFields);
        addQoreFields(PdfPasswordField);
        setRequiredGroups((("input_path", "data", "location"),));
    }
}

#! Create digital signature field request type with required input group
public class PdfCreateDigitalSignatureFieldRequestDataType inherits HashDataType {
    constructor() {
        addQoreFields(PdfInputFields);
        addQoreFields(PdfOutputFields);
        addQoreFields(PdfPasswordField);
        addQoreFields({
            "field": {
                "type": new Type("hash<PdfDigitalSignatureFieldSpec>"),
                "display_name": "Field",
                "short_desc": "Signature field specification",
                "desc": "Digital signature field specification (name, page, position, etc.)",
            },
        });
        setRequiredGroups((("input_path", "data", "location"),));
    }
}

#! List signatures request type with required input group
public class PdfListSignaturesRequestDataType inherits HashDataType {
    constructor() {
        addQoreFields(PdfInputFields);
        addQoreFields(PdfPasswordField);
        setRequiredGroups((("input_path", "data", "location"),));
    }
}

#! Render page request type with required input group
public class PdfRenderPageRequestDataType inherits HashDataType {
    constructor() {
        addQoreFields(PdfInputFields);
        addQoreFields({
            "page_index": {
                "type": IntType,
                "display_name": "Page Index",
                "short_desc": "Page index (zero-based)",
                "desc": "Zero-based index of the page to render",
            },
            "dpi": {
                "type": IntType,
                "display_name": "DPI",
                "short_desc": "DPI resolution",
                "desc": "Resolution in dots per inch",
                "default_value": 150,
            },
            "output_path": {
                "type": StringOrNothingType,
                "display_name": "Output File Path",
                "short_desc": "Path to write raw BGRA data",
                "desc": "Optional file path to write the raw BGRA pixel data to",
            },
        });
        setRequiredGroups((("input_path", "data", "location"),));
    }
}

#! Extract text request type with required input group
public class PdfExtractTextRequestDataType inherits HashDataType {
    constructor() {
        addQoreFields(PdfInputFields);
        addQoreFields({
            "page_index": {
                "type": IntType,
                "display_name": "Page Index",
                "short_desc": "Page index (zero-based)",
                "desc": "Zero-based index of the page to extract text from",
            },
        });
        setRequiredGroups((("input_path", "data", "location"),));
    }
}

#! Create document request type
public class PdfCreateDocumentRequestDataType inherits HashDataType {
    constructor() {
        addQoreFields(PdfOutputFields - "overwrite");
        addQoreFields({
            "page_count": {
                "type": IntOrNothingType,
                "display_name": "Page Count",
                "short_desc": "Number of blank pages",
                "desc": "Number of blank pages to create (used if `pages` is not specified)",
            },
            "pages": {
                "type": new Type("*list<hash<PdfCreatePageSpec>>"),
                "display_name": "Pages",
                "short_desc": "Page specifications",
                "desc": "Detailed page specifications (blank or text pages with optional dimensions)",
            },
            "metadata": {
                "type": new Type("*hash<Qore::Pdf::PdfMetadata>"),
                "display_name": "Metadata",
                "short_desc": "Document metadata",
                "desc": "Optional document metadata (title, author, etc.)",
            },
            "font_options": {
                "type": new Type("*hash<Qore::Pdf::PdfFontOptions>"),
                "display_name": "Font Options",
                "short_desc": "Font embedding options",
                "desc": "Optional font embedding and subsetting options",
            },
        });
    }
}
}
