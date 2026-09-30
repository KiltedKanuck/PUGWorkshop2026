/**************************************************************************************************************************
Copyright (c) 2026 by Progress Software Corporation and/or one of its subsidiaries or affiliates. All rights reserved.
***************************************************************************************************************************/
/*------------------------------------------------------------------------
    File        : DOHParams
    Purpose     : Distinct parameters for the DOH Event Handler
    Description :
    Author(s)   : Dustin Grau (dgrau)
    Created     : Mon Jul 20 09:56:47 EDT 2026
    Notes       : Used to pass parameters to the DOHEventHandler instance
--------------------------------------------------------------------------*/

block-level on error undo, throw.

// Define the name of the class package for this application.
&GLOBAL-DEFINE CLASS_PACKAGE OpenEdge.LoadSuite

using {&CLASS_PACKAGE}.Common.Util.FileTools.
using OpenEdge.Core.StringConstant.

class {&CLASS_PACKAGE}.Handler.DOHParams
    use-widget-pool
    final
:

    /**
     * Returns true when this ABL Application's name appears in the
     * CONTEXT_MANAGED_ABLAPPS environment variable (comma-delimited list).
     * Defaults to ? (unknown); computed from env var on first access unless
     * explicitly set by the caller before passing to DOHEventHandler.
     */
    define public property UseContextManager as logical initial ? no-undo
        get():
            var character cAppList = trim(os-getenv("CONTEXT_MANAGED_ABLAPPS":u)).
            if UseContextManager eq ? then do:
                if (cAppList gt "":u) eq true and (FileTools:GetCurrentAppName() gt "":u) eq true then
                    UseContextManager = can-do(cAppList, FileTools:GetCurrentAppName()).
                else
                    UseContextManager = false. // No app list or no current app name.
            end.

            return UseContextManager.
        end get.
        set.

    /**
     * Determines whether to use the original context logic from the customer application code
     * as opposed to an optimized version of that logic.
     * Reads the USE_ORIGINAL_CONTEXT_LOGIC environment variable; returns true on truthy values.
     */
    define public property UseOriginalContextLogic as logical initial ? no-undo
        get():
            if UseOriginalContextLogic eq ? then
                UseOriginalContextLogic = can-do("true,yes,1":u, trim(os-getenv("USE_ORIGINAL_CONTEXT_LOGIC":u))) eq true.

            return UseOriginalContextLogic.
        end get.
        set.

    /**
     * Determines whether to explicitly delete the user context object at the end of each request,
     * triggering its destructor, rather than simply dereferencing the object variable.
     * Reads the USE_EXPLICIT_CONTEXT_DELETE environment variable; returns true on truthy values.
     */
    define public property UseExplicitContextDelete as logical initial ? no-undo
        get():
            if UseExplicitContextDelete eq ? then
                UseExplicitContextDelete = can-do("true,yes,1":u, trim(os-getenv("USE_EXPLICIT_CONTEXT_DELETE":u))) eq true.

            return UseExplicitContextDelete.
        end get.
        set.

end class.