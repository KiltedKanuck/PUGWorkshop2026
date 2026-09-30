/**************************************************************************************************************************
Copyright (c) 2026 by Progress Software Corporation and/or one of its subsidiaries or affiliates. All rights reserved.
***************************************************************************************************************************/
/*------------------------------------------------------------------------
    File        : DOHEventHandler
    Purpose     : Provide event listeners for the OpenEdge DOH class
    Description :
    Author(s)   : Dustin Grau (dgrau)
    Created     : Thu Jul 11 12:02:17 EDT 2024
    Notes       : Create new instance in startup.p

  Options:

  Use an environment variable called USE_EXPLICIT_CONTEXT_DELETE set to any
  truthy value (e.g. "true", "yes", "1") to enable explicit deletion of the
  user context object. By default the object will be dereferenced (=?) as
  performed by a particular pattern followed by a customer.
--------------------------------------------------------------------------*/

block-level on error undo, throw.

// Define the name of the class package for this application.
&GLOBAL-DEFINE CLASS_PACKAGE OpenEdge.Workshop

using {&CLASS_PACKAGE}.Common.LoginModelEnum.
using {&CLASS_PACKAGE}.Handler.DOHParams.
using OpenEdge.Core.DateTimeAddIntervalEnum.
using OpenEdge.Core.SemanticVersion.
using OpenEdge.Core.Session.
using OpenEdge.Core.StringConstant.
using OpenEdge.Core.WidgetHandle.
using OpenEdge.Logging.ILogWriter.
using OpenEdge.Logging.LogFilterBuilderRegistry.
using OpenEdge.Logging.LoggerBuilder.
using OpenEdge.Logging.LoggerFilterRegistry.
using OpenEdge.Net.HTTP.Filter.Payload.MessageWriter.
using OpenEdge.Net.HTTP.Filter.Payload.MessageWriterErrorEventArgs.
using OpenEdge.Net.HTTP.Filter.Writer.BodyWriterRegistry.
using OpenEdge.Net.HTTP.Filter.Writer.EntityWriterRegistry.
using OpenEdge.Net.HTTP.HttpHeader.
using OpenEdge.Net.HTTP.StatusCodeEnum.
using OpenEdge.Net.HTTP.StatusCodeHelper.
using OpenEdge.Web.SendExceptionError.
using OpenEdge.Web.DataObject.AuthorizeOperationEventArgs.
using OpenEdge.Web.DataObject.DataObjectHandler.
using OpenEdge.Web.DataObject.HandlerErrorEventArgs.
using OpenEdge.Web.DataObject.HandlerLoadEntityEventArgs.
using OpenEdge.Web.DataObject.OperationInvocationEventArgs.
using OpenEdge.Web.DataObject.ServiceDiscoveryEventArgs.
using OpenEdge.Web.DataObject.ServiceRegistry.
using OpenEdge.Web.DataObject.TargetTypeEnum.
using OpenEdge.Web.DataObject.Writer.ArgumentValueWriterRegistry.
using OpenEdge.Web.DataObject.Writer.OperationHandlerRegistry.
using OpenEdge.Web.DataObject.Writer.ResponseElementWriterRegistry.
using Progress.Json.ObjectModel.JsonObject.
using Progress.Json.ObjectModel.ObjectModelParser.

class {&CLASS_PACKAGE}.Handler.DOHEventHandler
    use-widget-pool
    final
:

    /* Circular dependency to cheat death (aka GC). */
    var private {&CLASS_PACKAGE}.Handler.DOHEventHandler oCheat.

    /* Parameters passed to this handler at construction time. */
    var private DOHParams oParams.

    /* Used to track the start of execution for a request. */
    var private datetime dInvokeTime = ?.

    /* Holds the API version for this application. */
    var private SemanticVersion oApiVersion.

    /* Contains the current Client-Principal token for this request. */
    var private OpenEdge.Security.Principal oPrincipal.

    /* Sealed "reset" Client-Principal used for DB identity cleanup. */
    var handle hResetClientPrincipal.

    /* List of DOH services that should never be subject to context management (when enabled). */
    var private character cServicesWhitelist = "catalog,logs,system":u.

    /* Fixed credentials for sealed DB assertion token. */
    var private character cResetUser = "ResetUser":u, cResetDomain = "PUG":u, cResetPasscode = "DevSuite":u.

    /* Access the service-level logging manager. */
    define protected property oLogger as ILogWriter no-undo
        get():
            /* Create single logger instance for this class. */
            if not valid-object(oLogger) then
                assign oLogger = LoggerBuilder:GetLogger(this-object:getClass()).
            return oLogger.
        end get.
        private set.


    constructor public DOHEventHandler ( input poParams as DOHParams ):
        assign
            oCheat  = this-object
            oParams = poParams
            .

        // Define the API version for this application.
        assign oApiVersion = new SemanticVersion(0, 0, 0).

        // We intend to use the name "api" instead of the default "pdo".
        OpenEdge.Web.DataObject.DataObjectHandler:HANDLER_PREFIX = "api":u.

        this-object:InitializeResetToken(). // Create and seal DB assertion token.

        this-object:DefineEvents(). // Subscribe to standard DOH events.

        this-object:InitializeRegistries(). // Prepare the registries.

        this-object:GetAppVersion(). // Get the application version info.
    end constructor.


    destructor DOHEventHandler():
        DataObjectHandler:LoadEntity:Unsubscribe(this-object:LoadEntityHandler).
        DataObjectHandler:Invoking:Unsubscribe(this-object:InvokingHandler).
        DataObjectHandler:Invoked:Unsubscribe(this-object:InvokedHandler).
        DataObjectHandler:OperationError:Unsubscribe(this-object:OperationErrorHandler).
        DataObjectHandler:DiscoverService:Unsubscribe(this-object:DiscoverServiceHandler).
        DataObjectHandler:UnloadEntity:Unsubscribe(this-object:UnloadEntityHandler).
        DataObjectHandler:AuthorizeOperation:Unsubscribe(this-object:AuthorizeOperationHandler).

        delete object hResetClientPrincipal no-error.
    end destructor.


    /***** Helper Methods *****/


    method private character GetRequestContext ( ):
        // Returns a formatted server context representing the current request.
        if valid-object(session:current-request-info) then do:
            if (session:current-request-info:RequestId gt "":u) eq true then
                return substitute("A&1-S&2 | &3":u,
                                  session:current-request-info:AgentId,
                                  session:current-request-info:SessionId,
                                  session:current-request-info:RequestId).
            else
                return substitute("A&1-S&2":u,
                                  session:current-request-info:AgentId,
                                  session:current-request-info:SessionId).
        end.

        return "N/A".
    end method. // GetRequestContext


    method private character GetRequestUserID ( ):
        // Safely returns the current user identity as "user-id@domain-name" or "?" if unavailable.
        if valid-object(oPrincipal) and valid-handle(oPrincipal:Token) then
            return substitute("&1@&2":u, oPrincipal:Token:user-id, oPrincipal:Token:domain-name).
        return "?":u.
    end method. // GetRequestUserID


    method private void WriteErrorCallStack ( input poError as Progress.Lang.Error ):
        var character cCallStack = "":u, cSource = "":u.
        var SendExceptionError oSendError.

        if not valid-object(poError) then return. // Leave if no error object given.

        // If a SEE then it is an ApplicationError containing an InnerStop and InnerError.
        // We must check both error properties for a possible CallStack, if available.
        if type-of(poError, SendExceptionError) then do:
            assign oSendError = cast(poError, SendExceptionError).

            // Prefer the wrapped stop details when available.
            if valid-object(oSendError:InnerStop) then do:
                assign
                    cCallStack = trim(oSendError:InnerStop:CallStack)
                    cSource    = "InnerStop":u
                    .
            end.

            // Fall back to wrapped inner error details with supported CallStack types.
            if (cCallStack gt "":u) ne true and
               valid-object(oSendError:InnerError) and
               type-of(oSendError:InnerError, Progress.Lang.ProError) then do:
                assign
                    cCallStack = trim(cast(oSendError:InnerError, Progress.Lang.ProError):CallStack)
                    cSource    = "InnerError(ProError)":u
                    .
            end.
        end. // SendExceptionError

        // Final fallback: use outer error call stack when type supports it.
        if (cCallStack gt "":u) ne true and type-of(poError, Progress.Lang.ProError) then
            assign
                cCallStack = trim(cast(poError, Progress.Lang.ProError):CallStack)
                cSource    = "OperationError(ProError)":u
                .

        if (cCallStack gt "":u) eq true then
            oLogger:Error(substitute("OP-ERROR - &1 - CallStack for &2 (&3):~n&4":u,
                                     this-object:GetRequestContext(),
                                     poError:GetClass():TypeName,
                                     cSource,
                                     cCallStack)).
    end method. // WriteErrorCallStack


    method private void InitializeResetToken ( ):
        var character cQualifiedUserID = substitute("&1@&2":u, cResetUser, cResetDomain).
        var logical lValid = false.

        create client-principal hResetClientPrincipal.
        hResetClientPrincipal:initialize(cQualifiedUserID).
        assign
            hResetClientPrincipal:roles       = "SessionReset":u
            hResetClientPrincipal:domain-type = "Internal":u
            .

        if not hResetClientPrincipal:seal(cResetPasscode) then
            oLogger:Error("INIT - Unable to seal reset Client-Principal.":u).
        else
            oLogger:Info(substitute("INIT - Created sealed reset token for '&1'":u, cQualifiedUserID)).

        if num-dbs eq 1 and valid-object(hResetClientPrincipal) then do:
            assign lValid = set-db-client(hResetClientPrincipal, ldbname(1)) no-error.
            if lValid then
                oLogger:Debug(substitute("SESSION - &1 - Successfully asserted initial reset DB identity for '&2@&3'":u,
                                         this-object:GetRequestContext(), cResetUser, cResetDomain)).
            else do:
                oLogger:Error(substitute("INIT - Unable to assert initial reset DB identity for '&1@&2'":u,
                                         cResetUser, cResetDomain)).
                oLogger:Error(substitute("INIT - CP Token: user=&1 | domain=&2 | type=&3 | roles=[&4] | state=&5 | error=&6":u,
                                         hResetClientPrincipal:user-id,
                                         hResetClientPrincipal:domain-name,
                                         hResetClientPrincipal:domain-type,
                                         hResetClientPrincipal:roles,
                                         hResetClientPrincipal:login-state,
                                         error-status:get-message(1))).
            end.
        end.

        catch err as Progress.Lang.Error:
            oLogger:Error(substitute("INIT - Error creating reset principal: &1":u, err:GetMessage(1)), err).
            undo, throw err.
        end catch.
    end method. // InitializeResetToken


    method private void DefineEvents ( ):
        DataObjectHandler:LoadEntity:Subscribe(this-object:LoadEntityHandler).
        DataObjectHandler:Invoking:Subscribe(this-object:InvokingHandler).
        DataObjectHandler:Invoked:Subscribe(this-object:InvokedHandler).
        DataObjectHandler:OperationError:Subscribe(this-object:OperationErrorHandler).
        DataObjectHandler:DiscoverService:Subscribe(this-object:DiscoverServiceHandler).
        DataObjectHandler:UnloadEntity:Subscribe(this-object:UnloadEntityHandler).
        DataObjectHandler:AuthorizeOperation:Subscribe(this-object:AuthorizeOperationHandler).
    end method. // Define Events


    method private void InitializeRegistries ( ):
        var character cServiceMapPath = ?.
        var datetime-tz dStart = now. /* Mark start time. */

        /* Start some of the internal registries by accessing the static properties. */
        ArgumentValueWriterRegistry:Registry.
        BodyWriterRegistry:Registry.
        EntityWriterRegistry:Registry.
        LogFilterBuilderRegistry:Registry.
        LoggerFilterRegistry:Registry.
        OperationHandlerRegistry:Registry.
        ResponseElementWriterRegistry:Registry.
        ServiceRegistry:Registry.

        /* Discover any file-based DOH services if catalog.map file exists on disk. */
        file-info:file-name = search("catalog.map":u).
        if file-info:full-pathname ne ? then /* When file is present, obtain the base path of the file. */
            assign
                cServiceMapPath = replace(file-info:full-pathname, StringConstant:BACKSLASH, "/")
                cServiceMapPath = substring(cServiceMapPath, 1, length(cServiceMapPath) - length("catalog.map":u))
                .

        if (cServiceMapPath gt "") eq true then do:
            /* Use the base path of the catalog.map file to know where to look for other available .MAP files. */
            oLogger:Debug(substitute("INIT - Loading all Service Registry data from '&1'":u, cServiceMapPath)).
            OpenEdge.Web.DataObject.ServiceRegistry:RegisterAllFromFolder(cServiceMapPath).
        end. /* cServiceMapPath */

        /* Log the end of the initialization process with an elapsed time. */
        oLogger:Info(substitute("INIT - Finished Loading Resource Metadata in &1ms":u,
                                interval(now, dStart, string(DateTimeAddIntervalEnum:Milliseconds)))).

        catch err as Progress.Lang.Error:
            oLogger:Error(substitute("INIT - Error while initializing registries: &1":u, err:GetMessage(1)), err).
            undo, throw err.
        end catch.
    end method. // InitializeRegistries


    method private void GetAppVersion ( ):
        var ObjectModelParser oParser = new ObjectModelParser().
        var character cFilePath, cVersion.
        var JsonObject oVersion.

        oLogger:Debug("INIT - Checking for 'version.json' in ABL Application PROPATH...":u).

        /* Extract the version info from the JSON file and parse into a SemanticVersion object. */
        file-info:file-name = search("version.json":u).
        assign cFilePath = file-info:full-pathname.
        if cFilePath ne ? then do:
            assign oVersion = cast(oParser:ParseFile(cFilePath), JsonObject).

            if valid-object(oVersion) and oVersion:Has("version") then
                assign cVersion = oVersion:GetCharacter("version").

            if (cVersion gt "") eq true then
                assign oApiVersion = SemanticVersion:Parse(cVersion).
        end.

        catch err as Progress.Lang.Error:
            oLogger:Error(substitute("INIT - Error while obtaining version info: &1":u, err:GetMessage(1)), err).
            undo, throw err.
        end catch.
        finally:
            delete object oParser no-error.
            delete object oVersion no-error.
        end finally.
    end method. // GetAppVersion


    method private void EstablishSession ( input pcServiceName as character ):
        var character cSessionID = "".
        var longchar lcStoredContext = "".
        var logical lHasStoredContext = false, lValid = false.

        /**
         * Assert the current user's identity for this session request.
         *
         * Note: For working with anonymous security, ensure the following are set:
         *  OEClientPrincipalFilter.anonymous=true
         *  OEClientPrincipalFilter.sealAnonymous=true
         *  OEClientPrincipalFilter.passthru=true
         *
         * No principal token will be available without the above settings present.
         */
        assign oPrincipal = OpenEdge.Security.Principal:Import(session:current-request-info).
        if valid-object(oPrincipal) then do on error undo, throw:
            if num-dbs eq 1 and valid-object(oPrincipal:Token) then do:
                assign lValid = set-db-client(oPrincipal:Token, ldbname(1)) no-error.
                if lValid then
                    oLogger:Debug(substitute("SESSION - &1 - Successfully asserted user DB identity for '&2'":u,
                                             this-object:GetRequestContext(),
                                             this-object:GetRequestUserID())).
                else do:
                    oLogger:Error(substitute("SESSION - &1 - Unable to assert user DB identity for '&2'":u,
                                             this-object:GetRequestContext(),
                                             this-object:GetRequestUserID())).
                    oLogger:Error(substitute("SESSION - &1 - CPO Token: user=&2 | domain=&3 | type=&4 | roles=[&5] | state=&6 | error=&7":u,
                                             this-object:GetRequestContext(),
                                             oPrincipal:Token:user-id,
                                             oPrincipal:Token:domain-name,
                                             oPrincipal:Token:domain-type,
                                             oPrincipal:Token:roles,
                                             oPrincipal:Token:login-state,
                                             error-status:get-message(1))).
                end.
            end. // Assert DB Identity

            if lookup(lc(trim(pcServiceName)), cServicesWhitelist) gt 0 then do:
                if valid-object(oPrincipal:Token) then
                    assign cSessionID = oPrincipal:Token:session-id.

                /* Skip the creation of a user context object for whitelisted services. */
                oLogger:Debug(substitute("SESSION - &1 - Using CPO context for user '&2'; SessionID '&3'":u,
                                         this-object:GetRequestContext(),
                                         this-object:GetRequestUserID(),
                                         cSessionID)).
            end. // Skip Context Management
            else if valid-object(oPrincipal:Token) then
                // This could be quite verbose so it should remain at the Debug logging level.
                oLogger:Debug(substitute("SESSION - &1 - Skipping context management for user '&2'; feature disabled.":u,
                                         this-object:GetRequestContext(),
                                         this-object:GetRequestUserID())).
            else if num-dbs eq 0 then
                oLogger:Warn(substitute("SESSION - &1 - Skipping context management for user '&2'; no database connected.":u,
                                        this-object:GetRequestContext(),
                                        this-object:GetRequestUserID())).
            else
                oLogger:Warn(substitute("SESSION - &1 - Skipping context management; no valid CPO token; no database connected.":u,
                                        this-object:GetRequestContext())).

            finally:
                assign lcStoredContext = ?.
            end finally.
        end. // valid-object(oPrincipal)
        else
            oLogger:Warn(substitute("SESSION - &1 - No valid principal token found for current session request.":u,
                                    this-object:GetRequestContext())).
    end method. // EstablishSession


    method private void SessionCleanup ( ):
        var logical lValid = false.

        // Apply a fixed sealed token so DB access has an unprivileged, asserted identity.
        if num-dbs eq 1 and valid-object(hResetClientPrincipal) then do:
            assign lValid = set-db-client(hResetClientPrincipal, ldbname(1)) no-error.
            if lValid then
                oLogger:Debug(substitute("SESSION - &1 - Successfully asserted reset DB identity for '&2'":u,
                                         this-object:GetRequestContext(), this-object:GetRequestUserID())).
            else do:
                oLogger:Error(substitute("SESSION - &1 - Unable to assert reset DB identity for '&2@&3'":u,
                                         this-object:GetRequestContext(), cResetUser, cResetDomain)).
                oLogger:Error(substitute("SESSION - &1 - Reset CP Token: user=&2 | domain=&3 | type=&4 | roles=[&5] | state=&6 | error=&7":u,
                                         this-object:GetRequestContext(),
                                         hResetClientPrincipal:user-id,
                                         hResetClientPrincipal:domain-name,
                                         hResetClientPrincipal:domain-type,
                                         hResetClientPrincipal:roles,
                                         hResetClientPrincipal:login-state,
                                         error-status:get-message(1))).
            end.
        end.

        oLogger:Debug(substitute("SESSION - &1 - Completed user identity cleanup of the current request.":u,
                                 this-object:GetRequestContext())).

        catch err as Progress.Lang.Error:
            oLogger:Error(substitute("SESSION - &1 - Error while cleaning up session: &2":u,
                                     this-object:GetRequestContext(), err:GetMessage(1)), err).
            this-object:WriteErrorCallStack(err).
            undo, throw err.
        end catch.
        finally:
            // Delete the CP token held directly by this class.
            delete object oPrincipal no-error.
        end finally.
    end method. // SessionCleanup


    /***** Event Methods *****/


    /* Event published to perform a security check before running an entity.
     * @param Progress.Lang.Object The handler publishing the event
     * @param ServiceDiscoveryEventArgs Event args for this event
     */
    method private void AuthorizeOperationHandler ( input poSender    as Progress.Lang.Object,
                                                    input poEventArgs as AuthorizeOperationEventArgs):
        // Operation is an object of type "MappedOperation" representing the current operation.
        if extent(poEventArgs:Operation:AccessControl) ne ? then do:
            oLogger:Debug(substitute("AUTHZ - Operation target '&1:&2' has ACL roles [&3]":u,
                                     poEventArgs:Operation:TargetName,
                                     poEventArgs:Operation:TargetFunction,
                                     OpenEdge.Core.String:Join(poEventArgs:Operation:AccessControl, ",":u))).

            // User should be an object of type "Principal" obtained via the session:current-request-info.
            if valid-object(poEventArgs:User) and valid-handle(poEventArgs:User:Token) then
                oLogger:Debug(substitute("AUTHZ - Extracted token information for '&1@&2' with roles '&3' [&4]":u,
                                         poEventArgs:User:Token:user-id,
                                         poEventArgs:User:Token:domain-name,
                                         poEventArgs:User:Token:roles,
                                         poEventArgs:User:Token:session-id)).
        end. /* Has AccessControl */
    end method. // AuthorizeOperationHandler


    /* Event published to discover information about an available service.
     * eg. Determine the API version based on URL or header information.
     * @param Progress.Lang.Object The handler publishing the event
     * @param ServiceDiscoveryEventArgs Event args for this event
     */
    method private void DiscoverServiceHandler ( input poSender    as Progress.Lang.Object,
                                                 input poEventArgs as ServiceDiscoveryEventArgs ):
        /* Existing pattern uses the URL path to determine the name and URI of the current service being requested,
         * essentially the part after the /web/<prefix>/ segment of our request. Once the name and URI of the service
         * has been isolated, use either poEventArgs:Registry or ServiceRegistry object instance is consulted via
         * HasService() and GetService() by poEventArgs:Name and poEventArgs:Version and assigned to poEventArgs:Service.
         * The default pattern is /pdo[[/{version}]/{service}] but could be adjusted to meet your needs.
         */
        var datetime-tz dStart = now. /* Record start of discovery process. */

        /* If we have a service, or something already went wrong, return. */
        if valid-object(poEventArgs:Service) or poEventArgs:Cancel or valid-object(poEventArgs:Error) then return.

        /* Output the parsed service-related values as seen by the registry. */
        oLogger:Debug(substitute("DISCOVER - WebApp: &1 | Service: &2 v&3 | URI: &4 [&5 &6]":u,
                                 poEventArgs:Request:WebAppPath,
                                 poEventArgs:Name, SemanticVersion:Parse(poEventArgs:version):ToString(),
                                 poEventArgs:ServiceURI, poEventArgs:Request:Method, poEventArgs:Request:URI:ToString())).
    end method. // DiscoverServiceHandler


    /* Event published to invoke/load a piece of business logic (aka Business Entity).
     * If none exists, we try a simple DYNAMIC-NEW.
     * @param Progress.Lang.Object The handler publishing the event
     * @param HandlerLoadEntityEventArgs Event args for this event
     */
    method private void LoadEntityHandler ( input poSender    as Progress.Lang.Object,
                                            input poEventArgs as HandlerLoadEntityEventArgs ):
        /* Determine the target type of the entity, which for this implementation should be Class or Procedure. */
        var TargetTypeEnum oTargetType = TargetTypeEnum:GetEnum(poEventArgs:Operation:TargetType).

        /* Leave a log message that the DOH event handler is being loaded. */
        oLogger:Debug(substitute("DOH-LOAD - &1 - Requested Entity '&2' as &3":u,
                                 this-object:GetRequestContext(),
                                 poEventArgs?:Operation?:TargetName,
                                 poEventArgs?:Operation?:TargetType)).

        /* Attempt to load the requested service for this business entity. */
        case oTargetType:
            when TargetTypeEnum:Class then do:
                define variable oServiceClass as Progress.Lang.Class no-undo.
                assign oServiceClass = Progress.Lang.Class:GetClass(poEventArgs?:Operation?:TargetName) no-error.
                if valid-object(oServiceClass) then do:
                    /* Leave a log message that the DOH event handler has been loaded. */
                    oLogger:Debug(substitute("DOH-LOAD - &1 - Located Class Entity '&2'":u,
                                             this-object:GetRequestContext(), oServiceClass:TypeName)).
                end. /* valid-object */
            end. /* class */

            when TargetTypeEnum:Procedure then do:
                define variable hProcedure as handle no-undo.

                /* Start the procedure as a persistent handle and store in an OE.Core.WidgetHandle class. */
                run value(poEventArgs:Operation:TargetName) persistent set hProcedure.
                assign poEventArgs:BusinessEntity = new WidgetHandle(hProcedure, true). /* true = auto-destroy */

                /* Leave a log message that the DOH event handler has been loaded. */
                oLogger:Debug(substitute("DOH-LOAD - &1 - Located Procedure Entity '&2'":u,
                                         this-object:GetRequestContext(), poEventArgs?:Operation?:TargetName)).
            end. /* procedure */

            otherwise
                assign poEventArgs:BusinessEntity = ?.
        end case. /* oTargetType */

        /**
         * If we do not have an available entity by now, the default event logic will be run within the DOH class.
         */
    end method. // LoadEntityHandler


    /* Event published before the business logic function is called by the handler.
     * @param Progress.Lang.Object The handler publishing the event
     * @param OperationInvocationEventArgs Event args for this event
     */
    method private void InvokingHandler ( input poSender    as Progress.Lang.Object,
                                          input poEventArgs as OperationInvocationEventArgs ):
        var TargetTypeEnum oTargetType.
        var character cServiceName = "".
        assign dInvokeTime = now. // Remember when we start execution.

        /* Determine the service name and target type of the entity. */
        assign
            cServiceName = if valid-object(poEventArgs:Service) then poEventArgs:Service:Name else "unknown":u
            oTargetType  = TargetTypeEnum:GetEnum(poEventArgs?:Operation?:TargetType)
            .

        if poEventArgs:Operation:ServiceURI eq "/" then
            oLogger:Debug(substitute("INVOKING - &1 - &2 '&3' [&4]":u,
                                     this-object:GetRequestContext(),
                                     string(poEventArgs:Operation:Method),
                                     poEventArgs:Service:Name,
                                     poEventArgs:Operation:TargetName)).

        if oTargetType eq TargetTypeEnum:Procedure then
            oLogger:Debug(substitute("INVOKING - &1 - &2 /&3 &4 -> '&5' in &6":u,
                                     this-object:GetRequestContext(),
                                     string(poEventArgs:Operation:Method),
                                     poEventArgs:Service:Name,
                                     poEventArgs:Operation:ServiceURI,
                                     poEventArgs:Operation:TargetFunction,
                                     poEventArgs:Operation:TargetName)).
        else
            oLogger:Debug(substitute("INVOKING - &1 - &2 /&3&4 -> &5:&6":u,
                                     this-object:GetRequestContext(),
                                     string(poEventArgs:Operation:Method),
                                     poEventArgs:Service:Name,
                                     poEventArgs:Operation:ServiceURI,
                                     poEventArgs:Operation:TargetName,
                                     poEventArgs:Operation:TargetFunction)).

        // Establish the session for the current user based on the available principal token.
        this-object:EstablishSession(cServiceName).

        catch err as Progress.Lang.Error:
            assign poEventArgs:Error = err.

            if err:NumMessages eq 1 and err:GetMessageNum(1) eq -403 then
                oLogger:Debug(substitute("INVOKING - &1 - Session error for &2: &3":u,
                                         this-object:GetRequestContext(),
                                         poEventArgs?:Operation?:TargetName,
                                         err:GetMessage(1))).
            else
                oLogger:Error(substitute("INVOKING - &1 - &2: &3":u,
                                         this-object:GetRequestContext(),
                                         poEventArgs?:Operation?:TargetName,
                                         err:GetMessage(1)), err).
        end catch.
    end method. // InvokingHandler


    /* Event published after the business logic function was called by the handler.
     * @param Progress.Lang.Object The handler publishing the event
     * @param OperationInvocationEventArgs Event args for this event
     */
    method private void InvokedHandler ( input poSender    as Progress.Lang.Object,
                                         input poEventArgs as OperationInvocationEventArgs ):
        var int64 iElapsed = 0.
        var HttpHeader oHeader.
        var TargetTypeEnum oTargetType.

        if valid-object(poEventArgs?:Response) then do on error undo, leave:
            // Provide server timing information as defined by https://w3c.github.io/server-timing/
            if dInvokeTime ne ? then do:
                assign iElapsed = interval(now, dInvokeTime, string(OpenEdge.Core.DateTimeAddIntervalEnum:Milliseconds)).
                assign oHeader = new HttpHeader("Server-Timing":u, substitute('app;desc="ABL";dur=&1':u, trim(string(iElapsed, ">>>,>>>,>>9")))).
                poEventArgs:Response:SetHeader(oHeader).
            end.

            // Add an application-specific header to describe the API version in use. */
            assign oHeader = new HttpHeader("App-API-Version":u, oApiVersion:ToString()).
            poEventArgs:Response:SetHeader(oHeader).

            // Add the MDC request identifier to the response for client-side correlation.
            assign oHeader = new HttpHeader("App-Request-ID":u, session:current-request-info:RequestId).
            poEventArgs:Response:SetHeader(oHeader).

            // Add the agent/session info to the response for server-side correlation.
            assign oHeader = new HttpHeader("App-Agent-Session":u, substitute("A&1-S&2":u,
                                                                              session:current-request-info:AgentId,
                                                                              session:current-request-info:SessionId)).
            poEventArgs:Response:SetHeader(oHeader).
        end. // has Response

        /* Determine the target type of the entity. */
        assign oTargetType = TargetTypeEnum:GetEnum(poEventArgs?:Operation?:TargetType).

        if poEventArgs:Operation:ServiceURI eq "/" then
            oLogger:Debug(substitute("INVOKED_ - &1 - &2 '&3' [&4] (&5ms)":u,
                                     this-object:GetRequestContext(),
                                     string(poEventArgs:Operation:Method),
                                     poEventArgs:Service:Name,
                                     poEventArgs:Operation:TargetName,
                                     iElapsed)).

        if valid-object(oTargetType) and oTargetType eq TargetTypeEnum:Procedure then
            oLogger:Debug(substitute("INVOKED_ - &1 - &2 /&3 &4 -> '&5' in &6":u,
                                     this-object:GetRequestContext(),
                                     string(poEventArgs:Operation:Method),
                                     poEventArgs:Service:Name,
                                     poEventArgs:Operation:ServiceURI,
                                     poEventArgs:Operation:TargetFunction,
                                     poEventArgs:Operation:TargetName)).
        else
            oLogger:Debug(substitute("INVOKED_ - &1 - &2 /&3&4 -> &5:&6 (&7ms)":u,
                                     this-object:GetRequestContext(),
                                     string(poEventArgs:Operation:Method),
                                     poEventArgs:Service:Name,
                                     poEventArgs:Operation:ServiceURI,
                                     poEventArgs:Operation:TargetName,
                                     poEventArgs:Operation:TargetFunction,
                                     iElapsed)).

        catch err as Progress.Lang.Error:
            assign poEventArgs:Error = err.
            oLogger:Error(substitute("INVOKED_ - &1 - &2: &3":u,
                                     this-object:GetRequestContext(),
                                     poEventArgs?:Operation?:TargetName,
                                     err:GetMessage(1)), err).
        end catch.
        finally:
            this-object:SessionCleanup(). // Perform any necessary cleanup.
        end finally.
    end method. // InvokedHandler


    /* Event published when an error is encountered by the DataObjectHandler, as raised by the BusinessEntity.
     * @param Progress.Lang.Object The handler publishing the event
     * @param HandlerErrorEventArgs Event args for this event
     */
    method private void OperationErrorHandler ( input poSender    as Progress.Lang.Object,
                                                input poEventArgs as HandlerErrorEventArgs ):
        var HttpHeader oHeader.
        var int64 iElapsed = 0.

        if valid-object(poEventArgs?:Response) then do on error undo, leave:
            // Provide server timing information as defined by https://w3c.github.io/server-timing/
            if dInvokeTime ne ? then do:
                assign iElapsed = interval(now, dInvokeTime, string(OpenEdge.Core.DateTimeAddIntervalEnum:Milliseconds)).
                assign oHeader = new HttpHeader("Server-Timing":u, substitute('app;desc="ABL";dur=&1':u, trim(string(iElapsed, ">>>,>>>,>>9")))).
                poEventArgs:Response:SetHeader(oHeader).
            end.

            // Add an application-specific header to describe the API version in use.
            assign oHeader = new HttpHeader("App-API-Version":u, oApiVersion:ToString()).
            poEventArgs:Response:SetHeader(oHeader).

            // Add the MDC request identifier to the response for client-side correlation.
            assign oHeader = new HttpHeader("App-Request-ID":u, session:current-request-info:RequestId).
            poEventArgs:Response:SetHeader(oHeader).

            // Add the agent/session info to the response for server-side correlation.
            assign oHeader = new HttpHeader("App-Agent-Session":u, substitute("A&1-S&2":u,
                                                                              session:current-request-info:AgentId,
                                                                              session:current-request-info:SessionId)).
            poEventArgs:Response:SetHeader(oHeader).
        end. // has Response

        if valid-object(poEventArgs?:OperationError) then do:
            // Known session error: suppress noise, return HTTP 403 directly.
            if poEventArgs:OperationError:NumMessages eq 1 and
               poEventArgs:OperationError:GetMessageNum(1) eq -403 then do:
                oLogger:Debug(substitute("OP-ERROR - &1 - Session error (403) for &2: &3":u,
                                         this-object:GetRequestContext(),
                                         poEventArgs?:Operation?:TargetName,
                                         poEventArgs:OperationError:GetMessage(1))).
                if valid-object(poEventArgs:Response) then do:
                    poEventArgs:Response:StatusCode   = integer(StatusCodeEnum:Forbidden:GetValue()).
                    poEventArgs:Response:StatusReason = StatusCodeHelper:GetMessage(StatusCodeEnum:Forbidden).
                end.
                return. // finally still runs; SessionCleanup() executes.
            end.

            // Ensure that any error raised from the business logic is captured in the log.
            oLogger:Error(substitute("OP-ERROR - &1 - &2 raised in &3 [user: &4]: &5":u,
                                     this-object:GetRequestContext(),
                                     poEventArgs:OperationError:GetClass():TypeName,
                                     poEventArgs?:Operation?:TargetName,
                                     this-object:GetRequestUserID(),
                                     poEventArgs:OperationError:GetMessage(1)),
                            poEventArgs:OperationError).

            // Log a call stack if one is provided by the error object.
            this-object:WriteErrorCallStack(poEventArgs:OperationError).

            // Provide request (URI) context for easy correlation back to other logs.
            if valid-object(poEventArgs?:Request) and
               valid-object(poEventArgs?:Request?:URI) then
                oLogger:Error(substitute("OP-ERROR - &1 - URI Context: '&2 &3&4' [user: &5]":u,
                                         this-object:GetRequestContext(),
                                         poEventArgs:Request:Method,
                                         poEventArgs:Request:URI:BaseURI,
                                         poEventArgs:Request:URI:Path,
                                         this-object:GetRequestUserID())).
        end. // valid OperationError

        catch err as Progress.Lang.Error:
            /* Just provide a message, but don't throw this as an error (we want to focus on what the entity threw). */
            oLogger:Error(substitute("OP-ERROR - An error occurred while handling an Operation Error: &1":u, err:GetMessage(1)), err).
            this-object:WriteErrorCallStack(err).
        end catch.
        finally:
            this-object:SessionCleanup(). // Perform any necessary cleanup.
        end finally.
    end method. // OperationErrorHandler


    /* Event published to unload a piece of business logic (aka Business Entity).
     * @param Progress.Lang.Object The handler publishing the event
     * @param HandlerLoadEntityEventArgs Event args for this event
     */
    method private void UnloadEntityHandler ( input poSender    as Progress.Lang.Object,
                                              input poEventArgs as HandlerLoadEntityEventArgs ):
        /* Determine the target type of the entity. */
        var TargetTypeEnum oTargetType = TargetTypeEnum:GetEnum(poEventArgs?:Operation?:TargetType).

        if valid-object(oTargetType) and oTargetType eq TargetTypeEnum:Procedure then do:
            /* Directly destroy the WidgetHandle class around any procedures (auto-destroys procedure handle). */
            delete object poEventArgs:BusinessEntity no-error.
            assign poEventArgs:BusinessEntity = ?.
        end. /* procedure */

        /* Leave a log message that the DOH event handler has been loaded. */
        oLogger:Debug(substitute("DOH-UNLD - &1 - Unloading Entity '&2'":u,
                                 this-object:GetRequestContext(),
                                 poEventArgs?:Operation?:TargetName)).

        catch err as Progress.Lang.Error:
            /* Just provide a message, but don't throw this as an error (we want to focus on what the entity threw). */
            oLogger:Error(substitute("DOH-UNLD - An error occurred while unloading the entity handler: &1":u, err:GetMessage(1)), err).
        end catch.
    end method. // UnloadEntityHandler

end class.