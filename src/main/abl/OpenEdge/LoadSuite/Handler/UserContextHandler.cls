/**
 * Request-scoped user context model used by the session-scoped DOH event handler.
 *
 * Pattern intent:
 * - The DOH event handler is created once per Agent Session (session-scoped singleton).
 * - A new UserContextHandler is created per request only after a valid principal token is present.
 * - The handler stores that instance on currentUserContext for request-time access.
 *
 * Ownership and lifecycle:
 * - This class owns an internal clientPrincipal handle copy used to isolate request modifications.
 * - The owning handler is responsible for deterministic cleanup at the end of a user request.
 * - Preferred cleanup pattern in the owner: DELETE OBJECT currentUserContext NO-ERROR, then set to ?.
 * - Relying on dereference alone (currentUserContext = ?) leaves cleanup timing to GC, potentially.
 *
 * Usage notes:
 * - Do not cache UserContextHandler instances across requests.
 * - Cannot share this object between Agent Sessions (must re-create per session).
 * - Treat this class as request-scoped even when accessed from a session-scoped owner.
 *
 * Compatibility:
 * - Mirrors the legacy SecurityManager/IUserContext usage model for comparison and testing.
 * - Intended for load and memory-behavior validation in an isolated environment.
 */

block-level on error undo, throw.

// Define the name of the class package for this application.
&GLOBAL-DEFINE CLASS_PACKAGE OpenEdge.LoadSuite

&SCOPED-DEFINE clientPrincipalProperty "UserContextClientPrincipal":u
&SCOPED-DEFINE contextIDProperty "UserContextContextID":u
&SCOPED-DEFINE loginExpirationProperty "UserContextLoginExpiration":u
&SCOPED-DEFINE sessionInvalidatedProperty "UserContextSessionInvalidated":u

using {&CLASS_PACKAGE}.Common.LoginModelEnum.
using {&CLASS_PACKAGE}.Common.Util.ContextManager.
using {&CLASS_PACKAGE}.Handler.UserContextHandler.
using OpenEdge.Logging.ILogWriter.
using OpenEdge.Logging.LoggerBuilder.
using Progress.Json.ObjectModel.JsonObject.
using Progress.Json.ObjectModel.ObjectModelParser.

class {&CLASS_PACKAGE}.Handler.UserContextHandler use-widget-pool:

    /** The handle to the users Client Principal object */
    define public property clientPrincipal as handle no-undo get. protected set.

    /** A GUID representing the user context */
    define public property contextID as character no-undo get. protected set.

    /** The users display name */
    define public property userID as character no-undo get. protected set.

    /** The name of the users domain */
    define public property userDomain as character no-undo get. protected set.

    /** The time stamp of when the client-principal object will expire. */
    define public property loginExpiration as datetime-tz no-undo get. protected set.

    /** The login model - form, oauth2, etc */
    define public property loginModel as LoginModelEnum no-undo get. protected set.

    /** The time stamp of when this users session was invalidated. */
    define protected property sessionInvalidated as datetime-tz no-undo protected get. protected set.

    // Internal temp-table for caching of user properties (read: context details) during a request.
    define private temp-table ttUserSessionProp no-undo before-table biUserSessionProp
        field PropName as char
        field PropValue as char
        index ix1 as primary unique PropName
        .
    define dataset dsUserSessionProp for ttUserSessionProp. // Required for tracking changes.

    // Define a constant for login timeout (8 hours).
    var private integer LOGIN_TIMEOUT_SECONDS = 28800.

    /* Access the service-level logging manager. */
    define static property oStaticLogger as ILogWriter no-undo
        get():
            /* Create single logger instance for this class. */
            if not valid-object(oStaticLogger) then
                assign oStaticLogger = LoggerBuilder:GetLogger("StaticContextHandler").
            return oStaticLogger.
        end get.
        private set.

    /* Access the service-level logging manager. */
    define protected property oLogger as ILogWriter no-undo
        get():
            /* Create single logger instance for this class. */
            if not valid-object(oLogger) then
                assign oLogger = LoggerBuilder:GetLogger(this-object:getClass()).
            return oLogger.
        end get.
        private set.

    /**
     * Create a new user context from the session request info, utilizing its Client Principal object handle.
     * This uses the class property to refer to the incoming user's identity for further processing.
     */
    constructor public UserContextHandler ():
        oLogger:Info("Constructing UserContextHandler from session current-request-info CPO.":u).
        this-object:clientPrincipal = session:current-request-info:GetClientPrincipal().
        constructFromCPO(false).

        oLogger:Debug(substitute("Created new user context for '&1@&2'; Expires: &3; SessionID: '&4'":u,
                      this-object:userID,
                      this-object:userDomain,
                      this-object:loginExpiration,
                      this-object:contextID)).
    end constructor.

    /**
     * Create a new user context from an existing Client Principal handle.
     *
     * @param phClientPrincipal The handle to the existing Client Principal to copy
     */
    constructor public UserContextHandler (input phClientPrincipal as handle):
        var raw rCP.

        oLogger:Info(substitute("Constructing UserContextHandler from supplied CPO handle for '&1@&2'":u, phClientPrincipal:user-id, phClientPrincipal:domain-name)).
        rCP = phClientPrincipal:export-principal().
        create client-principal this-object:clientPrincipal.
        this-object:clientPrincipal:import-principal(rCP).

        constructFromCPO(false).

        oLogger:Debug(substitute("Created new user context for '&1@&2'; Expires: &3; SessionID: '&4'":u,
                      this-object:userID,
                      this-object:userDomain,
                      this-object:loginExpiration,
                      this-object:contextID)).
    end constructor.

    /**
     * Create a new user context from an existing Client Principal handle.
     * A new contextID is allocated so as to store this session as a new session in the state manager
     * The expiration can be reset but this does not change the CPO expiration (legacy usage)
     *
     * @param phClientPrincipal The handle to the existing Client Principal to copy
     * @param ptExpire When this UserContextHandler expires
     */
    constructor public UserContextHandler ( input phClientPrincipal as handle,
                                            input ptExpire as datetime-tz ):
        var raw rCP.

        rCP = phClientPrincipal:export-principal().
        create client-principal this-object:clientPrincipal.
        this-object:clientPrincipal:import-principal(rCP).

        assign
            this-object:userID          = this-object:clientPrincipal:user-id
            this-object:userDomain      = this-object:clientPrincipal:domain-name
            this-object:loginExpiration = this-object:clientPrincipal:login-expiration-timestamp
            .

        // Assign this UserContextHandler object a NEW contextID
        assign
            this-object:contextID       = guid(generate-uuid)
            this-object:loginExpiration = ptExpire
            .

        this-object:checkExpiration().
        this-object:setTrackingChangesOnUserProperties().

        oLogger:Debug(substitute("Created new user context for '&1@&2'; Expires: &3; SessionID: '&4'":u,
                      this-object:userID,
                      this-object:userDomain,
                      this-object:loginExpiration,
                      this-object:contextID)).
    end constructor.

    /**
     * Recreate the user context from the serialized string
     *
     * @param plcContext The serialized string representing the UserContext
     */
    constructor public UserContextHandler ( input plcContext as longchar ):
        oLogger:Info("Constructing UserContextHandler from serialized LONGCHAR context.").
        this-object:commonUserContext(input plcContext, input false, input false).
    end constructor.

    /**
     * Recreate the user context from the serialized string, forcing the ignoring of the session CPO.
     *
     * @param plcContext The serialized string representing the UserContext
     * @param plIgnoreExpiredTest Yes=Dont check whether context is expired
     */
    constructor public UserContextHandler ( input plcContext          as longchar,
                                            input plIgnoreExpiredTest as logical ):
        oLogger:Info(substitute("Constructing UserContextHandler from serialized context; IgnoreExpiredTest=&1":u, plIgnoreExpiredTest)).
        this-object:commonUserContext(input plcContext, input plIgnoreExpiredTest, input false).
    end constructor.

    /**
     * Recreate the user context from the serialized string, allowing an option for use of the session CPO.
     *
     * @param plcContext The serialized string representing the UserContext
     * @param plIgnoreExpiredTest Yes=Dont check whether context is expired
     * @param plUseSessionCPO Yes = Use the CPO from the session handle not the one stored in the StateManager
     */
    constructor public UserContextHandler ( input plcContext          as longchar,
                                            input plIgnoreExpiredTest as logical,
                                            input plUseSessionCPO     as logical ):
        oLogger:Info(substitute("Constructing UserContextHandler from serialized context; IgnoreExpiredTest=&1, UseSessionCPO=&2":u,
                                plIgnoreExpiredTest, plUseSessionCPO)).
        this-object:commonUserContext(input plcContext, input plIgnoreExpiredTest, input plUseSessionCPO).
    end constructor.

    /**
     * Create a new User Context and creates a new unsealed CPO.
     * When asserted against the DB the authentication system with a callback will validate the credentials
     *
     * @param pcUserID The User ID
     * @param pcUserDomain The User Domain
     * @param pcPassword The users password
     */
    constructor public UserContextHandler ( input pcUserID as character,
                                            input pcUserDomain as character,
                                            input pcPassword as character ):
        oLogger:Info(substitute("Constructing UserContextHandler from credentials for '&1@&2'":u, pcUserID, pcUserDomain)).
        create client-principal this-object:clientPrincipal.

        assign
            this-object:contextID       = guid(generate-uuid)
            this-object:loginExpiration = add-interval(now, LOGIN_TIMEOUT_SECONDS, "seconds":u)
            .

        if pcUserID eq ? or pcUserID eq "" then
            undo, throw new Progress.Lang.AppError(substitute("User ID cannot be unknown or empty":u)).
        if pcUserDomain eq ? then
            undo, throw new Progress.Lang.AppError(substitute("User Domain cannot be unknown":u)).

        assign
            this-object:userID     = pcUserID
            this-object:userDomain = pcUserDomain
            .

        pcPassword = decryptPassword(pcPassword).
        clientPrincipal:initialize(this-object:userID + "@" + this-object:userDomain, this-object:contextID, this-object:loginExpiration, pcPassword).

        this-object:setClientPrincipalAttributes().
        this-object:resolveCPO().
        this-object:setTrackingChangesOnUserProperties().
    end constructor.

    /**
     * Destructor for the class which _should_ delete the internal Client Principal object handle reference.
     */
    destructor public UserContextHandler ( ):
        oLogger:Info(substitute("Destroying UserContextHandler for '&1@&2', ContextID '&3'":u, this-object:userID, this-object:userDomain, this-object:contextID)).
        if valid-object(this-object:clientPrincipal) then
            delete object this-object:clientPrincipal no-error.
    end destructor.

    method public void prepareForSerializeContext ( ):
        var raw rCP.
        var longchar lcCP = "".
        var integer iLoop = 0.
        var character cTemp = "".

        /**
         * We are going to store the CPO in the state manager so that it can be used by the task scheduler to run the task on behalf of the user.
         * A new CPO will be cloned from this one with a new expiry when the task is executed.
         */
        assign
            rCP   = this-object:clientPrincipal:export-principal()
            lcCP  = base64-encode(rCP)
            iLoop = 0
            .

        /**
         * A temp-table cannot hold a longchar field so we need to chop up the CP object to ensure it will fit into a character field
         * Each user property will be given a base name + index based on the number of required loops.
         */
        do while length(lcCP, "character":u) gt 0:
            assign iLoop = iLoop + 1.
            this-object:setUserProperty({&clientPrincipalProperty} + string(iLoop), string(substring(lcCP, 1, 30000, "character":u))).
            assign lcCP = substring(lcCP, 30001, -1, "character":u).
        end.
        oLogger:Debug(substitute("Stored &1 CPO chunk(s) for serialization.", iLoop)).

        this-object:setUserProperty({&contextIDProperty}, this-object:contextID).

        // If the session was invalidated externally (e.g. via invalidateCurrentSession()) during
        // this request, the instance properties were never updated. Read the DB value once here;
        // if it is a real timestamp, sync it to the instance before serializing so the stale
        // in-memory values do not overwrite the invalidation that was just written to the DB.
        assign cTemp = ContextManager:getContextProperty(this-object:contextID, {&sessionInvalidatedProperty}, true).
        if (cTemp gt "") eq true and cTemp ne "?":u then do:
            assign
                this-object:sessionInvalidated = this-object:iso2DateTZ(cTemp)
                this-object:loginExpiration    = this-object:iso2DateTZ(cTemp)
                no-error.
        end.

        this-object:setUserProperty({&loginExpirationProperty}, this-object:loginExpiration).
        this-object:setUserProperty({&sessionInvalidatedProperty}, this-object:sessionInvalidated).
    end method. // prepareForSerializeContext

    /**
     * The serialized string returned from this method is used by the Constructor to recreate this object
     * @return Returns true if the context details did not yet exist
     */
    method public logical serializeContext ( ):
        // Parity path: initialize detail rows only when none exist for this context.
        // This mirrors the original session-login CAN-FIND gate behavior.
        if not ContextManager:contextDetailExists(this-object:contextID) then do:
            for each ttUserSessionProp no-lock:
                ContextManager:setContextProperty(this-object:contextID,
                                                  ttUserSessionProp.PropName,
                                                  ttUserSessionProp.PropValue).
            end.
            oLogger:Debug(substitute("Finished serializing context for ContextID '&1' [T: &2].":u,
                                     this-object:contextID, transaction)).

            return true. // Context details did not exist and should have been written.
        end.
        else
            oLogger:Debug(substitute("Skipping detail initialization; rows already exist for ContextID '&1' [T: &2].":u,
                                     this-object:contextID, transaction)).

        return false. // If we reach this point the serialization failed.
    end method. // serializeContext

    /**
     * New-session context table flow.
     * - Creates/updates ContextHeader for this context.
     * - Seeds ContextDetail properties from the in-memory user property table.
     */
    method public void applyNewSessionContextFlow ( input pcProductCode as character ):
        var character cProductCode = "".

        assign cProductCode = if pcProductCode eq ? or pcProductCode eq "":u then "LoadSuite":u else pcProductCode.

        oLogger:Info(substitute("Applying new session context flow for ContextID '&1'.":u, this-object:contextID)).

        ContextManager:createOrUpdateContextHeader(this-object:contextID,
                                                   this-object:userID,
                                                   cProductCode,
                                                   "":u).

        // Seed synthetic Group 2 + Group 3 properties before serialization so the
        // full ~57-row context_detail footprint matches production session volume.
        this-object:seedSyntheticContextProperties(cProductCode).

        // Prepare and write the context through the static manager class methods.
        this-object:prepareForSerializeContext().
        this-object:serializeContext().

        ContextManager:updateLastAccess(this-object:contextID).

        oLogger:Info(substitute("Applied new session context flow for ContextID '&1' [T: &2].":u,
                                this-object:contextID, transaction)).
    end method. // applyNewSessionContextFlow

    /**
     * Returning-session context table flow.
     * - Ensures a ContextHeader exists and touches last-access.
     * - Reads persisted ContextDetail values for known properties to simulate
     *   frequent table reads during session re-establish and request processing.
     */
    method public void applyReturningSessionContextFlow ( input pcProductCode as character ):
        var character cProductCode = "", cDbValue = "".

        assign cProductCode = if pcProductCode eq ? or pcProductCode eq "":u then "LoadTest":u else pcProductCode.

        oLogger:Info(substitute("Applying returning session context flow for ContextID '&1'.":u, this-object:contextID)).

        if not ContextManager:contextExists(this-object:contextID) then
            ContextManager:createOrUpdateContextHeader(this-object:contextID,
                                                       this-object:userID,
                                                       cProductCode,
                                                       "":u).

        ContextManager:updateLastAccess(this-object:contextID).

        for each ttUserSessionProp exclusive-lock:
            cDbValue = ContextManager:getContextProperty(this-object:contextID,
                                                         ttUserSessionProp.PropName,
                                                         true).
            if cDbValue ne ? then
                assign ttUserSessionProp.PropValue = cDbValue.
        end.

        this-object:setTrackingChangesOnUserProperties().

        oLogger:Info(substitute("Applied returning session context flow for ContextID '&1' [T: &2].":u,
                                this-object:contextID, transaction)).
    end method. // applyReturningSessionContextFlow

    /**
     * Per-request cleanup flow prior to object dereference/deletion.
     * Persists current in-memory properties and updates ContextHeader last-access.
     */
    method public void applySessionCleanupContextFlow ( ):
        oLogger:Info(substitute("Applying cleanup context flow for ContextID '&1'.":u, this-object:contextID)).

        this-object:prepareForSerializeContext().
        for each ttUserSessionProp no-lock:
            ContextManager:setContextProperty(this-object:contextID,
                                              ttUserSessionProp.PropName,
                                              ttUserSessionProp.PropValue).
        end.

        ContextManager:updateLastAccess(this-object:contextID).

        oLogger:Info(substitute("Applied cleanup context flow for ContextID '&1' [T: &2].":u,
                                this-object:contextID, transaction)).
    end method. // applySessionCleanupContextFlow

    /** Static Methods */

    /**
     * Invalidates the current session by writing the sessionInvalidated and loginExpiration
     * properties directly to ContextDetail for the context ID derived from the live CPO.
     *
     * This is the correct entry point for ContextService (or any caller without a
     * UserContextHandler instance) because it uses only session:current-request-info
     * and ContextManager static methods - no object reference is required.
     *
     * After this call, the next request for this session will hit checkExpiration() and
     * receive HTTP 403: "Your session has been terminated. Please login again."
     *
     * @return The datetime-tz timestamp written as the invalidation mark.
     * @throws AppError When the context ID cannot be resolved from the current session.
     */
    method public static datetime-tz invalidateCurrentSession ( ):
        var character cContextID = "".
        var datetime-tz dtExpiration = now.
        var handle hCP.

        assign hCP = session:current-request-info:GetClientPrincipal().
        if not valid-handle(hCP) then
            undo, throw new Progress.Lang.AppError("Unable to obtain Client-Principal from current session.":u, -400).

        assign cContextID = trim(UserContextHandler:getCPOSessionId(hCP)).
        if (cContextID gt "") ne true then
            undo, throw new Progress.Lang.AppError("Unable to resolve context ID from current session.":u, -400).

        ContextManager:setContextProperty(cContextID, {&sessionInvalidatedProperty}, iso-date(dtExpiration)).
        ContextManager:setContextProperty(cContextID, {&loginExpirationProperty},    iso-date(dtExpiration)).

        oStaticLogger:Info(substitute("Session invalidated for ContextID '&1' at &2.", cContextID, dtExpiration)).

        return dtExpiration.

        catch err as Progress.Lang.Error:
            oStaticLogger:Error(substitute("Error invalidating session: &1":u, err:GetMessage(1)), err).
            undo, throw err.
        end catch.
        finally:
            delete object hCP no-error.
        end finally.
    end method. // invalidateCurrentSession

    method public static character getCPOSessionId ( input hCP as handle ):
        var character cSessionID = "", cTimestamp = "".

        assign cSessionID = hCP:session-id no-error.
        oStaticLogger:Debug(substitute("getCPOSessionId: Initial sessionID = '&1'", cSessionID)).

        /**
         * Under PASOE the session-id assigned to the CPO is NOT a GUID or based on a UUID
         * The session-id will be unique within the lifetime of the PASOE server (i.e. between startup and shutdown)
         * but not unique accross all time.  We need unique contextID so that we have a unique identifier
         * for this user session when the state manager looks up the session state in the database.
         *
         * session:current-request-info:ClientContextID - Assigned by PAS as the session-id and cannot be changed by ABL server (PASOE just re-assignes it to the session-id)
         * session:server-connection-context - According to the documentation this is only valid for session-managed sessions
         */
        if cSessionID ne ? and cSessionID ne "" and cSessionID ne "0" and hCP:seal-timestamp ne ? then do:
            assign cTimestamp = iso-date(hCP:seal-timestamp) no-error.
            assign cSessionID = substitute("&1.&2", cSessionID,
                                           replace(replace(replace(replace(replace(cTimestamp, ":", ""), "-", ""), "+", ""), ".", ""), "T", "")).
        end.

        // new request - a new session ID will be allocated
        if cSessionID eq ? or cSessionID eq "" or cSessionID eq "0" then do:
            // if hCP:user-id eq "anonymousUser" then do:
            //     if not valid-object(SysAdm:instance:messageManager:webRequest) then
            //     undo, throw new Progress.Lang.AppError("Anonymous access not allowed for non web requests", 401).
            // end.

            // We should have a valid user-id on the CPO and if the sessionID is not yet defined
            // then this should be the first request and a new session will be created.
            assign cSessionID = "".
        end.

        oStaticLogger:Debug(substitute("getCPOSessionId: Returning sessionID = '&1'", cSessionID)).

        return cSessionID.
    end method. // getCPOSessionId

    /** Protected Helper Methods */

    /**
     * Simply a pass-through for a password value (actual decryption not implemented).
     */
    method protected character decryptPassword ( input pcPassword as character ):
        return pcPassword.
    end method. // decryptPassword

    /**
     * Used to assign any attributes and user properties to the client principal before it is sealed.
     */
    method protected void setClientPrincipalAttributes():
        clientPrincipal:roles = "DevUser".
        clientPrincipal:set-property("fldAuthType", "cpo").
        clientPrincipal:set-property("ATTR_ENABLED", "true").
        clientPrincipal:set-property("ATTR_LOCKED", "false").
        clientPrincipal:set-property("ATTR_EXPIRED", "false").
    end method. // setClientPrincipalAttributes

    method protected void constructFromCPO ( input plIgnoreExpiredTest as logical ):
        oLogger:Debug(substitute("Constructing context from CPO for '&1@&2'; IgnoreExpiredTest=&3.",
                      this-object:clientPrincipal:user-id, this-object:clientPrincipal:domain-name, plIgnoreExpiredTest)).
        assign
            this-object:userID          = this-object:clientPrincipal:user-id
            this-object:userDomain      = this-object:clientPrincipal:domain-name
            this-object:loginExpiration = this-object:clientPrincipal:login-expiration-timestamp
            this-object:contextID       = UserContextHandler:getCPOSessionId(this-object:clientPrincipal)
            .

        // If a new session then allocate a new session id.
        if this-object:contextID eq ? or
           this-object:contextID eq "" or
           this-object:contextID eq "0" then
            assign this-object:contextID = guid(generate-uuid).

        resolveCPO().

        if not plIgnoreExpiredTest then
            checkExpiration().

        oLogger:Debug(substitute("CPO construction complete; ContextID '&1', Model '&2', Expires: &3.",
                                 this-object:contextID, string(this-object:loginModel), this-object:loginExpiration)).
        this-object:setTrackingChangesOnUserProperties().

        catch err as Progress.Lang.Error:
            if err:NumMessages eq 1 and err:GetMessageNum(1) eq -403 then
                oLogger:Debug(substitute("Handled Session Exception: &1", err:GetMessage(1))).
            else
                oLogger:Error(substitute("Error constructing context from CPO for '&1@&2': &3",
                                         this-object:clientPrincipal:user-id, this-object:clientPrincipal:domain-name, err:GetMessage(1)), err).

            if valid-object(this-object:clientPrincipal) then do:
                oLogger:Debug("Deleting CPO handle after error in constructFromCPO.").
                delete object this-object:clientPrincipal no-error.
            end.

            undo, throw err.
        end catch.
    end method. // constructFromCPO

    /**
     * Convert an ISO date string to a datetime-tz value
     * @param pcString Character string representing the ISO date
     * @return The datatime-tz conversion
     */
    method protected datetime-tz iso2DateTZ ( input pcString as character ):
        var character cDateFormat = "".

        cDateFormat = session:date-format.
        session:date-format = "ymd":u.
        return datetime-tz(pcString).

        finally:
            session:date-format = cDateFormat.
        end finally.
    end method. // iso2DateTZ

    method protected logical hasUserProperty ( input pcProperty as character ):
        define buffer lbUserSessionProp for ttUserSessionProp.

        find first lbUserSessionProp no-lock
             where lbUserSessionProp.PropName eq pcProperty no-error.

        return available(lbUserSessionProp).
    end method. // hasUserProperty

    method protected character getUserProperty ( input pcProperty as character ):
        return getUserProperty(pcProperty, false).
    end method. // getUserProperty

    method public datetime-tz getUserPropertyAsDatetimeTZ ( input pcProperty as character ):
        return iso2DateTZ(getUserProperty(pcProperty)).
    end method. // getUserPropertyAsDatetimeTZ

    method protected character getUserProperty ( input pcProperty as character,
                                                 input plOptional as logical ):
        var character cPropValue = ?.

        oLogger:Trace(substitute("Getting property '&1' for user '&2' [&3]",
                                 pcProperty, this-object:userID, trim(string(plOptional, "OPTIONAL/REQUIRED")))).
        define buffer lbUserSessionProp for ttUserSessionProp.

        find first lbUserSessionProp no-lock
             where lbUserSessionProp.PropName eq pcProperty no-error.
        if not available(lbUserSessionProp) and not plOptional then do:
            oLogger:Warn(substitute("Required property '&1' for user '&2' has not been defined":u, pcProperty, this-object:userID)).
            return cPropValue. // Return the unknown value after reporting that the required property could not be obtained.
        end.

        if available(lbUserSessionProp) then
            assign cPropValue = lbUserSessionProp.PropValue.

        return cPropValue.
    end method. // getUserProperty

    method public void setUserProperty ( input pcProperty as character,
                                         input pcValue    as character ):
        define buffer lbUserSessionProp for ttUserSessionProp.

        oLogger:Trace(substitute("Setting property '&1' for user '&2': '&3'", pcProperty, this-object:userID, pcValue)).
        find first lbUserSessionProp exclusive-lock
             where lbUserSessionProp.PropName eq pcProperty no-error.
        if not available(lbUserSessionProp) then do:
            create lbUserSessionProp.
            assign lbUserSessionProp.PropName = pcProperty.
        end.

        assign lbUserSessionProp.PropValue = pcValue.
    end method. // setUserProperty

    method public void setUserProperty ( input pcProperty as character,
                                         input piValue as integer ):
        setUserProperty(pcProperty, string(piValue)).
    end method. // setUserProperty

    method public void setUserProperty ( input pcProperty as character,
                                         input piValue as int64 ):
        var character cDec = "", cSep = "".

        cDec = session:numeric-decimal-point.
        cSep = session:numeric-separator.
        session:set-numeric-format(",",".").

        setUserProperty(pcProperty, string(piValue)).

        finally:
            session:set-numeric-format(cSep,cDec).
        end finally.
    end method. // setUserProperty

    method public void setUserProperty ( input pcProperty as character,
                                         input pfValue as decimal ):
        var character cDec = "", cSep = "".

        cDec = session:numeric-decimal-point.
        cSep = session:numeric-separator.
        session:set-numeric-format(",",".").

        setUserProperty(pcProperty, string(pfValue)).

        finally:
            session:set-numeric-format(cSep,cDec).
        end finally.
    end method. // setUserProperty

    method public void setUserProperty( input pcProperty as character,
                                        input plValue as logical ):
        setUserProperty(pcProperty, string(plValue, "yes/no")).
    end method. // setUserProperty

    method public void setUserProperty( input pcProperty as character,
                                        input pdValue as date ):
        setUserProperty(pcProperty, iso-date(pdValue)).
    end method. // setUserProperty

    method public void setUserProperty( input pcProperty as character,
                                        input pdValue as datetime ):
        setUserProperty(pcProperty, iso-date(pdValue)).
    end method. // setUserProperty

    method public void setUserProperty( input pcProperty as character,
                                        input pdValue as datetime-tz ):
        setUserProperty(pcProperty, iso-date(pdValue)).
    end method. // setUserProperty

    method protected void resolveCPO ( ):
        case this-object:clientPrincipal:get-property("fldAuthType"):
            when string(LoginModelEnum:oauth2) then
                assign this-object:loginModel = LoginModelEnum:oauth2.
            when string(LoginModelEnum:form) then
                assign this-object:loginModel = LoginModelEnum:form.
            when string(LoginModelEnum:cpo) then
                assign this-object:loginModel = LoginModelEnum:cpo.

            /**
            * A CPO can be created from a API login, legacy login, imported from file created with genspacp.
            * anonymousUser has a sealed CPO but no properties. These are all valid.
            */
            otherwise do:
                assign this-object:loginModel = LoginModelEnum:cpo.
            end.
        end case.
        oLogger:Debug(substitute("Resolved CPO auth type '&1' to LoginModel '&2' for user '&3'.",
                                 this-object:clientPrincipal:get-property("fldAuthType"),
                                 string(this-object:loginModel),
                                 this-object:userID)).
    end method. // resolveCPO

    /**
     * Return the Raw CPO object saved in the UserContext data
     */
    method protected raw getStoredCPO ( ):
        var raw rCP.
        var longchar lcCP = "".
        var character cTemp = "".
        var integer iLoop = 0.

        assign iLoop = 0.
        SEARCH-LOOP:
        do while true:
            assign iLoop = iLoop + 1.
            assign cTemp = this-object:getUserProperty({&clientPrincipalProperty} + string(iLoop)).
            if cTemp eq "" or cTemp eq ? then
                leave SEARCH-LOOP.
            assign lcCP = lcCP + cTemp.
        end.

        assign rCP = base64-decode(lcCP).

        oLogger:Debug(substitute("Retrieved stored CPO for user '&1' as &2 chunk(s).", this-object:userID, iLoop - 1)).

        return rCP.
    end method. // getStoredCPO

    /** Private Helper Methods */

    /**
     * Seeds synthetic Group 2 (identity/product) and Group 3 (user-control) context
     * properties into the in-memory property table, replicating the ~50 rows that
     * the production application writes from user_ctl and related tables at login.
     *
     * Values are intentionally static/synthetic - sufficient for realistic row-count
     * and lock-contention simulation without requiring a live application database.
     * Properties that would normally vary per user (email, login) are derived from
     * the current userID so each simulated user has distinct values.
     */
    method private void seedSyntheticContextProperties ( input pcProductCode as character ):
        oLogger:Debug(substitute("Seeding synthetic context properties for ContextID '&1'.", this-object:contextID)).

        // GROUP 2 - Identity and product context.
        setUserProperty("currentUserLogin",            this-object:userID).                  // Login identity used for user-scoped lookups.
        setUserProperty("currentProduct",              pcProductCode).                       // Active product code for product-specific behavior.
        setUserProperty("subProduct",                  "BASE").                              // Optional product partition; generic default.
        setUserProperty("currentBranchOverride",       "NO").                                // Branch override flag.
        setUserProperty("currentAuditManagerOverride", "NO").                                // Audit behavior override flag.
        setUserProperty("currentAscProdObj",           "1.0").                               // Product object key from catalog tables.
        setUserProperty("topMenuObj",                  "1.0").                               // Root menu structure object key.
        setUserProperty("languagePreference",          "en-US").                             // User language/culture preference.
        setUserProperty("agilityCustomerName",         "Tenant A").                          // Tenant display label (genericized value).
        setUserProperty("orgLevelList",                "1").                                 // Org hierarchy levels available to user.
        setUserProperty("currentOrganisationObj",      "1.0").                               // Current organization object key.

        // GROUP 3 - User control properties (sourced from user_ctl in production).
        setUserProperty("currentCostToggle",              "NO").                             // Allow cost visibility/actions.
        setUserProperty("currentUserName",                this-object:userID).               // Display name shown in UI.
        setUserProperty("queryServiceUserName",           "").                               // External query/report service username.
        setUserProperty("queryServicePassword",           "").                               // External query/report service password token.
        setUserProperty("queryServiceFileName",           "").                               // External query/report executable/path.
        setUserProperty("queryServiceCustomApp",          "").                               // External query/report custom app name.
        setUserProperty("userType",                       "TESTING").                        // User category/classification code.
        setUserProperty("defaultReportGroup",             "RPT-STD").                        // Default report permission group.
        setUserProperty("defaultTranGroup",               "TRN-STD").                        // Default transaction permission group.
        setUserProperty("defaultMaintgroup",              "MNT-STD").                        // Default maintenance permission group.
        setUserProperty("currentFaxReturnEmail",          "no-reply@loadsuite.local").       // Return email for fax/eform workflow.
        setUserProperty("currentLastAccessedPO",          "0").                              // Last PO viewer context key.
        setUserProperty("currentLastAccessedSO",          "0").                              // Last SO viewer context key.
        setUserProperty("currentLastAccessedRM",          "0").                              // Last RM viewer context key.
        setUserProperty("currentMultiSession",            "NO").                             // Allow multiple simultaneous sessions.
        setUserProperty("currentUserEmail",               this-object:userID + "@" + this-object:userDomain + ".local"). // Primary user email.
        setUserProperty("currentDefaultBranch",           "01").                             // Default operating branch.
        setUserProperty("currentLastAccessedINV",         "0").                              // Last inventory viewer context key.
        setUserProperty("currentLastAccessedATT",         "0").                              // Last attachment viewer context key.
        setUserProperty("currentLastAccessedDisp",        "0").                              // Last dispatch viewer context key.
        setUserProperty("lastViewerCalledFromStockStatus", "").                              // Source marker for viewer launch.
        setUserProperty("lastViewerCalledFromCustInfo",    "").                              // Source marker for viewer launch.
        setUserProperty("defaultCreditgroup",             "CRD-STD").                        // Default credit group.
        setUserProperty("defaultSalesAgent",              "").                               // Default sales agent ID.
        setUserProperty("defaultSAPosition",              "0").                              // Default sales agent position.
        setUserProperty("defaultBuyer",                   "").                               // Default buyer ID.
        setUserProperty("defaultBuyerPosition",           "0").                              // Default buyer position.
        setUserProperty("defaultSaleType",                "").                               // Default sale type code.
        setUserProperty("defaultPicker",                  "").                               // Default warehouse picker ID.
        setUserProperty("currentLastAccessedCO",          "0").                              // Last customer order viewer context key.
        setUserProperty("currentLastAccessedDM",          "0").                              // Last dimension viewer context key.
        setUserProperty("currentLastAccessedUO",          "0").                              // Last utility/order viewer context key.
        setUserProperty("useUserEmailAddress",            "NO").                             // Use user email as sender in forms.
        setUserProperty("defaultPOSSalesAgent",           "").                               // Default POS sales agent ID.
        setUserProperty("defaultPOSSAPosition",           "0").                              // Default POS sales agent position.
        setUserProperty("viewerSalesAgentID",             "").                               // Sales agent filter in viewer screens.
        setUserProperty("currentLastAccessedPK",          "0").                              // Last pick viewer context key.
        setUserProperty("currentLastAccessedSH",          "0").                              // Last ship viewer context key.
        setUserProperty("currentUserObj",                 "1.0").                            // Internal numeric user object key.
        setUserProperty("qtyAvailableDisplay",            "COMMITTED").                      // Available quantity display mode.
    end method. // seedSyntheticContextProperties

    method private void setTrackingChangesOnUserProperties ( ):
        buffer biUserSessionProp:accept-changes().
        temp-table ttUserSessionProp:tracking-changes = true.
    end method. // setTrackingChangesOnUserProperties

    method private void checkExpiration ( ):
        oLogger:Debug(substitute("Checking expiration; LoginExpiration=&1, SessionInvalidated=&2.",
                                 this-object:loginExpiration, this-object:sessionInvalidated)).

        if this-object:loginExpiration ne ? and
            this-object:loginExpiration lt now then
            undo, throw new Progress.Lang.AppError("Your session has expired. Please login again.":u, -403).

        if this-object:sessionInvalidated ne ? and
           this-object:sessionInvalidated lt now then
            undo, throw new Progress.Lang.AppError("Your session has been terminated. Please login again.":u, -403).
    end method. // checkExpiration

    /**
     * Recreate the user context from the serialized string
     *
     * @param plcContext The serialized string representing the UserContext
     * @param plIgnoreExpiredTest true (yes) = Dont check whether context is expired
     * @param plUseSessionCPO true (yes) = Use the CP token from the session info
     */
    method private void commonUserContext ( input plcContext          as longchar,
                                            input plIgnoreExpiredTest as logical,
                                            input plUseSessionCPO     as logical ):
        var JsonObject oContext.
        var character[] cNames.
        var integer iLoop.

        oLogger:Debug(substitute("Restoring user context from serialized state; IgnoreExpiredTest=&1, UseSessionCPO=&2.",
                                 plIgnoreExpiredTest, plUseSessionCPO)).

        assign oContext = cast(new ObjectModelParser():parse(plcContext), JsonObject).
        assign cNames = oContext:GetNames().

        empty temp-table ttUserSessionProp.
        do iLoop = 1 to extent(cNames):
            this-object:setUserProperty(cNames[iLoop], oContext:GetCharacter(cNames[iLoop])).
        end.

        this-object:setTrackingChangesOnUserProperties().

        if this-object:hasUserProperty({&sessionInvalidatedProperty}) then
            assign this-object:sessionInvalidated = this-object:getUserPropertyAsDatetimeTZ({&sessionInvalidatedProperty}).

        if plUseSessionCPO then do:
            oLogger:Debug("Using current session CPO as authoritative identity for user context.").
            assign this-object:clientPrincipal = session:current-request-info:GetClientPrincipal().
            this-object:constructFromCPO(plIgnoreExpiredTest).

            // If the saved contextID exists, it must match this request's session ID.
            // If it is missing, add it from the current session so the saved state is complete.
            if this-object:hasUserProperty({&contextIDProperty}) then do:
                // If the stored contextID exists, it still must match the current session.
                if this-object:contextID ne this-object:getUserProperty({&contextIDProperty}) then
                    undo, throw new Progress.Lang.AppError("The session ID on the CPO does not match this stored session data.", -403).
            end.
            else do:
                // Add the missing contextID now so cleanup writes back a complete record.
                oLogger:Warn(substitute("Stored context for user '&1' is missing property '&2'; using current session from CPO.",
                                        this-object:userID, {&contextIDProperty})).
                this-object:setUserProperty({&contextIDProperty}, this-object:contextID).
            end.
        end. // plUseSessionCPO
        else do:
            oLogger:Debug("Using stored CPO from serialized state for user context.").
            assign this-object:contextID = this-object:getUserProperty({&contextIDProperty}).

            create client-principal this-object:clientPrincipal.
            this-object:clientPrincipal:import-principal(this-object:getStoredCPO()).

            assign
                this-object:userID     = this-object:clientPrincipal:user-id
                this-object:userDomain = this-object:clientPrincipal:domain-name
                .

            assign this-object:loginExpiration = this-object:getUserPropertyAsDatetimeTZ({&loginExpirationProperty}).

            this-object:resolveCPO().

            if not plIgnoreExpiredTest then
                this-object:checkExpiration().
        end. // not plUseSessionCPO

        oLogger:Debug(substitute("Restored user context; ContextID '&1', User '&2@&3', Model '&4' [T: &5].",
                                 this-object:contextID, this-object:userID, this-object:userDomain, string(this-object:loginModel), transaction)).

        catch err as Progress.Lang.Error:
            if err:NumMessages eq 1 and err:GetMessageNum(1) eq -403 then
                // Do not clutter the logs with distinct 403 errors which indicate known session issues.
                oLogger:Debug(substitute("Handled Session Exception: &1", err:GetMessage(1))).
            else
                // However, log any unexpected errors for further investigation.
                oLogger:Error(substitute("Error restoring user context: &1", err:GetMessage(1)), err).

            if valid-object(this-object:clientPrincipal) then do:
                oLogger:Debug("Deleting CPO handle after error in commonUserContext.").
                delete object this-object:clientPrincipal no-error.
            end.

            undo, throw err. // Continue throwing the original error.
        end catch.
        finally:
            extent(cNames) = ?. // Reset the extent to clear any existing contents.
            assign plcContext = ?. // Clear the input context string from memory after use.
            delete object oContext no-error. // Explicitly delete the JsonObject to free memory.
        end finally.
    end method. // commonUserContext

end class.