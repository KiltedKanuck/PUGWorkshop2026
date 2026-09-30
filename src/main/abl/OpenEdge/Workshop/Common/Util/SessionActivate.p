/**************************************************************************************************************************
Copyright (c) 2026 by Progress Software Corporation and/or one of its subsidiaries or affiliates. All rights reserved.
***************************************************************************************************************************/
/*------------------------------------------------------------------------
    File        : SessionActivate.p
    Purpose     : Run any common logic for a request
    Description :
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Tue Mar 17 08:36:17 EDT 2026
    Notes       : PAS: Assign as sessionActivateProc in openedge.properties
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

// Define the name of the class package for this application.
&GLOBAL-DEFINE CLASS_PACKAGE OpenEdge.Workshop

// General Supporting Classes
using OpenEdge.Logging.ILogWriter.
using OpenEdge.Logging.LoggerBuilder.

// Create a logger for startup actions.
var ILogWriter oLogger = LoggerBuilder:GetLogger("ActivateLogger":u).

// Set up a custom log file if not in an MSAS environment (eg. ABLUnit).
if session:client-type eq "4GLCLIENT":u then do:
    log-manager:logfile-name = session:temp-directory + "sessionActivate.log":u.
end. /* session:client-type */

/* ***************************  Main Block  *************************** */

session:timezone = ?. // Force the server to work without an explicit timezone.

// If the session somehow does not have a database, attempt to connect now.
if num-dbs eq 0 then do on error undo, throw:
    run OpenEdge/Workshop/Common/Util/DatabaseConnect.p (input oLogger).
end. // num-dbs eq 0

catch err as Progress.Lang.Error:
    oLogger:Error("Session Activation Error":u, err).
    if session:error-stack-trace then
        oLogger:Error(substitute("Session Activation CallStack:~n&1":u, err:CallStack)).
end catch.