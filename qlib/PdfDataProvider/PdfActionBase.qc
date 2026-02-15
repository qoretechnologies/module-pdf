# -*- mode: qore; indent-tabs-mode: nil -*-
#! Qore PdfActionBase class definition

/** PdfActionBase.qc Copyright (C) 2026 Qore Technologies, s.r.o.

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

#! @file PdfActionBase.qc Base class for PDF action data providers

#! Contains all public definitions in the PdfDataProvider module
public namespace PdfDataProvider {
#! Base class for PDF action providers
/** Provides common functionality for loading PDFs and writing output.
*/
public class PdfActionBase inherits AbstractDataProvider {
    #! Loads a PdfDocument from a request hash (input_path, data, or location)
    static PdfDocument loadDocument(hash<auto> req) {
        *string password = req.password;
        if (req.input_path) {
            return new PdfDocument(req.input_path, password);
        }
        if (req.location) {
            binary loc_data = FileLocationHandler::getBinaryFileFromLocation(req.location);
            return new PdfDocument(loc_data, password);
        }
        if (req.data) {
            return new PdfDocument(req.data, password);
        }
        throw "PDF-ERROR", "one of 'input_path', 'data', or 'location' must be provided";
    }

    #! Loads a PdfEditor from a request hash (input_path, data, or location)
    static PdfEditor loadEditor(hash<auto> req) {
        *string password = req.password;
        if (req.input_path) {
            return new PdfEditor(req.input_path, password);
        }
        if (req.location) {
            binary loc_data = FileLocationHandler::getBinaryFileFromLocation(req.location);
            return new PdfEditor(loc_data, password);
        }
        if (req.data) {
            return new PdfEditor(req.data, password);
        }
        throw "PDF-ERROR", "one of 'input_path', 'data', or 'location' must be provided";
    }

    #! Loads a PdfEditor from a request hash using a custom password field
    static PdfEditor loadEditorWithPassword(hash<auto> req, *string password) {
        if (req.input_path) {
            return new PdfEditor(req.input_path, password);
        }
        if (req.location) {
            binary loc_data = FileLocationHandler::getBinaryFileFromLocation(req.location);
            return new PdfEditor(loc_data, password);
        }
        if (req.data) {
            return new PdfEditor(req.data, password);
        }
        throw "PDF-ERROR", "one of 'input_path', 'data', or 'location' must be provided";
    }

    #! Gets binary PDF data for use with PdfRenderer static methods
    /** Returns the binary data from the request, resolving from input_path, data, or location.
        @param req the request hash
        @return binary PDF data for the renderer
    */
    static binary getRendererData(hash<auto> req) {
        if (req.data) {
            return req.data;
        }
        if (req.location) {
            return FileLocationHandler::getBinaryFileFromLocation(req.location);
        }
        if (req.input_path) {
            return ReadOnlyFile::readBinaryFile(req.input_path);
        }
        throw "PDF-ERROR", "one of 'input_path', 'data', or 'location' must be provided";
    }

    #! Determines if the request uses a file path input
    static bool hasFilePathInput(hash<auto> req) {
        return exists req.input_path && req.input_path.val();
    }

    #! Returns the output response hash for PDF-producing actions
    /** Handles writing to output_path, output_location, and returning data.

        @param pdf_data serialized PDF binary data
        @param req the original request hash
        @return response hash with output_path, output_location, data, and size
    */
    static hash<auto> makeOutputResponse(binary pdf_data, hash<auto> req) {
        hash<auto> response = {};

        # Write to output_path if specified
        if (req.output_path) {
            PdfActionBase::writeBinaryFile(req.output_path, pdf_data);
            response."output_path" = req.output_path;
        } else if (req.overwrite && PdfActionBase::hasFilePathInput(req)) {
            # Overwrite input file with atomic temp + rename
            string output_path = req.input_path;
            string temp_path = output_path + ".tmp";
            PdfActionBase::writeBinaryFile(temp_path, pdf_data);
            rename(temp_path, output_path);
            response."output_path" = output_path;
        }

        # Write to output_location if specified
        if (req.output_location) {
            FileLocationHandler::writeFileToLocation(req.output_location, pdf_data);
            response."output_location" = req.output_location;
        }

        # Determine if we should return data in the response
        bool has_output = exists req.output_path || exists req.output_location
            || (req.overwrite && PdfActionBase::hasFilePathInput(req));
        bool do_return_data = exists req.return_data ? req.return_data : !has_output;
        if (do_return_data) {
            response."data" = pdf_data;
        }

        response."size" = pdf_data.size();
        return response;
    }

    #! Saves a PdfEditor to the appropriate output and returns response fields
    /** Handles the overwrite pattern with temp file + rename.

        @param editor the PdfEditor to save
        @param req the request hash (needs output_path, output_location, return_data, overwrite, input_path)
        @return response hash with output_path, output_location, data, and size
    */
    static hash<auto> saveEditorOutput(PdfEditor editor, hash<auto> req) {
        # Determine if we need binary output for location or return_data
        bool has_output_path = exists req.output_path && req.output_path.val();
        bool has_output_location = exists req.output_location && req.output_location.val();
        bool has_output = has_output_path || has_output_location;
        bool do_return_data = exists req.return_data ? req.return_data : !has_output;
        bool needs_binary = has_output_location || do_return_data || !has_output_path;

        hash<auto> response = {};
        *binary pdf_data;

        if (needs_binary) {
            pdf_data = editor.saveToMemory();
        }

        # Write to output_path if specified
        if (has_output_path) {
            if (req.output_path == req.input_path) {
                # Atomic overwrite with temp file
                string temp_path = req.output_path + ".tmp";
                if (pdf_data) {
                    PdfActionBase::writeBinaryFile(temp_path, pdf_data);
                } else {
                    editor.save(temp_path);
                }
                rename(temp_path, req.output_path);
            } else {
                if (pdf_data) {
                    PdfActionBase::writeBinaryFile(req.output_path, pdf_data);
                } else {
                    editor.save(req.output_path);
                }
            }
            response."output_path" = req.output_path;
        } else if (req.overwrite && PdfActionBase::hasFilePathInput(req)) {
            # Overwrite input file
            string output_path = req.input_path;
            string temp_path = output_path + ".tmp";
            if (pdf_data) {
                PdfActionBase::writeBinaryFile(temp_path, pdf_data);
            } else {
                editor.save(temp_path);
            }
            rename(temp_path, output_path);
            response."output_path" = output_path;
        }

        # Write to output_location if specified
        if (has_output_location) {
            if (!pdf_data) {
                pdf_data = editor.saveToMemory();
            }
            FileLocationHandler::writeFileToLocation(req.output_location, pdf_data);
            response."output_location" = req.output_location;
        }

        # Return data if requested
        if (do_return_data) {
            if (!pdf_data) {
                pdf_data = editor.saveToMemory();
            }
            response."data" = pdf_data;
        }

        # Set size
        if (pdf_data) {
            response."size" = pdf_data.size();
        } else if (response.output_path) {
            response."size" = hstat(response.output_path).size;
        }

        return response;
    }

    #! Saves a PdfDocument to the appropriate output and returns response fields
    static hash<auto> saveDocumentOutput(PdfDocument doc, hash<auto> req) {
        binary pdf_data = doc.toData();
        return PdfActionBase::makeOutputResponse(pdf_data, req);
    }

    #! Validates that an output destination is specified for modifying actions
    /** Throws an error if no output destination is configured.
    */
    static validateOutputRequired(hash<auto> req) {
        if (!req.output_path && !req.output_location && !req.return_data && !req.overwrite) {
            throw "PDF-ERROR", "one of 'output_path', 'output_location', 'return_data', or "
                "'overwrite' must be specified";
        }
    }

    #! Writes binary data to a file
    static writeBinaryFile(string path, binary data) {
        File f();
        f.open2(path, O_CREAT | O_WRONLY | O_TRUNC);
        f.write(data);
    }
}
}
