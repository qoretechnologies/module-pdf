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
    /**
        @throw PERMISSION-DENIED the calling code (also the code that a host-created provider was lent to) is restricted
        from the \c FILESYSTEM functional domain, or from a functional domain of the handler of a location; see
        checkCallerPaths()
    */
    static PdfDocument loadDocument(hash<auto> req) {
        # the path and location are the caller's input (also when this public method is called directly)
        PdfActionBase::checkCallerPaths(req, ("input_path",), ("location",));
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
    /**
        @throw PERMISSION-DENIED the calling code (also the code that a host-created provider was lent to) is restricted
        from the \c FILESYSTEM functional domain, or from a functional domain of the handler of a location; see
        checkCallerPaths()
    */
    static PdfEditor loadEditor(hash<auto> req) {
        # the path and location are the caller's input (also when this public method is called directly)
        PdfActionBase::checkCallerPaths(req, ("input_path",), ("location",));
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
    /**
        @throw PERMISSION-DENIED the calling code (also the code that a host-created provider was lent to) is restricted
        from the \c FILESYSTEM functional domain, or from a functional domain of the handler of a location; see
        checkCallerPaths()
    */
    static PdfEditor loadEditorWithPassword(hash<auto> req, *string password) {
        # the path and location are the caller's input (also when this public method is called directly)
        PdfActionBase::checkCallerPaths(req, ("input_path",), ("location",));
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
        # the path and location are the caller's input (also when this public method is called directly)
        PdfActionBase::checkCallerPaths(req, ("input_path",), ("location",));
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
        # the paths and location are the caller's input (also when this public method is called directly); with
        # overwrite, the input file is written
        PdfActionBase::checkCallerPaths(req, req.overwrite ? ("output_path", "input_path") : ("output_path",),
            ("output_location",));
        hash<auto> response = {};

        # Write to output_path if specified
        if (req.output_path) {
            PdfActionBase::writeBinaryFile(req.output_path, pdf_data);
            response."output_path" = req.output_path;
        } else if (req.overwrite && PdfActionBase::hasFilePathInput(req)) {
            # Overwrite input file with atomic temp + rename
            string output_path = req.input_path;
            PdfActionBase::replaceFile(output_path, pdf_data);
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
        # the paths and location are the caller's input (also when this public method is called directly); with
        # overwrite, the input file is written
        PdfActionBase::checkCallerPaths(req, req.overwrite ? ("output_path", "input_path") : ("output_path",),
            ("output_location",));
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
                # Atomic overwrite with a new temporary file
                PdfActionBase::replaceFile(req.output_path, pdf_data ?? editor.saveToMemory());
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
            PdfActionBase::replaceFile(output_path, pdf_data ?? editor.saveToMemory());
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

    #! Refuses the filesystem paths and locations of a request if the calling code is restricted from them
    /** Library code runs with its own %Program's options, so the paths and locations that the calling code gives are
        refused before anything is read or written if that code is restricted from the \c FILESYSTEM functional
        domain (for example with \c PO_NO_FILESYSTEM), also when the provider was lent to that code by the host (see
        @ref Qore::SandboxManager::isLentToRestricted() "SandboxManager::isLentToRestricted()"); a location is refused
        if that code is restricted from a functional domain that the handler of the location's scheme uses for its
        caller (see @ref FileLocationHandler::AbstractFileLocationHandler::getCallerDomains()
        "AbstractFileLocationHandler::getCallerDomains()").

        @param req the request
        @param paths the fields of the request that are filesystem paths; a field of a nested hash is given with
        \c "." (ex: \c "watermark.font.font_path"), and \c "[]" after the name of a field that holds a list stands
        for each of its elements (ex: \c "placements[].image_path", \c "inputs[]")
        @param locations the fields of the request that are FileLocationHandler locations

        @throw LOCATION-ERROR the options of a location cannot be parsed
        @throw PERMISSION-DENIED the calling code is restricted from the \c FILESYSTEM functional domain or from a
        functional domain of the handler of a location
    */
    static checkCallerPaths(hash<auto> req, list<string> paths, *list<string> locations) {
        foreach string field in (paths) {
            foreach auto v in (PdfActionBase::getFieldValues(req, field.split("."))) {
                if (exists v && SandboxManager::isLentToRestricted(DOM_FILESYSTEM)) {
                    throw "PERMISSION-DENIED", sprintf("the %y field of the request cannot be used: the calling code "
                        "is restricted from the FILESYSTEM functional domain", field);
                }
            }
        }
        foreach string field in (locations) {
            if (exists req{field}) {
                PdfActionBase::checkCallerLocation(field, req{field});
            }
        }
    }

    #! Returns the values of the given field of a request
    /** @param v the value to search
        @param path the components of the field's name; a component that ends in \c "[]" stands for each element of
        a list

        @return the values found; a value that is not a hash where a hash is expected (or not a list where a list is
        expected) has no fields
    */
    private static list<auto> getFieldValues(auto v, list<string> path) {
        if (!path) {
            return (v,);
        }
        string key = shift path;
        bool each = key =~ /\[\]$/;
        if (each) {
            splice key, -2;
        }
        if (v.typeCode() != NT_HASH) {
            return ();
        }
        auto fv = v{key};
        if (!each) {
            return PdfActionBase::getFieldValues(fv, path);
        }
        list<auto> rv = ();
        if (fv.typeCode() == NT_LIST) {
            foreach auto e in (fv) {
                rv += PdfActionBase::getFieldValues(e, path);
            }
        }
        return rv;
    }

    #! Refuses a location given in a request if the calling code is restricted from a functional domain of its handler
    /** @param field the name of the request field, for the error message
        @param location the location

        @throw LOCATION-ERROR the options of the location cannot be parsed
        @throw PERMISSION-DENIED the calling code is restricted from a functional domain of the location's handler
    */
    private static checkCallerLocation(string field, string location) {
        string scheme = (location =~ x/^(\w+):\/\//)[0] ?? "file";
        AbstractFileLocationHandler handler;
        try {
            handler = FileLocationHandler::getHandler(scheme);
        } catch (hash<ExceptionInfo> ex) {
            if (ex.err == "SCHEME-ERROR") {
                # an unknown scheme is refused when the location is used
                return;
            }
            rethrow;
        }
        # the options at the end of the location, as FileLocationHandler takes them
        *hash<auto> opts;
        *string opt_str = (location =~ x/((?:{).*(?:}))$/)[0];
        if (opt_str) {
            auto v = parse_to_qore_value(opt_str);
            if (v.typeCode() == NT_HASH) {
                opts = v;
            } else if (v.strp()) {
                opts = {v: True};
            } else {
                throw "LOCATION-ERROR", sprintf("the options of the location in the %y field of the request cannot be "
                    "parsed", field);
            }
        }
        int dom = handler.getCallerDomains(scheme, opts);
        if (dom && SandboxManager::isLentToRestricted(dom)) {
            throw "PERMISSION-DENIED", sprintf("the %y field of the request cannot be used: the calling code is "
                "restricted from a functional domain of the handler of %y locations", field, scheme);
        }
        # the handler of conn locations has no domains of its own and gives the options that the caller adds to the
        # handler that it resolves the location to, which judges the calling code as
        # SandboxManager::isCallerRestricted() does; for the code that a host-created provider was lent to, which that
        # does not see, the options are refused here if that code is restricted from the file system or the network
        if (!dom && opts && (scheme == "conn" || scheme == "connection")
                && ((SandboxManager::isLentToRestricted(DOM_FILESYSTEM)
                        && !SandboxManager::isCallerRestricted(DOM_FILESYSTEM))
                    || (SandboxManager::isLentToRestricted(DOM_NETWORK)
                        && !SandboxManager::isCallerRestricted(DOM_NETWORK)))) {
            throw "PERMISSION-DENIED", sprintf("the options of the location in the %y field of the request cannot be "
                "used: the calling code is restricted from the FILESYSTEM or NETWORK functional domain", field);
        }
    }

    #! Replaces a file with the given data atomically: the data is written to a new file next to it, which is renamed
    /** The new file has a random name and is created exclusively (\c O_EXCL), so a file or symbolic link that another
        user created at a predictable name is never written through (module-pdf#10)

        @param path the file to replace
        @param data the new content of the file

        @throw PERMISSION-DENIED the calling code (also the code that a host-created provider was lent to) is restricted
        from the \c FILESYSTEM functional domain; see checkCallerPaths()
    */
    static replaceFile(string path, binary data) {
        # the path is the caller's input when this public method is called directly
        PdfActionBase::checkCallerPaths({"path": path}, ("path",));
        string temp_path;
        File f();
        int tries = 0;
        while (True) {
            temp_path = sprintf("%s.%s.tmp", path, get_random_string(16));
            try {
                f.open2(temp_path, O_CREAT | O_EXCL | O_WRONLY);
                break;
            } catch (hash<ExceptionInfo> ex) {
                # another file has the name: another name is tried
                if (exists hlstat(temp_path) && ++tries < 10) {
                    continue;
                }
                rethrow;
            }
        }
        on_error {
            f.close();
            unlink(temp_path);
        }
        f.write(data);
        f.close();
        rename(temp_path, path);
    }

    #! Writes binary data to a file
    /**
        @throw PERMISSION-DENIED the calling code (also the code that a host-created provider was lent to) is restricted
        from the \c FILESYSTEM functional domain, or from a functional domain of the handler of a location; see
        checkCallerPaths()
    */
    static writeBinaryFile(string path, binary data) {
        # the path is the caller's input when this public method is called directly
        PdfActionBase::checkCallerPaths({"path": path}, ("path",));
        File f();
        f.open2(path, O_CREAT | O_WRONLY | O_TRUNC);
        f.write(data);
    }
}
}
