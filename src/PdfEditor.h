/* -*- mode: c++; indent-tabs-mode: nil -*- */
/*
    Qore pdf module

    Copyright (C) 2026 Qore Technologies, s.r.o.

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

#ifndef QORE_PDF_EDITOR_H
#define QORE_PDF_EDITOR_H

#include <qore/Qore.h>
#include <podofo/podofo.h>

#include <string>
#include <memory>

//! PDF Editor class for modifying existing PDF documents
/**
    This class uses PoDoFo's PdfMemDocument to load existing PDFs and draw
    images and text on them. It supports:
    - Loading PDFs from files or binary data
    - Drawing images (PNG, JPEG) with positioning, scaling, rotation, opacity
    - Drawing styled text with fonts, colors, and alignment
    - Coordinate transformation (top-left origin to PDF's bottom-left origin)
    - Saving to file or memory
*/
class QorePdfEditor : public AbstractPrivateData {
public:
    //! Create an editor from an existing PDF file
    /** @param path path to the PDF file
        @param password optional password for encrypted PDFs
        @param xsink exception sink for error handling
    */
    QorePdfEditor(const std::string& path, const std::string& password, ExceptionSink* xsink);

    //! Create an editor from binary PDF data
    /** @param data binary PDF data
        @param password optional password for encrypted PDFs
        @param xsink exception sink for error handling
    */
    QorePdfEditor(const BinaryNode* data, const std::string& password, ExceptionSink* xsink);

    //! Returns the number of pages in the document
    int pageCount() const;

    //! Returns page dimensions for the specified page
    /** @param pageIndex zero-based page index
        @param xsink exception sink for error handling
        @return hash with width and height in points
    */
    QoreHashNode* getPageDimensions(int pageIndex, ExceptionSink* xsink);

    //! Draw an image from a file path onto a page
    /** @param pageIndex zero-based page index
        @param imagePath path to image file (PNG, JPEG)
        @param x x coordinate in points (PDF coordinate system)
        @param y y coordinate in points (PDF coordinate system)
        @param width target width in points (0 = auto)
        @param height target height in points (0 = auto)
        @param rotation rotation in degrees (0, 90, 180, 270)
        @param opacity opacity value 0.0-1.0
        @param xsink exception sink for error handling
    */
    void drawImage(int pageIndex, const std::string& imagePath,
                   double x, double y, double width, double height,
                   double rotation, double opacity, ExceptionSink* xsink);

    //! Draw an image from binary data onto a page
    /** @param pageIndex zero-based page index
        @param imageData binary image data (PNG, JPEG)
        @param x x coordinate in points (PDF coordinate system)
        @param y y coordinate in points (PDF coordinate system)
        @param width target width in points (0 = auto)
        @param height target height in points (0 = auto)
        @param rotation rotation in degrees (0, 90, 180, 270)
        @param opacity opacity value 0.0-1.0
        @param xsink exception sink for error handling
    */
    void drawImageFromData(int pageIndex, const BinaryNode* imageData,
                   double x, double y, double width, double height,
                   double rotation, double opacity, ExceptionSink* xsink);

    //! Draw styled text onto a page
    /** @param pageIndex zero-based page index
        @param text text string to draw
        @param x x coordinate in points (PDF coordinate system)
        @param y y coordinate in points (PDF coordinate system)
        @param style hash with style options (font, color, align, etc.)
        @param rotation rotation in degrees
        @param opacity opacity value 0.0-1.0
        @param xsink exception sink for error handling
    */
    void drawText(int pageIndex, const std::string& text,
                  double x, double y, const QoreHashNode* style,
                  double rotation, double opacity, ExceptionSink* xsink);

    //! Save the document to a file
    /** @param path output file path
        @param xsink exception sink for error handling
    */
    void save(const std::string& path, ExceptionSink* xsink);

    //! Save the document to memory
    /** @param xsink exception sink for error handling
        @return binary PDF data
    */
    BinaryNode* saveToMemory(ExceptionSink* xsink);

    //! Set font options for text drawing
    /** @param opts hash with font options (embed, subset, prefer_non_cid)
        @param xsink exception sink for error handling
    */
    void setFontOptions(const QoreHashNode* opts, ExceptionSink* xsink);

    //! Get image dimensions from a file
    /** @param path path to image file
        @param xsink exception sink for error handling
        @return hash with width and height in pixels
    */
    static QoreHashNode* getImageDimensions(const std::string& path, ExceptionSink* xsink);

    //! Get image dimensions from binary data
    /** @param data binary image data
        @param xsink exception sink for error handling
        @return hash with width and height in pixels
    */
    static QoreHashNode* getImageDimensionsFromData(const BinaryNode* data, ExceptionSink* xsink);

private:
    std::unique_ptr<PoDoFo::PdfMemDocument> doc;
    bool embed_fonts = true;
    bool subset_fonts = true;
    bool prefer_non_cid = false;

    //! Parse color from a hash specification
    /** @param colorHash hash with color spec (hex, r/g/b, gray, name)
        @param xsink exception sink for error handling
        @return PoDoFo color object
    */
    PoDoFo::PdfColor parseColor(const QoreHashNode* colorHash, ExceptionSink* xsink);

    //! Get a font for text drawing
    /** @param fontSpec hash with font specification
        @param xsink exception sink for error handling
        @return reference to font object
    */
    PoDoFo::PdfFont& getFont(const QoreHashNode* fontSpec, ExceptionSink* xsink);

    //! Apply graphics state for opacity
    /** @param painter the painter object
        @param page the page object
        @param opacity opacity value 0.0-1.0
    */
    void applyOpacity(PoDoFo::PdfPainter& painter, PoDoFo::PdfPage& page, double opacity);

    //! Internal image drawing implementation
    void drawImageInternal(int pageIndex, PoDoFo::PdfImage& image,
                          double x, double y, double width, double height,
                          double rotation, double opacity, ExceptionSink* xsink);

    //! Wrap text to fit within a maximum width
    /** @param text the text to wrap
        @param font the font to use for measuring
        @param fontSize the font size
        @param state the text state for character spacing
        @param maxWidth the maximum width for each line
        @return vector of lines
    */
    std::vector<std::string> wrapText(const std::string& text, PoDoFo::PdfFont& font,
                                      double fontSize, const PoDoFo::PdfTextState& state,
                                      double maxWidth);

public:
    // ========== Form Field Operations ==========

    //! Returns a list of all form fields in the document
    /** @param xsink exception sink for error handling
        @return list of hashes with field information
    */
    QoreListNode* getFormFields(ExceptionSink* xsink);

    //! Gets the value of a form field by name
    /** @param fieldName the field name (can be hierarchical like "form.field1")
        @param xsink exception sink for error handling
        @return the field value (string for text, bool for checkbox, int for combo index)
    */
    QoreValue getFormFieldValue(const std::string& fieldName, ExceptionSink* xsink);

    //! Sets the value of a form field by name
    /** @param fieldName the field name
        @param value the value to set
        @param xsink exception sink for error handling
    */
    void setFormFieldValue(const std::string& fieldName, QoreValue value, ExceptionSink* xsink);

    //! Creates a new form field
    /** @param fieldName field name
        @param fieldType field type: "text", "checkbox", "combo", "list", "button"
        @param pageIndex zero-based page index
        @param x x coordinate
        @param y y coordinate
        @param width field width
        @param height field height
        @param options optional field configuration
        @param xsink exception sink for error handling
    */
    void createFormField(const std::string& fieldName, const std::string& fieldType,
                         int pageIndex, double x, double y, double width, double height,
                         const QoreHashNode* options, ExceptionSink* xsink);

    //! Flattens form fields, converting them to static content
    /** @param xsink exception sink for error handling
    */
    void flattenFormFields(ExceptionSink* xsink);

    // ========== Encryption Operations ==========

    //! Sets encryption on the document
    /** @param userPassword the user password (empty for no user password)
        @param ownerPassword the owner password (required)
        @param permissions permission flags hash
        @param algorithm encryption algorithm: "rc4-40", "rc4-128", "aes-128", "aes-256"
        @param xsink exception sink for error handling
    */
    void setEncryption(const std::string& userPassword, const std::string& ownerPassword,
                       const QoreHashNode* permissions, const std::string& algorithm,
                       ExceptionSink* xsink);

    //! Removes encryption from the document
    /** @param xsink exception sink for error handling
    */
    void removeEncryption(ExceptionSink* xsink);

    //! Gets encryption information from a PDF file
    /** @param path path to PDF file
        @param password optional password to decrypt
        @param xsink exception sink for error handling
        @return hash with encryption information
    */
    static QoreHashNode* getEncryptionInfo(const std::string& path, const std::string& password,
                                           ExceptionSink* xsink);

    //! Returns whether the document is encrypted
    /** @return true if encrypted, false otherwise
    */
    bool isEncrypted() const;

    // ========== Digital Signature Operations ==========

    //! Creates a signature field (interactive form field for signing)
    /** @param fieldName field name
        @param pageIndex zero-based page index
        @param x x coordinate
        @param y y coordinate
        @param width field width
        @param height field height
        @param options optional field configuration (signer_name, reason, location)
        @param xsink exception sink for error handling
    */
    void createSignatureField(const std::string& fieldName, int pageIndex,
                              double x, double y, double width, double height,
                              const QoreHashNode* options, ExceptionSink* xsink);

    //! Signs the document using a certificate and private key
    /** @param fieldName the signature field name to sign
        @param certificate X.509 certificate data
        @param privateKey private key data
        @param keyPassword optional password for encrypted private key
        @param options optional signing options (reason, location, signer_name, hash_algorithm)
        @param xsink exception sink for error handling
    */
    void signDocument(const std::string& fieldName, const BinaryNode* certificate,
                      const BinaryNode* privateKey, const std::string& keyPassword,
                      const QoreHashNode* options, ExceptionSink* xsink);

    //! Returns a list of signature fields and their status
    /** @param xsink exception sink for error handling
        @return list of signature information hashes
    */
    QoreListNode* getSignatures(ExceptionSink* xsink);

private:
    //! Convert PoDoFo field type to string
    static std::string fieldTypeToString(PoDoFo::PdfFieldType type);

    //! Convert string to PoDoFo field type
    static PoDoFo::PdfFieldType stringToFieldType(const std::string& type);
};

#endif
