#include <podofo/podofo.h>
#include <iostream>

int main(int argc, char** argv) {
    if (argc < 3) {
        std::cerr << "usage: " << argv[0] << " <font-path> <output.pdf> [no-embed]" << std::endl;
        return 2;
    }

    const char* font_path = argv[1];
    const char* output_path = argv[2];
    bool no_embed = argc > 3;

    try {
        PoDoFo::PdfMemDocument doc;
        PoDoFo::Rect rect(0.0, 0.0, 595.0, 842.0);
        PoDoFo::PdfPage& page = doc.GetPages().CreatePage(rect);

        PoDoFo::PdfFontCreateParams params;
        if (no_embed) {
            params.Flags = params.Flags | PoDoFo::PdfFontCreateFlags::DontEmbed;
        }

        PoDoFo::PdfFont& font = doc.GetFonts().GetOrCreateFont(font_path, params);

        PoDoFo::PdfPainter painter;
        painter.SetCanvas(page);
        painter.TextState.SetFont(font, 24.0);
        painter.DrawText("PoDoFo embedding leak test", 72.0, 720.0, PoDoFo::PdfDrawTextStyle::Regular);
        painter.FinishDrawing();

        doc.Save(output_path);
    } catch (const PoDoFo::PdfError& err) {
        std::cerr << "PoDoFo error: " << err.what() << std::endl;
        return 1;
    } catch (const std::exception& ex) {
        std::cerr << "error: " << ex.what() << std::endl;
        return 1;
    }

    return 0;
}
