/**************************************************************************************************************************
Copyright (c) 2026 by Progress Software Corporation and/or one of its subsidiaries or affiliates. All rights reserved.
***************************************************************************************************************************/
/*------------------------------------------------------------------------
    File        : ContextService
    Purpose     : Allow modification of a user's context state
    Description :
    Author(s)   : Dustin Grau
    Created     : Mon Jun 15 13:43:00 EDT 2026
    Notes       :

    DOH Mapping: logs.map

    Provides two endpoints:
    - /list: returns metadata for allowed text files in SESSION:TEMP-DIRECTORY
    - /download: returns file content for an indexed file from the same folder
------------------------------------------------------------------------*/

block-level on error undo, throw.

// Define the name of the class package for this application.
&GLOBAL-DEFINE CLASS_PACKAGE OpenEdge.LoadSuite

using {&CLASS_PACKAGE}.Handler.UserContextHandler.
using OpenEdge.Logging.ILogWriter.
using OpenEdge.Logging.LoggerBuilder.

class {&CLASS_PACKAGE}.Interface.ContextService
    use-widget-pool
    final
:

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
     * Checks if the user's current context is still valid.
     */
    method public void CheckValidUserContext ( output pcUserID as character,
                                               output plValid  as logical ):
        // If the user makes it to this point, then their session was still valid.
        // The business entity (class) could only be called if this were the case.
        assign
            pcUserID = userid(ldbname(1))
            plValid  = true
            .
    end method. // CheckValidUserContext

    /**
     * Sets the user's current context as invalidated by writing the sessionInvalidated
     * and loginExpiration properties to ContextDetail for the current session.
     * The next request from this session would receive an error.
     */
    method public void InvalidateUserContext ( output pdExpired as datetime-tz ):
        if not {&CLASS_PACKAGE}.Common.Util.ContextManager:UseContextManager then do:
            oLogger:Warn("InvalidateUserContext skipped: context management is not enabled.":u).
            assign pdExpired = ?.
        end.
        else
            assign pdExpired = UserContextHandler:invalidateCurrentSession().

        catch err as Progress.Lang.Error:
            oLogger:Error(substitute("Error invalidating user context: &1":u, err:GetMessage(1)), err).
            undo, throw err.
        end catch.
    end method. // InvalidateUserContext

    /**
     * Performs a cleanup of user context records for a specific username.
     */
    method public void CleanupUserContext ( input  pcUserID  as character,
                                            output plSuccess as logical ):
        if not {&CLASS_PACKAGE}.Common.Util.ContextManager:UseContextManager then do:
            oLogger:Warn("CleanupUserContext skipped: context management is not enabled.":u).
            assign plSuccess = false.
            return.
        end.

        if (trim(pcUserID) gt "":u) ne true then
            undo, throw new Progress.Lang.AppError("Missing UserID":u).

        {&CLASS_PACKAGE}.Common.Util.ContextManager:deleteContextsByUser(trim(pcUserID)).

        assign plSuccess = true. // If we get here, it's good.

        catch err as Progress.Lang.Error:
            oLogger:Error(substitute("Error removing user context: &1":u, err:GetMessage(1)), err).
            undo, throw err.
        end catch.
    end method. // CleanupUserContext

end class.
