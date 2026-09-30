/**
 * Manage the application context for a user session via hierarchical tables.
 *
 * Normal request execution flow (target pattern for load/locking tests):
 *
 * 1) Resolve ContextID from current request CPO/session (UserContextHandler).
 * 2) Read ContextHeader by ContextID to confirm session context exists.
 * 3) New session path:
 *    - createOrUpdateContextHeader(...)
 *    - replaceContextProperties(...) to seed ContextDetail property rows
 *      only when no detail rows exist yet for the context
 * 4) Returning session path:
 *    - getContextProperty(...)
 *    - rebuild request/session properties in memory from ContextDetail
 * 5) Every request:
 *    - updateLastAccess(...) to touch ContextHeader.ContextLastAccess
 *    - optional setContextProperty(...) updates as request state changes
 * 6) Cleanup paths (logout, stale-session cleanup, lock-system cleanup):
 *    - deleteContext(...) or deleteContextsByUser(...)
 *
 * Parity notes (intentional in/out):
 * - IN: New-session detail initialization uses a CAN-FIND gate and inserts the
 *   full property set only when missing (original login behavior).
 * - IN: CAN-FIND gate intentionally does not force NO-LOCK to preserve observed
 *   lock behavior from the legacy path.
 * - OUT: Product-specific business-rule procedures and external lookups
 *   (security, hierarchy, license checks) are not duplicated here.
 * - OUT: Real customer values are not copied; generic defaults are used while
 *   preserving property names and semantics for operational parity.
 *
 * ---------------------------------------------------------------------------
 * Table role summary:
 * ---------------------------------------------------------------------------
 * - ContextHeader: one row per active login context; multiple rows per user
 *   are expected and normal. Cleaned up at logout or stale-session eviction.
 * - ContextDetail: ~57 rows per context; seeded at login, read on every
 *   request, updated during session, deleted on cleanup.
 *
 * ---------------------------------------------------------------------------
 * ContextHeader row volume:
 * ---------------------------------------------------------------------------
 * - NOT one-per-user. One row is created per context ID, which maps to one
 *   active login session. A single user can hold MULTIPLE simultaneous context
 *   headers (e.g. different products, different browser tabs, different devices).
 * - Stale-session cleanup (pre-login or logout) scans ALL headers for a user_id
 *   and deletes those that have timed out; this is the primary source of
 *   contention: a broad user_id-keyed scan + cascading context_detail deletes
 *   at exactly the moment many users are logging in simultaneously.
 * - At scale, expect O (active_sessions) headers - not O (users). A typical
 *   5,000-user system with some multi-tab/multi-device use could have
 *   10,000–15,000 header rows at peak. Cleanup reduces this, but login storms
 *   cause both inserts and deletes to happen concurrently on the same index.
 *
 * ---------------------------------------------------------------------------
 * ContextDetail row volume per context:
 * ---------------------------------------------------------------------------
 * - ~57 rows per context are created at login time, across three groups.
 * - All rows share the same ContextID, matching the parent ContextHeader.
 * - Synthetic values for each property are noted below; "" = empty string is
 *   a valid default where the real value is user- or DB-specific.
 *
 * GROUP 1 - CPO serialization envelope (~6 rows, always present):
 *   Written by prepareForSerializeContext() in UserContextHandler.
 *   These carry the encoded Client Principal and session identity.
 *
 *   Property name                  Synthetic value / notes
 *   ------------------------------ ------------------------------------------
 *   UserContextClientPrincipal1    Base64 CPO chunk 1 (30,000-char max each)
 *   UserContextClientPrincipal2    Base64 CPO chunk 2 (if CPO exceeds 30,000)
 *   UserContextContextID           The session GUID (same as ContextHeader.ContextID)
 *   UserContextUserExtra           ""  (unused in base implementation)
 *   UserContextLoginExpiration     ISO datetime-tz string, e.g. "2026-05-04T08:00:00-05:00"
 *   UserContextSessionInvalidated  ""  (set only when the session is invalidated)
 *   UserContextSessionVersion      "1" (monotonic version counter; can be fixed for load tests)
 *
 * GROUP 2 - Identity and product context (~11 rows):
 *   Written by setUserIdentityProperties and initializeUserProperties at login.
 *   These establish which product and organizational unit the user is operating in.
 *
 *   Property name                  Synthetic value / purpose
 *   ------------------------------ ------------------------------------------
 *   currentUserLogin               this-object:userID (login identity used for user-scoped lookups)
 *   currentProduct                 "LoadTest" (active product code for product-specific behavior)
 *   SubProduct                     "BASE" (optional product partition)
 *   currentBranchOverride          "NO" (branch override flag)
 *   currentAuditManagerOverride    "NO" (audit behavior override flag)
 *   currentAscProdObj              "1.0" (product object key)
 *   TopMenuObj                     "1.0" (root menu structure object key)
 *   languagePreference             "en-US" (user language/culture preference)
 *   agilityCustomerName            "Tenant A" (tenant display label)
 *   OrgLevelList                   "1" (org hierarchy levels available to user)
 *   currentOrganisationObj         "1.0" (current organization object key)
 *
 * GROUP 3 - User control properties (~40 rows):
 *   These drive per-user feature flags, viewer state, and operational defaults.
 *   Skipped on state-free AppServers but always present on full sessions.
 *
 *   Property name                     Synthetic value / purpose
 *   --------------------------------- -----------------------------------------
 *   currentCostToggle                 "NO" (allow cost visibility/actions)
 *   currentUserName                   "Generic User" (display name shown in UI)
 *   queryServiceUserName              "" (external query/report service username)
 *   queryServicePassword              "" (external query/report service password token)
 *   queryServiceFileName              "" (external query/report executable/path)
 *   queryServiceCustomApp             "" (external query/report custom app name)
 *   UserType                          "STANDARD" (user category/classification code)
 *   defaultReportGroup                "RPT-STD" (default report permission group)
 *   defaultTranGroup                  "TRN-STD" (default transaction permission group)
 *   defaultMaintgroup                 "MNT-STD" (default maintenance permission group)
 *   currentFaxReturnEmail             "no-reply@loadsuite.local" (return email for fax/eform workflow)
 *   currentLastAccessedPO             "0" (last PO viewer context key)
 *   currentLastAccessedSO             "0" (last SO viewer context key)
 *   currentLastAccessedRM             "0" (last RM viewer context key)
 *   currentMultiSession               "NO" (allow multiple simultaneous sessions)
 *   currentUserEmail                  "user@domain.local" (primary user email)
 *   currentDefaultBranch              "01" (default operating branch)
 *   currentLastAccessedINV            "0" (last inventory viewer context key)
 *   currentLastAccessedATT            "0" (last attachment viewer context key)
 *   currentLastAccessedDisp           "0" (last dispatch viewer context key)
 *   LastSOViewerCalledFromStockStatus "" (source marker for SO viewer launch)
 *   LastSOViewerCalledFromCustInfo    "" (source marker for SO viewer launch)
 *   defaultCreditgroup                "CRD-STD" (default credit group)
 *   defaultSalesAgent                 "" (default sales agent ID)
 *   defaultSAPosition                 "0" (default sales agent position)
 *   defaultBuyer                      "" (default buyer ID)
 *   defaultBuyerPosition              "0" (default buyer position)
 *   defaultSaleType                   "" (default sale type code)
 *   defaultPicker                     "" (default warehouse picker ID)
 *   currentLastAccessedCO             "0" (last customer order viewer context key)
 *   currentLastAccessedDM             "0" (last dimension viewer context key)
 *   currentLastAccessedUO             "0" (last utility/order viewer context key)
 *   useUserEmailAddress               "NO" (use user email as sender in forms)
 *   defaultPOSSalesAgent              "" (default POS sales agent ID)
 *   defaultPOSSAPosition              "0" (default POS sales agent position)
 *   viewerSalesAgentID                "" (sales agent filter in viewer screens)
 *   currentLastAccessedPK             "0" (last pick viewer context key)
 *   currentLastAccessedSH             "0" (last ship viewer context key)
 *   currentUserObj                    "1.0" (internal numeric user object key)
 *   qtyAvailableDisplay               "COMMITTED" (available quantity display mode)
 */

block-level on error undo, throw.

// Define the name of the class package for this application.
&GLOBAL-DEFINE CLASS_PACKAGE OpenEdge.LoadSuite

using {&CLASS_PACKAGE}.Common.LoginModelEnum.
using {&CLASS_PACKAGE}.Handler.UserContextHandler.
using OpenEdge.Logging.ILogWriter.
using OpenEdge.Logging.LoggerBuilder.
using Progress.Collections.List.
using Progress.Json.ObjectModel.JsonObject.
using Progress.Lang.AppError.

class {&CLASS_PACKAGE}.Common.Util.ContextManager use-widget-pool:

    /* Shared tables for user context state. */
    define private static buffer bContextHeader   for ContextHeader. // Implied Read-Write Buffer
    define private static buffer bContextHeaderRO for ContextHeader. // Explicit Read-Only Buffer
    define private static buffer bContextDetail   for ContextDetail. // Implied Read-Write Buffer
    define private static buffer bContextDetailRO for ContextDetail. // Explicit Read-Only Buffer

    /**
     * IMPORTANT OVERRIDE FLAGS!
     *
     * These static flags are set once at startup via ContextManager:Configure(), called
     * from DOHEventHandler on the first request after the database is connected. They
     * persist for the lifetime of the ABL Session unless Configure() is called again.
     *
     * lUseContextManager:
     *   When TRUE, context management is active for this ABL Application — ContextHeader
     *   and ContextDetail records will be read, written, and maintained per request.
     *   When FALSE, all context operations are bypassed. This is driven by a list via the
     *   CONTEXT_MANAGED_ABLAPPS environment variable and the current ABL Application name.
     *   Default: FALSE (disabled).
     *
     * lRunOriginalLogic:
     *   When TRUE, the original context logic from the customer application is executed,
     *   preserving FIND statement and locking behavior around ContextHeader/ContextDetail
     *   (including implicit exclusive-locks without NO-WAIT, which can contend under load).
     *   When FALSE, an alternate code path is used that applies explicit NO-LOCK/NO-WAIT
     *   patterns intended to reduce lock contention during stress testing.
     *   Default: FALSE (alternate/optimized logic).
     */
    var private static logical lUseContextManager = false.
    var private static logical lRunOriginalLogic  = false.

    /**
     * Returns TRUE when context management has been enabled via Configure().
     * Safe to read from any class after the first request has been processed.
     */
    define public static property UseContextManager as logical no-undo
        get(): return lUseContextManager. end get.
        private set.

    /* Access the service-level logging manager. */
    define static property oStaticLogger as ILogWriter no-undo
        get():
            /* Create single logger instance for this class. */
            if not valid-object(oStaticLogger) then
                assign oStaticLogger = LoggerBuilder:GetLogger("StaticContextManager").
            return oStaticLogger.
        end get.
        private set.

    constructor static ContextManager():
        // Intentionally empty; flags are set externally via Configure().
    end constructor.

    constructor private ContextManager ():
        // Private constructor, prevent direct instantiation.
    end constructor.

    /**
     * Configures the context management behavior. Must be called once at application startup
     * (via DOHEventHandler) before any context operations are performed.
     *
     * @param logical plUseContextManager Pass TRUE to enable context management for this app.
     * @param logical plRunOriginalLogic  Pass TRUE to use the original locking behavior;
     *                                   FALSE (default) uses the optimized/alternate logic.
     */
    method public static void Configure ( input plUseContextManager as logical,
                                          input plRunOriginalLogic  as logical ):
        assign
            lUseContextManager = plUseContextManager
            lRunOriginalLogic  = plRunOriginalLogic
            .

        oStaticLogger:Debug(substitute("ContextManager Configured: UseContextManager=&1, UseOriginalLogic=&2":u,
                                       trim(string(lUseContextManager, "true/false":u)),
                                       trim(string(lRunOriginalLogic, "true/false":u)))).
    end method. // Configure

    /* Release write buffer for ContextHeader. */
    method private static void releaseContextHeaderBuffer ( input pcSourceMethod as character ):
        release bContextHeader no-error.
        oStaticLogger:Trace(substitute("Releasing context header buffer from '&1'. [Error Status: &2]":u,
                                       pcSourceMethod, error-status:error)).
        if error-status:error then
            assign error-status:error = false.
    end method. // releaseContextHeaderBuffer

    /* Release write buffer for ContextDetail. */
    method private static void releaseContextDetailBuffer ( input pcSourceMethod as character ):
        release bContextDetail no-error.
        oStaticLogger:Trace(substitute("Releasing context detail buffer from '&1'. [Error Status: &2]":u,
                                       pcSourceMethod, error-status:error)).
        if error-status:error then
            assign error-status:error = false.
    end method. // releaseContextDetailBuffer

    /**
     * Returns TRUE when a ContextHeader row exists for the supplied context ID.
     */
    method public static logical contextExists ( input pcContextID as character ):
        // Leave if a blank context ID was provided.
        if (trim(pcContextID) gt "":u) ne true then return false.

        find first bContextHeaderRO no-lock
             where bContextHeaderRO.ContextID eq pcContextID no-error.

        return available(bContextHeaderRO).
    end method. // contextExists

    /**
     * Returns TRUE when one or more ContextDetail rows exist for the supplied context ID.
     */
    method public static logical contextDetailExists ( input pcContextID as character ):
        // Leave if a blank context ID was provided.
        if (trim(pcContextID) gt "":u) ne true then return false.

        if lRunOriginalLogic then
            // Original code path, included here for reference and potential reuse in load tests.
            // Purposefully does not use NO-LOCK to preserve original application behavior.
            return can-find(first bContextDetailRO // OMITTED NO-LOCK
                            where bContextDetailRO.ContextID eq pcContextID).
        else
            // Utilize an explicit no-lock on the can-find statement.
            return can-find(first bContextDetailRO no-lock
                            where bContextDetailRO.ContextID eq pcContextID).
    end method. // contextDetailExists

    /**
     * Constructs a serialized (text) payload from ContextDetail rows as stringified JSON.
     */
    method public static longchar readSerializedContext ( input pcContextID as character ):
        var longchar lcContext = "".
        var JsonObject oContext.

        // Leave if a blank context ID was provided.
        if (trim(pcContextID) gt "":u) ne true then return "".

        assign oContext = new JsonObject().
        for each bContextDetailRO no-lock
           where bContextDetailRO.ContextID eq pcContextID:
            if oContext:Has(bContextDetailRO.PropertyName) then
                oContext:Set(bContextDetailRO.PropertyName, bContextDetailRO.PropertyValue).
            else
                oContext:Add(bContextDetailRO.PropertyName, bContextDetailRO.PropertyValue).
        end.

        assign lcContext = oContext:GetJsonText().

        oStaticLogger:Debug(substitute("Read serialized context for session '&1' as &2 bytes.",
                                       pcContextID, length(lcContext, "RAW":u))).

        return lcContext.
    end method. // readSerializedContext

    /**
     * Creates (if needed) and updates the ContextHeader row for the current request/session.
     * Also refreshes ContextLastAccess.
     */
    method public static void createOrUpdateContextHeader ( input pcContextID   as character,
                                                            input pcUserID      as character,
                                                            input pcProductCode as character,
                                                            input pcSetUserInfo as character ):
        var character cContextID = trim(pcContextID), cUserID = trim(pcUserID),
                      cProductCode = trim(pcProductCode), cSetUserInfo = trim(pcSetUserInfo).

        // Leave if a blank context ID was provided.
        if (cContextID gt "":u) ne true then return.

        oStaticLogger:Debug(substitute("Modifying context header for session '&1', user '&2', product '&3'.":u,
                                       cContextID, cUserID, cProductCode)).

                                       
        if lRunOriginalLogic then do:
            // Original code path, included here for reference and potential reuse in load tests.
            // NOTE: Two requests could reach this block at the same time for the same context ID.
            // If that happens, both may try to create the row, so this path can contend under load.
            find first bContextHeader exclusive-lock
                 where bContextHeader.ContextID eq cContextID no-error.
            if not available(bContextHeader) then do:
                create bContextHeader.
                assign bContextHeader.ContextID = cContextID.
                oStaticLogger:Debug(substitute("Created context header for session '&1', user '&2', product '&3'.":u,
                                               cContextID, cUserID, cProductCode)).
            end.

            assign
                bContextHeader.ClientUserID      = cUserID
                bContextHeader.ProductCode       = cProductCode
                bContextHeader.ContextLastAccess = now
                .

            if (cSetUserInfo gt "":u) eq true then do:
                assign bContextHeader.SetUserInfo = cSetUserInfo.
                oStaticLogger:Debug(substitute("Updated user info for session '&1', user '&2', product '&3': &4":u,
                                               cContextID, cUserID, cProductCode, cSetUserInfo)).
            end.
        end. // Original Logic
        else do transaction:
            // Run a safer form of lookup and modification that should not leak a transaction.
            // First, attempt to find the record using the unique field ContextID and use no-wait to avoid lock waits.
            find bContextHeader exclusive-lock
            where bContextHeader.ContextID eq cContextID no-wait no-error.

            // Next, make sure the record is even available, and wrap all further logic within a DO block.
            if locked(bContextHeader) then
                oStaticLogger:Error(substitute("Context header record is locked for session '&1', user '&2', product '&3': &4":u,
                                               cContextID, cUserID, cProductCode, cSetUserInfo)).
            else if available(bContextHeader) then do:
                // Once past the lock check, an available record means we can safely update the value fields.
                assign
                    bContextHeader.ContextID         = cContextID
                    bContextHeader.ClientUserID      = cUserID
                    bContextHeader.ProductCode       = cProductCode
                    bContextHeader.ContextLastAccess = now
                    .

                if (cSetUserInfo gt "":u) eq true then do:
                    assign bContextHeader.SetUserInfo = cSetUserInfo.
                    oStaticLogger:Debug(substitute("Updated user info for session '&1', user '&2', product '&3': &4":u,
                                                   cContextID, cUserID, cProductCode, cSetUserInfo)).
                end.
            end.
            else if not available(bContextHeader) then do:
                // Once past the lock check, a missing record means it must be created so we do that in full.
                create bContextHeader.
                assign
                    bContextHeader.ContextID         = cContextID
                    bContextHeader.ClientUserID      = cUserID
                    bContextHeader.ProductCode       = cProductCode
                    bContextHeader.ContextLastAccess = now
                    .

                oStaticLogger:Debug(substitute("+Created user info for session '&1', user '&2', product '&3': &4":u,
                                               cContextID, cUserID, cProductCode, cSetUserInfo)).

                if (cSetUserInfo gt "":u) eq true then do:
                    assign bContextHeader.SetUserInfo = cSetUserInfo.
                    oStaticLogger:Debug(substitute("Updated user info for session '&1', user '&2', product '&3': &4":u,
                                                   cContextID, cUserID, cProductCode, cSetUserInfo)).
                end.
            end.
            else
                oStaticLogger:Warn(substitute("Unable to create/update context header record for session '&1', user '&2', product '&3'.":u,
                                              cContextID, cUserID, cProductCode)).                          
        end. // Alternate Logic

        oStaticLogger:Debug(substitute("Completed context header create/update for session '&1' (user '&2', product '&3').":u,
                                       cContextID, cUserID, cProductCode)).

        catch err as Progress.Lang.Error:
            oStaticLogger:Error(substitute("Error creating/updating context header for session '&1' (user '&2', product '&3'): &4":u,
                                           cContextID, cUserID, cProductCode, err:GetMessage(1)), err).
            undo, throw err.
        end catch.
        finally:
            // Clear any error state that may have been raised by the NO-ERROR above.
            if error-status:error then
                assign error-status:error = false.

            releaseContextHeaderBuffer("createOrUpdateContextHeader":u).
        end finally.
    end method. // createOrUpdateContextHeader

    /**
     * Updates only the ContextLastAccess timestamp for an existing context row.
     * Called on every request to track session activity and drive stale-session cleanup:
     * - Called by applyNewSessionContextFlow
     * - Called by applyReturningSessionContextFlow
     * - Called by applySessionCleanupContextFlow
     */
    method public static void updateLastAccess ( input pcContextID as character ):
        var character cContextID = trim(pcContextID).

        // Leave if a blank context ID was provided.
        if (cContextID gt "":u) ne true then return.

        oStaticLogger:Debug(substitute("Updating last-access timestamp for session '&1'.":u, cContextID)).

        if lRunOriginalLogic then do:
            // Original code path, included here for reference and potential reuse in load tests.
            // This method is called often during request traffic and uses EXCLUSIVE-LOCK by design.
            // WARNING: In heavy load tests this can possibly contribute to lock waits.
            find first bContextHeader exclusive-lock
                 where bContextHeader.ContextID eq cContextID no-error.
            if available(bContextHeader) then do:
                assign bContextHeader.ContextLastAccess = now.
                oStaticLogger:Debug(substitute("+Touched last-access timestamp for session '&1'.":u, cContextID)).
            end.
        end. // Original Logic
        else do transaction:
            // Run a safer form of lookup and modification that should not leak a transaction.
            // First, attempt to find the record using the unique field ContextID and use no-wait to avoid lock waits.
            find bContextHeader exclusive-lock
            where bContextHeader.ContextID eq cContextID no-wait no-error.

            // Next, make sure the record is even available, and wrap all further logic within a DO block.
            if locked(bContextHeader) then
                oStaticLogger:Error(substitute("Context header record is locked for session '&1', unable to set last-access timestamp.":u, cContextID)).
            else if available(bContextHeader) then do:
                assign bContextHeader.ContextLastAccess = now.
                oStaticLogger:Debug(substitute("+Touched last-access timestamp for session '&1'.":u, cContextID)).
            end.
            else
                oStaticLogger:Warn(substitute("Unable to find context header to update last-access timestamp for session '&1'.":u, cContextID)).
        end. // Alternate Logic

        // Last, always report the end of the method logic and report if still in a transaction state.
        oStaticLogger:Debug(substitute("End of logic for last-access timestamp for session '&1' [T: &2].":u, cContextID, transaction)).

        catch err as Progress.Lang.Error:
            oStaticLogger:Error(substitute("Error updating last-access timestamp for session '&1': &2":u,
                                           cContextID, err:GetMessage(1)), err).
            undo, throw err.
        end catch.
        finally:
            // Clear any error state that may have been raised by the NO-ERROR above.
            if error-status:error then
                assign error-status:error = false.

            releaseContextHeaderBuffer("updateLastAccess":u).
        end finally.
    end method. // updateLastAccess

    /**
     * Convenience overload that treats missing properties as optional.
     */
    method public static character getContextProperty ( input pcContextID    as character,
                                                        input pcPropertyName as character ):
        return getContextProperty(pcContextID, pcPropertyName, true).
    end method. // getContextProperty

    /**
     * Reads a single context property value.
     * When plOptional is FALSE, throws an AppError if the property is not found.
     */
    method public static character getContextProperty ( input pcContextID    as character,
                                                        input pcPropertyName as character,
                                                        input plOptional     as logical ):
        var character cPropertyValue = ?.

        // Leave if a blank context ID was provided.
        if (trim(pcContextID) gt "":u) ne true then return cPropertyValue.

        // Leave if a blank property name was provided.
        if (trim(pcPropertyName) gt "":u) ne true then return cPropertyValue.

        // Only log the pre-read message when the property is required to avoid noisy logs.
        if not plOptional then
            oStaticLogger:Trace(substitute("Reading required context property '&1' for session '&2'.":u,
                                           pcPropertyName, pcContextID)).

        find first bContextDetailRO no-lock
             where bContextDetailRO.ContextID eq pcContextID
               and bContextDetailRO.PropertyName eq pcPropertyName no-error.
        if available(bContextDetailRO) then
            assign cPropertyValue = bContextDetailRO.PropertyValue.
        else if not plOptional then
            undo, throw new AppError(substitute("Context property '&1' is not defined for session '&2'.":u,
                                                pcPropertyName, pcContextID),
                                     500).

        oStaticLogger:Trace(substitute("Read context property '&1' for session '&2'.":u,
                                       pcPropertyName, pcContextID)).

        return cPropertyValue.
    end method. // getContextProperty

    /**
     * Upserts a single context property row by ContextID + PropertyName.
     */
    method public static void setContextProperty ( input pcContextID      as character,
                                                   input pcPropertyName   as character,
                                                   input pcPropertyValue  as character ):
        // Leave if a blank context ID was provided.
        if (trim(pcContextID) gt "":u) ne true then return.

        // Leave if a blank property name was provided.
        if (trim(pcPropertyName) gt "":u) ne true then return.

        oStaticLogger:Trace(substitute("Saving context property '&1' for session '&2'.":u,
                                       pcPropertyName, pcContextID)).

        if lRunOriginalLogic then do:
            // Original code path, included here for reference and potential reuse in load tests.
            // Two requests can try to create the same property row at the same time.
            // This is expected in stress tests and can increase lock contention.
            find first bContextDetail exclusive-lock
                 where bContextDetail.ContextID eq pcContextID
                   and bContextDetail.PropertyName eq pcPropertyName no-error.
            if not available(bContextDetail) then do:
                create bContextDetail.
                assign
                    bContextDetail.ContextID    = pcContextID
                    bContextDetail.PropertyName = pcPropertyName
                    .
            end.
            assign bContextDetail.PropertyValue = pcPropertyValue.

            oStaticLogger:Trace(substitute("+Saved context property '&1' for session '&2' [T: &3].":u,
                                        pcPropertyName, pcContextID, transaction)).
        end. // Original Logic
        else do transaction:
            // Run a safer form of lookup and modification that should not leak a transaction.
            // First, attempt to find the record using the unique fields ContextID/PropertyName and use no-wait to avoid lock waits.
            find bContextDetail exclusive-lock
            where bContextDetail.ContextID eq pcContextID
              and bContextDetail.PropertyName eq pcPropertyName no-wait no-error.

            // Next, make sure the record is even available, and wrap all further logic within a DO block.
            if locked(bContextDetail) then
                oStaticLogger:Error(substitute("Context detail record is locked for session '&1', unable to set property '&2'.":u,
                                               pcContextID, pcPropertyName)).
            else if available(bContextDetail) then do:
                // Once past the lock check, an available record means we can safely update the value field.
                assign bContextDetail.PropertyValue = pcPropertyValue.
                oStaticLogger:Debug(substitute("+Updated property '&1' for session '&2'.":u, pcPropertyName, pcContextID)).
            end.
            else if not available(bContextDetail) then do:
                // Once past the lock check, a missing record means it must be created so we do that in full.
                create bContextDetail.
                assign
                    bContextDetail.ContextID     = pcContextID
                    bContextDetail.PropertyName  = pcPropertyName
                    bContextDetail.PropertyValue = pcPropertyValue
                    .
                oStaticLogger:Debug(substitute("+Created property '&1' for session '&2'.":u, pcPropertyName, pcContextID)).
            end.
            else
                oStaticLogger:Warn(substitute("Unable to create/update context detail record for session '&1', unable to set property '&2'.":u,
                                              pcContextID, pcPropertyName)).
        end. // Alternate Logic

        finally:
            // Clear any error state that may have been raised by the NO-ERROR above.
            if error-status:error then
                assign error-status:error = false.

            releaseContextDetailBuffer("setContextProperty":u).
        end finally.
    end method. // setContextProperty

    /**
     * Deletes a single ContextDetail property row.
     */
    method public static void deleteContextProperty ( input pcContextID    as character,
                                                      input pcPropertyName as character ):
        // Leave if a blank context ID was provided.
        if (trim(pcContextID) gt "":u) ne true then return.

        // Leave if a blank property name was provided.
        if (trim(pcPropertyName) gt "":u) ne true then return.

        oStaticLogger:Trace(substitute("Deleting context property '&1' for session '&2'.":u,
                                       pcPropertyName, pcContextID)).

        if lRunOriginalLogic then do:
            // Original code path, included here for reference and potential reuse in load tests.
            find first bContextDetail exclusive-lock
                 where bContextDetail.ContextID eq pcContextID
                   and bContextDetail.PropertyName eq pcPropertyName no-error.
            if available(bContextDetail) then do:
                delete bContextDetail.

                oStaticLogger:Trace(substitute("Deleted context property '&1' for session '&2'.":u,
                                            pcPropertyName, pcContextID)).
            end.
        end. // Original Logic
        else do transaction:
            // Run a safer form of lookup and modification that should not leak a transaction.
            // First, attempt to find the record using the unique fields ContextID/PropertyName and use no-wait to avoid lock waits.
            find bContextDetail exclusive-lock
            where bContextDetail.ContextID eq pcContextID
              and bContextDetail.PropertyName eq pcPropertyName no-wait no-error.

            // Next, make sure the record is even available, and wrap all further logic within a DO block.
            if locked(bContextDetail) then
                oStaticLogger:Error(substitute("Context detail record is locked for session '&1', unable to delete property '&2'.":u,
                                               pcContextID, pcPropertyName)).
            else if available(bContextDetail) then do:
                // Once past the lock check, an available record means we can safely delete it.
                delete bContextDetail.
                oStaticLogger:Debug(substitute("+Deleted property '&1' for session '&2'.":u, pcPropertyName, pcContextID)).
            end.
            else
                oStaticLogger:Warn(substitute("Unable to find context detail record for session '&1', unable to delete property '&2'.":u,
                                              pcContextID, pcPropertyName)).
        end. // Alternate Logic

        finally:
            // Clear any error state that may have been raised by the NO-ERROR above.
            if error-status:error then
                assign error-status:error = false.

            releaseContextDetailBuffer("deleteContextProperty":u).
        end finally.
    end method. // deleteContextProperty

    /**
     * Deletes all ContextDetail rows for a context and then removes the ContextHeader row.
     */
    method public static void deleteContext ( input pcContextID as character ):
        var character cContextID = trim(pcContextID).

        // Leave if a blank context ID was provided.
        if (cContextID gt "":u) ne true then return.

        oStaticLogger:Trace(substitute("Deleting context details for session '&1'.":u, cContextID)).

        if lRunOriginalLogic then do:
            // Original code path, included here for reference and potential reuse in load tests.
            for each bContextDetail exclusive-lock
               where bContextDetail.ContextID eq cContextID:
                delete bContextDetail.
            end.

            find first bContextHeader exclusive-lock
                 where bContextHeader.ContextID eq cContextID no-error.
            if available(bContextHeader) then do:
                delete bContextHeader.
                oStaticLogger:Trace(substitute("-Deleted all context for session '&1'.":u, cContextID)).
            end.
        end. // Original Logic
        else do transaction:
            // Run a safer form of lookup and modification that should not leak a transaction.
            // First, attempt to find the record using the unique field ContextID and use no-wait to avoid lock waits.
            find bContextHeader exclusive-lock
            where bContextHeader.ContextID eq cContextID no-wait no-error.

            // Next, make sure the record is even available, and wrap all further logic within a DO block.
            if locked(bContextHeader) then
                oStaticLogger:Error(substitute("Context header record is locked for session '&1', unable to delete record.":u, cContextID)).
            else if available(bContextHeader) then do:
                // Once past the lock check, an available record means we can safely delete the child records first.
                for each bContextDetail exclusive-lock
                where bContextDetail.ContextID eq cContextID:
                    delete bContextDetail.
                end.

                // Now the parent record can be safely deleted.
                delete bContextHeader.
                oStaticLogger:Debug(substitute("-Deleted all context for session '&1'.":u, cContextID)).
            end.
            else
                oStaticLogger:Warn(substitute("Unable to find context header record for session '&1', unable to delete record.":u, cContextID)).
        end. // Alternate Logic

        catch err as Progress.Lang.Error:
            oStaticLogger:Error(substitute("Error deleting context for session '&1': &2":u,
                                           cContextID, err:GetMessage(1)), err).
            undo, throw err.
        end catch.
        finally:
            // Clear any error state that may have been raised by the NO-ERROR above.
            if error-status:error then
                assign error-status:error = false.

            releaseContextDetailBuffer("deleteContext":u).
            releaseContextHeaderBuffer("deleteContext":u).
        end finally.
    end method. // deleteContext

    /**
     * Deletes all context rows for a specific user across all active context IDs.
     * Useful for stale-session cleanup and lock-stress simulations.
     */
    method public static void deleteContextsByUser ( input pcUserID as character ):
        var character cContextID = "", cUserID = trim(pcUserID).
        var List<OpenEdge.Core.String> oContextList = new List<OpenEdge.Core.String>().
        var integer iCount = 0, iContext = 0.

        // Leave if a blank user ID was provided.
        if (cUserID gt "":u) ne true then return.

        oStaticLogger:Trace(substitute("Deleting all context records for User '&1'.":u, cUserID)).

        if lRunOriginalLogic then do:
            // Original code path, included here for reference and potential reuse in load tests.
            for each bContextHeader exclusive-lock
               where bContextHeader.ClientUserID eq cUserID:
                assign cContextID = bContextHeader.ContextID.

                for each bContextDetail exclusive-lock
                    where bContextDetail.ContextID eq cContextID:
                    delete bContextDetail.
                end.

                delete bContextHeader.
                oStaticLogger:Trace(substitute("Deleted all context records for User '&1'.":u, cUserID)).
            end.
        end. // Original Logic
        else do:
            // First, iterate over the context headers using a read-only scan to gather affected context IDs.
            for each bContextHeaderRO no-lock
               where bContextHeaderRO.ClientUserID eq cUserID:
                oContextList:Add(new OpenEdge.Core.String(bContextHeaderRO.ContextID)).
            end.

            // Next, iterate over the gathered context IDs and delete each context using the dedicated method.
            assign iCount = oContextList:Count.
            do iContext = 1 to iCount:
                assign cContextID = string(cast(oContextList:Get(iContext), OpenEdge.Core.String):Value).
                deleteContext(cContextID).
            end.
        end. // Alternate Logic

        catch err as Progress.Lang.Error:
            oStaticLogger:Error(substitute("Error deleting context records for User '&1': &2":u,
                                           cUserID, err:GetMessage(1)), err).
            undo, throw err.
        end catch.
    end method. // deleteContextsByUser

end class.