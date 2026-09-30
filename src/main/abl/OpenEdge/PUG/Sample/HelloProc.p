/**************************************************************************************************************************
Copyright (c) 2026 by Progress Software Corporation and/or one of its subsidiaries or affiliates. All rights reserved.
***************************************************************************************************************************/
/*------------------------------------------------------------------------
    File        : HelloProc
    Purpose     : Sample procedure code for various sample endpoints
    Description :
    Author(s)   : Dustin Grau
    Created     : Tue Jun 23 07:12:00 EDT 2026
    Notes       :
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

/* Used for testing persistent procedures. */
define variable cUser as character no-undo.

/* Used for session-managed APSV connections. */
procedure setHelloUser:
    define input parameter toWhom as character no-undo.

    assign cUser = toWhom.
end procedure.

/* Used for session-managed APSV connections. */
procedure sayHelloStoredUser:
    define output parameter greeting as character no-undo.

    assign greeting = substitute("Hello &1", cUser).
end procedure.

procedure sayHello:
    define input  parameter toWhom   as character no-undo.
    define output parameter greeting as character no-undo.

    assign greeting = substitute("Hello &1", toWhom).
end procedure.

