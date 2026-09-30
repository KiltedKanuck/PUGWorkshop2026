/*------------------------------------------------------------------------
    File        : OEUserRealm
    Purpose     : Implement methods for OERealm service.
    Description : Applies back-end logic to OERealm authorization requests.
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Tue Apr 5 14:46:00 EST 2026
    Notes       :

    For purposes of the this application ALL usernames with ANY password
    are considered as valid and will be authenticated. This is meant to
    simplify the testing of the application without need for a database
    nor registry of users and credentials. The expectation is to merely
    allow any requesting authentication to result in a logged-in user
    with a valid role to access the API endpoints, and continue passing
    their session ID and token to appears as the same user for subsequent
    requests. Conversely, "anonymous" users always get a new session ID.
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

// Define the name of the class package for this application.
&GLOBAL-DEFINE CLASS_PACKAGE OpenEdge.Workshop

using {&CLASS_PACKAGE}.Security.Realm.OERealmDefs.
using OpenEdge.Logging.ILogWriter.
using Progress.Lang.*.
using OpenEdge.Logging.LoggerBuilder.

class {&CLASS_PACKAGE}.Security.OEUserRealm
    implements Progress.Security.Realm.IHybridRealm,
               {&CLASS_PACKAGE}.Security.IAuthHandler
    abstract:

    // Expect a token to be sent for validatin using a hardcoded RealmClient@OESPA with role SPAClient, sealed wtih "OEDevSuite" passcode.
    // These values are intended to simple setup for the DevSuite application only to avoid the need for a configuration file.
    define private variable cTokenUser   as character no-undo initial "RealmClient".
    define private variable cTokenDomain as character no-undo initial "OESPA".
    define private variable cTokenRole   as character no-undo initial "SPAClient".
    define private variable cPasscode    as character no-undo initial "OEDevSuite".

    /* Access the service-level logging manager. */
    define protected property oLogger as ILogWriter no-undo
        get():
            /* Create single logger instance for this class. */
            if not valid-object(oLogger) then
                assign oLogger = LoggerBuilder:GetLogger("OEUserRealm").
            return oLogger.
        end get.
        private set.

    constructor public OEUserRealm ( ):
        // No-op.
    end constructor.

    method protected logical validateRequest ( ):
        return validateRequest("[No Name]").
    end method.

    method protected logical validateRequest ( input pcSourceName as character ):
        var logical lResult = false.
        var OpenEdge.Security.Principal oPrincipal = OpenEdge.Security.Principal:Import(session:current-request-info).

        /**
         * Each request to this class is expected to be a separate request from the Tomcat server which
         * is authenticating a user. As such, each request must go through this routine to ensure that
         * it is originating from a known point by including a distinct CP token with a non-application
         * token domain and passcode. This is meant to deter requests from outside sources that are not
         * here for the express purpose of authenticating a user; in other words, potential attacks.
         */
        if oPrincipal:Token ne ? and valid-handle(oPrincipal:Token) then do:
            // Just confirm if sealed request matches a known password.
            assign lResult = oPrincipal:Token:validate-seal(cPasscode).
            if lResult eq true then do:
                // If seal is validated, check the initial CP role.
                if not oPrincipal:Authorize(cTokenRole) then do:
                    assign lResult = false.
                    oLogger:Error(substitute("Request CP seal is valid, but role &1 is not.", oPrincipal:Token:roles)).
                end. // cTokenRole
            end.
            else
                oLogger:Error(substitute("Unable to validate CP seal for token domain '&1''", oPrincipal:Token:domain-name)).

            oLogger:Debug(substitute("OERealm request by &1@&2 for '&3' is &4.",
                                     oPrincipal:Token:user-id, oPrincipal:Token:domain-name,
                                     pcSourceName, trim(string(lResult, "valid/invalid")))).
        end. /* hCPO */
        else
            oLogger:Error("Invalid request CP handle, unable to validate.").

        return lResult.

        finally:
            delete object oPrincipal no-error.
        end finally.
    end method. // validateRequest

    /**************************** IAuthHandler Methods *****************************/

    /**
     * These methods are meant to be "helpers" to the larger tasks provided by the
     * IHybridRealm class. NOTE: The default for these methods is to return a passing
     * value, so if your application does not support a particular function, leaving
     * the default method will allow authentication to continue without error.
     */

    /*------------------------------------------------------------------------------
     Purpose: Compare the user-supplied password to a hashed password.
     Notes: Implement as a protected method in your own class.
        @param pcPassword Externally supplied password by user
        @param pcHashPass Internally stored password for user
        @return Logical pass/fail for operation
    ------------------------------------------------------------------------------*/
    method protected logical checkPasswordHash ( input pcPassword as character,
                                                 input pcHashPass as character ):
        // Forward to actual method without need of UserID.
        return checkPasswordHash(?, pcPassword, pcHashPass).
    end method. // checkPasswordHash


    /*------------------------------------------------------------------------------
     Purpose: Compare the user-supplied password to a hashed password, with UserID.
     Notes: Implement as a protected method in your own class.
        @param piUserID UserID value, as integer
        @param pcPassword Externally supplied password by user
        @param pcHashPass Internally stored password for user
        @return Logical pass/fail for operation
    ------------------------------------------------------------------------------*/
    method protected logical checkPasswordHash ( input piUserID   as integer,
                                                 input pcPassword as character,
                                                 input pcHashPass as character ):
        return true. // If not overridden, assume password is good.
    end method. // checkPasswordHash


    /*------------------------------------------------------------------------------
     Purpose: Obtain the password for a given UserID.
     Notes: Implement as a protected method in your own class.
         @param piUserID UserID value, as integer
         @return Internally stored password value
    ------------------------------------------------------------------------------*/
    method protected character getPassword ( input piUserID as integer ):
        return ?. // If not overridden, assume no password.
    end method. // getPassword


    /*------------------------------------------------------------------------------
     Purpose: Perform an action after authentication (validatePassword).
     Notes: Implement as a protected method in your own class, if needed.
         @param piUserID UserID value, as integer
         @param lRetVal Result of authentication action, as logical
         @return Void
    ------------------------------------------------------------------------------*/
    method protected void postAuthenticate ( input piUserID as integer,
                                             input lRetVal  as logical ):
        // Override to perform an action based on this user's success/failure to authenticate.
    end method. // postAuthenticate


    /*------------------------------------------------------------------------------
     Purpose: Obtain the UserID for a given username (and domain, optional).
     Notes:
        @param pcUsername Username portion of credentials
        @param pcDomainName Domain portion of credentials
        @return Unique identifier for user, as integer
    ------------------------------------------------------------------------------*/
    method public integer getUserID ( input pcUsername   as character,
                                      input pcDomainName as character ):
        return 100. // If not overridden, just return a static positive value.
    end method. // getUserID


    /*------------------------------------------------------------------------------
     Purpose: Return active status for a given UserID.
     Notes:
        @param piUserID UserID value, as integer
        @return Logical pass/fail for operation
    ------------------------------------------------------------------------------*/
    method public logical isActive ( input piUserID as integer ):
        return true. // If not overridden, assume is active.
    end method. // isActive


    /*------------------------------------------------------------------------------
     Purpose: Return expiration status for a given UserID.
     Notes:
        @param piUserID UserID value, as integer
        @return Logical pass/fail for operation
    ------------------------------------------------------------------------------*/
    method public logical isExpired ( input piUserID as integer ):
        return false. // If not overridden, assume not expired.
    end method. // isExpired


    /*------------------------------------------------------------------------------
     Purpose: Return locked status for a given UserID.
     Notes:
        @param piUserID UserID value, as integer
        @return Logical pass/fail for operation
    ------------------------------------------------------------------------------*/
    method public logical isLocked ( input piUserID as integer ):
        return false. // If not overridden, assume not locked.
    end method. // isLocked


    /*------------------------------------------------------------------------------
     Purpose: Return available roles for a given UserID.
     Notes:
        @param piUserID UserID value, as integer
        @return Comma-separated list of roles (without ROLE_ prefix)
    ------------------------------------------------------------------------------*/
    method public character getUserRoles ( input piUserID as integer ):
        return "EndUser". // Provides basic role for access.
    end method. // getUserRoles


    /**************************** IHybridRealm Methods ******************************/

    /**
     * These methods come from the original IHybridRealm class within OpenEdge,
     * and are broken down to call more atomic methods to obtain data. The goal
     * is to not have to know how these are implemented directly, but to only
     * require the individual components be overridden when necessary.
     */

    method public character GetAttribute ( input piUserID   as integer,
                                           input pcAttrName as character ):
        var character cValue = ?.

        if not this-object:validateRequest("GetAttribute") then
            oLogger:Error(substitute("Unauthorized request")).
        else
            case pcAttrName:
                when OERealmDefs:REALM_ATTR_ENABLED then
                    // Value for OERealm ATTR_ENABLED
                    assign cValue = string(isActive(piUserID), "1/0").
                when OERealmDefs:REALM_ATTR_LOCKED then
                    // Value for OERealm ATTR_LOCKED
                    assign cValue = string(isLocked(piUserID), "1/0").
                when OERealmDefs:REALM_ATTR_EXPIRED then
                    // Value for OERealm ATTR_EXPIRED
                    assign cValue = string(isExpired(piUserID), "1/0").
                when OERealmDefs:REALM_ATTR_ROLES then
                    /* Generate a comma-delimited list of roles associated with this user.
                     * These roles will map to intercept-url patterns to grant access to
                     * various resource URI's as defined for the REST adapter services.
                     * A basic role of "EndUser" (mapped to ROLE_EndUser) is required for
                     * minimum secured access, based on this demo code. Your actual app
                     * security may vary.
                     */
                    assign cValue = getUserRoles(piUserID).
                otherwise
                    assign cValue = ?.
            end case.

        oLogger:Debug(substitute("GetAttribute: '&1' for user '&2' = '&3'", pcAttrName, piUserID, cValue)).

        return cValue.

        catch err as Progress.Lang.Error:
            oLogger:Error(substitute("GetAttribute: &1", err:GetMessage(1))).
            return ?.
        end catch.
    end method. // GetAttribute


    method public character extent GetAttributeNames ( input piUserID as integer ):
        /* Not configured for this project. */
        var character[] cpcAttrNames.

        if not this-object:validateRequest("GetAttributeNames") then
            oLogger:Error(substitute("Unauthorized request")).

        oLogger:Debug(substitute("GetAttributeNames: &1", piUserID)).

        return cpcAttrNames.

        catch err as Progress.Lang.Error:
            oLogger:Error(substitute("GetAttributeNames: &1", err:GetMessage(1))).
            return cpcAttrNames.
        end catch.
    end method. // GetAttributeNames


    method public character extent GetUsernames ( ):
        /* Not configured for this project. */
        var character[] cUsernames.

        if not this-object:validateRequest("GetUsernames") then
            oLogger:Error(substitute("Unauthorized request")).

        return cUsernames.

        catch err as Progress.Lang.Error:
            oLogger:Error(substitute("GetUsernames: &1", err:GetMessage(1))).
            return cUsernames.
        end catch.
    end method. // GetUsernames


    method public character extent GetUsernamesByQuery ( input pcQueryString as character ):
        /* Not configured for this project. */
        var character[] cUsernames.

        if not this-object:validateRequest("GetUsernamesByQuery") then
            oLogger:Error(substitute("Unauthorized request")).

        oLogger:Debug(substitute("GetUsernamesByQuery: &1", pcQueryString)).

        return cUsernames.

        catch err as Progress.Lang.Error:
            oLogger:Error(substitute("GetUsernamesByQuery: &1", err:GetMessage(1))).
            return cUsernames.
        end catch.
    end method. // GetUsernamesByQuery


    method public character extent GetUsernamesByQuery ( input pcAttrName  as character,
                                                         input pcAttrValue as character ):
        /* Not configured for this project. */
        var character[] cUsernames.

        if not this-object:validateRequest("GetUsernamesByQuery") then
            oLogger:Error(substitute("Unauthorized request")).

        oLogger:Debug(substitute("GetUsernamesByQuery: &1: &2", pcAttrName, pcAttrValue)).

        return cUsernames.

        catch err as Progress.Lang.Error:
            oLogger:Error(substitute("GetUsernamesByQuery: &1", err:GetMessage(1))).
            return cUsernames.
        end catch.
    end method. // GetUsernamesByQuery


    method public logical RemoveAttribute ( input piUserID   as integer,
                                            input pcAttrName as character ):
        /* Not configured for this project. */
        if not this-object:validateRequest("RemoveAttribute") then
            oLogger:Error(substitute("Unauthorized request")).

        oLogger:Debug(substitute("RemoveAttribute: &1: &2", piUserID, pcAttrName)).

        return true.

        catch err as Progress.Lang.Error:
            oLogger:Error(substitute("RemoveAttribute: &1", err:GetMessage(1))).
            return false.
        end catch.
    end method. // RemoveAttribute


    method public logical SetAttribute ( input piUserID    as integer,
                                         input pcAttrName  as character,
                                         input pcAttrValue as character ):
        /* Not configured for this project. */
        if not this-object:validateRequest("SetAttribute") then
            oLogger:Error(substitute("Unauthorized request")).

        oLogger:Debug(substitute("SetAttribute: &1: &2: &3", piUserID, pcAttrName, pcAttrValue)).

        return true.

        catch err as Progress.Lang.Error:
            oLogger:Error(substitute("SetAttribute: &1", err:GetMessage(1))).
            return false.
        end catch.
    end method. // SetAttribute


    method public logical ValidatePassword ( input piUserID   as integer,
                                             input pcPassword as character ):
        /* Validate the password hash to the value in the user's profile. */
        if not this-object:validateRequest("ValidatePassword") then do:
            oLogger:Error(substitute("Unauthorized request")).
            return false.
        end.

        oLogger:Debug(substitute("ValidatePassword: UserID: &1 Password: &2", piUserID, substring(pcPassword, 1, 1) + fill("*", length(pcPassword) - 1))).

        if piUserID eq 0 and pcPassword eq "undefined" then
            assign pcPassword = "".

        define variable lRetVal as logical no-undo initial ?.
        assign lRetVal = checkPasswordHash(piUserID, pcPassword, getPassword(piUserID)).
        postAuthenticate(piUserID, lRetVal).

        return lRetVal.

        catch err as Progress.Lang.Error:
            oLogger:Error(substitute("ValidatePassword: &1", err:GetMessage(1))).
            return false.
        end catch.
    end method. // ValidatePassword


    method public logical ValidatePassword ( input piUserID    as integer,
                                             input pcDigest    as character,
                                             input pcNonce     as character,
                                             input pcTimestamp as character ):
        /* Not configured for this project. */
        if not this-object:validateRequest("ValidatePassword") then
            oLogger:Error(substitute("Unauthorized request")).

        oLogger:Debug(substitute("ValidatePassword: &1: &2: &3: &4", piUserID, pcDigest, pcNonce, pcTimestamp)).

        return false.

        catch err as Progress.Lang.Error:
            oLogger:Error(substitute("ValidatePassword: &1", err:GetMessage(1))).
            return false.
        end catch.
    end method. // ValidatePassword


    method public integer ValidateUser ( input pcUsername as character ):
        // Users are identified by a unique integer value.
        var character cUsername = "", cDomainName = "".

        if not this-object:validateRequest("ValidateUser") then do:
            oLogger:Error(substitute("Unauthorized request")).
            return -1.
        end.

        assign
            cUsername   = entry(1, pcUsername, "@")
            cDomainName = entry(2, pcUsername, "@") when num-entries(pcUsername, "@") eq 2
            no-error
            .

        oLogger:Debug(substitute("ValidateUser: '&1@&2'", cUsername, cDomainName)).

        return getUserID(cUsername, cDomainName).

        catch err as Progress.Lang.Error:
            oLogger:Error(substitute("ValidateUser: &1", err:GetMessage(1))).
            return -1.
        end catch.
    end method. // ValidateUser

end class.
