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
    string output_path;

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
    string output_path;

    #! Number of pages created
    int page_count;

    #! Output file size in bytes
    int size;
}

#! Request type for reading PDF document info
public hashdecl PdfDocumentInfoRequest {
    #! Input file path
    string input_path;

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
    string input_path;

    #! Metadata fields to set
    hash<Qore::Pdf::PdfMetadata> metadata;

    #! Output file path (optional if overwrite is true)
    *string output_path;

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
    string output_path;

    #! Number of pages
    int page_count;

    #! Warnings encountered while processing the document
    *list<string> warnings;
}

#! Request type for merging documents
public hashdecl PdfMergeDocumentRequest {
    #! Input file paths
    list<string> inputs;

    #! Output file path
    string output_path;

    #! Optional password for input files
    *string password;
}

#! Response type for merging documents
public hashdecl PdfMergeDocumentResponse {
    #! True if successful
    bool success;

    #! Output file path
    string output_path;

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
    string input_path;

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
    string input_path;

    #! Output file path (optional if overwrite is true)
    *string output_path;

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
    string output_path;

    #! Number of pages
    int page_count;

    #! Warnings encountered while processing the document
    *list<string> warnings;
}

#! Request type for rendering a page
public hashdecl PdfRenderPageRequest {
    #! Input file path
    string input_path;

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
    string input_path;

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
    string input_path;

    #! Output file path (optional if overwrite is true)
    *string output_path;

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
    string output_path;

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
    string input_path;

    #! Output file path (optional if overwrite is true)
    *string output_path;

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
    string output_path;

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
    string input_path;

    #! Output file path (optional if overwrite is true)
    *string output_path;

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
    string output_path;

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
    string input_path;

    #! Output file path (optional if overwrite is true)
    *string output_path;

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
    string output_path;

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
    string input_path;

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
    string input_path;

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
    string input_path;

    #! Output file path (optional if overwrite is true)
    *string output_path;

    #! Overwrite the input file if true
    *bool overwrite;

    #! Optional password for encrypted PDFs
    *string password;

    #! Field name to value mapping
    hash<auto> data;

    #! Convert fields to static content after filling
    *bool flatten;
}

#! Response type for filling form fields
public hashdecl PdfFillFormResponse {
    #! True if successful
    bool success;

    #! Output file path
    string output_path;

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
    string input_path;

    #! Output file path (optional if overwrite is true)
    *string output_path;

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
    string output_path;

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
    #! Input file path (required)
    string input_path;

    #! Output file path (optional if overwrite is true)
    *string output_path;

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
    string output_path;

    #! Algorithm used
    string algorithm;

    #! Output file size in bytes
    int size;
}

#! Request type for decrypting a PDF
public hashdecl PdfDecryptRequest {
    #! Input file path
    string input_path;

    #! Output file path (optional if overwrite is true)
    *string output_path;

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
    string output_path;

    #! Output file size in bytes
    int size;
}

#! Request type for getting encryption info
public hashdecl PdfGetEncryptionInfoRequest {
    #! Input file path
    string input_path;

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
    string input_path;

    #! Output file path (optional if overwrite is true)
    *string output_path;

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
    string output_path;

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
    #! Input file path (required)
    string input_path;

    #! Output file path (optional if overwrite is true)
    *string output_path;

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
    string output_path;

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
    string input_path;

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
}
