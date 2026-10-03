// Copyright (C) 2026 Qore Technologies, s.r.o.
// SPDX-License-Identifier: MIT
#include <podofo/podofo.h>
#include <cassert>
#include <iostream>
#include <memory>
#include <type_traits>

using namespace PoDoFo;

static void checkOwningView(PdfContentReaderFlags flags, PdfContentType expected) {
    PdfMemDocument document;
    auto& page = document.GetPages().CreatePage(PdfPageSize::A4);
    auto form = document.CreateXObjectForm(Rect(0, 0, 20, 10));
    PdfPainter painter;
    painter.SetCanvas(page);
    painter.DrawXObject(*form, 0, 0);
    painter.FinishDrawing();
    PdfContentReaderArgs args;
    args.Flags = flags;
    PdfContentStreamReader reader(page, args);
    PdfContent content;
    bool found = false;
    while (reader.TryReadNext(content)) {
        if (content.GetType() != expected) {
            continue;
        }
        assert(!content.HasErrors() && !content.HasWarnings());
        found = true;
        auto* original = content->XObject.get();
        std::weak_ptr<const PdfXObject> weak;
        {
            // The converted owner's lifetime must extend with the reference,
            // rather than aliasing a differently typed shared_ptr in content.
            const auto& view = content.GetXObject();
            static_assert(std::is_same_v<std::decay_t<decltype(view)>,
                                        std::shared_ptr<const PdfXObject>>);
            assert(view.get() == original);
            assert(view->GetType() == PdfXObjectType::Form);
            weak = view;
            content->XObject.reset();
            assert(view.get() == original && !weak.expired());
            while (reader.TryReadNext(content)) {
                assert(!content.HasErrors() && !content.HasWarnings());
            }
            assert(view.get() == original && !weak.expired());
            assert(view->GetObject().GetIndirectReference()
                == form->GetObject().GetIndirectReference());
        }
        assert(weak.expired());
    }
    assert(found);
}

int main() {
    PdfContent empty;
    bool rejected = false;
    try {
        (void)empty.GetXObject();
    } catch (const PdfError& error) {
        rejected = error.GetCode() == PdfErrorCode::InvalidDataType;
    }
    assert(rejected);
    checkOwningView(PdfContentReaderFlags::None, PdfContentType::BeginFormXObject);
    checkOwningView(PdfContentReaderFlags::SkipFollowFormXObjects, PdfContentType::DoXObject);
    std::cout << "PASS: const ownership, reader advancement, release and invalid access\n";
}
