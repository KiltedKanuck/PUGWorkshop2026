/*------------------------------------------------------------------------------
  File    : AuditManager.cls
  Purpose : Audit logic for table write or delete events.
  Assumed : Must be running in the same AVM as the ABL trigger that called it.

  Options:

  Use an environment variable called SKIP_TRIGGER_LOGIC set to any truthy value
  (e.g. "true", "yes", "1") to skip the execution of the trigger logic. This is
  primarily intended for use in testing to allow the same audit logic to be
  executed without also executing any additional trigger/auditing logic.

  Use an environment variable called SKIP_AUDIT_LOGIC set to any truthy value
  (e.g. "true", "yes", "1") to skip writing audit header and detail records in
  PerformWriteAudit and PerformDeleteAudit. Replication queue updates are unaffected
  unless SKIP_REPL_UPDATE is also set.

  Use an environment variable called SKIP_REPL_UPDATE set to any truthy value
  (e.g. "true", "yes", "1") to skip writing replication queue records in
  PerformReplUpdate.

  Usage:

    /* Write trigger */
    trigger procedure for write of <table_name>
      new buffer btNewBuffer old buffer btOldBuffer.

    OpenEdge.LoadSuite.Common.Util.AuditManager:PerformWriteAudit(
      input  "<table_name>":U,
      input  buffer btOldBuffer:handle,
      input  buffer btNewBuffer:handle,
      input  "<comma_delimited_audit_fields>":U,
      output lAuditPerformed,
      output iAuditKey).

    /* Delete trigger */
    trigger procedure for delete of <table_name>.

    define variable iAuditKey        as int64   no-undo initial 0.
    define variable lAuditPerformed  as logical no-undo initial false.
    define variable lAuditSuccessful as logical no-undo initial false.

    OpenEdge.LoadSuite.Common.Util.AuditManager:PerformDeleteAudit(
                                    input  "<table_name>":U,
                                    input  buffer <table_name>:handle,
                                    input  "<comma_delimited_audit_fields>":U,
                                    output lAuditPerformed,
                                    output iAuditKey).
------------------------------------------------------------------------------*/

block-level on error undo, throw.

// Define the name of the class package for this application.
&GLOBAL-DEFINE CLASS_PACKAGE OpenEdge.LoadSuite

using OpenEdge.Logging.ILogWriter.
using OpenEdge.Logging.LoggerBuilder.

class {&CLASS_PACKAGE}.Common.Util.AuditManager
    use-widget-pool
    final
:

    // Static table buffers for table audits.
    define private static buffer bAuditHeader for AuditHeader.
    define private static buffer bAuditDetail for AuditDetail.

    // Static table buffers for PerformReplUpdate.
    define private static buffer bReplTableXRef for ReplTableXRef.
    define private static buffer bReplProperties for ReplProperties.
    define private static buffer bReplQueueRW for ReplQueue.
    define private static buffer bReplQueueRO for ReplQueue.

    /**
     * IMPORTANT OVERRIDE FLAG!
     *
     * This allows the application database to run any normal trigger logic, including sequences.
     * This will not block the AuditManager from running, but would allow code to directly pass in a key
     * value instead of using the NextValue (sequence), or execute additional logic on a write or delete.
     *
     * Change via environment variable SKIP_TRIGGER_LOGIC and set truthy.
     * Alternatively, change directly via code using the static property, eg.:
     *   OpenEdge.LoadSuite.Common.Util.AuditManager:RunTriggerLogic = false.
     */
    define public static property RunTriggerLogic as logical initial true no-undo get. set.

    /**
     * IMPORTANT OVERRIDE FLAG!
     *
     * Controls whether audit header and detail records are written in PerformWriteAudit
     * and PerformDeleteAudit. Replication queue updates are unaffected unless
     * RunReplUpdate is also set to false.
     *
     * Change via environment variable SKIP_AUDIT_LOGIC and set truthy.
     * Alternatively, change directly via code using the static property, eg.:
     *   OpenEdge.LoadSuite.Common.Util.AuditManager:RunAuditLogic = false.
     */
    define public static property RunAuditLogic as logical initial true no-undo get. set.

    /**
     * IMPORTANT OVERRIDE FLAG!
     *
     * Controls whether replication queue records are written in PerformReplUpdate.
     *
     * Change via environment variable SKIP_REPL_UPDATE and set truthy.
     * Alternatively, change directly via code using the static property, eg.:
     *   OpenEdge.LoadSuite.Common.Util.AuditManager:RunReplUpdate = false.
     */
    define public static property RunReplUpdate as logical initial true no-undo get. set.

    define protected static property oStaticLogger as ILogWriter no-undo
        get():
            // Create single logger instance for this class.
            if not valid-object(oStaticLogger) then
                assign oStaticLogger = LoggerBuilder:GetLogger("StaticAuditManager").
            return oStaticLogger.
        end get.
        private set.

    constructor static AuditManager ():
        CheckEnvironmentOptions(). // Check environment options.
    end constructor.

    constructor private AuditManager ():
        // Private constructor, prevent direct instantiation.
    end constructor.

    method private static void CheckEnvironmentOptions ( ):
        var character cSkipTriggerLogic = "".
        var character cSkipAuditLogic   = "".
        var character cSkipReplUpdate   = "".

        // Environment variable must be explicitly present and set to a valid truthy value.
        assign cSkipTriggerLogic = trim(os-getenv("SKIP_TRIGGER_LOGIC")).
        if (cSkipTriggerLogic gt "") eq true and can-do("true,yes,1", cSkipTriggerLogic) then do:
            {&CLASS_PACKAGE}.Common.Util.AuditManager:RunTriggerLogic = false.
            oStaticLogger:Warn("Execution of trigger logic will be skipped!":u).
        end.

        assign cSkipAuditLogic = trim(os-getenv("SKIP_AUDIT_LOGIC")).
        if (cSkipAuditLogic gt "") eq true and can-do("true,yes,1", cSkipAuditLogic) then do:
            {&CLASS_PACKAGE}.Common.Util.AuditManager:RunAuditLogic = false.
            oStaticLogger:Warn("Writing of audit records will be skipped!":u).
        end.

        assign cSkipReplUpdate = trim(os-getenv("SKIP_REPL_UPDATE")).
        if (cSkipReplUpdate gt "") eq true and can-do("true,yes,1", cSkipReplUpdate) then do:
            {&CLASS_PACKAGE}.Common.Util.AuditManager:RunReplUpdate = false.
            oStaticLogger:Warn("Writing of replication queue records will be skipped!":u).
        end.

        catch err as Progress.Lang.Error:
            oStaticLogger:Error(substitute("Error while checking environment options: &1":u, err:GetMessage(1)), err).
        end catch.
    end method. // CheckEnvironmentOptions

    method public static logical PerformReplUpdate ( input pcTableName as character,
                                                     input pcEventType as character,
                                                     input phOldBuffer as handle,
                                                     input phNewBuffer as handle ):
        var character cRowid, cRecID.
        var integer iP2SplitNum, iP2QThreadNum.
        var int64 iP2RecidModulo.
        var logical lCreatedOne = false.

        if not {&CLASS_PACKAGE}.Common.Util.AuditManager:RunReplUpdate then
            return false.

        find first bReplTableXRef
             where bReplTableXRef.SrcDB    eq ldbname(1)
               and bReplTableXRef.SrcTable eq pcTableName
               no-lock no-error.

        if available(bReplTableXRef) and bReplTableXRef.GenQRec then do:
            case pcEventType:
                when "Create":u or
                when "Update":u then
                    assign cRowID = string(phNewBuffer:rowid).
                when "Delete":u then
                    assign cRowID = string(phOldBuffer:rowid).
            end case.

            // Start with thread ID from the ReplTableXref assignment
            assign iP2QThreadNum = bReplTableXRef.QThread.

            // Check if splitting this thread
            find first bReplProperties
                 where bReplProperties.PropertyName eq "SPLIT_THREAD":u + string(iP2QThreadNum) no-lock no-error.

            if available(bReplProperties) then do:
                iP2SplitNum = minimum(integer(bReplProperties.PropertyValue), 10) no-error. // Max is 10 splits

                // IF we"re splitting,then calculate the modulo of the RECID
                if iP2SplitNum > 0  then do:
                    case pcEventType:
                        when "Create":u or
                        when "Update":u then
                            assign cRecID = string(phNewBuffer:recid).
                        when "Delete":u then
                            assign cRecID = string(phOldBuffer:recid).
                    end case.

                    assign iP2RecidModulo = int64(cRecID) modulo iP2SplitNum.
                end.
                else
                    assign iP2RecidModulo = 0.

                // Now do the split calcuation for potentially sendsing to an alternate thread
                if iP2RecidModulo gt 0 then
                    assign iP2QThreadNum = iP2QThreadNum * 10 + iP2RecidModulo. // This means thread 5 splits would be 51,52,53,etc.
            end. // splitting threads

            find last bReplQueueRW
                where bReplQueueRW.SrcDB     eq ldbname(1)
                  and bReplQueueRW.SrcTable  eq pcTableName
                  and bReplQueueRW.SrcRecord eq cRowID
                  exclusive-lock no-wait no-error.

            if locked(bReplQueueRW) then do:
                /**
                 * If some other process has a lock on the ReplQueue record then we need a separate ReplQueue record
                 * in the same thread but a later sequence so that the actions stay in the correct order, in case the
                 * ROWID represents both a record that has been deleted in the locked record and a newer record that is
                 * re-using the ROWID in this pass
                 */
                find last bReplQueueRO
                    where bReplQueueRO.SrcDB     eq ldbname(1)
                      and bReplQueueRO.SrcTable  eq pcTableName
                      and bReplQueueRO.SrcRecord eq cRowID
                      no-lock no-error.

                if available(bReplQueueRO) then do:
                    create bReplQueueRW.
                    assign
                        bReplQueueRW.SrcDB      = ldbname(1)
                        bReplQueueRW.SrcTable   = pcTableName
                        bReplQueueRW.SrcRecord  = cRowID
                        bReplQueueRW.SrcTransID = dbtaskid(1)
                        bReplQueueRW.EventType  = substring(pcEventType, 1, 1)
                        bReplQueueRW.EventDate  = today
                        bReplQueueRW.EventTime  = string(time,"HH:MM:SS":u)
                        bReplQueueRW.Sequence   = next-value(NextReplNum)
                        bReplQueueRW.Username   = userid
                        bReplQueueRW.QThread    = bReplQueueRO.QThread
                        lCreatedOne             = true.
                end.
            end. // locked

            if not lCreatedOne then do:
                if not available(bReplQueueRW) or
                    (available(bReplQueueRW) and bReplQueueRW.Applied eq true) or
                    (available(bReplQueueRW) and bReplQueueRW.EventType eq "D":u) then do:
                    /**
                     * Make sure that we keep updates for the same ROWID for the same table in the same thread -
                     * don't let the new record get assigned a different split thread and possibly get the event
                     * types processed in the wrong order.
                     */
                    if available(bReplQueueRW) then
                        assign iP2QThreadNum = bReplQueueRW.QThread.

                    create bReplQueueRW.
                    assign
                        bReplQueueRW.SrcDB      = ldbname(1)
                        bReplQueueRW.SrcTable   = pcTableName
                        bReplQueueRW.SrcRecord  = cRowID
                        bReplQueueRW.SrcTransID = dbtaskid(1)
                        bReplQueueRW.EventType  = substring(pcEventType, 1, 1)
                        bReplQueueRW.EventDate  = today
                        bReplQueueRW.EventTime  = string(time,"HH:MM:SS":u)
                        bReplQueueRW.Sequence   = next-value(NextReplNum)
                        bReplQueueRW.Username   = userid
                        bReplQueueRW.QThread    = iP2QThreadNum.
                end. // do if we need a new queue record
                else
                    assign
                        bReplQueueRW.SrcTransID = dbtaskid(1)
                        bReplQueueRW.EventType  = substring(pcEventType, 1, 1)
                        bReplQueueRW.QThread    = iP2QThreadNum
                        bReplQueueRW.Sequence   = next-value(NextReplNum)
                        bReplQueueRW.EventDate  = today
                        bReplQueueRW.EventTime  = string(time,"HH:MM:SS":u).

                release bReplQueueRW.
            end. // do if we didn"t encounter a locked ReplQueue record for the same srcTable/ROWID combo

            oStaticLogger:Info(substitute("Completed replication update for &1 on table '&2'":u, pcEventType, pcTableName)).
        end. // do if replTableXref indicates we are replicating the current table
    end method. // PerformReplUpdate

    method public static logical PerformWriteAudit ( input  pcTableName      as character,
                                                     input  phOldBuffer      as handle,
                                                     input  phNewBuffer      as handle,
                                                     input  pcFieldsToAudit  as character,
                                                     output plAuditPerformed as logical,
                                                     output piAuditKey       as int64 ):
        var logical lAuditSuccessful = false, lAuditHeaderCreated = false.
        var character cAuditType = "Write":u, cBufferFieldName = "":u, cBufferFieldValueNew = "":u, cBufferFieldValueOld = "":u.
        var handle hNewBufferField, hOldBufferField.
        var integer iLoop = 0, iLoopFields = 0.

        assign
            plAuditPerformed  = false
            piAuditKey        = 0
            .

        if not valid-handle(phOldBuffer) or not valid-handle(phNewBuffer) then
            return false.

        if phNewBuffer:buffer-compare(phOldBuffer, "":u, "":u, "":u, true) then
            return false.

        assign cAuditType = if phNewBuffer:new then "Create":u else "Update":u.

        {&CLASS_PACKAGE}.Common.Util.AuditManager:PerformReplUpdate(pcTableName, cAuditType, phOldBuffer, phNewBuffer).

        if not {&CLASS_PACKAGE}.Common.Util.AuditManager:RunAuditLogic then
            return false.

        do transaction on error undo, leave:
            assign iLoopFields = num-entries(pcFieldsToAudit).

            FIELDBLK:
            do iLoop = 1 to iLoopFields:
                assign cBufferFieldName = entry(iLoop, pcFieldsToAudit).

                if cBufferFieldName eq "":u then
                    next FIELDBLK.

                assign
                    hNewBufferField = phNewBuffer:buffer-field(cBufferFieldName)
                    hOldBufferField = phOldBuffer:buffer-field(cBufferFieldName)
                    .

                if hNewBufferField eq ? or hOldBufferField eq ? then
                    next FIELDBLK.

                if not GetFieldValueForAudit(hNewBufferField, output cBufferFieldValueNew) then
                    next FIELDBLK.

                if not GetFieldValueForAudit(hOldBufferField, output cBufferFieldValueOld) then
                    next FIELDBLK.

                if cAuditType eq "Create":u or cBufferFieldValueNew ne cBufferFieldValueOld then do:
                    if not lAuditHeaderCreated then
                        assign lAuditHeaderCreated = CreateAuditHeader(cAuditType, pcTableName, output piAuditKey).

                    if lAuditHeaderCreated then
                        CreateAuditDetail(piAuditKey, cBufferFieldName, cBufferFieldValueOld, cBufferFieldValueNew).
                end.
            end.

            if lAuditHeaderCreated then
                assign lAuditSuccessful = ProcessAudits(piAuditKey).
        end.

        if lAuditSuccessful then
            assign plAuditPerformed = true.

        oStaticLogger:Info(substitute("Audit &1 for &2 of table '&3' with AuditKey '&4'":u,
                                      trim(string(plAuditPerformed, "performed/failed")), cAuditType, pcTableName, piAuditKey)).

        return lAuditSuccessful.

        catch err as Progress.Lang.Error:
            oStaticLogger:Error(substitute("Error performing write audit: &1":u, err:GetMessage(1))).
            if session:error-stack-trace then
                oStaticLogger:Error(err:CallStack).
        end catch.
        finally:
            // Reserved for any cleanup.
        end finally.
    end method. // PerformWriteAudit

    method public static logical PerformDeleteAudit ( input  pcTableName      as character,
                                                      input  phOldBuffer      as handle,
                                                      input  pcFieldsToAudit  as character,
                                                      output plAuditPerformed as logical,
                                                      output piAuditKey       as int64 ):
        var logical lAuditSuccessful = false, lAuditHeaderCreated = false.
        var character cBufferFieldName = "":u, cBufferFieldValueNew = "":u, cBufferFieldValueOld = "":u.
        var handle hOldBufferField.
        var integer iLoop = 0, iLoopFields = 0.

        assign
            plAuditPerformed  = false
            piAuditKey        = 0
            .

        if not valid-handle(phOldBuffer) then
            return false.

        {&CLASS_PACKAGE}.Common.Util.AuditManager:PerformReplUpdate(pcTableName, "Delete":u, phOldBuffer, phOldBuffer).

        if not {&CLASS_PACKAGE}.Common.Util.AuditManager:RunAuditLogic then
            return false.

        do transaction on error undo, leave:
            assign iLoopFields = num-entries(pcFieldsToAudit).

            FIELDBLK:
            do iLoop = 1 to iLoopFields:
                assign cBufferFieldName = entry(iLoop, pcFieldsToAudit).

                if cBufferFieldName eq "":u then
                    next FIELDBLK.

                assign hOldBufferField = phOldBuffer:buffer-field(cBufferFieldName).

                if hOldBufferField eq ? then
                    next FIELDBLK.

                if not GetFieldValueForAudit(hOldBufferField, output cBufferFieldValueOld) then
                    next FIELDBLK.

                assign cBufferFieldValueNew = "":u.

                if not lAuditHeaderCreated then
                    assign lAuditHeaderCreated = CreateAuditHeader("Delete":u, pcTableName, output piAuditKey).

                if lAuditHeaderCreated then
                    CreateAuditDetail(piAuditKey, cBufferFieldName, cBufferFieldValueOld, cBufferFieldValueNew).
            end.

            if lAuditHeaderCreated then
                assign lAuditSuccessful = ProcessAudits(piAuditKey).
        end.

        if lAuditSuccessful then
            assign plAuditPerformed = true.

        oStaticLogger:Info(substitute("Audit &1 for Delete of table '&2' with AuditKey '&3'":u,
                                      trim(string(plAuditPerformed, "performed/failed")), pcTableName, piAuditKey)).

        return lAuditSuccessful.

        catch err as Progress.Lang.Error:
            oStaticLogger:Error(substitute("Error performing delete audit: &1":u, err:GetMessage(1))).
            if session:error-stack-trace then
                oStaticLogger:Error(err:CallStack).
        end catch.
        finally:
            // Reserved for any cleanup.
        end finally.
    end method. // PerformDeleteAudit

    /** Private Helper Methods */

    method private static logical GetFieldValueForAudit ( input  phBufferField as handle,
                                                          output pcValue       as character ):
        var character cDataType = "":u.

        assign pcValue = "":u.

        if not valid-handle(phBufferField) then
            return false.

        assign cDataType = caps(phBufferField:data-type) no-error.

        // Do not attempt to coerce LOB values to character for audit detail text values.
        if cDataType eq "BLOB":u or cDataType eq "CLOB":u then do:
            oStaticLogger:Debug(substitute("Skipping audit field '&1' because type '&2' cannot be copied to character.":u,
                                           phBufferField:name, cDataType)).
            error-status:error = false.
            return false.
        end.

        assign pcValue = string(phBufferField:buffer-value) no-error.
        if error-status:error then do:
            oStaticLogger:Warn(substitute("Skipping audit field '&1' due to conversion error (type '&2'): &3":u,
                                    phBufferField:name, cDataType, error-status:get-message(1))).
            error-status:error = false.
            return false.
        end.

        if pcValue eq ? then
            assign pcValue = "":u.

        return true.
    end method. // GetFieldValueForAudit

    method private static logical CreateAuditHeader ( input  pcAuditType as character,
                                                      input  pcTableName as character,
                                                      output piAuditKey  as int64 ):
        var character cCallStack = "":u.
        var integer iCount = 0.
        var logical lCreated = false.

        assign piAuditKey = 0.

        FIELDBLK:
        do on error undo, leave:
            assign piAuditKey = next-value(NextAuditKey).

            create bAuditHeader.
            assign
                bAuditHeader.AuditKey  = piAuditKey
                bAuditHeader.AuditName = pcTableName
                bAuditHeader.AuditType = pcAuditType
                lCreated               = true.

            PROGBLK:
            do iCount = 1 to 18:
                if program-name(iCount) eq ? or program-name(iCount) eq "":u then
                    leave PROGBLK.

                assign cCallStack = cCallStack + ",":u + program-name(iCount).
            end.

            assign bAuditHeader.CallStack = trim(cCallStack, ",":u).
        end.

        oStaticLogger:Debug(substitute("Created '&1' header for &2 of '&3'":u,
                                       piAuditKey, pcAuditType, pcTableName)).

        return lCreated.

        catch err as Progress.Lang.Error:
            oStaticLogger:Error(substitute("Error creating audit header: &1":u, err:GetMessage(1))).
            if session:error-stack-trace then
                oStaticLogger:Error(err:CallStack).
        end catch.
        finally:
            // Reserved for any cleanup.
        end finally.
    end method. // CreateAuditHeader

    method private static void CreateAuditDetail ( input piAuditKey    as int64,
                                                   input pcBufferField as character,
                                                   input pcOldValue    as character,
                                                   input pcNewValue    as character ):
        do on error undo, leave:
            create bAuditDetail.
            assign
                bAuditDetail.AuditKey    = piAuditKey
                bAuditDetail.AuditEntity = pcBufferField
                bAuditDetail.BeforeValue = pcOldValue
                bAuditDetail.AfterValue  = pcNewValue
                .

            oStaticLogger:Debug(substitute("Created '&1' detail for '&2': '&3' -> '&4'":u,
                                           piAuditKey, pcBufferField, pcOldValue, pcNewValue)).
        end.
    end method. // CreateAuditDetail

    method private static logical ProcessAudits ( input piAuditKey as int64 ):
        var logical lSuccessful = false.

        find first bAuditHeader exclusive-lock
            where bAuditHeader.AuditKey = piAuditKey.

        if not available(bAuditHeader) then
            return false.

        do on error undo, leave:
            assign
                bAuditHeader.CreatedBy         = userid
                bAuditHeader.AuthenticatedUser = userid
                bAuditHeader.CreatedDate       = today
                bAuditHeader.CreatedTime       = string(time, 'HH:MM:SS')
                bAuditHeader.UpdateBy          = bAuditHeader.CreatedBy
                bAuditHeader.UpdateDate        = bAuditHeader.CreatedDate
                bAuditHeader.UpdateTime        = bAuditHeader.CreatedTime
                bAuditHeader.ProfName          = "":u
                bAuditHeader.ProgramName       = "OpenEdge.LoadSuite.Common.Util.AuditManager":u
                bAuditHeader.WindowTitle       = "":u
                bAuditHeader.ParentAuditKey    = 0
                lSuccessful                    = true
                .
        end.

        return lSuccessful.
    end method. // ProcessAudits

end class.
