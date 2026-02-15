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

#include "PdfEditor.h"
#include "pdf-module.h"

#include <cmath>
#include <algorithm>
#include <cctype>
#include <map>

static void pdf_error(ExceptionSink* xsink, const char* msg) {
    xsink->raiseException("PDF-ERROR", msg);
}

static void pdf_error(ExceptionSink* xsink, const std::string& msg) {
    xsink->raiseException("PDF-ERROR", msg.c_str());
}

// Named colors mapping
static const std::map<std::string, std::tuple<double, double, double>> namedColors = {
    {"black", {0.0, 0.0, 0.0}},
    {"white", {1.0, 1.0, 1.0}},
    {"red", {1.0, 0.0, 0.0}},
    {"green", {0.0, 1.0, 0.0}},
    {"blue", {0.0, 0.0, 1.0}},
    {"yellow", {1.0, 1.0, 0.0}},
    {"cyan", {0.0, 1.0, 1.0}},
    {"magenta", {1.0, 0.0, 1.0}},
    {"gray", {0.5, 0.5, 0.5}},
    {"grey", {0.5, 0.5, 0.5}},
    {"lightgray", {0.75, 0.75, 0.75}},
    {"lightgrey", {0.75, 0.75, 0.75}},
    {"darkgray", {0.25, 0.25, 0.25}},
    {"darkgrey", {0.25, 0.25, 0.25}},
    {"orange", {1.0, 0.65, 0.0}},
    {"pink", {1.0, 0.75, 0.8}},
    {"purple", {0.5, 0.0, 0.5}},
    {"brown", {0.65, 0.16, 0.16}},
    {"navy", {0.0, 0.0, 0.5}},
    {"teal", {0.0, 0.5, 0.5}},
    {"olive", {0.5, 0.5, 0.0}},
    {"maroon", {0.5, 0.0, 0.0}},
};

// Helper to parse hex color
static bool parseHexColor(const std::string& hex, double& r, double& g, double& b) {
    std::string h = hex;
    // Remove leading #
    if (!h.empty() && h[0] == '#') {
        h = h.substr(1);
    }

    if (h.length() == 3) {
        // Short form #RGB
        r = std::stoi(h.substr(0, 1) + h.substr(0, 1), nullptr, 16) / 255.0;
        g = std::stoi(h.substr(1, 1) + h.substr(1, 1), nullptr, 16) / 255.0;
        b = std::stoi(h.substr(2, 1) + h.substr(2, 1), nullptr, 16) / 255.0;
        return true;
    } else if (h.length() == 6) {
        // Full form #RRGGBB
        r = std::stoi(h.substr(0, 2), nullptr, 16) / 255.0;
        g = std::stoi(h.substr(2, 2), nullptr, 16) / 255.0;
        b = std::stoi(h.substr(4, 2), nullptr, 16) / 255.0;
        return true;
    }
    return false;
}

QorePdfEditor::QorePdfEditor(const std::string& path, const std::string& password,
                             ExceptionSink* xsink) {
    QoreSandboxManagerHelper smh;
    if (smh && !smh->checkFilesystemAccess(path.c_str(), QSEC_READ, xsink)) {
        return;
    }
    if (qore_check_io_interrupt(xsink, "PDF editor load")) {
        return;
    }

    try {
        doc = std::make_unique<PoDoFo::PdfMemDocument>();
        if (password.empty()) {
            doc->Load(path);
        } else {
            doc->Load(path, password);
        }
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
    }
}

QorePdfEditor::QorePdfEditor(const BinaryNode* data, const std::string& password,
                             ExceptionSink* xsink) {
    if (!data || data->size() == 0) {
        pdf_error(xsink, "binary data is empty");
        return;
    }
    if (qore_check_io_interrupt(xsink, "PDF editor load from memory")) {
        return;
    }

    try {
        doc = std::make_unique<PoDoFo::PdfMemDocument>();
        PoDoFo::bufferview buffer(
            reinterpret_cast<const char*>(data->getPtr()),
            data->size()
        );
        if (password.empty()) {
            doc->LoadFromBuffer(buffer);
        } else {
            doc->LoadFromBuffer(buffer, password);
        }
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
    }
}

int QorePdfEditor::pageCount() const {
    if (!doc) {
        return 0;
    }
    return static_cast<int>(doc->GetPages().GetCount());
}

QoreHashNode* QorePdfEditor::getPageDimensions(int pageIndex, ExceptionSink* xsink) {
    if (!doc) {
        pdf_error(xsink, "document not loaded");
        return nullptr;
    }

    if (pageIndex < 0 || pageIndex >= pageCount()) {
        pdf_error(xsink, "page index out of range");
        return nullptr;
    }

    try {
        PoDoFo::PdfPage& page = doc->GetPages().GetPageAt(pageIndex);
        PoDoFo::Rect rect = page.GetRect();

        ReferenceHolder<QoreHashNode> result(new QoreHashNode(autoTypeInfo), xsink);
        result->setKeyValue("width", rect.Width, xsink);
        result->setKeyValue("height", rect.Height, xsink);
        return result.release();
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
        return nullptr;
    }
}

PoDoFo::PdfColor QorePdfEditor::parseColor(const QoreHashNode* colorHash, ExceptionSink* xsink) {
    if (!colorHash) {
        return PoDoFo::PdfColor(0.0, 0.0, 0.0); // Default black
    }

    // Check for hex color
    QoreValue val = colorHash->getKeyValue("hex");
    if (val.getType() == NT_STRING) {
        std::string hex = val.get<const QoreStringNode>()->c_str();
        double r, g, b;
        if (parseHexColor(hex, r, g, b)) {
            return PoDoFo::PdfColor(r, g, b);
        }
        pdf_error(xsink, "invalid hex color format");
        return PoDoFo::PdfColor(0.0, 0.0, 0.0);
    }

    // Check for RGB values
    QoreValue rv = colorHash->getKeyValue("r");
    QoreValue gv = colorHash->getKeyValue("g");
    QoreValue bv = colorHash->getKeyValue("b");
    if (rv.getType() == NT_FLOAT || rv.getType() == NT_INT) {
        double r = rv.getAsFloat();
        double g = gv.getAsFloat();
        double b = bv.getAsFloat();
        return PoDoFo::PdfColor(
            std::max(0.0, std::min(1.0, r)),
            std::max(0.0, std::min(1.0, g)),
            std::max(0.0, std::min(1.0, b))
        );
    }

    // Check for grayscale
    val = colorHash->getKeyValue("gray");
    if (val.getType() == NT_FLOAT || val.getType() == NT_INT) {
        double gray = std::max(0.0, std::min(1.0, val.getAsFloat()));
        return PoDoFo::PdfColor(gray);
    }

    // Check for named color
    val = colorHash->getKeyValue("name");
    if (val.getType() == NT_STRING) {
        std::string name = val.get<const QoreStringNode>()->c_str();
        std::transform(name.begin(), name.end(), name.begin(), ::tolower);

        auto it = namedColors.find(name);
        if (it != namedColors.end()) {
            return PoDoFo::PdfColor(
                std::get<0>(it->second),
                std::get<1>(it->second),
                std::get<2>(it->second)
            );
        }
        pdf_error(xsink, "unknown color name: " + name);
    }

    return PoDoFo::PdfColor(0.0, 0.0, 0.0); // Default black
}

PoDoFo::PdfFont& QorePdfEditor::getFont(const QoreHashNode* fontSpec, ExceptionSink* xsink) {
    PoDoFo::PdfFontCreateParams params;
    if (!embed_fonts) {
        params.Flags = params.Flags | PoDoFo::PdfFontCreateFlags::DontEmbed;
    }
    if (!subset_fonts) {
        params.Flags = params.Flags | PoDoFo::PdfFontCreateFlags::DontSubset;
    }
    if (prefer_non_cid) {
        params.Flags = params.Flags | PoDoFo::PdfFontCreateFlags::PreferNonCID;
    }

    // Default font
    PoDoFo::PdfStandard14FontType fontType = PoDoFo::PdfStandard14FontType::Helvetica;

    if (!fontSpec) {
        return doc->GetFonts().GetStandard14Font(fontType, params);
    }

    // Check for custom font path
    QoreValue val = fontSpec->getKeyValue("font_path");
    if (val.getType() == NT_STRING) {
        std::string fontPath = val.get<const QoreStringNode>()->c_str();
        try {
            return doc->GetFonts().GetOrCreateFont(fontPath, params);
        } catch (const std::exception& e) {
            pdf_error(xsink, std::string("failed to load font: ") + e.what());
            return doc->GetFonts().GetStandard14Font(fontType, params);
        }
    }

    // Check for font family
    val = fontSpec->getKeyValue("family");
    if (val.getType() == NT_STRING) {
        std::string family = val.get<const QoreStringNode>()->c_str();
        std::transform(family.begin(), family.end(), family.begin(), ::tolower);

        bool bold = false;
        bool italic = false;

        QoreValue boldVal = fontSpec->getKeyValue("bold");
        if (boldVal.getType() == NT_BOOLEAN) {
            bold = boldVal.getAsBool();
        }
        QoreValue italicVal = fontSpec->getKeyValue("italic");
        if (italicVal.getType() == NT_BOOLEAN) {
            italic = italicVal.getAsBool();
        }

        // Map to Standard14 fonts
        if (family == "helvetica" || family == "arial" || family == "sans-serif") {
            if (bold && italic) {
                fontType = PoDoFo::PdfStandard14FontType::HelveticaBoldOblique;
            } else if (bold) {
                fontType = PoDoFo::PdfStandard14FontType::HelveticaBold;
            } else if (italic) {
                fontType = PoDoFo::PdfStandard14FontType::HelveticaOblique;
            } else {
                fontType = PoDoFo::PdfStandard14FontType::Helvetica;
            }
        } else if (family == "times" || family == "times-roman" || family == "serif") {
            if (bold && italic) {
                fontType = PoDoFo::PdfStandard14FontType::TimesBoldItalic;
            } else if (bold) {
                fontType = PoDoFo::PdfStandard14FontType::TimesBold;
            } else if (italic) {
                fontType = PoDoFo::PdfStandard14FontType::TimesItalic;
            } else {
                fontType = PoDoFo::PdfStandard14FontType::TimesRoman;
            }
        } else if (family == "courier" || family == "monospace") {
            if (bold && italic) {
                fontType = PoDoFo::PdfStandard14FontType::CourierBoldOblique;
            } else if (bold) {
                fontType = PoDoFo::PdfStandard14FontType::CourierBold;
            } else if (italic) {
                fontType = PoDoFo::PdfStandard14FontType::CourierOblique;
            } else {
                fontType = PoDoFo::PdfStandard14FontType::Courier;
            }
        } else if (family == "symbol") {
            fontType = PoDoFo::PdfStandard14FontType::Symbol;
        } else if (family == "zapfdingbats" || family == "dingbats") {
            fontType = PoDoFo::PdfStandard14FontType::ZapfDingbats;
        }
    }

    return doc->GetFonts().GetStandard14Font(fontType, params);
}

void QorePdfEditor::applyOpacity(PoDoFo::PdfPainter& painter, PoDoFo::PdfPage& page,
                                 double opacity) {
    if (opacity >= 1.0) {
        return; // No transparency needed
    }

    // Clamp opacity
    opacity = std::max(0.0, std::min(1.0, opacity));

    // Create an extended graphics state for transparency
    auto definition = std::make_shared<PoDoFo::PdfExtGStateDefinition>();
    definition->StrokingAlpha = opacity;
    definition->NonStrokingAlpha = opacity;

    auto extGState = doc->CreateExtGState(definition);
    painter.GraphicsState.SetExtGState(*extGState);
}

void QorePdfEditor::drawImageInternal(int pageIndex, PoDoFo::PdfImage& image,
                                      double x, double y, double width, double height,
                                      double rotation, double opacity, ExceptionSink* xsink) {
    if (!doc) {
        pdf_error(xsink, "document not loaded");
        return;
    }

    if (pageIndex < 0 || pageIndex >= pageCount()) {
        pdf_error(xsink, "page index out of range");
        return;
    }

    try {
        PoDoFo::PdfPage& page = doc->GetPages().GetPageAt(pageIndex);
        PoDoFo::PdfPainter painter;
        painter.SetCanvas(page);

        // Get image dimensions
        double imgWidth = image.GetWidth();
        double imgHeight = image.GetHeight();

        // Calculate target dimensions
        if (width <= 0 && height <= 0) {
            // Use original image size (pixels to points, assuming 72 DPI)
            width = imgWidth;
            height = imgHeight;
        } else if (width <= 0) {
            // Calculate width from height preserving aspect ratio
            width = (height / imgHeight) * imgWidth;
        } else if (height <= 0) {
            // Calculate height from width preserving aspect ratio
            height = (width / imgWidth) * imgHeight;
        }

        // Apply opacity
        applyOpacity(painter, page, opacity);

        // Handle rotation
        if (rotation != 0.0) {
            // Save graphics state
            painter.Save();

            // Move to center of image position
            double cx = x + width / 2.0;
            double cy = y + height / 2.0;

            // Convert rotation to radians
            double rad = rotation * M_PI / 180.0;
            double cosA = std::cos(rad);
            double sinA = std::sin(rad);

            // Apply rotation matrix around center
            PoDoFo::Matrix matrix(cosA, sinA, -sinA, cosA, cx - cx * cosA + cy * sinA,
                                  cy - cx * sinA - cy * cosA);
            painter.GraphicsState.ConcatenateTransformationMatrix(matrix);

            // Draw image
            painter.DrawImage(image, x, y, width / imgWidth, height / imgHeight);

            // Restore graphics state
            painter.Restore();
        } else {
            // Draw image without rotation
            painter.DrawImage(image, x, y, width / imgWidth, height / imgHeight);
        }

        painter.FinishDrawing();
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
    }
}

void QorePdfEditor::drawImage(int pageIndex, const std::string& imagePath,
                              double x, double y, double width, double height,
                              double rotation, double opacity, ExceptionSink* xsink) {
    if (!doc) {
        pdf_error(xsink, "document not loaded");
        return;
    }

    QoreSandboxManagerHelper smh;
    if (smh && !smh->checkFilesystemAccess(imagePath.c_str(), QSEC_READ, xsink)) {
        return;
    }
    if (qore_check_io_interrupt(xsink, "PDF draw image")) {
        return;
    }

    try {
        auto image = doc->CreateImage();
        image->Load(imagePath);
        drawImageInternal(pageIndex, *image, x, y, width, height, rotation, opacity, xsink);
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
    }
}

void QorePdfEditor::drawImageFromData(int pageIndex, const BinaryNode* imageData,
                                      double x, double y, double width, double height,
                                      double rotation, double opacity, ExceptionSink* xsink) {
    if (!doc) {
        pdf_error(xsink, "document not loaded");
        return;
    }

    if (!imageData || imageData->size() == 0) {
        pdf_error(xsink, "image data is empty");
        return;
    }

    try {
        auto image = doc->CreateImage();
        PoDoFo::bufferview buffer(
            reinterpret_cast<const char*>(imageData->getPtr()),
            imageData->size()
        );
        image->LoadFromBuffer(buffer);
        drawImageInternal(pageIndex, *image, x, y, width, height, rotation, opacity, xsink);
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
    }
}

void QorePdfEditor::drawText(int pageIndex, const std::string& text,
                             double x, double y, const QoreHashNode* style,
                             double rotation, double opacity, ExceptionSink* xsink) {
    if (!doc) {
        pdf_error(xsink, "document not loaded");
        return;
    }

    if (pageIndex < 0 || pageIndex >= pageCount()) {
        pdf_error(xsink, "page index out of range");
        return;
    }

    if (text.empty()) {
        return; // Nothing to draw
    }

    try {
        PoDoFo::PdfPage& page = doc->GetPages().GetPageAt(pageIndex);
        PoDoFo::PdfPainter painter;
        painter.SetCanvas(page);

        // Get font specification from style
        const QoreHashNode* fontSpec = nullptr;
        double fontSize = 12.0;

        if (style) {
            QoreValue fontVal = style->getKeyValue("font");
            if (fontVal.getType() == NT_HASH) {
                fontSpec = fontVal.get<const QoreHashNode>();
                QoreValue sizeVal = fontSpec->getKeyValue("size");
                if (sizeVal.getType() == NT_FLOAT || sizeVal.getType() == NT_INT) {
                    fontSize = sizeVal.getAsFloat();
                }
            }
        }

        PoDoFo::PdfFont& font = getFont(fontSpec, xsink);
        if (*xsink) {
            return;
        }

        painter.TextState.SetFont(font, fontSize);

        // Set text color
        if (style) {
            QoreValue colorVal = style->getKeyValue("color");
            if (colorVal.getType() == NT_HASH) {
                PoDoFo::PdfColor color = parseColor(colorVal.get<const QoreHashNode>(), xsink);
                if (!*xsink) {
                    painter.GraphicsState.SetNonStrokingColor(color);
                }
            }

            // Check for stroke settings
            QoreValue renderModeVal = style->getKeyValue("render_mode");
            if (renderModeVal.getType() == NT_STRING) {
                std::string mode = renderModeVal.get<const QoreStringNode>()->c_str();
                if (mode == "stroke") {
                    painter.TextState.SetRenderingMode(PoDoFo::PdfTextRenderingMode::Stroke);
                } else if (mode == "fill_stroke") {
                    painter.TextState.SetRenderingMode(PoDoFo::PdfTextRenderingMode::FillStroke);
                }
            }

            QoreValue strokeColorVal = style->getKeyValue("stroke_color");
            if (strokeColorVal.getType() == NT_HASH) {
                PoDoFo::PdfColor strokeColor = parseColor(strokeColorVal.get<const QoreHashNode>(), xsink);
                if (!*xsink) {
                    painter.GraphicsState.SetStrokingColor(strokeColor);
                }
            }

            QoreValue strokeWidthVal = style->getKeyValue("stroke_width");
            if (strokeWidthVal.getType() == NT_FLOAT || strokeWidthVal.getType() == NT_INT) {
                painter.GraphicsState.SetLineWidth(strokeWidthVal.getAsFloat());
            }

            // Character spacing
            QoreValue charSpacingVal = style->getKeyValue("char_spacing");
            if (charSpacingVal.getType() == NT_FLOAT || charSpacingVal.getType() == NT_INT) {
                painter.TextState.SetCharSpacing(charSpacingVal.getAsFloat());
            }
        }

        // Apply opacity
        applyOpacity(painter, page, opacity);

        // Get text wrapping and line height parameters
        double maxWidth = 0.0;
        double maxHeight = 0.0;
        double lineHeight = 1.2;  // Default line height multiplier
        if (style) {
            QoreValue maxWidthVal = style->getKeyValue("max_width");
            if (maxWidthVal.getType() == NT_FLOAT || maxWidthVal.getType() == NT_INT) {
                maxWidth = maxWidthVal.getAsFloat();
            }
            QoreValue maxHeightVal = style->getKeyValue("max_height");
            if (maxHeightVal.getType() == NT_FLOAT || maxHeightVal.getType() == NT_INT) {
                maxHeight = maxHeightVal.getAsFloat();
            }
            QoreValue lineHeightVal = style->getKeyValue("line_height");
            if (lineHeightVal.getType() == NT_FLOAT || lineHeightVal.getType() == NT_INT) {
                lineHeight = lineHeightVal.getAsFloat();
            }
        }

        // Calculate text metrics
        double ascent = font.GetMetrics().GetAscent() * fontSize / 1000.0;
        double descent = font.GetMetrics().GetDescent() * fontSize / 1000.0;
        double lineSpacing = fontSize * lineHeight;

        // Get decoration flags
        bool underline = false;
        bool strikethrough = false;
        std::string align = "left";
        std::string valign = "top";
        if (style) {
            QoreValue underlineVal = style->getKeyValue("underline");
            if (underlineVal.getType() == NT_BOOLEAN) {
                underline = underlineVal.getAsBool();
            }
            QoreValue strikeVal = style->getKeyValue("strikethrough");
            if (strikeVal.getType() == NT_BOOLEAN) {
                strikethrough = strikeVal.getAsBool();
            }
            QoreValue alignVal = style->getKeyValue("align");
            if (alignVal.getType() == NT_STRING) {
                align = alignVal.get<const QoreStringNode>()->c_str();
            }
            QoreValue valignVal = style->getKeyValue("valign");
            if (valignVal.getType() == NT_STRING) {
                valign = valignVal.get<const QoreStringNode>()->c_str();
            }
        }

        // Wrap text if max_width is specified
        std::vector<std::string> lines;
        if (maxWidth > 0) {
            lines = wrapText(text, font, fontSize, painter.TextState, maxWidth);
        } else {
            lines.push_back(text);
        }

        // Calculate total height for vertical alignment
        double totalHeight = lines.size() * lineSpacing;
        if (!lines.empty()) {
            totalHeight -= (lineSpacing - fontSize); // Last line doesn't need full spacing
        }

        // Apply vertical alignment offset
        double startY = y;
        if (valign == "middle") {
            startY = y + totalHeight / 2.0;
        } else if (valign == "bottom") {
            startY = y + totalHeight;
        }

        // Handle rotation
        if (rotation != 0.0) {
            painter.Save();

            // Convert rotation to radians
            double rad = rotation * M_PI / 180.0;
            double cosA = std::cos(rad);
            double sinA = std::sin(rad);

            // Apply rotation matrix around text position
            PoDoFo::Matrix matrix(cosA, sinA, -sinA, cosA, x - x * cosA + y * sinA,
                                  y - x * sinA - y * cosA);
            painter.GraphicsState.ConcatenateTransformationMatrix(matrix);
        }

        // Draw each line
        double currentY = startY;
        double heightUsed = 0.0;
        for (const auto& line : lines) {
            // Check max_height constraint
            if (maxHeight > 0 && heightUsed + fontSize > maxHeight) {
                break;
            }

            double lineWidth = font.GetStringLength(line, painter.TextState);

            // Apply horizontal alignment
            double drawX = x;
            if (align == "center") {
                drawX = x - lineWidth / 2.0;
            } else if (align == "right") {
                drawX = x - lineWidth;
            }

            painter.DrawText(line, drawX, currentY);

            // Draw underline if requested
            if (underline) {
                double lineY = currentY + descent - fontSize * 0.1;
                painter.DrawLine(drawX, lineY, drawX + lineWidth, lineY);
            }

            // Draw strikethrough if requested
            if (strikethrough) {
                double lineY = currentY + ascent * 0.35;
                painter.DrawLine(drawX, lineY, drawX + lineWidth, lineY);
            }

            currentY -= lineSpacing;  // PDF coordinates go upward
            heightUsed += lineSpacing;
        }

        if (rotation != 0.0) {
            painter.Restore();
        }

        painter.FinishDrawing();
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
    }
}

void QorePdfEditor::save(const std::string& path, ExceptionSink* xsink) {
    if (!doc) {
        pdf_error(xsink, "document not loaded");
        return;
    }

    QoreSandboxManagerHelper smh;
    if (smh && !smh->checkFilesystemAccess(path.c_str(), QSEC_WRITE | QSEC_CREATE, xsink)) {
        return;
    }
    if (qore_check_io_interrupt(xsink, "PDF editor save")) {
        return;
    }

    try {
        doc->Save(path);
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
    }
}

BinaryNode* QorePdfEditor::saveToMemory(ExceptionSink* xsink) {
    if (!doc) {
        pdf_error(xsink, "document not loaded");
        return nullptr;
    }

    try {
        PoDoFo::charbuff buffer;
        PoDoFo::BufferStreamDevice device(buffer);
        doc->Save(device);

        SimpleRefHolder<BinaryNode> result(new BinaryNode);
        result->append(buffer.data(), buffer.size());
        return result.release();
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
        return nullptr;
    }
}

void QorePdfEditor::setFontOptions(const QoreHashNode* opts, ExceptionSink* xsink) {
    if (!opts) {
        return;
    }

    QoreValue val = opts->getKeyValue("embed");
    if (val.getType() == NT_BOOLEAN) {
        embed_fonts = val.getAsBool();
    }

    val = opts->getKeyValue("subset");
    if (val.getType() == NT_BOOLEAN) {
        subset_fonts = val.getAsBool();
    }

    val = opts->getKeyValue("prefer_non_cid");
    if (val.getType() == NT_BOOLEAN) {
        prefer_non_cid = val.getAsBool();
    }
}

QoreHashNode* QorePdfEditor::getImageDimensions(const std::string& path, ExceptionSink* xsink) {
    QoreSandboxManagerHelper smh;
    if (smh && !smh->checkFilesystemAccess(path.c_str(), QSEC_READ, xsink)) {
        return nullptr;
    }

    try {
        // Create a temporary document to load the image
        PoDoFo::PdfMemDocument tempDoc;
        auto image = tempDoc.CreateImage();
        image->Load(path);

        ReferenceHolder<QoreHashNode> result(new QoreHashNode(autoTypeInfo), xsink);
        result->setKeyValue("width", static_cast<int64>(image->GetWidth()), xsink);
        result->setKeyValue("height", static_cast<int64>(image->GetHeight()), xsink);
        return result.release();
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
        return nullptr;
    }
}

QoreHashNode* QorePdfEditor::getImageDimensionsFromData(const BinaryNode* data,
                                                        ExceptionSink* xsink) {
    if (!data || data->size() == 0) {
        pdf_error(xsink, "image data is empty");
        return nullptr;
    }

    try {
        PoDoFo::PdfMemDocument tempDoc;
        auto image = tempDoc.CreateImage();
        PoDoFo::bufferview buffer(
            reinterpret_cast<const char*>(data->getPtr()),
            data->size()
        );
        image->LoadFromBuffer(buffer);

        ReferenceHolder<QoreHashNode> result(new QoreHashNode(autoTypeInfo), xsink);
        result->setKeyValue("width", static_cast<int64>(image->GetWidth()), xsink);
        result->setKeyValue("height", static_cast<int64>(image->GetHeight()), xsink);
        return result.release();
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
        return nullptr;
    }
}

std::vector<std::string> QorePdfEditor::wrapText(const std::string& text, PoDoFo::PdfFont& font,
                                                  double fontSize, const PoDoFo::PdfTextState& state,
                                                  double maxWidth) {
    std::vector<std::string> lines;

    if (text.empty() || maxWidth <= 0) {
        lines.push_back(text);
        return lines;
    }

    std::string currentLine;
    std::string currentWord;

    for (size_t i = 0; i <= text.size(); ++i) {
        char c = (i < text.size()) ? text[i] : '\0';

        if (c == ' ' || c == '\n' || c == '\0') {
            // End of word
            if (!currentWord.empty()) {
                std::string testLine = currentLine.empty() ? currentWord : (currentLine + " " + currentWord);
                double testWidth = font.GetStringLength(testLine, state);

                if (testWidth <= maxWidth) {
                    currentLine = testLine;
                } else {
                    // Word doesn't fit, start new line
                    if (!currentLine.empty()) {
                        lines.push_back(currentLine);
                    }
                    // Check if word itself is too long
                    double wordWidth = font.GetStringLength(currentWord, state);
                    if (wordWidth > maxWidth) {
                        // Break word character by character
                        std::string partialWord;
                        for (char wc : currentWord) {
                            std::string testPart = partialWord + wc;
                            if (font.GetStringLength(testPart, state) > maxWidth && !partialWord.empty()) {
                                lines.push_back(partialWord);
                                partialWord = std::string(1, wc);
                            } else {
                                partialWord = testPart;
                            }
                        }
                        currentLine = partialWord;
                    } else {
                        currentLine = currentWord;
                    }
                }
                currentWord.clear();
            }

            // Handle explicit newlines
            if (c == '\n') {
                lines.push_back(currentLine);
                currentLine.clear();
            }
        } else {
            currentWord += c;
        }
    }

    // Add remaining text
    if (!currentLine.empty()) {
        lines.push_back(currentLine);
    }

    return lines;
}

// ========== Form Field Operations ==========

std::string QorePdfEditor::fieldTypeToString(PoDoFo::PdfFieldType type) {
    switch (type) {
        case PoDoFo::PdfFieldType::TextBox:
            return "text";
        case PoDoFo::PdfFieldType::CheckBox:
            return "checkbox";
        case PoDoFo::PdfFieldType::RadioButton:
            return "radio";
        case PoDoFo::PdfFieldType::ComboBox:
            return "combo";
        case PoDoFo::PdfFieldType::ListBox:
            return "list";
        case PoDoFo::PdfFieldType::PushButton:
            return "button";
        case PoDoFo::PdfFieldType::Signature:
            return "signature";
        default:
            return "unknown";
    }
}

PoDoFo::PdfFieldType QorePdfEditor::stringToFieldType(const std::string& type) {
    if (type == "text") {
        return PoDoFo::PdfFieldType::TextBox;
    } else if (type == "checkbox") {
        return PoDoFo::PdfFieldType::CheckBox;
    } else if (type == "radio") {
        return PoDoFo::PdfFieldType::RadioButton;
    } else if (type == "combo") {
        return PoDoFo::PdfFieldType::ComboBox;
    } else if (type == "list") {
        return PoDoFo::PdfFieldType::ListBox;
    } else if (type == "button") {
        return PoDoFo::PdfFieldType::PushButton;
    } else if (type == "signature") {
        return PoDoFo::PdfFieldType::Signature;
    }
    return PoDoFo::PdfFieldType::Unknown;
}

QoreListNode* QorePdfEditor::getFormFields(ExceptionSink* xsink) {
    if (!doc) {
        pdf_error(xsink, "document not loaded");
        return nullptr;
    }

    try {
        ReferenceHolder<QoreListNode> result(new QoreListNode(autoTypeInfo), xsink);

        PoDoFo::PdfAcroForm& acroForm = doc->GetOrCreateAcroForm();

        for (auto* field : acroForm) {
            if (!field) {
                continue;
            }
            ReferenceHolder<QoreHashNode> fieldInfo(new QoreHashNode(autoTypeInfo), xsink);

            // Get field name
            fieldInfo->setKeyValue("name", new QoreStringNode(field->GetFullName().c_str()), xsink);

            // Get field type
            PoDoFo::PdfFieldType fieldType = field->GetType();
            fieldInfo->setKeyValue("type", new QoreStringNode(fieldTypeToString(fieldType)), xsink);

            // Get read-only and required flags
            fieldInfo->setKeyValue("read_only", field->IsReadOnly(), xsink);
            fieldInfo->setKeyValue("required", field->IsRequired(), xsink);

            // Get field value based on type
            switch (fieldType) {
                case PoDoFo::PdfFieldType::TextBox: {
                    auto* textBox = dynamic_cast<PoDoFo::PdfTextBox*>(field);
                    if (textBox) {
                        auto text = textBox->GetText();
                        if (text.has_value()) {
                            std::string_view sv = text.value().GetString();
                            fieldInfo->setKeyValue("value",
                                new QoreStringNode(std::string(sv).c_str()), xsink);
                        }
                        fieldInfo->setKeyValue("multiline", textBox->IsMultiLine(), xsink);
                        fieldInfo->setKeyValue("password", textBox->IsPasswordField(), xsink);
                        auto maxLen = textBox->GetMaxLen();
                        if (maxLen > 0) {
                            fieldInfo->setKeyValue("max_length", static_cast<int64>(maxLen), xsink);
                        }
                    }
                    break;
                }
                case PoDoFo::PdfFieldType::CheckBox: {
                    auto* checkBox = dynamic_cast<PoDoFo::PdfCheckBox*>(field);
                    if (checkBox) {
                        fieldInfo->setKeyValue("checked", checkBox->IsChecked(), xsink);
                    }
                    break;
                }
                case PoDoFo::PdfFieldType::ComboBox: {
                    auto* comboBox = dynamic_cast<PoDoFo::PdfComboBox*>(field);
                    if (comboBox) {
                        int selectedIndex = comboBox->GetSelectedIndex();
                        if (selectedIndex >= 0) {
                            fieldInfo->setKeyValue("selected_index", static_cast<int64>(selectedIndex), xsink);
                        }

                        // Get options
                        ReferenceHolder<QoreListNode> options(new QoreListNode(autoTypeInfo), xsink);
                        unsigned int count = comboBox->GetItemCount();
                        for (unsigned int i = 0; i < count; ++i) {
                            PoDoFo::PdfString item = comboBox->GetItem(i);
                            std::string_view sv = item.GetString();
                            options->push(new QoreStringNode(std::string(sv).c_str()), xsink);
                        }
                        fieldInfo->setKeyValue("options", options.release(), xsink);
                    }
                    break;
                }
                case PoDoFo::PdfFieldType::ListBox: {
                    auto* listBox = dynamic_cast<PoDoFo::PdfListBox*>(field);
                    if (listBox) {
                        int selectedIndex = listBox->GetSelectedIndex();
                        if (selectedIndex >= 0) {
                            fieldInfo->setKeyValue("selected_index", static_cast<int64>(selectedIndex), xsink);
                        }

                        // Get options
                        ReferenceHolder<QoreListNode> options(new QoreListNode(autoTypeInfo), xsink);
                        unsigned int count = listBox->GetItemCount();
                        for (unsigned int i = 0; i < count; ++i) {
                            PoDoFo::PdfString item = listBox->GetItem(i);
                            std::string_view sv = item.GetString();
                            options->push(new QoreStringNode(std::string(sv).c_str()), xsink);
                        }
                        fieldInfo->setKeyValue("options", options.release(), xsink);
                    }
                    break;
                }
                case PoDoFo::PdfFieldType::Signature: {
                    fieldInfo->setKeyValue("signed", false, xsink);
                    break;
                }
                default:
                    break;
            }

            // Try to get rectangle information from the widget
            if (auto* widget = field->GetWidget()) {
                PoDoFo::Rect rect = widget->GetRect();
                ReferenceHolder<QoreHashNode> rectInfo(new QoreHashNode(autoTypeInfo), xsink);
                rectInfo->setKeyValue("x", rect.X, xsink);
                rectInfo->setKeyValue("y", rect.Y, xsink);
                rectInfo->setKeyValue("width", rect.Width, xsink);
                rectInfo->setKeyValue("height", rect.Height, xsink);
                fieldInfo->setKeyValue("rect", rectInfo.release(), xsink);
            }

            result->push(fieldInfo.release(), xsink);
        }

        return result.release();
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
        return nullptr;
    }
}

QoreValue QorePdfEditor::getFormFieldValue(const std::string& fieldName, ExceptionSink* xsink) {
    if (!doc) {
        pdf_error(xsink, "document not loaded");
        return QoreValue();
    }

    try {
        PoDoFo::PdfAcroForm& acroForm = doc->GetOrCreateAcroForm();

        for (auto* field : acroForm) {
            if (!field) {
                continue;
            }
            if (field->GetFullName() == fieldName) {
                PoDoFo::PdfFieldType fieldType = field->GetType();

                switch (fieldType) {
                    case PoDoFo::PdfFieldType::TextBox: {
                        auto* textBox = dynamic_cast<PoDoFo::PdfTextBox*>(field);
                        if (textBox) {
                            auto text = textBox->GetText();
                            if (text.has_value()) {
                                std::string_view sv = text.value().GetString();
                                return new QoreStringNode(std::string(sv).c_str());
                            }
                        }
                        return QoreValue();
                    }
                    case PoDoFo::PdfFieldType::CheckBox: {
                        auto* checkBox = dynamic_cast<PoDoFo::PdfCheckBox*>(field);
                        if (checkBox) {
                            return checkBox->IsChecked();
                        }
                        return QoreValue();
                    }
                    case PoDoFo::PdfFieldType::ComboBox: {
                        auto* comboBox = dynamic_cast<PoDoFo::PdfComboBox*>(field);
                        if (comboBox) {
                            return static_cast<int64>(comboBox->GetSelectedIndex());
                        }
                        return QoreValue();
                    }
                    case PoDoFo::PdfFieldType::ListBox: {
                        auto* listBox = dynamic_cast<PoDoFo::PdfListBox*>(field);
                        if (listBox) {
                            return static_cast<int64>(listBox->GetSelectedIndex());
                        }
                        return QoreValue();
                    }
                    default:
                        return QoreValue();
                }
            }
        }

        pdf_error(xsink, "form field not found: " + fieldName);
        return QoreValue();
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
        return QoreValue();
    }
}

void QorePdfEditor::setFormFieldValue(const std::string& fieldName, QoreValue value,
                                       ExceptionSink* xsink) {
    if (!doc) {
        pdf_error(xsink, "document not loaded");
        return;
    }

    try {
        PoDoFo::PdfAcroForm& acroForm = doc->GetOrCreateAcroForm();

        for (auto* field : acroForm) {
            if (!field) {
                continue;
            }
            if (field->GetFullName() == fieldName) {
                PoDoFo::PdfFieldType fieldType = field->GetType();

                switch (fieldType) {
                    case PoDoFo::PdfFieldType::TextBox: {
                        auto* textBox = dynamic_cast<PoDoFo::PdfTextBox*>(field);
                        if (textBox) {
                            if (value.getType() == NT_STRING) {
                                textBox->SetText(PoDoFo::PdfString(value.get<const QoreStringNode>()->c_str()));
                            } else {
                                QoreStringValueHelper str(value);
                                textBox->SetText(PoDoFo::PdfString(str->c_str()));
                            }
                        }
                        return;
                    }
                    case PoDoFo::PdfFieldType::CheckBox: {
                        auto* checkBox = dynamic_cast<PoDoFo::PdfCheckBox*>(field);
                        if (checkBox) {
                            checkBox->SetChecked(value.getAsBool());
                        }
                        return;
                    }
                    case PoDoFo::PdfFieldType::ComboBox: {
                        auto* comboBox = dynamic_cast<PoDoFo::PdfComboBox*>(field);
                        if (comboBox) {
                            comboBox->SetSelectedIndex(static_cast<int>(value.getAsBigInt()));
                        }
                        return;
                    }
                    case PoDoFo::PdfFieldType::ListBox: {
                        auto* listBox = dynamic_cast<PoDoFo::PdfListBox*>(field);
                        if (listBox) {
                            listBox->SetSelectedIndex(static_cast<int>(value.getAsBigInt()));
                        }
                        return;
                    }
                    default:
                        pdf_error(xsink, "cannot set value on field type: " +
                                  fieldTypeToString(fieldType));
                        return;
                }
            }
        }

        pdf_error(xsink, "form field not found: " + fieldName);
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
    }
}

void QorePdfEditor::createFormField(const std::string& fieldName, const std::string& fieldType,
                                     int pageIndex, double x, double y, double width, double height,
                                     const QoreHashNode* options, ExceptionSink* xsink) {
    if (!doc) {
        pdf_error(xsink, "document not loaded");
        return;
    }

    if (pageIndex < 0 || pageIndex >= pageCount()) {
        pdf_error(xsink, "page index out of range");
        return;
    }

    try {
        PoDoFo::PdfPage& page = doc->GetPages().GetPageAt(pageIndex);
        PoDoFo::Rect rect(x, y, width, height);

        if (fieldType == "text") {
            auto& textBox = page.CreateField<PoDoFo::PdfTextBox>(fieldName, rect);

            if (options) {
                QoreValue val = options->getKeyValue("default_value");
                if (val.getType() == NT_STRING) {
                    textBox.SetText(PoDoFo::PdfString(val.get<const QoreStringNode>()->c_str()));
                }

                val = options->getKeyValue("max_length");
                if (val.getType() == NT_INT) {
                    textBox.SetMaxLen(static_cast<int64_t>(val.getAsBigInt()));
                }

                val = options->getKeyValue("multiline");
                if (val.getType() == NT_BOOLEAN && val.getAsBool()) {
                    textBox.SetMultiLine(true);
                }

                val = options->getKeyValue("password");
                if (val.getType() == NT_BOOLEAN && val.getAsBool()) {
                    textBox.SetPasswordField(true);
                }

                val = options->getKeyValue("read_only");
                if (val.getType() == NT_BOOLEAN && val.getAsBool()) {
                    textBox.SetReadOnly(true);
                }

                val = options->getKeyValue("required");
                if (val.getType() == NT_BOOLEAN && val.getAsBool()) {
                    textBox.SetRequired(true);
                }
            }
        } else if (fieldType == "checkbox") {
            auto& checkBox = page.CreateField<PoDoFo::PdfCheckBox>(fieldName, rect);

            if (options) {
                QoreValue val = options->getKeyValue("checked");
                if (val.getType() == NT_BOOLEAN && val.getAsBool()) {
                    checkBox.SetChecked(true);
                }

                val = options->getKeyValue("read_only");
                if (val.getType() == NT_BOOLEAN && val.getAsBool()) {
                    checkBox.SetReadOnly(true);
                }

                val = options->getKeyValue("required");
                if (val.getType() == NT_BOOLEAN && val.getAsBool()) {
                    checkBox.SetRequired(true);
                }
            }
        } else if (fieldType == "combo") {
            auto& comboBox = page.CreateField<PoDoFo::PdfComboBox>(fieldName, rect);

            if (options) {
                QoreValue val = options->getKeyValue("options");
                if (val.getType() == NT_LIST) {
                    const QoreListNode* list = val.get<const QoreListNode>();
                    ConstListIterator it(list);
                    while (it.next()) {
                        QoreValue item = it.getValue();
                        if (item.getType() == NT_STRING) {
                            comboBox.InsertItem(PoDoFo::PdfString(item.get<const QoreStringNode>()->c_str()));
                        }
                    }
                }

                val = options->getKeyValue("selected_index");
                if (val.getType() == NT_INT) {
                    comboBox.SetSelectedIndex(static_cast<int>(val.getAsBigInt()));
                }

                val = options->getKeyValue("read_only");
                if (val.getType() == NT_BOOLEAN && val.getAsBool()) {
                    comboBox.SetReadOnly(true);
                }

                val = options->getKeyValue("required");
                if (val.getType() == NT_BOOLEAN && val.getAsBool()) {
                    comboBox.SetRequired(true);
                }
            }
        } else if (fieldType == "list") {
            auto& listBox = page.CreateField<PoDoFo::PdfListBox>(fieldName, rect);

            if (options) {
                QoreValue val = options->getKeyValue("options");
                if (val.getType() == NT_LIST) {
                    const QoreListNode* list = val.get<const QoreListNode>();
                    ConstListIterator it(list);
                    while (it.next()) {
                        QoreValue item = it.getValue();
                        if (item.getType() == NT_STRING) {
                            listBox.InsertItem(PoDoFo::PdfString(item.get<const QoreStringNode>()->c_str()));
                        }
                    }
                }

                val = options->getKeyValue("selected_index");
                if (val.getType() == NT_INT) {
                    listBox.SetSelectedIndex(static_cast<int>(val.getAsBigInt()));
                }

                val = options->getKeyValue("read_only");
                if (val.getType() == NT_BOOLEAN && val.getAsBool()) {
                    listBox.SetReadOnly(true);
                }

                val = options->getKeyValue("required");
                if (val.getType() == NT_BOOLEAN && val.getAsBool()) {
                    listBox.SetRequired(true);
                }
            }
        } else if (fieldType == "button") {
            auto& pushButton = page.CreateField<PoDoFo::PdfPushButton>(fieldName, rect);

            if (options) {
                QoreValue val = options->getKeyValue("caption");
                if (val.getType() == NT_STRING) {
                    pushButton.SetCaption(PoDoFo::PdfString(val.get<const QoreStringNode>()->c_str()));
                }

                val = options->getKeyValue("read_only");
                if (val.getType() == NT_BOOLEAN && val.getAsBool()) {
                    pushButton.SetReadOnly(true);
                }
            }
        } else if (fieldType == "signature") {
            // Create a signature field
            auto& sigField = page.CreateField<PoDoFo::PdfSignature>(fieldName, rect);

            if (options) {
                QoreValue val = options->getKeyValue("read_only");
                if (val.getType() == NT_BOOLEAN && val.getAsBool()) {
                    sigField.SetReadOnly(true);
                }

                val = options->getKeyValue("required");
                if (val.getType() == NT_BOOLEAN && val.getAsBool()) {
                    sigField.SetRequired(true);
                }
            }
        } else {
            pdf_error(xsink, "unknown field type: " + fieldType);
        }
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
    }
}

void QorePdfEditor::flattenFormFields(ExceptionSink* xsink) {
    if (!doc) {
        pdf_error(xsink, "document not loaded");
        return;
    }

    try {
        PoDoFo::PdfAcroForm& acroForm = doc->GetOrCreateAcroForm();
        // PoDoFo doesn't have a built-in flatten method, so we need to draw field values
        // as static content and then remove the fields

        // Collect indices of fields to remove (in reverse order to avoid index shifting)
        std::vector<unsigned> indicesToRemove;

        unsigned fieldCount = acroForm.GetFieldCount();
        for (unsigned i = 0; i < fieldCount; ++i) {
            PoDoFo::PdfField& field = acroForm.GetFieldAt(i);

            if (field.GetType() == PoDoFo::PdfFieldType::TextBox) {
                auto* textBox = dynamic_cast<PoDoFo::PdfTextBox*>(&field);
                if (textBox) {
                    auto text = textBox->GetText();
                    if (text.has_value() && !text.value().IsEmpty()) {
                        // Get field rectangle from widget
                        if (auto* widget = field.GetWidget()) {
                            PoDoFo::Rect rect = widget->GetRect();

                            // Get the page this widget is on
                            PoDoFo::PdfPage* page = widget->GetPage();
                            if (page) {
                                // Draw the text at the field location
                                PoDoFo::PdfPainter painter;
                                painter.SetCanvas(*page);

                                // Use default font
                                PoDoFo::PdfFontCreateParams params;
                                PoDoFo::PdfFont& font = doc->GetFonts().GetStandard14Font(
                                    PoDoFo::PdfStandard14FontType::Helvetica, params);
                                painter.TextState.SetFont(font, 10.0);

                                // Draw text inside the field bounds
                                std::string textStr(text.value().GetString());
                                painter.DrawText(textStr, rect.X + 2, rect.Y + rect.Height - 12);
                                painter.FinishDrawing();
                            }
                        }
                    }
                    indicesToRemove.push_back(i);
                }
            } else if (field.GetType() == PoDoFo::PdfFieldType::CheckBox) {
                auto* checkBox = dynamic_cast<PoDoFo::PdfCheckBox*>(&field);
                if (checkBox && checkBox->IsChecked()) {
                    // Draw a checkmark for checked boxes
                    if (auto* widget = field.GetWidget()) {
                        PoDoFo::Rect rect = widget->GetRect();
                        PoDoFo::PdfPage* page = widget->GetPage();
                        if (page) {
                            PoDoFo::PdfPainter painter;
                            painter.SetCanvas(*page);

                            PoDoFo::PdfFontCreateParams params;
                            PoDoFo::PdfFont& font = doc->GetFonts().GetStandard14Font(
                                PoDoFo::PdfStandard14FontType::ZapfDingbats, params);
                            painter.TextState.SetFont(font, std::min(rect.Width, rect.Height) * 0.8);

                            // ZapfDingbats checkmark character
                            painter.DrawText("\x34", rect.X + 2, rect.Y + 2);
                            painter.FinishDrawing();
                        }
                    }
                }
                indicesToRemove.push_back(i);
            } else {
                // Remove all other field types as well (combo, list, radio, button, signature)
                indicesToRemove.push_back(i);
            }
        }

        // Remove fields in reverse order to avoid index shifting issues
        for (auto it = indicesToRemove.rbegin(); it != indicesToRemove.rend(); ++it) {
            acroForm.RemoveFieldAt(*it);
        }
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
    }
}

// ========== Encryption Operations ==========

void QorePdfEditor::setEncryption(const std::string& userPassword, const std::string& ownerPassword,
                                   const QoreHashNode* permissions, const std::string& algorithm,
                                   ExceptionSink* xsink) {
    if (!doc) {
        pdf_error(xsink, "document not loaded");
        return;
    }

    if (ownerPassword.empty()) {
        pdf_error(xsink, "owner password is required for encryption");
        return;
    }

    try {
        PoDoFo::PdfEncryptionAlgorithm algo = PoDoFo::PdfEncryptionAlgorithm::AESV3R6;
        int keyLength = 256;

        if (algorithm == "rc4-40") {
            algo = PoDoFo::PdfEncryptionAlgorithm::RC4V1;
            keyLength = 40;
        } else if (algorithm == "rc4-128") {
            algo = PoDoFo::PdfEncryptionAlgorithm::RC4V2;
            keyLength = 128;
        } else if (algorithm == "aes-128") {
            algo = PoDoFo::PdfEncryptionAlgorithm::AESV2;
            keyLength = 128;
        } else if (algorithm == "aes-256" || algorithm.empty()) {
            algo = PoDoFo::PdfEncryptionAlgorithm::AESV3R6;
            keyLength = 256;
        } else {
            pdf_error(xsink, "unknown encryption algorithm: " + algorithm +
                      " (valid: rc4-40, rc4-128, aes-128, aes-256)");
            return;
        }

        // Build permission flags - start with all permissions enabled (default)
        // Only disable permissions that are explicitly set to false
        PoDoFo::PdfPermissions permFlags =
            PoDoFo::PdfPermissions::Print |
            PoDoFo::PdfPermissions::Edit |
            PoDoFo::PdfPermissions::Copy |
            PoDoFo::PdfPermissions::EditNotes |
            PoDoFo::PdfPermissions::FillAndSign |
            PoDoFo::PdfPermissions::Accessible |
            PoDoFo::PdfPermissions::DocAssembly |
            PoDoFo::PdfPermissions::HighPrint;

        if (permissions) {
            // Helper lambda to check if permission should be disabled
            auto checkPerm = [&](const char* key, PoDoFo::PdfPermissions perm) {
                QoreValue val = permissions->getKeyValue(key);
                // Only disable if explicitly set to false (not if missing or null)
                if (!val.isNullOrNothing() && !val.getAsBool()) {
                    permFlags = permFlags & ~perm;
                }
            };

            checkPerm("print", PoDoFo::PdfPermissions::Print);
            checkPerm("edit", PoDoFo::PdfPermissions::Edit);
            checkPerm("copy", PoDoFo::PdfPermissions::Copy);
            checkPerm("edit_notes", PoDoFo::PdfPermissions::EditNotes);
            checkPerm("fill_and_sign", PoDoFo::PdfPermissions::FillAndSign);
            checkPerm("accessible", PoDoFo::PdfPermissions::Accessible);
            checkPerm("doc_assembly", PoDoFo::PdfPermissions::DocAssembly);
            checkPerm("high_print", PoDoFo::PdfPermissions::HighPrint);
        }

        // Set encryption using SetEncrypted which creates the encryption internally
        PoDoFo::PdfKeyLength keyLen = PoDoFo::PdfKeyLength::Unknown;
        if (keyLength == 40) {
            keyLen = PoDoFo::PdfKeyLength::L40;
        } else if (keyLength == 128) {
            keyLen = PoDoFo::PdfKeyLength::L128;
        } else if (keyLength == 256) {
            keyLen = PoDoFo::PdfKeyLength::L256;
        }
        doc->SetEncrypted(userPassword, ownerPassword, permFlags, algo, keyLen);
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
    }
}

void QorePdfEditor::removeEncryption(ExceptionSink* xsink) {
    if (!doc) {
        pdf_error(xsink, "document not loaded");
        return;
    }

    try {
        // Pass nullptr to SetEncrypt to remove encryption
        // The document must have been loaded with the correct password
        doc->SetEncrypt(nullptr);
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
    }
}

bool QorePdfEditor::isEncrypted() const {
    if (!doc) {
        return false;
    }
    return doc->GetEncrypt() != nullptr;
}

QoreHashNode* QorePdfEditor::getEncryptionInfo(const std::string& path, const std::string& password,
                                                ExceptionSink* xsink) {
    QoreSandboxManagerHelper smh;
    if (smh && !smh->checkFilesystemAccess(path.c_str(), QSEC_READ, xsink)) {
        return nullptr;
    }

    try {
        PoDoFo::PdfMemDocument tempDoc;
        bool encrypted = false;

        try {
            if (password.empty()) {
                tempDoc.Load(path);
            } else {
                tempDoc.Load(path, password);
            }
        } catch (const PoDoFo::PdfError& e) {
            // Check if it's a password error
            if (e.GetCode() == PoDoFo::PdfErrorCode::InvalidPassword) {
                encrypted = true;
            } else {
                throw;
            }
        }

        ReferenceHolder<QoreHashNode> result(new QoreHashNode(autoTypeInfo), xsink);

        const PoDoFo::PdfEncrypt* encrypt = tempDoc.GetEncrypt();
        if (encrypt || encrypted) {
            result->setKeyValue("encrypted", true, xsink);

            if (encrypt) {
                PoDoFo::PdfEncryptionAlgorithm algo = encrypt->GetEncryptAlgorithm();
                std::string algoStr;
                int keyLen = 0;

                switch (algo) {
                    case PoDoFo::PdfEncryptionAlgorithm::RC4V1:
                        algoStr = "rc4-40";
                        keyLen = 40;
                        break;
                    case PoDoFo::PdfEncryptionAlgorithm::RC4V2:
                        algoStr = "rc4-128";
                        keyLen = 128;
                        break;
                    case PoDoFo::PdfEncryptionAlgorithm::AESV2:
                        algoStr = "aes-128";
                        keyLen = 128;
                        break;
                    case PoDoFo::PdfEncryptionAlgorithm::AESV3R6:
                        algoStr = "aes-256";
                        keyLen = 256;
                        break;
                    default:
                        algoStr = "unknown";
                }

                result->setKeyValue("algorithm", new QoreStringNode(algoStr), xsink);
                result->setKeyValue("key_length", static_cast<int64>(keyLen), xsink);

                // Get permissions
                ReferenceHolder<QoreHashNode> perms(new QoreHashNode(autoTypeInfo), xsink);
                PoDoFo::PdfPermissions permFlags = encrypt->GetPValue();

                perms->setKeyValue("print",
                    (permFlags & PoDoFo::PdfPermissions::Print) == PoDoFo::PdfPermissions::Print, xsink);
                perms->setKeyValue("edit",
                    (permFlags & PoDoFo::PdfPermissions::Edit) == PoDoFo::PdfPermissions::Edit, xsink);
                perms->setKeyValue("copy",
                    (permFlags & PoDoFo::PdfPermissions::Copy) == PoDoFo::PdfPermissions::Copy, xsink);
                perms->setKeyValue("edit_notes",
                    (permFlags & PoDoFo::PdfPermissions::EditNotes) == PoDoFo::PdfPermissions::EditNotes, xsink);
                perms->setKeyValue("fill_and_sign",
                    (permFlags & PoDoFo::PdfPermissions::FillAndSign) == PoDoFo::PdfPermissions::FillAndSign, xsink);
                perms->setKeyValue("accessible",
                    (permFlags & PoDoFo::PdfPermissions::Accessible) == PoDoFo::PdfPermissions::Accessible, xsink);
                perms->setKeyValue("doc_assembly",
                    (permFlags & PoDoFo::PdfPermissions::DocAssembly) == PoDoFo::PdfPermissions::DocAssembly, xsink);
                perms->setKeyValue("high_print",
                    (permFlags & PoDoFo::PdfPermissions::HighPrint) == PoDoFo::PdfPermissions::HighPrint, xsink);

                result->setKeyValue("permissions", perms.release(), xsink);
            }
        } else {
            result->setKeyValue("encrypted", false, xsink);
        }

        return result.release();
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
        return nullptr;
    }
}

// ========== Digital Signature Operations ==========

void QorePdfEditor::createSignatureField(const std::string& fieldName, int pageIndex,
                                          double x, double y, double width, double height,
                                          const QoreHashNode* options, ExceptionSink* xsink) {
    // Use the form field creation method with type "signature"
    createFormField(fieldName, "signature", pageIndex, x, y, width, height, options, xsink);
}

void QorePdfEditor::signDocument(const std::string& fieldName, const BinaryNode* certificate,
                                  const BinaryNode* privateKey, const std::string& keyPassword,
                                  const QoreHashNode* options, ExceptionSink* xsink) {
    if (!doc) {
        pdf_error(xsink, "document not loaded");
        return;
    }

    if (!certificate || certificate->size() == 0) {
        pdf_error(xsink, "certificate data is required");
        return;
    }

    if (!privateKey || privateKey->size() == 0) {
        pdf_error(xsink, "private key data is required");
        return;
    }

    try {
        PoDoFo::PdfAcroForm& acroForm = doc->GetOrCreateAcroForm();

        // Find the signature field
        PoDoFo::PdfSignature* sigField = nullptr;
        for (auto* field : acroForm) {
            if (!field) {
                continue;
            }
            if (field->GetFullName() == fieldName &&
                field->GetType() == PoDoFo::PdfFieldType::Signature) {
                sigField = dynamic_cast<PoDoFo::PdfSignature*>(field);
                break;
            }
        }

        if (!sigField) {
            pdf_error(xsink, "signature field not found: " + fieldName);
            return;
        }

        // Get signing options
        std::string reason;
        std::string location;
        std::string signerName;

        if (options) {
            QoreValue val = options->getKeyValue("reason");
            if (val.getType() == NT_STRING) {
                reason = val.get<const QoreStringNode>()->c_str();
            }

            val = options->getKeyValue("location");
            if (val.getType() == NT_STRING) {
                location = val.get<const QoreStringNode>()->c_str();
            }

            val = options->getKeyValue("signer_name");
            if (val.getType() == NT_STRING) {
                signerName = val.get<const QoreStringNode>()->c_str();
            }
        }

        // Set signature information
        if (!reason.empty()) {
            sigField->SetSignatureReason(PoDoFo::PdfString(reason));
        }
        if (!location.empty()) {
            sigField->SetSignatureLocation(PoDoFo::PdfString(location));
        }
        if (!signerName.empty()) {
            sigField->SetSignerName(PoDoFo::PdfString(signerName));
        }

        // Note: Actual cryptographic signing requires OpenSSL integration
        // PoDoFo provides the structure, but the actual signature computation
        // needs to be done with OpenSSL or a similar library
        // For now, we set up the signature field metadata

        pdf_error(xsink, "digital signing requires OpenSSL integration - not fully implemented");
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
    }
}

QoreListNode* QorePdfEditor::getSignatures(ExceptionSink* xsink) {
    if (!doc) {
        pdf_error(xsink, "document not loaded");
        return nullptr;
    }

    try {
        ReferenceHolder<QoreListNode> result(new QoreListNode(autoTypeInfo), xsink);

        PoDoFo::PdfAcroForm& acroForm = doc->GetOrCreateAcroForm();

        for (auto* field : acroForm) {
            if (!field) {
                continue;
            }
            if (field->GetType() == PoDoFo::PdfFieldType::Signature) {
                ReferenceHolder<QoreHashNode> sigInfo(new QoreHashNode(autoTypeInfo), xsink);

                sigInfo->setKeyValue("name", new QoreStringNode(field->GetFullName().c_str()), xsink);

                auto* sigField = dynamic_cast<PoDoFo::PdfSignature*>(field);
                if (!sigField) {
                    continue;
                }

                // Get signature details if available
                auto reason = sigField->GetSignatureReason();
                if (reason.has_value() && !reason.value().IsEmpty()) {
                    std::string_view sv = reason.value().GetString();
                    sigInfo->setKeyValue("reason", new QoreStringNode(std::string(sv).c_str()), xsink);
                }

                auto location = sigField->GetSignatureLocation();
                if (location.has_value() && !location.value().IsEmpty()) {
                    std::string_view sv = location.value().GetString();
                    sigInfo->setKeyValue("location", new QoreStringNode(std::string(sv).c_str()), xsink);
                }

                auto signerName = sigField->GetSignerName();
                if (signerName.has_value() && !signerName.value().IsEmpty()) {
                    std::string_view sv = signerName.value().GetString();
                    sigInfo->setKeyValue("signer_name", new QoreStringNode(std::string(sv).c_str()), xsink);
                }

                auto date = sigField->GetSignatureDate();
                if (date.has_value()) {
                    std::string_view dateStr = date.value().ToString().GetString();
                    sigInfo->setKeyValue("date", new QoreStringNode(std::string(dateStr).c_str()), xsink);
                }

                // Get rectangle from widget
                if (auto* widget = field->GetWidget()) {
                    PoDoFo::Rect rect = widget->GetRect();
                    ReferenceHolder<QoreHashNode> rectInfo(new QoreHashNode(autoTypeInfo), xsink);
                    rectInfo->setKeyValue("x", rect.X, xsink);
                    rectInfo->setKeyValue("y", rect.Y, xsink);
                    rectInfo->setKeyValue("width", rect.Width, xsink);
                    rectInfo->setKeyValue("height", rect.Height, xsink);
                    sigInfo->setKeyValue("rect", rectInfo.release(), xsink);
                }

                result->push(sigInfo.release(), xsink);
            }
        }

        return result.release();
    } catch (const std::exception& e) {
        pdf_error(xsink, e.what());
        return nullptr;
    }
}
