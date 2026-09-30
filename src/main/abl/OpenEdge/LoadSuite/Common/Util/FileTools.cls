/**************************************************************************************************************************
Copyright (c) 2026 by Progress Software Corporation and/or one of its subsidiaries or affiliates. All rights reserved.
***************************************************************************************************************************/
/*------------------------------------------------------------------------
    File        : FileTools
    Purpose     : Common static utilities for common file operations
    Description :
    Author(s)   : Dustin Grau
    Created     : Mon Jul 20 11:41:45 EDT 2026
    Notes       :
------------------------------------------------------------------------*/

block-level on error undo, throw.

// Define the name of the class package for this application.
&GLOBAL-DEFINE CLASS_PACKAGE OpenEdge.LoadSuite

using {&CLASS_PACKAGE}.Common.Util.FileTools.
using OpenEdge.Core.StringConstant.

class {&CLASS_PACKAGE}.Common.Util.FileTools
    use-widget-pool
    final
    :

    var static character CatalinaBase = ?. // Store once derived (not subject to change at runtime).

    /**
     * Return the CATALINA_BASE environment variable WITHOUT a trailing "/".
     */
    method public static character GetCatalinaBase ( ):
        if CatalinaBase eq ? then do:
            CatalinaBase = right-trim(FileTools:GetFullPathname(trim(os-getenv("CATALINA_BASE":u))), "/":u).
            if CatalinaBase eq ? then
                CatalinaBase = "".
        end. // unset value

        return CatalinaBase.
    end method. // GetCatalinaBase

    var static character CurrentAppName = ?. // Store once derived (not subject to change at runtime).

    /**
     * Return the current ABL Application name.
     */
    method public static character GetCurrentAppName ( ):
        var character cBase = "", cEntry = "", cPath = "".
        var integer iCount = 0, ix = 0, iPos = 0.

        if CurrentAppName eq ? then do:
            assign
                cBase  = FileTools:GetCatalinaBase()
                iCount = num-entries(propath, ";":u)
                .

            PROPATHLOOP:
            do ix = 1 to iCount:
                assign cEntry = trim(right-trim(replace(entry(ix, propath, ";":u), StringConstant:BACKSLASH, "/":u), "/":u)).
                if (cBase gt "":u) eq true and not (cEntry begins cBase) then next PROPATHLOOP.
                assign iPos = index(cEntry, "/ablapps/":u).
                if iPos eq 0 then next PROPATHLOOP.

                // Extract the segment immediately after "/ablapps/"
                assign
                    cPath          = substring(cEntry, iPos + length("/ablapps/":u))
                    CurrentAppName = entry(1, cPath, "/":u)
                    .
                leave PROPATHLOOP.
            end.

            if CurrentAppName eq ? then
                assign CurrentAppName = "".
        end. // unset value

        return CurrentAppName.
    end method.

    /**
     * Get the full pathname of a file or directory
     * Will return with "/" as the directory separator
     * Directories are returned with a trailing "/"
     */
    method public static character GetFullPathname ( input pcPath as character ):
        var character cReturn.

        file-info:filename = pcPath.
        assign cReturn = right-trim(replace(file-info:full-pathname, StringConstant:BACKSLASH, "/":u), "/":u).

        if cReturn eq ? then
            undo, throw new Progress.Lang.AppError(substitute("Unable to resolve path '&1'":u, pcPath), 0).

        if cReturn ne ? and
            index(file-info:file-type, "D":u) ne 0 then
            assign cReturn = cReturn + "/":u.

        return cReturn.
    end method. // GetFullPathname

end class.
