/**************************************************************************************************************************
Copyright (c) 2026 by Progress Software Corporation and/or one of its subsidiaries or affiliates. All rights reserved.
***************************************************************************************************************************/
/*------------------------------------------------------------------------
    File        : DatabaseConnect.p
    Purpose     : Handle database connection logic
    Description :
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Wed Apr 22 14:35:17 EDT 2026
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

// Define the name of the class package for this application.
&GLOBAL-DEFINE CLASS_PACKAGE OpenEdge.Workshop

// Application-Specific Classes
using {&CLASS_PACKAGE}.Common.Util.AppConstants.

// General Supporting Classes
using OpenEdge.Core.Folder.
using OpenEdge.Core.Json.JsonPropertyHelper.
using OpenEdge.Core.StringConstant.
using Progress.Json.ObjectModel.JsonDataType.
using Progress.Lang.AppError.

// Expect a single parameter as a shared logger instance.
define input parameter oLogger as OpenEdge.Logging.ILogWriter no-undo.

// Set some limits on retrying the DB connection.
var integer iDBRetry = 10, iDBWait = 1, iLoop = 0, iDBPortNumber = 0.
var character cDBDirectory = "", cDBPhysicalName = "", cDBFullPath = "", cDBHostname = "",
              cDBConnection = "", cDBUser = "", cDBPass = "", cCatalinaBase = "".
var Folder oFolder.

// Create a local variable for the CATALINA_BASE path which should be known to the PASOE instance.
assign cCatalinaBase = right-trim(replace(os-getenv("CATALINA_BASE":u), StringConstant:BACKSLASH, "/":u), "/":u).

// Create a new Folder object for the CATALINA_BASE location.
// We'll use this to confirm the true path, which on Windows may have used DOS 8.3 names.
assign oFolder = new Folder(cCatalinaBase).
if oFolder:AbsolutePath() gt "" and cCatalinaBase ne oFolder:AbsolutePath() then
    assign cCatalinaBase = oFolder:AbsolutePath().
oLogger:Debug(substitute("Using CATALINA_BASE: &1":u, cCatalinaBase)).

// If startup params are given, and look like JSON, then parse the value as a JSON object.
if (AppConstants:DatabaseParams gt "") eq true and
    AppConstants:DatabaseParams begins "~{":u then do on error undo, throw:
    define variable oParser  as Progress.Json.ObjectModel.ObjectModelParser no-undo.
    define variable oStartup as Progress.Json.ObjectModel.JsonObject        no-undo.

    /* Parse the params as JSON. */
    assign oParser = new Progress.Json.ObjectModel.ObjectModelParser().
    assign oStartup = cast(oParser:Parse(AppConstants:DatabaseParams),
                            Progress.Json.ObjectModel.JsonObject).

    if not valid-object(oStartup) then
        undo, throw new AppError("Invalid JSON object from startup parameters":u, 0).
    else do:
        if JsonPropertyHelper:HasTypedProperty(oStartup, "dbPath":u, JsonDataType:String) then
            assign cDBDirectory = replace(oStartup:GetCharacter("dbPath":u), StringConstant:BACKSLASH, "/":u).

        if JsonPropertyHelper:HasTypedProperty(oStartup, "dbName":u, JsonDataType:String) then
            assign cDBPhysicalName = oStartup:GetCharacter("dbName":u).

        if JsonPropertyHelper:HasTypedProperty(oStartup, "dbHost":u, JsonDataType:String) then
            assign cDBHostname = oStartup:GetCharacter("dbHost":u).

        if JsonPropertyHelper:HasTypedProperty(oStartup, "dbPort":u, JsonDataType:Number) then
            assign iDBPortNumber = oStartup:GetInteger("dbPort":u).

        if JsonPropertyHelper:HasTypedProperty(oStartup, "dbUser":u, JsonDataType:String) then
            assign cDBUser = oStartup:GetCharacter("dbUser":u).

        if JsonPropertyHelper:HasTypedProperty(oStartup, "dbPass":u, JsonDataType:String) then
            assign cDBPass = oStartup:GetCharacter("dbPass":u).
    end.

    catch err as Progress.Lang.Error:
        oLogger:Error("Error parsing startup parameter data":u, err).
    end catch.
    finally:
        delete object oParser  no-error.
        delete object oStartup no-error.
    end finally.
end. // AppConstants:DatabaseParams

// If given a distinct host and port use that for the connection to a networked database.
if (cDBPhysicalName gt "") eq true and (cDBHostname gt "") eq true and (iDBPortNumber gt 0) then do:
    assign cDBConnection = substitute('-db &1 -H &2 -S &3':u, cDBPhysicalName, cDBHostname, iDBPortNumber).
end.
else if (cDBDirectory gt "") eq true and (cDBPhysicalName gt "") eq true then do:
    assign // Otherwise fall back to a physical database at a given path.
        cDBDirectory  = replace(cDBDirectory, "CATALINA_BASE":u, cCatalinaBase)
        cDBFullPath   = substitute("&1/&2":u, cDBDirectory, cDBPhysicalName)
        cDBConnection = substitute("-db &1":u, quoter(cDBFullPath))
        .
end.

// If given a user and/or password, append those to the connection string.
if (cDBConnection gt "") eq true and (cDBUser gt "") eq true then
    assign cDBConnection = substitute('&1 -u &2':u, cDBConnection, cDBUser).
if (cDBConnection gt "") eq true and (cDBPass gt "") eq true then
    assign cDBConnection = substitute('&1 -p &2':u, cDBConnection, cDBPass).

if (cDBConnection gt "") eq true then
CONNECTBLK:
do iLoop = 1 to iDBRetry:
    // Report on the connection attempt, but hide any user password when present.
    oLogger:Info(substitute("Dynamically Connecting to Database: &1 [Attempt #&2]":u,
                            if (cDBPass gt "") eq true
                            then replace(cDBConnection, substitute("-p &1":u, cDBPass), "-p ***":u)
                            else cDBConnection, iLoop)).

    connect value(cDBConnection) no-error. // Attempt to connect to the database.

    if error-status:error then do:
        // Report on any error raised from the connection attempt.
        if connected(cDBPhysicalName) then
            oLogger:Warn(substitute("Database connection succeeded with a warning: &1":u, error-status:get-message(1))).
        else
            oLogger:Error(substitute("Database connection failed with an error: &1":u, error-status:get-message(1))).

        error-status:error = false. // Always clear the error status.

        if not connected(cDBPhysicalName) then
            pause iDBWait no-message. // Wait briefly before retrying.
    end.

    if connected(cDBPhysicalName) then leave CONNECTBLK. // Leave if connected.
end.

if num-dbs eq 0 then
    oLogger:Fatal("No Database Connected!":u).
else if num-dbs eq 1 then
    oLogger:Info(substitute("Connected to Database: &1":u, ldbname(1))).
else
    oLogger:Info(substitute("Connected Database Count: &1":u, num-dbs)).

catch err as Progress.Lang.Error:
    oLogger:Error("Error creating database connection":u, err).
    if session:error-stack-trace then
        oLogger:Error(substitute("Database Connection CallStack:~n&1":u, err:CallStack)).
end catch.
finally:
    delete object oFolder no-error.
end finally.