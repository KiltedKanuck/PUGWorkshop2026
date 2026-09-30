/**************************************************************************************************************************
Copyright (c) 2026 by Progress Software Corporation and/or one of its subsidiaries or affiliates. All rights reserved.
***************************************************************************************************************************/
/*------------------------------------------------------------------------
    File        : BasicService
    Purpose     : Provide common methods for API service classes
    Description :
    Author(s)   : Dustin Grau
    Created     : Thu Jan 30 08:15:28 EST 2025
    Notes       :
------------------------------------------------------------------------*/

block-level on error undo, throw.

// Define the name of the class package for this application.
&GLOBAL-DEFINE CLASS_PACKAGE OpenEdge.LoadSuite

class {&CLASS_PACKAGE}.Interface.BasicService
    implements {&CLASS_PACKAGE}.Interface.IStandardService
    abstract
:

end class.