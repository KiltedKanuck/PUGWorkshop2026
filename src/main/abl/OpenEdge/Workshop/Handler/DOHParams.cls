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
&GLOBAL-DEFINE CLASS_PACKAGE OpenEdge.Workshop

using {&CLASS_PACKAGE}.Common.Util.FileTools.
using OpenEdge.Core.StringConstant.

class {&CLASS_PACKAGE}.Handler.DOHParams
    use-widget-pool
    final
:

end class.