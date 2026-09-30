/**************************************************************************************************************************
Copyright (c) 2026 by Progress Software Corporation and/or one of its subsidiaries or affiliates. All rights reserved.
***************************************************************************************************************************/
/*------------------------------------------------------------------------
    File        : SessionStartupp
    Purpose     : Run any "bootloader" type processes for each session
    Description :
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Tue Mar 17 08:36:17 EDT 2026
    Notes       : PAS: Assign as sessionStartupProc in openedge.properties
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

// Define the name of the class package for this application.
&GLOBAL-DEFINE CLASS_PACKAGE OpenEdge.Workshop

// Application-Specific Classes
using {&CLASS_PACKAGE}.Common.Util.AppConstants.
using {&CLASS_PACKAGE}.Handler.DOHEventHandler.
using {&CLASS_PACKAGE}.Handler.DOHParams.

// General Supporting Classes
using OpenEdge.Logging.ILogWriter.
using OpenEdge.Logging.LoggerBuilder.

// Standard input parameter as set via sessionStartupProcParam.
define input parameter startup-data as character no-undo.

// Create a logger for startup actions.
var ILogWriter oLogger = LoggerBuilder:GetLogger("StartupLogger":u).

// Create a parameter object for the DOHEventHandler.
var DOHParams oDOHParams = new DOHParams().

// Set up a custom log file if not in an MSAS environment (eg. ABLUnit).
if session:client-type eq "4GLCLIENT":u then do:
    log-manager:logfile-name = session:temp-directory + "sessionStartup.log":u.
end. // session:client-type

/* ***************************  Main Block  *************************** */

session:timezone = ?. // Force the server to work without an explicit timezone.

oLogger:Debug(substitute("Session Startup Parameters: [&1]":u, startup-data)).
oLogger:Info(substitute("Internal Codepage: &1":u, session:cpinternal)). // Expected: UTF-8
oLogger:Info(substitute("  Stream Codepage: &1":u, session:cpstream)).   // Expected: UTF-8
oLogger:Info(substitute(" Current Timezone: &1":u, session:timezone)).   // Expected: ?

if (startup-data gt "") eq true then do:
    // Pass through session startup params for storing with this ABLSession.
    AppConstants:DatabaseParams = startup-data.
end.

/**
 * Create a persistent handler for OpenEdge.Web.DataObject.DataObjectHandler events.
 * This defines overrides to the default DOH class events and provides integration
 * points for each client request. Additionally, starting the class will subscribe
 * to the necessary events and begin loading the necessary registries ahead of any
 * requests. This greatly reduces the "time to first data" on the initial request.
 */
new DOHEventHandler(oDOHParams).

catch err as Progress.Lang.Error:
    oLogger:Error("Session Startup Error":u, err).
    if session:error-stack-trace then
        oLogger:Error(substitute("Session Startup CallStack:~n&1":u, err:CallStack)).
end catch.
