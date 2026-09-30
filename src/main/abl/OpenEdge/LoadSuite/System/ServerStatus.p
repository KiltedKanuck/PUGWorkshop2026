/**************************************************************************
Copyright (c) 2026 by Progress Software Corporation. All rights reserved.
**************************************************************************/
/*------------------------------------------------------------------------
    File        : ServerStatus
    Purpose     : Returns comprehensive PASOE server status via OEManager
    Description :
    Author(s)   : Dustin Grau
    Created     : Thu Jul 16 11:50:10 EDT 2026
    Notes       : Based on the getStatus.p in ServerAdmin
------------------------------------------------------------------------*/

using OpenEdge.ApplicationServer.Util.OEManagerConnection.
using OpenEdge.ApplicationServer.Util.OEManagerEndpoint.
using OpenEdge.Core.Json.JsonPropertyHelper.
using OpenEdge.Core.JsonDataTypeEnum.
using OpenEdge.Core.Collections.StringStringMap.
using OpenEdge.Core.SemanticVersion.
using OpenEdge.Core.String.
using OpenEdge.Core.StringConstant.
using Progress.Json.ObjectModel.ObjectModelParser.
using Progress.Json.ObjectModel.JsonObject.
using Progress.Json.ObjectModel.JsonArray.
using Progress.Json.ObjectModel.JsonDataType.

/* Connection Parameters */
define input  parameter pcScheme   as character no-undo.
define input  parameter pcHost     as character no-undo.
define input  parameter piPort     as integer   no-undo.
define input  parameter pcUserId   as character no-undo.
define input  parameter pcPassword as character no-undo.
define input  parameter pcAblApp   as character no-undo.
define input  parameter pcFormat   as character no-undo.
define output parameter poOutput   as String    no-undo.

/* Application Globals */
define variable dOutTime   as datetime-tz     no-undo initial now.
define variable cOutDate   as character       no-undo.
define variable cOutFile   as character       no-undo.
define variable cAblApp    as character       no-undo.
define variable oClSess    as JsonArray       no-undo.
define variable oMetrics   as JsonObject      no-undo.
define variable oAgentMap  as StringStringMap no-undo.
define variable iCollect   as integer         no-undo.
define variable iTotClSess as integer         no-undo.
define variable iBaseMem   as int64           no-undo initial 85774. // Measured KB at startup of a clean session, update as needed.
define variable lHasApps   as logical         no-undo.

/* Manage the server connection to the OEManager webapp */
define variable oMgrConn as OEManagerConnection no-undo.

define temp-table ttApplication no-undo serialize-name "application":u
    field appName              as character
    field appVersion           as character
    field requestTime          as datetime-tz
    field maxAgents            as integer
    field minAgents            as integer
    field numInitialAgents     as integer
    field maxConnsPerAgent     as integer
    field maxSessPerAgent      as integer
    field idleConnTimeout      as int64
    field idleSessTimeout      as int64
    field idleAgentTimeout     as int64
    field idleResourceTimeout  as int64
    field connWaitTimeout      as int64
    field reqWaitTimeout       as int64
    field collectMetrics       as integer
    field numInitialSessions   as integer
    field minAvailableSessions as integer
    .

define temp-table ttWebApp no-undo serialize-name "webapps":u
    field appName        as character
    field webAppName     as character
    index pukWebApp as primary unique appName webAppName
    .

define temp-table ttTransport no-undo serialize-name "transports":u
    field webAppName     as character
    field transportName  as character
    field transportState as character
    index pukTransport as primary unique webAppName transportName
    .

define temp-table ttAgent no-undo serialize-name "agents":u
    field appName      as character
    field agentID      as character
    field agentPID     as integer
    field agentState   as character
    field startTime    as datetime-tz
    field runningTime  as int64
    field maxSessions  as int64 initial ?
    field ablSessions  as int64 initial ?
    field availSess    as int64 initial ?
    field openConns    as int64 initial ?
    field memoryBytes  as int64 initial ?
    field busySess     as integer
    field usedSess     as integer
    field totSess      as integer
    field totalMem     as int64
    field minActiveMem as int64
    field maxActiveMem as int64
    field sumActiveMem as int64
    field minReqComp   as int64
    field maxReqComp   as int64
    field totReqComp   as int64
    field minReqFail   as int64
    field maxReqFail   as int64
    field totReqFail   as int64
    field minReqTotal  as int64
    field maxReqTotal  as int64
    field totReqTotal  as int64
    index pukAgentStart as primary unique appName agentPID startTime
    .

define temp-table ttAgentSession no-undo serialize-name "agentSessions":u
    field agentID        as character
    field agentPID       as integer serialize-hidden
    field sessionID      as integer
    field sessionState   as character
    field startTime      as datetime-tz
    field runningTime    as int64
    field memoryBytes    as int64
    field memAtRestBytes as int64
    field memActiveBytes as int64
    field reqCompleted   as int64
    field reqFailed      as int64
    field reqTotal       as int64
    field boundSession   as character
    field boundReqID     as character
    .

define temp-table ttMetric no-undo serialize-name "sessMgrMetrics":u
    field appName               as character
    field requests              as int64
    field reads                 as int64
    field readErrors            as int64
    field minAgentReadTime      as int64
    field maxAgentReadTime      as int64
    field avgAgentReadTime      as int64
    field writes                as int64
    field writeErrors           as int64
    field concurrentConnClients as int64
    field maxConcurrentClients  as int64
    field totResvSessWaitTime   as int64
    field numResvSessWaits      as int64
    field avgResvSessWaitTime   as int64
    field maxResvSessWaitTime   as int64
    field numResvSessTimeouts   as int64
    .

define temp-table ttClientSession no-undo serialize-name "clientHttpSessions":u
    field appName          as character
    field sessionID        as character
    field requestState     as character
    field sessionState     as character
    field isBound          as logical
    field lastAccessStr    as character
    field elapsedTimeMs    as int64
    field sessionType      as character
    field adapterType      as character
    field requestID        as character
    field boundRef         as character // resolved "PID #ablSessionID" for bound sessions
    field clientName       as character
    field requestStartTime as character
    field clientElapsed    as int64
    field reqProcedure     as character
    field agentConnPID     as character
    field agentConnState   as character
    field agentAddr        as character
    field localAddr        as character
    .

define dataset dsInstance for ttApplication, ttWebApp, ttTransport, ttAgent, ttAgentSession, ttMetric, ttClientSession
    data-relation WebApp for ttApplication, ttWebApp relation-fields(appName,appName) nested foreign-key-hidden
    data-relation Transport for ttWebApp, ttTransport relation-fields(webAppName,webAppName) nested foreign-key-hidden
    data-relation AppName for ttApplication, ttAgent relation-fields(appName,appName) nested foreign-key-hidden
    data-relation AgentID for ttAgent, ttAgentSession relation-fields(agentID,agentID) nested foreign-key-hidden
    data-relation Clients for ttApplication, ttMetric relation-fields(appName,appName) nested foreign-key-hidden
    data-relation Clients for ttApplication, ttClientSession relation-fields(appName,appName) nested foreign-key-hidden
    .

function FormatLongNumber returns character ( input pcValue as character, input piWidth as integer ) forward.
function FormatMemory returns character ( input piValue as int64, input piWidth as integer ) forward.
function FormatMsTime returns character ( input piValue as int64, input piWidth as integer ) forward.
function FormatCharAsNumber returns character ( input pcValue as character, input piWidth as integer ) forward.
function FormatIntAsNumber returns character ( input piValue as int64, input piWidth as integer ) forward.
function WriteOutputLine returns logical ( input pcString as character ) forward.

/* Copy the original name, will be replaced by the case-sensitive name from the list of applications. */
assign cAblApp = pcAblApp.

/* String object (LONGCHAR Value) to be used for output. */
assign poOutput = new String().

/* Create and OEManager connection for API calls. */
assign oMgrConn = OEManagerConnection:Build(pcScheme, pcHost, piPort, pcUserId, pcPassword).
assign cOutDate = replace(iso-date(dOutTime), ":", "_").
assign oAgentMap = new StringStringMap().

/* Output the name of the program being executed. */
oMgrConn:LogCommand("RUN":u, this-procedure:name).

/* Clear all temp-tables. */
empty temp-table ttApplication.
empty temp-table ttWebApp.
empty temp-table ttTransport.
empty temp-table ttAgent.
empty temp-table ttAgentSession.
empty temp-table ttMetric.
empty temp-table ttClientSession.

/* Gather all necessary metrics. */
run GetApplications.
if lHasApps then do:
    /* Only continue if ABL Application data exists. */
    run GetProperties.
    run GetAgents.
    run GetSessions.
end.

/* Output to the appropriate format. */
do on error undo, throw:
    case pcFormat:
        when "text" then do:
            /* Begin output of status information to a dated file. */
            assign cOutFile = substitute("&1status_&2_&3.txt":u, session:temp-directory, cAblApp, cOutDate).
            output to value(cOutFile).
            run GenerateReport.
        end.
        when "json" then do:
            /* Write the internal dataset as JSON to a longchar (format, use UTF-8, without the outer object). */
            dataset dsInstance:write-json("longchar":u, poOutput:Value, true, "UTF-8":u, false, true).
        end.
    end case.

    finally:
        if pcFormat eq "text" then do:
            output close.
            copy-lob from file cOutFile to poOutput:Value no-convert no-error.
            os-delete value(cOutFile). // Remove the temporary file.
        end. // format = text
    end finally.
end.

finally:
    /* Return value expected by PCT Ant task. */
    {&_proparse_ prolint-nowarn(returnfinally)}
    return string(0).
end finally.

/* PROCEDURES / FUNCTIONS */

function FormatMemory returns character ( input piValue as int64, input piWidth as integer ):
    /* Should show up to 999,999,999 GB which is more than expected for any process. */
    return FormatLongNumber(string(round(piValue / 1024, 0)), piWidth).
end function. /* FormatMemory */

function FormatMsTime returns character ( input piValue as int64, input piWidth as integer ):
    define variable iMS   as integer   no-undo.
    define variable iSec  as integer   no-undo.
    define variable iMin  as integer   no-undo.
    define variable iHr   as integer   no-undo.
    define variable iDay  as integer   no-undo.
    define variable cTime as character no-undo.

    /* Break down millisecond time into D:H:M:S.SSS */
    assign iMS = piValue modulo 1000.
    assign piValue = (piValue - iMS) / 1000.
    assign iSec = piValue modulo 60.
    assign piValue = (piValue - iSec) / 60.
    assign iMin = piValue modulo 60.
    {&_proparse_ prolint-nowarn(overflow)}
    assign iHr = (piValue - iMin) / 60.
    {&_proparse_ prolint-nowarn(overflow)}
    assign iDay = truncate(iHr / 24, 0).
    if iDay gt 0 then
        assign iHr = iHr modulo 24.

    /**
     * Allow for days beyond 365 as we do not calculate for years (though possible, this is a highly unlikely scenario).
     * The expected format is "DD:HH:MM:SS.SSS" with a potential maximum size of "999,999:23:59:59.999" (20 characters).
     */
    assign cTime = trim(string(iDay, ">>>,>99":u)) + ":" + string(iHr, "99":u) + ":" + string(iMin, "99":u) + ":" + string(iSec, "99":u) + "." + string(iMS, "999":u).
    return fill(StringConstant:SPACE, max(0, piWidth - length(cTime, "raw":u))) + cTime.
end function. /* FormatMsTime */

function FormatLongNumber returns character ( input pcValue as character, input piWidth as integer ):
    define variable cVal as character no-undo.
    assign cVal = trim(string(int64(pcValue), "->>>,>>>,>>>,>>9":u)). // Max 16 characters.
    assign cVal = fill(StringConstant:SPACE, max(0, piWidth - length(cVal, "raw":u))) + cVal.
    return cVal.
end function. /* FormatLongNumber */

function FormatCharAsNumber returns character ( input pcValue as character, input piWidth as integer ):
    define variable cVal as character no-undo.
    assign cVal = if integer(pcValue) gt 0 then trim(string(int64(pcValue), "->>>,>>>,>>>,>>9":u)) else "0". // Max 16 characters.
    return fill(StringConstant:SPACE, max(0, piWidth - length(cVal, "raw":u))) + cVal.
end function. /* FormatCharAsNumber */

function FormatIntAsNumber returns character ( input piValue as int64, input piWidth as integer ):
    define variable cVal as character no-undo.
    assign cVal = if piValue gt 0 then trim(string(piValue, "->>>,>>>,>>>,>>9":u)) else "0". // Max 16 characters.
    return fill(StringConstant:SPACE, max(0, piWidth - length(cVal, "raw":u))) + cVal.
end function. /* FormatIntAsNumber */

function PadString returns character ( input pcString as character, input piWidth as integer ):
    return fill(StringConstant:SPACE, max(0, piWidth - length(pcString, "raw":u))) + pcString.
end function. /* PadString */

function WriteOutputLine returns logical ( input pcString as character ):
    put unformatted pcString skip.
    return true.
end function. /* WriteOutputLine */

/* Get available applications and confirm the given name as valid (and for proper case). */
procedure GetApplications:
    define variable oVersion  as SemanticVersion no-undo.
    define variable oABLApps  as JsonArray  no-undo.
    define variable oTemp     as JsonObject no-undo.
    define variable oWebApps  as JsonArray  no-undo.
    define variable oWebTrans as JsonArray  no-undo.
    define variable cVersion  as character  no-undo.
    define variable cWebApp   as character  no-undo.
    define variable iTotApps  as integer    no-undo.
    define variable iLoop     as integer    no-undo.
    define variable iLoop2    as integer    no-undo.
    define variable iLoop3    as integer    no-undo.

    /* Set a default object in case we have no applications or cannot determine the remote OE version. */
    assign oVersion = new SemanticVersion(0, 0 ,0).

    assign oABLApps = oMgrConn:GetApplications().
    assign iTotApps = oABLApps:Length.
    if iTotApps gt 0 then
    do iLoop = 1 to iTotApps:
        assign lHasApps = true. /* Important: Set this to indicate the server is alive and returned with ABL Apps. */

        assign oTemp = oABLApps:GetJsonObject(iLoop).
        if oTemp:Has("name":u) and oTemp:GetCharacter("name":u) eq cAblApp then do:
            /* This should be the proper and case-sensitive name of the ABLApp, so let's make sure we use that going forward. */
            assign cAblApp = oTemp:GetCharacter("name":u).

            /* Remember the OpenEdge version for this PAS instance, sent in the format "v#.#.# ( YYYY-MM-DD )". */
            if JsonPropertyHelper:HasTypedProperty(oTemp, "version":u, JsonDataType:String) then do:
                assign cVersion = oTemp:GetCharacter("version":u).
                assign oVersion = SemanticVersion:Parse(entry(1, replace(cVersion, "v":u, StringConstant:EMPTY), StringConstant:SPACE)).
            end.

            create ttApplication.
            assign
                ttApplication.appName     = cAblApp
                ttApplication.appVersion  = cVersion
                ttApplication.requestTime = dOutTime
                .

            if JsonPropertyHelper:HasTypedProperty(oTemp, "webapps":u, JsonDataType:Array) then do:
                assign oWebApps = oTemp:GetJsonArray("webapps":u).
                do iLoop2 = 1 to oWebApps:Length:
                    assign cWebApp = if oWebApps:GetJsonObject(iLoop2):Has("name":u)
                                     then oWebApps:GetJsonObject(iLoop2):GetCharacter("name":u)
                                     else "UNKNOWN":u.

                    create ttWebApp.
                    assign
                        ttWebApp.appName    = cAblApp
                        ttWebApp.webAppName = cWebApp.
                    release ttWebApp no-error.

                    assign oWebTrans = oWebApps:GetJsonObject(iLoop2):GetJsonArray("transports":u).
                    do iLoop3 = 1 to oWebTrans:Length:
                        create ttTransport.
                        assign
                            ttTransport.webAppName     = cWebApp
                            ttTransport.transportName  = oWebTrans:GetJsonObject(iLoop3):GetCharacter("name":u)
                            ttTransport.transportState = oWebTrans:GetJsonObject(iLoop3):GetCharacter("state":u)
                            .
                        release ttTransport no-error.
                    end. /* transports */
                end. /* webapp */
            end. /* has webapps */

            release ttApplication no-error.
        end. /* matching ABLApp */
    end. /* Application */

    catch err as Progress.Lang.Error:
        // Catch and swallow. A lack of ttApplication record will trigger the correct output later.
    end catch.
end procedure.

/* Get the configured max for ABLSessions/Connections per MSAgent, along with min/max/initial MSAgents. */
procedure GetProperties:
    define variable oSessMgrProps as JsonObject no-undo.
    define variable oAgntMgrProps as JsonObject no-undo.

    assign oSessMgrProps = oMgrConn:GetSessionManagerProperties(cAblApp).
    assign oAgntMgrProps = oMgrConn:GetAgentManagerProperties(cAblApp).

    /* Store all manager properties into the ttApplication record. */
    for first ttApplication exclusive-lock:
        if JsonPropertyHelper:HasTypedProperty(oSessMgrProps, "maxAgents":u, JsonDataType:string) then
            assign ttApplication.maxAgents = integer(oSessMgrProps:GetCharacter("maxAgents":u)).

        if JsonPropertyHelper:HasTypedProperty(oSessMgrProps, "minAgents":u, JsonDataType:string) then
            assign ttApplication.minAgents = integer(oSessMgrProps:GetCharacter("minAgents":u)).

        if JsonPropertyHelper:HasTypedProperty(oSessMgrProps, "numInitialAgents":u, JsonDataType:string) then
            assign ttApplication.numInitialAgents = integer(oSessMgrProps:GetCharacter("numInitialAgents":u)).

        if JsonPropertyHelper:HasTypedProperty(oSessMgrProps, "maxConnectionsPerAgent":u, JsonDataType:string) then
            assign ttApplication.maxConnsPerAgent = integer(oSessMgrProps:GetCharacter("maxConnectionsPerAgent":u)).

        if JsonPropertyHelper:HasTypedProperty(oSessMgrProps, "maxABLSessionsPerAgent":u, JsonDataType:string) then
            assign ttApplication.maxSessPerAgent = integer(oSessMgrProps:GetCharacter("maxABLSessionsPerAgent":u)).

        if JsonPropertyHelper:HasTypedProperty(oSessMgrProps, "idleConnectionTimeout":u, JsonDataType:string) then
            assign ttApplication.idleConnTimeout = int64(oSessMgrProps:GetCharacter("idleConnectionTimeout":u)).

        if JsonPropertyHelper:HasTypedProperty(oSessMgrProps, "idleSessionTimeout":u, JsonDataType:string) then
            assign ttApplication.idleSessTimeout = int64(oSessMgrProps:GetCharacter("idleSessionTimeout":u)).

        if JsonPropertyHelper:HasTypedProperty(oSessMgrProps, "idleAgentTimeout":u, JsonDataType:string) then
            assign ttApplication.idleAgentTimeout = int64(oSessMgrProps:GetCharacter("idleAgentTimeout":u)).

        if JsonPropertyHelper:HasTypedProperty(oSessMgrProps, "idleResourceTimeout":u, JsonDataType:string) then
            assign ttApplication.idleResourceTimeout = int64(oSessMgrProps:GetCharacter("idleResourceTimeout":u)).

        if JsonPropertyHelper:HasTypedProperty(oSessMgrProps, "connectionWaitTimeout":u, JsonDataType:string) then
            assign ttApplication.connWaitTimeout = int64(oSessMgrProps:GetCharacter("connectionWaitTimeout":u)).

        if JsonPropertyHelper:HasTypedProperty(oSessMgrProps, "requestWaitTimeout":u, JsonDataType:string) then
            assign ttApplication.reqWaitTimeout = int64(oSessMgrProps:GetCharacter("requestWaitTimeout":u)).

        if JsonPropertyHelper:HasTypedProperty(oSessMgrProps, "collectMetrics":u, JsonDataType:string) then
            assign ttApplication.collectMetrics = integer(oSessMgrProps:GetCharacter("collectMetrics":u)).

        if JsonPropertyHelper:HasTypedProperty(oAgntMgrProps, "numInitialSessions":u, JsonDataType:string) then
            assign ttApplication.numInitialSessions = integer(oAgntMgrProps:GetCharacter("numInitialSessions":u)).

        if JsonPropertyHelper:HasTypedProperty(oAgntMgrProps, "minAvailableABLSessions":u, JsonDataType:string) then
            assign ttApplication.minAvailableSessions = integer(oAgntMgrProps:GetCharacter("minAvailableABLSessions":u)).

        /* iCollect is used in GetSessions; keep synchronized with the stored property. */
        assign iCollect = ttApplication.collectMetrics.
    end. /* for first ttApplication */

    finally:
        if valid-object(oSessMgrProps) then
            delete object oSessMgrProps.

        if valid-object(oAgntMgrProps) then
            delete object oAgntMgrProps.
    end finally.
end procedure.

/* Initial URL to obtain a list of all agents for an ABL Application. */
procedure GetAgents:
    define variable iTotAgent as integer     no-undo.
    define variable iTotSess  as integer     no-undo.
    define variable iTotThrd  as integer     no-undo.
    define variable iLoop     as integer     no-undo.
    define variable iLoop2    as integer     no-undo.
    define variable iMinMem   as int64       no-undo.
    define variable dInstTime as datetime    no-undo.
    define variable dStart    as datetime    no-undo.
    define variable dTemp     as datetime-tz no-undo.
    define variable oAgents   as JsonArray   no-undo.
    define variable oAgent    as JsonObject  no-undo.
    define variable oSessions as JsonArray   no-undo.
    define variable oSessInfo as JsonObject  no-undo.
    define variable oStatHist as JsonArray   no-undo.
    define variable oTemp     as JsonObject  no-undo.
    define variable oThreads  as JsonArray   no-undo.

    /* Get metrics about the session manager which comes from the collectMetrics flag. */
    assign oMetrics = oMgrConn:GetSessionMetrics(cAblApp).
    if JsonPropertyHelper:HasTypedProperty(oMetrics, "accessTime":u, JsonDataType:String) then do:
        /* Get the server access time (should be a timestamp from the server's timezone). */
        assign dTemp = oMetrics:GetDateTimeTZ("accessTime":u).
        assign dInstTime = datetime(date(dTemp), mtime(dTemp)).

        create ttMetric.
        assign ttMetric.appName = cAblApp.

        if JsonPropertyHelper:HasTypedProperty(oMetrics, "requests":u, JsonDataType:Number) then
            assign ttMetric.requests = oMetrics:GetInt64("requests":u).

        if JsonPropertyHelper:HasTypedProperty(oMetrics, "reads":u, JsonDataType:Number) then
            assign ttMetric.reads = oMetrics:GetInt64("reads":u).

        if JsonPropertyHelper:HasTypedProperty(oMetrics, "readErrors":u, JsonDataType:Number) then
            assign ttMetric.readErrors = oMetrics:GetInt64("readErrors":u).

        if JsonPropertyHelper:HasTypedProperty(oMetrics, "minAgentReadTime":u, JsonDataType:Number) then
            assign ttMetric.minAgentReadTime = oMetrics:GetInt64("minAgentReadTime":u).

        if JsonPropertyHelper:HasTypedProperty(oMetrics, "maxAgentReadTime":u, JsonDataType:Number) then
            assign ttMetric.maxAgentReadTime = oMetrics:GetInt64("maxAgentReadTime":u).

        if JsonPropertyHelper:HasTypedProperty(oMetrics, "avgAgentReadTime":u, JsonDataType:Number) then
            assign ttMetric.avgAgentReadTime = oMetrics:GetInt64("avgAgentReadTime":u).

        if JsonPropertyHelper:HasTypedProperty(oMetrics, "writes":u, JsonDataType:Number) then
            assign ttMetric.writes = oMetrics:GetInt64("writes":u).

        if JsonPropertyHelper:HasTypedProperty(oMetrics, "writeErrors":u, JsonDataType:Number) then
            assign ttMetric.writeErrors = oMetrics:GetInt64("writeErrors":u).

        if JsonPropertyHelper:HasTypedProperty(oMetrics, "concurrentConnectedClients":u, JsonDataType:Number) then
            assign ttMetric.concurrentConnClients = oMetrics:GetInt64("concurrentConnectedClients":u).

        if JsonPropertyHelper:HasTypedProperty(oMetrics, "maxConcurrentClients":u, JsonDataType:Number) then
            assign ttMetric.maxConcurrentClients = oMetrics:GetInt64("maxConcurrentClients":u).

        if JsonPropertyHelper:HasTypedProperty(oMetrics, "totReserveABLSessionWaitTime":u, JsonDataType:Number) then
            assign ttMetric.totResvSessWaitTime = oMetrics:GetInt64("totReserveABLSessionWaitTime":u).

        if JsonPropertyHelper:HasTypedProperty(oMetrics, "numReserveABLSessionWaits":u, JsonDataType:Number) then
            assign ttMetric.numResvSessWaits = oMetrics:GetInt64("numReserveABLSessionWaits":u).

        if JsonPropertyHelper:HasTypedProperty(oMetrics, "avgReserveABLSessionWaitTime":u, JsonDataType:Number) then
            assign ttMetric.avgResvSessWaitTime = oMetrics:GetInt64("avgReserveABLSessionWaitTime":u).

        if JsonPropertyHelper:HasTypedProperty(oMetrics, "maxReserveABLSessionWaitTime":u, JsonDataType:Number) then
            assign ttMetric.maxResvSessWaitTime = oMetrics:GetInt64("maxReserveABLSessionWaitTime":u).

        if JsonPropertyHelper:HasTypedProperty(oMetrics, "numReserveABLSessionTimeouts":u, JsonDataType:Number) then
            assign ttMetric.numResvSessTimeouts = oMetrics:GetInt64("numReserveABLSessionTimeouts":u).

        release ttMetric no-error.
    end.
    else
        assign dInstTime = dOutTime.

    /* Capture all available agent info to a temp-table before we proceed. */
    assign oAgents = oMgrConn:GetAgents(cAblApp).
    assign iTotAgent = oAgents:Length.
    if iTotAgent gt 0 then
    AGENTBLK:
    do iLoop = 1 to iTotAgent on error undo, next AGENTBLK:
        oAgent = oAgents:GetJsonObject(iLoop).

        create ttAgent.
        assign
            ttAgent.appName    = cAblApp
            ttAgent.agentID    = oAgent:GetCharacter("agentId":u)
            ttAgent.agentPID   = integer(oAgent:GetCharacter("pid":u))
            ttAgent.agentState = oAgent:GetCharacter("state":u)
            .

        /* Provides a simple means of lookup later to relate agentID to PID. */
        oAgentMap:Put(ttAgent.agentID, string(ttAgent.agentPID)).

        release ttAgent no-error.
    end. /* iLoop - Agents */

    /* This data will be related to the MSAgent-sessions to denote which ones are bound. */
    assign oClSess = oMgrConn:GetClientSessions(cAblApp).
    assign iTotClSess = oClSess:Length.

    for each ttAgent exclusive-lock:
        /* We should only obtain additional status and metrics if the MSAgent is available. */
        if ttAgent.agentState eq "available":u then do:
            /* Get the dynamic value for the available sessions of this MSAgent (available only to an instance running 12.2+). */
            oSessions = oMgrConn:GetDynamicSessionLimit(cAblApp, ttAgent.agentPID).
            if oSessions:Length ge 1 and JsonPropertyHelper:HasTypedProperty(oSessions:GetJsonObject(1), "ABLOutput":u, JsonDataType:object) then do:
                oSessInfo = oSessions:GetJsonObject(1):GetJsonObject("ABLOutput":u). /* Expects an array with at least 1 element (object). */

                /* Should be the current calculated maximum # of ABL Sessions which can be started/utilized. */
                if JsonPropertyHelper:HasTypedProperty(oSessInfo, "dynmaxablsessions":u, JsonDataType:Number) then
                    assign ttAgent.maxSessions = oSessInfo:GetInt64("dynmaxablsessions":u).

                /* This should represent the total number of ABL Sessions started, not to exceed the Dynamic Max. */
                if JsonPropertyHelper:HasTypedProperty(oSessInfo, "numABLSessions":u, JsonDataType:Number) then
                    assign ttAgent.ablSessions = oSessInfo:GetInt64("numABLSessions":u).

                /* This should be the number of ABL Sessions available to execute ABL code for this MSAgent. */
                if JsonPropertyHelper:HasTypedProperty(oSessInfo, "numAvailableSessions":u, JsonDataType:Number) then
                    assign ttAgent.availSess = oSessInfo:GetInt64("numAvailableSessions":u).
            end. /* session info array length ge 1 */

            /* Get threads for this particular MSAgent. */
            assign dStart = ?. /* Clear before use. */
            assign oThreads = oMgrConn:GetAgentThreads(cAblApp, ttAgent.agentPID).
            assign
                iTotThrd          = oThreads:Length
                ttAgent.startTime = dInstTime
                .

            /* Loop through the threads to get the earliest start time; should be the agent's epoch. */
            do iLoop2 = 1 to iTotThrd:
                assign oTemp = oThreads:GetJsonObject(iLoop2).
                if JsonPropertyHelper:HasTypedProperty(oTemp, "StartTime":u, JsonDataType:String) then
                    assign ttAgent.startTime = min(ttAgent.startTime, oTemp:GetDateTimeTZ("StartTime":u)).
            end. /* iLoop2 - oThreads */

            /* Attempt to calculate the time this session has been running, though we don't have a current timestamp directly from the server. */
            assign dStart = datetime(date(ttAgent.startTime), mtime(ttAgent.startTime)) when ttAgent.startTime ne ?.
            assign ttAgent.runningTime = interval(dInstTime, dStart, "milliseconds":u) when (dInstTime ne ? and dStart ne ? and dInstTime ge dStart).

            /* Get metrics about this particular MSAgent (expects an array with at least 1 element). */
            assign oStatHist = oMgrConn:GetAgentMetrics(cAblApp, ttAgent.agentPID).
            if oStatHist:Length ge 1 then do:
                oTemp = oStatHist:GetJsonObject(1).

                if JsonPropertyHelper:HasTypedProperty(oTemp, "OpenConnections":u, JsonDataType:Number) then
                    assign ttAgent.openConns = oTemp:GetInt64("OpenConnections":u).

                if JsonPropertyHelper:HasTypedProperty(oTemp, "OverheadMemory":u, JsonDataType:Number) then
                    assign ttAgent.memoryBytes = oTemp:GetInt64("OverheadMemory":u).
            end.

            /* Get sessions and count non-idle states. */
            assign dStart = ?. /* Clear before use. */
            assign oSessions = oMgrConn:GetAgentSessions(cAblApp, ttAgent.agentPID).
            assign iTotSess  = oSessions:Length.
            do iLoop2 = 1 to iTotSess:
                create ttAgentSession.
                assign
                    ttAgentSession.agentID        = ttAgent.agentID
                    ttAgentSession.agentPID       = ttAgent.agentPID
                    ttAgentSession.sessionID      = oSessions:GetJsonObject(iLoop2):GetInteger("SessionId":u)
                    ttAgentSession.sessionState   = oSessions:GetJsonObject(iLoop2):GetCharacter("SessionState":u)
                    ttAgentSession.startTime      = oSessions:GetJsonObject(iLoop2):GetDatetimeTZ("StartTime":u)
                    ttAgentSession.memoryBytes    = oSessions:GetJsonObject(iLoop2):GetInt64("SessionMemory":u) // Potentially volatile, moment-in-time value.
                    ttAgentSession.memAtRestBytes = ttAgentSession.memoryBytes // Defaults to SessionMemory until we know otherwise.
                    ttAgentSession.memActiveBytes = ttAgentSession.memoryBytes // Defaults to SessionMemory until we know otherwise.
                    .

                // Obtain a distinct value for at-rest memory (available in 12.7+).
                if JsonPropertyHelper:HasTypedProperty(oSessions:GetJsonObject(iLoop2), "MemAtRestHighWater":u, JsonDataType:Number) then
                    ttAgentSession.memAtRestBytes = max(ttAgentSession.memAtRestBytes, oSessions:GetJsonObject(iLoop2):GetInt64("MemAtRestHighWater":u)).

                // Obtain a distinct value for peak memory (available in 12.7+).
                if JsonPropertyHelper:HasTypedProperty(oSessions:GetJsonObject(iLoop2), "MemActiveHighWater":u, JsonDataType:Number) then
                    ttAgentSession.memActiveBytes = max(ttAgentSession.memActiveBytes, oSessions:GetJsonObject(iLoop2):GetInt64("MemActiveHighWater":u)).

                if JsonPropertyHelper:HasTypedProperty(oSessions:GetJsonObject(iLoop2), "RequestsCompleted":u, JsonDataType:Number) then
                    ttAgentSession.reqCompleted = oSessions:GetJsonObject(iLoop2):GetInt64("RequestsCompleted":u).

                if JsonPropertyHelper:HasTypedProperty(oSessions:GetJsonObject(iLoop2), "RequestsFailed":u, JsonDataType:Number) then
                    ttAgentSession.reqFailed = oSessions:GetJsonObject(iLoop2):GetInt64("RequestsFailed":u).

                assign ttAgentSession.reqTotal = ttAgentSession.reqCompleted + ttAgentSession.reqFailed.

                /* Attempt to determine the most minimal (ideally: at-rest) memory value for all sessions of all agents available. */
                if iMinMem eq 0 then
                    assign iMinMem = ttAgentSession.memAtRestBytes.
                else
                    assign iMinMem = min(iMinMem, ttAgentSession.memAtRestBytes).

                /* Attempt to calculate the time this session has been running, though we don't have a current timestamp directly from the server. */
                assign dStart = datetime(date(ttAgentSession.startTime), mtime(ttAgentSession.startTime)) when ttAgentSession.startTime ne ?.
                assign ttAgentSession.runningTime = interval(dInstTime, dStart, "milliseconds":u) when (dInstTime ne ? and dStart ne ? and dInstTime ge dStart).

                if iTotClSess gt 0 then
                do iLoop = 1 to iTotClSess
                on error undo, leave:
                    assign oTemp = oClSess:GetJsonObject(iLoop).

                    if oTemp:Has("bound":u) and oTemp:GetLogical("bound":u) and
                       oTemp:GetCharacter("agentID":u) eq ttAgent.agentID and
                       integer(oTemp:GetCharacter("ablSessionID":u)) eq oSessions:GetJsonObject(iLoop2):GetInteger("SessionId":u) then
                        assign
                            ttAgentSession.boundSession = oTemp:GetCharacter("sessionID":u)
                            ttAgentSession.boundReqID   = oTemp:GetCharacter("requestID":u)
                            .
                end. /* iLoop - iTotClSess */

                release ttAgentSession no-error.
            end. /* iLoop2 - oSessions */
        end. /* agent state = available */
    end. /* for each ttAgent */

    /* iMinMem is now fully populated; compute the global baseline once before the stats pass. */
    assign iBaseMem = max(iBaseMem, iMinMem) + 1024.

    /* Compute per-agent summary statistics from the collected session data. */
    for each ttAgent exclusive-lock:
        /* totalMem seeds from overhead memory; all other summary fields default to 0 via empty temp-table. */
        assign ttAgent.totalMem = if ttAgent.memoryBytes ne ? then ttAgent.memoryBytes else 0.

        for each ttAgentSession no-lock
            where ttAgentSession.agentID eq ttAgent.agentID:
            assign
                ttAgent.totSess      = ttAgent.totSess + 1
                ttAgent.totalMem     = ttAgent.totalMem + ttAgentSession.memActiveBytes
                ttAgent.sumActiveMem = ttAgent.sumActiveMem + ttAgentSession.memActiveBytes
                ttAgent.minActiveMem = (if ttAgent.totSess eq 1 then ttAgentSession.memActiveBytes else min(ttAgent.minActiveMem, ttAgentSession.memActiveBytes))
                ttAgent.maxActiveMem = max(ttAgent.maxActiveMem, ttAgentSession.memActiveBytes)
                ttAgent.totReqComp   = ttAgent.totReqComp + ttAgentSession.reqCompleted
                ttAgent.minReqComp   = (if ttAgent.totSess eq 1 then ttAgentSession.reqCompleted else min(ttAgent.minReqComp, ttAgentSession.reqCompleted))
                ttAgent.maxReqComp   = max(ttAgent.maxReqComp, ttAgentSession.reqCompleted)
                ttAgent.totReqFail   = ttAgent.totReqFail + ttAgentSession.reqFailed
                ttAgent.minReqFail   = (if ttAgent.totSess eq 1 then ttAgentSession.reqFailed else min(ttAgent.minReqFail, ttAgentSession.reqFailed))
                ttAgent.maxReqFail   = max(ttAgent.maxReqFail, ttAgentSession.reqFailed)
                ttAgent.totReqTotal  = ttAgent.totReqTotal + ttAgentSession.reqTotal
                ttAgent.minReqTotal  = (if ttAgent.totSess eq 1 then ttAgentSession.reqTotal else min(ttAgent.minReqTotal, ttAgentSession.reqTotal))
                ttAgent.maxReqTotal  = max(ttAgent.maxReqTotal, ttAgentSession.reqTotal)
                .

            if ttAgentSession.sessionState ne "IDLE":u then
                assign ttAgent.busySess = ttAgent.busySess + 1.

            if ttAgentSession.memAtRestBytes gt iBaseMem then
                assign ttAgent.usedSess = ttAgent.usedSess + 1.
        end. /* for each ttAgentSession */

        release ttAgent no-error.
    end. /* for each ttAgent - stats */
end procedure.

/* Consults the SessionManager for a count of Client HTTP Sessions, along with stats on the Client Connections and Agent Connections. */
procedure GetSessions:
    define variable iLoop     as integer    no-undo.
    define variable oConnInfo as JsonObject no-undo.
    define variable oTemp     as JsonObject no-undo.

    /* Parse client session data from oClSess into the temp-table before any output. */
    SESSIONBLK:
    do iLoop = 1 to iTotClSess
        on error undo, next:
        assign oTemp = oClSess:GetJsonObject(iLoop).
        if not valid-object(oTemp) then next SESSIONBLK.

        create ttClientSession.
        assign
            ttClientSession.appName       = cAblApp
            ttClientSession.sessionID     = oTemp:GetCharacter("sessionID":u)
            ttClientSession.requestState  = oTemp:GetCharacter("requestState":u)
            ttClientSession.sessionState  = oTemp:GetCharacter("sessionState":u)
            ttClientSession.lastAccessStr = oTemp:GetCharacter("lastAccessStr":u)
            ttClientSession.elapsedTimeMs = oTemp:GetInt64("elapsedTimeMs":u)
            ttClientSession.sessionType   = oTemp:GetCharacter("sessionType":u)
            ttClientSession.adapterType   = oTemp:GetCharacter("adapterType":u)
            ttClientSession.requestID     = oTemp:GetCharacter("requestID":u)
            .

        if JsonPropertyHelper:HasTypedProperty(oTemp, "bound":u, JsonDataType:Boolean) then
            assign ttClientSession.isBound = oTemp:GetLogical("bound":u) eq true.

        if ttClientSession.isBound and oTemp:Has("agentID":u) and oTemp:Has("ablSessionID":u) then do:
            if oAgentMap:ContainsKey(oTemp:GetCharacter("agentID":u)) then
                assign ttClientSession.boundRef = substitute("&1 #&2":u, oAgentMap:Get(oTemp:GetCharacter("agentID":u)), oTemp:GetCharacter("ablSessionID":u)).
            else if (oTemp:GetCharacter("agentID":u) gt StringConstant:EMPTY) eq true then
                assign ttClientSession.boundRef = substitute("[PID Unknown] #&1":u, oTemp:GetCharacter("ablSessionID":u)).
        end.

        if JsonPropertyHelper:HasTypedProperty(oTemp, "clientConnInfo":u, JsonDataType:object) then do:
            assign oConnInfo = oTemp:GetJsonObject("clientConnInfo":u).
            if valid-object(oConnInfo) then
                assign
                    ttClientSession.clientName       = if oConnInfo:Has("clientName":u)       then oConnInfo:GetCharacter("clientName":u)      else "UNKNOWN":u
                    ttClientSession.requestStartTime = if oConnInfo:Has("reqStartTimeStr":u)  then oConnInfo:GetCharacter("reqStartTimeStr":u) else "UNKNOWN":u
                    ttClientSession.clientElapsed    = if oConnInfo:Has("elapsedTimeMs":u)    then oConnInfo:GetInt64("elapsedTimeMs":u)       else 0
                    ttClientSession.reqProcedure     = if oConnInfo:Has("requestProcedure":u) then oConnInfo:GetCharacter("requestProcedure":u) else StringConstant:EMPTY
                    .
        end.

        if JsonPropertyHelper:HasTypedProperty(oTemp, "agentConnInfo":u, JsonDataType:object) then do:
            assign oConnInfo = oTemp:GetJsonObject("agentConnInfo":u).
            if JsonPropertyHelper:HasTypedProperty(oConnInfo, "agentID":u, JsonDataType:string) then
                assign
                    ttClientSession.agentConnPID   = if oAgentMap:ContainsKey(oConnInfo:GetCharacter("agentID":u))
                                                     then substitute("PID &1":u, oAgentMap:Get(oConnInfo:GetCharacter("agentID":u)))
                                                     else substitute("ID &1":u, oConnInfo:GetCharacter("agentID":u))
                    ttClientSession.agentConnState = if oConnInfo:Has("state":u)     then oConnInfo:GetCharacter("state":u)     else "UNKNOWN":u
                    ttClientSession.agentAddr      = if oConnInfo:Has("agentAddr":u) then oConnInfo:GetCharacter("agentAddr":u) else "NA":u
                    ttClientSession.localAddr      = if oConnInfo:Has("localAddr":u) then oConnInfo:GetCharacter("localAddr":u) else "NA":u
                    .
        end.

        release ttClientSession no-error.

        catch err as Progress.Lang.Error:
            message substitute("Encountered error parsing Client Session &1 of &2: &3":u, iLoop, iTotClSess, err:GetMessage(1)).
            if valid-object(oConnInfo) then
                oClSess:WriteFile(substitute("&1ClientSession_&2.json":u, session:temp-directory, cOutDate), true).
        end catch.
    end. /* iLoop - parse client sessions */
end procedure.

/* Utilize all captured data to generate a text-based report. */
procedure GenerateReport:
    /* Start with some basic header information for this report. */
    WriteOutputLine(substitute("Utility Runtime: &1":u, proversion(1))).      /* Reports the OE runtime version used to execute this utility.     */
    WriteOutputLine(substitute("Report Executed: &1":u, iso-date(dOutTime))). /* Produce a timestamp relative to where utility was run.           */
    WriteOutputLine(substitute(" PASOE Instance: &1":u, oMgrConn:Instance)).  /* Reports the combined scheme, hostname, and port of the instance. */

    if not can-find(first ttApplication no-lock) then do:
        WriteOutputLine("~nNo applications available. Is the PASOE instance correctly configured and running?":u).
        return. // Nothing more that we can do here.
    end.

    /* ABL Application Information (GetProperties) */
    for first ttApplication no-lock:
        WriteOutputLine(substitute("~nABL Application Information [&1 - &2]":u, ttApplication.appName, ttApplication.appVersion)).

        for each ttWebApp no-lock
           where ttWebApp.appName eq ttApplication.appName:
            WriteOutputLine(substitute("&1: &2":u, PadString("WebApp":u, 10), ttWebApp.webAppName)).

            for each ttTransport no-lock
               where ttTransport.webAppName eq ttWebApp.webAppName:
                WriteOutputLine(substitute("&1: &2":u, PadString(ttTransport.transportName, 10), ttTransport.transportState)).
            end. /* for each ttTransport */
        end. /* for each ttWebApp */

        WriteOutputLine("~nManager Properties":u).

        /* Output manager properties for the ABL Application. */
        WriteOutputLine(substitute("&1: &2":u, PadString("Maximum Agents":u, 28), FormatIntAsNumber(ttApplication.maxAgents, 20))).
        WriteOutputLine(substitute("&1: &2":u, PadString("Minimum Agents":u, 28), FormatIntAsNumber(ttApplication.minAgents, 20))).
        WriteOutputLine(substitute("&1: &2":u, PadString("Initial Agents":u, 28), FormatIntAsNumber(ttApplication.numInitialAgents, 20))).
        WriteOutputLine(substitute("&1: &2":u, PadString("Max. Connections/Agent":u, 28), FormatIntAsNumber(ttApplication.maxConnsPerAgent, 20))).
        WriteOutputLine(substitute("&1: &2":u, PadString("Max. ABLSessions/Agent":u, 28), FormatIntAsNumber(ttApplication.maxSessPerAgent, 20))).
        WriteOutputLine(substitute("&1: &2 ms (&3)":u,
                                   PadString("Idle Connection Timeout":u, 28),
                                   FormatLongNumber(string(ttApplication.idleConnTimeout), 20),
                                   FormatMsTime(ttApplication.idleConnTimeout, 0))).
        WriteOutputLine(substitute("&1: &2 ms (&3)":u,
                                   PadString("Idle Session Timeout":u, 28),
                                   FormatLongNumber(string(ttApplication.idleSessTimeout), 20),
                                   FormatMsTime(ttApplication.idleSessTimeout, 0))).
        WriteOutputLine(substitute("&1: &2 ms (&3)":u,
                                   PadString("Idle Agent Timeout":u, 28),
                                   FormatLongNumber(string(ttApplication.idleAgentTimeout), 20),
                                   FormatMsTime(ttApplication.idleAgentTimeout, 0))).
        WriteOutputLine(substitute("&1: &2 ms (&3)":u,
                                   PadString("Idle Resource Timeout":u, 28),
                                   FormatLongNumber(string(ttApplication.idleResourceTimeout), 20),
                                   FormatMsTime(ttApplication.idleResourceTimeout, 0))).
        WriteOutputLine(substitute("&1: &2 ms (&3)":u,
                                   PadString("Connection Wait Timeout":u, 28),
                                   FormatLongNumber(string(ttApplication.connWaitTimeout), 20),
                                   FormatMsTime(ttApplication.connWaitTimeout, 0))).
        WriteOutputLine(substitute("&1: &2 ms (&3)":u,
                                   PadString("Request Wait Timeout":u, 28),
                                   FormatLongNumber(string(ttApplication.reqWaitTimeout), 20),
                                   FormatMsTime(ttApplication.reqWaitTimeout, 0))).
        WriteOutputLine(substitute("&1: &2":u, PadString("Initial Sessions/Agent":u, 28), FormatIntAsNumber(ttApplication.numInitialSessions, 20))).
        WriteOutputLine(substitute("&1: &2":u, PadString("Min. Avail. Sess/Agent":u, 28), FormatIntAsNumber(ttApplication.minAvailableSessions, 20))).
    end. /* for first ttApplication */

    /* MSAgent + ABLSession Information (GetAgents/GetSessions) */
    if not can-find(first ttAgent no-lock) then
        WriteOutputLine("~nNo MSAgents running":u).
    else do:
        for each ttAgent no-lock:
            WriteOutputLine(substitute("~n> Agent PID &1: &2":u, ttAgent.agentPID, ttAgent.agentState)).

            if ttAgent.startTime ne ? then
                WriteOutputLine(substitute("&1: &2":u, PadString("Est. Agent Lifetime":u, 24), FormatMsTime(ttAgent.runningTime, 20))).

            if ttAgent.maxSessions ne ? then
                WriteOutputLine(substitute("&1: &2":u, PadString("DynMax ABL Sessions":u, 24), FormatIntAsNumber(ttAgent.maxSessions, 16))).

            if ttAgent.ablSessions ne ? then
                WriteOutputLine(substitute("&1: &2":u, PadString("Total ABL Sessions":u, 24), FormatIntAsNumber(ttAgent.ablSessions, 16))).

            if ttAgent.availSess ne ? then
                WriteOutputLine(substitute("&1: &2":u, PadString("Avail ABL Sessions":u, 24), FormatIntAsNumber(ttAgent.availSess, 16))).

            if ttAgent.openConns ne ? then
                WriteOutputLine(substitute("&1: &2":u, PadString("Open Connections":u, 24), FormatIntAsNumber(ttAgent.openConns, 16))).

            if ttAgent.memoryBytes ne ? then
                WriteOutputLine(substitute("&1: &2 KB":u, PadString("Overhead Memory":u, 24), FormatMemory(ttAgent.memoryBytes, 16))).

            // Output a header for the session information for this agent, using space padding to align the columns.
            WriteOutputLine(substitute("~n &1 &2 &3 &4 &5 &6 &7 &8":u,
                                       PadString("SESSION ID":u, 12),
                                       PadString("STATE":u, 7),
                                       PadString("STARTED":u, 15),
                                       PadString("LIFETIME":u, 33),
                                       PadString("SESS. MEMORY":u, 28),
                                       PadString("ACTIVE MEM.":u, 22),
                                       PadString("REQUESTS":u, 17),
                                       PadString("BOUND~/ACTIVE CLIENT SESSION":u, 31))).

            for each ttAgentSession no-lock
               where ttAgentSession.agentID eq ttAgent.agentID:
                WriteOutputLine(substitute("&1    &2    &3    &4 &5 KB &6 KB &7    &8 &9":u,
                                            PadString(string(ttAgentSession.sessionID, ">>>9":u), 12),
                                            string(ttAgentSession.sessionState, "x(10)":u),
                                            ttAgentSession.startTime,
                                            FormatMsTime(ttAgentSession.runningTime, 0),
                                            FormatMemory(ttAgentSession.memAtRestBytes, 18),
                                            FormatMemory(ttAgentSession.memActiveBytes, 18),
                                            FormatLongNumber(string(ttAgentSession.reqTotal), 18),
                                            (if ttAgentSession.boundSession gt StringConstant:EMPTY then ttAgentSession.boundSession else StringConstant:EMPTY),
                                            (if ttAgentSession.boundReqID gt StringConstant:EMPTY then substitute("[&1]":u, ttAgentSession.boundReqID) else "-":u))).
            end. /* for each ttAgentSession */

            WriteOutputLine(" "). // Provides a break after the session information.

            /* Output summary information about agent-sessions, such as how many are busy out of the total count. */
            WriteOutputLine(substitute("&1: &2 of &3 (&4% Busy)":u,
                                        PadString("Active Agent-Sessions":u, 28),
                                        ttAgent.busySess,
                                        ttAgent.totSess,
                                        if ttAgent.totSess gt 0 then round((ttAgent.busySess / ttAgent.totSess) * 100, 1) else 0)).

            /* Establish an educated guess on how many sessions have been utilized via a baseline memory value. */
            WriteOutputLine(substitute("&1: &2 of &3 (>&4 KB)":u,
                                        PadString("Utilized Agent-Sessions":u, 28),
                                        ttAgent.usedSess,
                                        ttAgent.totSess,
                                        FormatMemory(iBaseMem, 0))).

            /* Output min/max/avg for total, completed, and failed requests across all sessions for this agent. */
            WriteOutputLine(substitute("&1: &2 / &3 / &4":u,
                                        PadString("Total Requests (Mn/Mx/Av)":u, 28),
                                        FormatIntAsNumber(ttAgent.minReqTotal, 0),
                                        FormatIntAsNumber(ttAgent.maxReqTotal, 0),
                                        FormatIntAsNumber(if ttAgent.totSess gt 0 then int64(round(ttAgent.totReqTotal / ttAgent.totSess, 0)) else 0, 0))).
            WriteOutputLine(substitute("&1: &2 / &3 / &4":u,
                                        PadString("Completed Reqs (Mn/Mx/Av)":u, 28),
                                        FormatIntAsNumber(ttAgent.minReqComp, 0),
                                        FormatIntAsNumber(ttAgent.maxReqComp, 0),
                                        FormatIntAsNumber(if ttAgent.totSess gt 0 then int64(round(ttAgent.totReqComp / ttAgent.totSess, 0)) else 0, 0))).
            WriteOutputLine(substitute("&1: &2 / &3 / &4":u,
                                        PadString("Failed Reqs (Mn/Mx/Av)":u, 28),
                                        FormatIntAsNumber(ttAgent.minReqFail, 0),
                                        FormatIntAsNumber(ttAgent.maxReqFail, 0),
                                        FormatIntAsNumber(if ttAgent.totSess gt 0 then int64(round(ttAgent.totReqFail / ttAgent.totSess, 0)) else 0, 0))).

            /* Output min/max/avg active memory (KB) across all sessions for this agent. */
            WriteOutputLine(substitute("&1: &2 KB / &3 KB / &4 KB":u,
                                        PadString("Active Memory (Mn/Mx/Av)":u, 28),
                                        FormatMemory(ttAgent.minActiveMem, 0),
                                        FormatMemory(ttAgent.maxActiveMem, 0),
                                        FormatMemory(if ttAgent.totSess gt 0 then int64(round(ttAgent.sumActiveMem / ttAgent.totSess, 0)) else 0, 0))).

            /* For 12.2+ this should include agent overhead memory + all sessions, otherwise just all sessions. */
            WriteOutputLine(substitute("&1: &2 KB":u, PadString("Approx. Agent Memory":u, 28), FormatMemory(ttAgent.totalMem, 0))).
        end. /* for each ttAgent */
    end. // can-find(ttAgent)

    /* Client HTTP Sessions (GetSessions) */

    /* https://docs.progress.com/bundle/pas-for-openedge-management/page/Collect-runtime-metrics.html */
    case iCollect:
        when 0 then WriteOutputLine("~nSession Manager Metrics (Not Enabled)":u).
        when 1 then WriteOutputLine("~nSession Manager Metrics (Count-Based)":u).
        when 2 then WriteOutputLine("~nSession Manager Metrics (Time-Based)":u).
        when 3 then WriteOutputLine("~nSession Manager Metrics (Count+Time)":u).
    end case.

    for first ttMetric no-lock
        where ttMetric.appName eq cAblApp:
        WriteOutputLine(substitute("&1: &2":u,
                                   PadString("# Requests to Session":u, 32),
                                   FormatLongNumber(string(ttMetric.requests), 16))).
        WriteOutputLine(substitute("&1: &2 (&3 Errors)":u,
                                   PadString("# Agent Responses Read":u, 32),
                                   FormatLongNumber(string(ttMetric.reads), 16),
                                   FormatLongNumber(string(ttMetric.readErrors), 0))).
        WriteOutputLine(substitute("&1: &2 / &3 / &4":u,
                                   PadString("Agent Read Time (Mn, Mx, Av)":u, 32),
                                   FormatMsTime(ttMetric.minAgentReadTime, 0),
                                   FormatMsTime(ttMetric.maxAgentReadTime, 0),
                                   FormatMsTime(ttMetric.avgAgentReadTime, 0))).
        WriteOutputLine(substitute("&1: &2 (&3 Errors)":u,
                                   PadString("# Agent Requests Written":u, 32),
                                   FormatLongNumber(string(ttMetric.writes), 16),
                                   FormatLongNumber(string(ttMetric.writeErrors), 0))).
        WriteOutputLine(substitute("&1: &2 (Max: &3)":u,
                                   PadString("Concurrent Connected Clients":u, 32),
                                   FormatLongNumber(string(ttMetric.concurrentConnClients), 16),
                                   FormatLongNumber(string(ttMetric.maxConcurrentClients), 0))).
        WriteOutputLine(substitute("&1: &2":u,
                                   PadString("Tot. Reserve ABLSession Wait":u, 32),
                                   FormatMsTime(ttMetric.totResvSessWaitTime, 20))).
        WriteOutputLine(substitute("&1: &2":u,
                                   PadString("# Reserve ABLSession Waits":u, 32),
                                   FormatLongNumber(string(ttMetric.numResvSessWaits), 16))).
        WriteOutputLine(substitute("&1: &2":u,
                                   PadString("Avg. Reserve ABLSession Wait":u, 32),
                                   FormatMsTime(ttMetric.avgResvSessWaitTime, 20))).
        WriteOutputLine(substitute("&1: &2":u,
                                   PadString("Max. Reserve ABLSession Wait":u, 32),
                                   FormatMsTime(ttMetric.maxResvSessWaitTime, 20))).
        WriteOutputLine(substitute("&1: &2":u,
                                   PadString("# Reserve ABLSession Timeout":u, 32),
                                   FormatLongNumber(string(ttMetric.numResvSessTimeouts), 16))).
    end. /* for first ttMetric */

    /* Output client session data from the populated temp-table. */
    WriteOutputLine(substitute("~nClient HTTP Sessions: &1":u, iTotClSess)).

    if iTotClSess gt 0 then do:
        //WriteOutputLine("    STATE     SESS STATE  BOUND  LAST ACCESS / STARTED                 ELAPSED TIME  SESSION MODEL    ADAPTER   SESSION ID                              REQUEST ID":u).
        WriteOutputLine(substitute(" &1 &2 &3 &4 &5 &6 &7 &8 &9":u,
                                   PadString("STATE":u, 8),
                                   PadString("SESS STATE":u, 14),
                                   PadString("BOUND":u, 6),
                                   PadString("LAST ACCESS / STARTED":u, 22),
                                   PadString("ELAPSED TIME":u, 28),
                                   PadString("SESSION MODEL":u, 14),
                                   PadString("ADAPTER":u, 10),
                                   PadString("SESSION ID":u, 12),
                                   PadString("REQUEST ID":u, 39))).

        for each ttClientSession no-lock
            where ttClientSession.appName eq cAblApp:
            WriteOutputLine(substitute("~n    &1&2&3    &4    &5  &6 &7&8 &9":u,
                                       string(ttClientSession.requestState, "x(10)":u),
                                       string(ttClientSession.sessionState, "x(12)":u),
                                       string(ttClientSession.isBound, "YES/NO":u),
                                       ttClientSession.lastAccessStr,
                                       FormatMsTime(ttClientSession.elapsedTimeMs, 18),
                                       string(ttClientSession.sessionType, "x(16)":u),
                                       string(ttClientSession.adapterType, "x(10)":u),
                                       string(ttClientSession.sessionID, "x(40)":u),
                                       ttClientSession.requestID)).

            if ttClientSession.clientName gt StringConstant:EMPTY then
                WriteOutputLine(substitute("    |- ClientConn: &1    &2    &3  Proc: &4 &5":u,
                                           ttClientSession.clientName,
                                           ttClientSession.requestStartTime,
                                           FormatMsTime(ttClientSession.clientElapsed, 7),
                                           string(ttClientSession.reqProcedure, "x(40)":u),
                                           if ttClientSession.boundRef gt StringConstant:EMPTY
                                           then substitute("Agent-Session: &1":u, ttClientSession.boundRef)
                                           else StringConstant:EMPTY)).

            if ttClientSession.agentConnPID gt StringConstant:EMPTY then
                WriteOutputLine(substitute("    |-- AgentConn: &1  &2  Agent: &3  Local: &4":u,
                                           ttClientSession.agentConnPID,
                                           ttClientSession.agentConnState,
                                           ttClientSession.agentAddr,
                                           ttClientSession.localAddr)).
        end. /* for each ttClientSession */
    end. /* response - ClientSessions */
end procedure.
