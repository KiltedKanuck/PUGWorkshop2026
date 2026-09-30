/**************************************************************************************************************************
Copyright (c) 2026 by Progress Software Corporation and/or one of its subsidiaries or affiliates. All rights reserved.
***************************************************************************************************************************/
/*------------------------------------------------------------------------
   File        : AppConstants
   Purpose     : Common strings used throughout the application
   Description :
   Author(s)   : dugrau
   Created     : Tue Mar 17 08:38:22 EST 2026
   Notes       :
 ----------------------------------------------------------------------*/

block-level on error undo, throw.

// Define the name of the class package for this application.
&GLOBAL-DEFINE CLASS_PACKAGE OpenEdge.Workshop

class {&CLASS_PACKAGE}.Common.Util.AppConstants:

    // Keep track of database connection parameters
    define static property DatabaseParams as character no-undo initial "":u get. set.

end class.