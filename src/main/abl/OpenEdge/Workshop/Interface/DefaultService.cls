/**************************************************************************************************************************
Copyright (c) 2026 by Progress Software Corporation and/or one of its subsidiaries or affiliates. All rights reserved.
***************************************************************************************************************************/
/*------------------------------------------------------------------------
    File        : DefaultService
    Purpose     : Default implementation of a service
    Description :
    Author(s)   : Dustin Grau
    Created     : Tue Jul 16 11:34:04 EDT 2024
    Notes       :

    DOH Mapping: default.map
------------------------------------------------------------------------*/

block-level on error undo, throw.

&GLOBAL-DEFINE CLASS_PACKAGE OpenEdge.Workshop

using {&CLASS_PACKAGE}.Common.Util.FileTools.

class {&CLASS_PACKAGE}.Interface.DefaultService
    use-widget-pool
    final
    :

    method public void SayHello ( output pcMessage as character ):
        define variable hProc as handle no-undo.

        run OpenEdge/Workshop/Sample/HelloProc persistent set hProc.
        run sayHello in hProc ("World", output pcMessage).

        delete object hProc.
    end method.

end class.