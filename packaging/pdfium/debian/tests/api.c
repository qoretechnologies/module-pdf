/* Copyright (C) 2026 David Nichols; SPDX-License-Identifier: MIT */
#include <assert.h>
#include <stdio.h>
#include "fpdfview.h"
#include "fpdf_edit.h"
#include "fpdf_text.h"
#include "fpdf_save.h"

int main(void) {
    FPDF_LIBRARY_CONFIG config = {0};
    config.version = 2;
    FPDF_InitLibraryWithConfig(&config);
    assert(!FPDF_LoadMemDocument64("bad", 3, NULL));
    FPDF_DOCUMENT doc = FPDF_CreateNewDocument();
    assert(doc);
    FPDF_PAGE page = FPDFPage_New(doc, 0, 100, 100);
    assert(page && FPDF_GetPageCount(doc) == 1);
    FPDF_FONT font = FPDFText_LoadStandardFont(doc, "Helvetica");
    assert(font);
    FPDF_PAGEOBJECT text = FPDFPageObj_CreateTextObj(doc, font, 12);
    assert(text);
    const unsigned short message[] = {'I','n','v','o','i','c','e',0};
    assert(FPDFText_SetText(text, message));
    FPDFPageObj_Transform(text, 1, 0, 0, 1, 10, 20);
    FPDFPage_InsertObject(page, text);
    assert(FPDFPage_GenerateContent(page));
    FPDF_TEXTPAGE textpage = FPDFText_LoadPage(page);
    assert(textpage && FPDFText_CountChars(textpage) == 7);
    unsigned short actual[8] = {0};
    assert(FPDFText_GetText(textpage, 0, 7, actual) == 8);
    for (int i = 0; i < 8; ++i) assert(actual[i] == message[i]);
    FPDFText_ClosePage(textpage);
    FPDF_BITMAP bitmap = FPDFBitmap_Create(100, 100, 1);
    assert(bitmap);
    FPDFBitmap_FillRect(bitmap, 0, 0, 100, 100, 0xffffffff);
    FPDF_RenderPageBitmap(bitmap, page, 0, 0, 100, 100, 0, 0);
    const unsigned char *pixels = FPDFBitmap_GetBuffer(bitmap);
    int stride = FPDFBitmap_GetStride(bitmap);
    assert(pixels && stride >= 400);
    int colored = 0;
    for (int y = 0; y < 100; ++y)
        for (int x = 0; x < 100; ++x)
            colored += pixels[y * stride + x * 4] != 255;
    assert(colored > 0);
    FPDFBitmap_Destroy(bitmap);
    FPDF_ClosePage(page);
    FPDFFont_Close(font);
    FPDF_CloseDocument(doc);
    FPDF_DestroyLibrary();
    puts("PASS: installed C API, text extraction, rendered pixels and invalid input");
    return 0;
}
