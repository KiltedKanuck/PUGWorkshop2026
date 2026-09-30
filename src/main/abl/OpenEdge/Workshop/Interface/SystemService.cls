/**************************************************************************************************************************
Copyright (c) 2026 by Progress Software Corporation and/or one of its subsidiaries or affiliates. All rights reserved.
***************************************************************************************************************************/
/*------------------------------------------------------------------------
    File        : SystemService
    Purpose     : Provide information about system-level behavior & status
    Description :
    Author(s)   : Dustin Grau
    Created     : Thu Jul 09 09:00:00 EDT 2026
    Notes       :

    DOH Mapping: system.map
------------------------------------------------------------------------*/

block-level on error undo, throw.

// Define the name of the class package for this application.
&GLOBAL-DEFINE CLASS_PACKAGE OpenEdge.Workshop

using {&CLASS_PACKAGE}.Common.Util.AppConstants.
using {&CLASS_PACKAGE}.Common.Util.FileTools.
using {&CLASS_PACKAGE}.System.DatabaseStats.
using OpenEdge.Logging.ILogWriter.
using OpenEdge.Logging.LoggerBuilder.
using Progress.Json.ObjectModel.JsonObject.

class {&CLASS_PACKAGE}.Interface.SystemService
    use-widget-pool
    final
    :

    /* Access the service-level logging manager. */
    define protected property oLogger as ILogWriter no-undo
        get():
            if not valid-object(oLogger) then
                assign oLogger = LoggerBuilder:GetLogger(this-object:getClass()).
            return oLogger.
        end get.
        private set.

    /* Cached PASOE connection parameters — static so files are read only once per session. */
    define private static property cConnScheme   as character no-undo get. set.
    define private static property cConnUser     as character no-undo get. set.
    define private static property cConnPassword as character no-undo get. set.
    define private static property iConnPort     as integer   no-undo get. set.
    define private static property cConnAblApp   as character no-undo get. set.

    /** ***** Private Helpers ***** */

    /**
        Reads $CATALINA_BASE/install.properties and extracts management
        credentials and the ABL application name.

        @param character pcCatalinaBase Normalized CATALINA_BASE path (no trailing slash)
        @param character pcUser         [OUTPUT] Value of tomcat.management.user
        @param character pcPassword     [OUTPUT] Value of tomcat.management.code
        @param character pcAblApp       [OUTPUT] Value of primary.ablapp.name
      */
    method private void ReadInstallProperties ( output pcUser     as character,
                                                output pcPassword as character,
                                                output pcAblApp   as character ):
        var character cFilePath, cLine.
        var integer iLine, iLines.
        var longchar lcFile.

        file-info:file-name = substitute("&1/install.properties":u, FileTools:GetCatalinaBase()).
        assign cFilePath = file-info:full-pathname.
        if cFilePath eq ? then return.

        copy-lob from file cFilePath to lcFile no-error.
        assign iLines = num-entries(lcFile, "~n":u).
        do iLine = 1 to iLines:
            assign cLine = trim(entry(iLine, lcFile, "~n":u)).
            if cLine begins "#":u or index(cLine, "=":u) eq 0 then next.
            case true:
                when cLine begins "tomcat.management.user=":u then
                    assign pcUser     = trim(entry(2, cLine, "=":u)).
                when cLine begins "tomcat.management.code=":u then
                    assign pcPassword = trim(substring(cLine, index(cLine, "=":u) + 1)).
                when cLine begins "primary.ablapp.name=":u then
                    assign pcAblApp   = trim(entry(2, cLine, "=":u)).
            end case.
        end.
    end method. /* ReadInstallProperties */

    /**
        Reads $CATALINA_BASE/conf/catalina.properties and extracts the
        configured HTTP and HTTPS listener ports.

        @param character pcCatalinaBase Normalized CATALINA_BASE path (no trailing slash)
        @param integer   piHttpPort     [OUTPUT] Value of psc.as.http.port  (0 if absent)
        @param integer   piHttpsPort    [OUTPUT] Value of psc.as.https.port (0 if absent)
      */
    method private void ReadCatalinaProperties ( output piHttpPort  as integer,
                                                 output piHttpsPort as integer ):
        var character cFilePath, cLine.
        var integer iLine, iLines.
        var longchar lcFile.

        file-info:file-name = substitute("&1/conf/catalina.properties":u, FileTools:GetCatalinaBase()).
        assign cFilePath = file-info:full-pathname.
        if cFilePath eq ? then return.

        copy-lob from file cFilePath to lcFile no-error.
        assign iLines = num-entries(lcFile, "~n":u).
        do iLine = 1 to iLines:
            assign cLine = trim(entry(iLine, lcFile, "~n":u)).
            case true:
                when cLine begins "psc.as.http.port=":u  then
                    assign piHttpPort  = integer(trim(entry(2, cLine, "=":u))).
                when cLine begins "psc.as.https.port=":u then
                    assign piHttpsPort = integer(trim(entry(2, cLine, "=":u))).
            end case.
        end.
    end method. /* ReadCatalinaProperties */

    /**
        Reads CATALINA_BASE property files once and caches the results in static properties.
        Subsequent calls return immediately when iConnPort is already set.
      */
    method private void LoadConnectionProperties ():
        var character cUser, cPassword, cAblApp.
        var integer iHttpPort, iHttpsPort.

        if iConnPort gt 0 then return. // Already loaded.

        this-object:ReadInstallProperties(output cUser, output cPassword, output cAblApp).
        this-object:ReadCatalinaProperties(output iHttpPort, output iHttpsPort).

        if iHttpPort gt 0 then
            assign iConnPort = iHttpPort.
        else if iHttpsPort gt 0 then
            assign
                iConnPort   = iHttpsPort
                cConnScheme = "https":u
                .

        if (cUser gt "":u) ne true or (cPassword gt "":u) ne true or iConnPort eq 0 then
            undo, throw new Progress.Lang.AppError("Unable to determine PASOE connection parameters from install.properties/catalina.properties.":u, 0).

        assign
            cConnScheme   = (if cConnScheme gt "":u then cConnScheme else "http":u)
            cConnUser     = cUser
            cConnPassword = cPassword
            cConnAblApp   = (if (cAblApp gt "":u) then cAblApp else "DevSuite":u)
            .
    end method. /* LoadConnectionProperties */

    /** ***** Database Endpoints ***** */

    /**
        Returns all connected databases keyed by logical name, each with
        physical name, database type, and connection index.
        Exposed as GET /system/database/list

        @param JsonObject poDatabases [OUTPUT] Object keyed by ldbname; values contain index, params, physicalName, etc.
      */
    method public void GetDatabaseList ( output poDatabases as JsonObject ):
        var JsonObject oDbEntry.
        var character cRestrictions.
        var integer ix.

        assign poDatabases = new JsonObject().

        do ix = 1 to num-dbs:
            assign
                cRestrictions = dbrestrictions(ix)
                oDbEntry      = new JsonObject()
                .
            oDbEntry:Add("index":u,         ix).
            oDbEntry:Add("physicalName":u,  pdbname(ix)).
            oDbEntry:Add("readOnly":u,      lookup("READ-ONLY":u, cRestrictions) gt 0).
            oDbEntry:Add("runtimeParams":u, dbparam(ix)).
            oDbEntry:Add("startupParams":u, AppConstants:DatabaseParams).
            poDatabases:Add(ldbname(ix), oDbEntry).
        end.
    end method. /* GetDatabaseList */

    /**
        Returns useful runtime statistics at a moment in time for a single connected database sourced
        from OpenEdge Virtual System Tables (VSTs). See DatabaseStats.cls for implementation details.
        Exposed as GET /system/database/stats/{ldbname}

        @param character pcDatabaseName [INPUT]  Logical name of the database to retrieve stats for
        @param JsonObject poStatistics  [OUTPUT] Statistics object containing transactions, bufferCache, locks, and connections
      */
    method public void GetDatabaseStats ( input  pcDatabaseName as character,
                                          output poStatistics   as JsonObject ):
        if (pcDatabaseName gt "") ne true then
            undo, throw new Progress.Lang.AppError("A database name must be specified.":u, 0).

        if not connected(pcDatabaseName) then
            undo, throw new Progress.Lang.AppError(substitute("Database '&1' is not connected.":u, pcDatabaseName), 0).

        create alias statsdb for database value(pcDatabaseName) no-error.
        if error-status:error then
            undo, throw new Progress.Lang.AppError(substitute("Unable to create statsdb alias for database '&1': &2":u,
                                                              pcDatabaseName, error-status:get-message(1)), 0).

        do on error undo, throw:
            define variable oStats as DatabaseStats no-undo.
            assign oStats = new DatabaseStats().
            assign poStatistics = oStats:GetAllStats(pcDatabaseName).

            catch err as Progress.Lang.Error:
                oLogger:Error(substitute("Unable to retrieve database statistics for '&1': &2":u, pcDatabaseName, err:GetMessage(1)), err).
                undo, throw err.
            end.
            finally:
                if valid-object(oStats) then
                    delete object oStats.
            end finally.
        end.

        finally:
            delete alias statsdb. // Remove the database alias.

            if not valid-object(poStatistics) then
                assign poStatistics = new JsonObject().
        end finally.
    end method. /* GetDatabaseStats */

    /** ***** PASOE Endpoints ***** */

    /**
        Runs ServerStatus.p with the PASOE connection parameters read from
        CATALINA_BASE and returns the formatted status report as plain text.
        Exposed as GET /system/pasoe/report

        @param OpenEdge.Core.String poOutput [OUTPUT] Contains the report text
      */
    method public void GetServerReport ( output poOutput as OpenEdge.Core.String ):
        this-object:LoadConnectionProperties().

        run OpenEdge/Workshop/System/ServerStatus.p ( input  cConnScheme,
                                                       input  "127.0.0.1":u,
                                                       input  iConnPort,
                                                       input  cConnUser,
                                                       input  cConnPassword,
                                                       input  cConnAblApp,
                                                       input  "text":u,
                                                       output poOutput ).
    end method. /* GetServerReport */

    /**
        Runs ServerStatus.p with the PASOE connection parameters read from
        CATALINA_BASE and returns the raw server status data as JSON.
        Exposed as GET /system/pasoe/status

        @param OpenEdge.Core.String poOutput [OUTPUT] Contains the status JSON
      */
    method public void GetServerStatus ( output poOutput as OpenEdge.Core.String ):
        this-object:LoadConnectionProperties().

        run OpenEdge/Workshop/System/ServerStatus.p ( input  cConnScheme,
                                                       input  "127.0.0.1":u,
                                                       input  iConnPort,
                                                       input  cConnUser,
                                                       input  cConnPassword,
                                                       input  cConnAblApp,
                                                       input  "json":u,
                                                       output poOutput ).
    end method. /* GetServerStatus */

end class.
