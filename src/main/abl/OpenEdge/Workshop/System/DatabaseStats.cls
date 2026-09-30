/**************************************************************************************************************************
Copyright (c) 2026 by Progress Software Corporation and/or one of its subsidiaries or affiliates. All rights reserved.
***************************************************************************************************************************/
/*------------------------------------------------------------------------
   File        : DatabaseStats
   Purpose     : Returns database statistics from VSTs
   Description :
   Author(s)   : dugrau
   Created     : Thu Jul 16 15:52:12 EST 2026
   Notes       : Requires an alias "statsdb" to be created PRIOR
                 to creating an instance of this class!
 ----------------------------------------------------------------------*/

block-level on error undo, throw.

// Define the name of the class package for this application.
&GLOBAL-DEFINE CLASS_PACKAGE OpenEdge.Workshop

using Progress.Json.ObjectModel.JsonObject.

class {&CLASS_PACKAGE}.System.DatabaseStats
    use-widget-pool
    final
:

    /**
        Looks up a single startup parameter by name from the tt-DbParams staging table.
        Returns ? when the parameter is not present, matching the ProMonitor convention.

        @param character pcName [INPUT] Startup flag name, e.g. "-B", "-directio"
        @return character Parameter value, or ? if not found
      */
    method private character GetDbParam ( input pcName as character ):
        find first statsdb._DbParams no-lock
             where statsdb._DbParams._DbParams-Name eq pcName no-error.
        if not available(statsdb._DbParams) then return ?.
        return statsdb._DbParams._DbParams-Value.
    end method. /* GetDbParam */

    /**
        Sanitizes a VST-derived string for safe use as a JSON property name.
        Centralizes all key transformations so future changes apply in one place.

        @param character pcName [INPUT] Raw property name from a VST field
        @return character Sanitized name suitable for use as a JSON key
      */
    method private character MakeJsonSafe ( input pcName as character ):
        return replace(trim(pcName), " ":u, "_":u).
    end method. /* MakeJsonSafe */

    /**
        Returns the active database startup parameters from the _DbParams VST (OE12+).
        Loads all VST records into a temp-table first, then resolves each parameter
        via GetDbParam (returning "-1" when absent), matching the ProMonitor pattern.
        The biThresholdMB value is converted from bytes to megabytes.

        @return JsonObject containing startup parameter values keyed by friendly name
      */
    method public JsonObject GetConfigStats():
        var JsonObject oResult = new JsonObject().

        oResult:Add("aiArchiveInterval":u,    int64(this-object:GetDbParam("-aiarcinterval"))). // Seconds between automatic AI extent archiving cycles
        oResult:Add("aiBuffers":u,            int64(this-object:GetDbParam("-aibufs"))).  // After-image log buffers; more buffers reduce AI I/O waits when AI is enabled
        oResult:Add("biBuffers":u,            int64(this-object:GetDbParam("-bibufs"))).  // Before-image log buffers; more buffers reduce BI I/O waits under write-heavy load
        oResult:Add("biThresholdMB":u,        int64(this-object:GetDbParam("-bithold")) / 1024 / 1024). // BI file size in MB that triggers an automatic BI truncation
        oResult:Add("bufferPoolSize":u,       int64(this-object:GetDbParam("-B"))).       // Number of database buffers in the primary buffer cache; larger = more data held in memory
        oResult:Add("directIO":u,             int64(this-object:GetDbParam("-directio")) gt 0). // True when Direct I/O is enabled, bypassing the OS file cache for database writes
        oResult:Add("hashBuckets":u,          int64(this-object:GetDbParam("-hash"))).    // Hash buckets for the lock table; more buckets reduce collision under high lock volume
        oResult:Add("lockTableEntries":u,     int64(this-object:GetDbParam("-L"))).       // Maximum concurrent record locks; governs the size of the in-memory lock table
        oResult:Add("maxClientsPerServer":u,  int64(this-object:GetDbParam("-Ma"))).      // Maximum ABL client sessions per server process before a new server spawns
        oResult:Add("maxOpenFiles":u,         int64(this-object:GetDbParam("-Mf"))).      // Maximum simultaneously open database files
        oResult:Add("maxPrivateBufferPool":u, int64(this-object:GetDbParam("-Bpmax"))).   // Maximum private buffer pool size in buffers per user session
        oResult:Add("maxServers":u,           int64(this-object:GetDbParam("-Mn"))).      // Hard cap on total server processes across all brokers
        oResult:Add("maxServersPerBroker":u,  int64(this-object:GetDbParam("-Mpb"))).     // Maximum server processes managed by a single login broker
        oResult:Add("maxSharedMemSegment":u,  int64(this-object:GetDbParam("-Mxs"))).     // Maximum shared memory segment size in KB
        oResult:Add("maxUsers":u,             int64(this-object:GetDbParam("-n"))).       // Maximum number of connected user sessions allowed
        oResult:Add("minClientsPerServer":u,  int64(this-object:GetDbParam("-Mi"))).      // Minimum clients per server; new server spawns when existing servers exceed this
        oResult:Add("msgBufferSize":u,        int64(this-object:GetDbParam("-Mm"))).      // Maximum network message buffer size in bytes; governs client/server message segmentation
        oResult:Add("semaphoreSets":u,        int64(this-object:GetDbParam("-semsets"))). // Number of OS semaphore sets allocated (Unix only)
        oResult:Add("spinLockRetries":u,      int64(this-object:GetDbParam("-spin"))).    // CPU spin-wait retries before yielding on a latch; higher reduces context switches on busy systems

        return oResult.
    end method. /* GetConfigStats */

    /**
        Returns buffer cache efficiency statistics from the _ActBuffer VST.
        Field names follow the _Buffer-* prefix convention confirmed by
        the ProMonitor reference implementation.

        @return JsonObject containing logicalReads, physicalReads, and physicalWrites
      */
    method public JsonObject GetBufferCacheStats():
        var JsonObject oResult = new JsonObject().

        for first statsdb._ActBuffer no-lock:
            oResult:Add("logicalReads":u,   statsdb._ActBuffer._Buffer-LogicRds).  // Total buffer read requests; includes both cache hits and misses
            oResult:Add("logicalWrites":u,  statsdb._ActBuffer._Buffer-LogicWrts). // Total buffer write requests; marks buffers dirty for eventual flush
            oResult:Add("physicalReads":u,  statsdb._ActBuffer._Buffer-OSRds).     // Actual OS disk reads; cache misses that required fetching from disk
            oResult:Add("physicalWrites":u, statsdb._ActBuffer._Buffer-OSWrts).    // Actual OS disk writes; dirty buffers flushed to disk by APW or checkpoint
        end.

        return oResult.
    end method. /* GetBufferCacheStats */

    /**
        Returns the active connection count from the _Connect VST.

        @return JsonObject containing active connection count
      */
    method public JsonObject GetConnectionStats():
        var JsonObject oResult = new JsonObject().
        var integer iCount = 0, iBlocked = 0.

        for each statsdb._Connect no-lock
           where statsdb._Connect._Connect-Usr ne ?:
            assign iCount = iCount + 1.
            if statsdb._Connect._Connect-Wait ne ? and statsdb._Connect._Connect-Wait ne " --" then
                assign iBlocked = iBlocked + 1.
        end.

        oResult:Add("active":u,  iCount).   // Sessions with an assigned user number; excludes unoccupied pre-allocated slots
        oResult:Add("blocked":u, iBlocked). // Active sessions currently waiting on a lock or resource (_Connect-Wait is set)

        return oResult.
    end method. /* GetConnectionStats */

    /**
        Returns aggregate lock contention statistics from the _ActSummary VST.
        ProMonitor sources lock aggregates from _Summary-RecLock (requests)
        and _Summary-RecWait (waits).

        @return JsonObject containing requests and waits
      */
    method public JsonObject GetRecordLockStats():
        var JsonObject oResult = new JsonObject().

        for first statsdb._ActSummary no-lock:
            oResult:Add("requests":u, statsdb._ActSummary._Summary-RecLock). // Cumulative record lock requests since database startup
            oResult:Add("waits":u,    statsdb._ActSummary._Summary-RecWait). // Times a lock request had to wait because another session held the lock
        end.

        return oResult.
    end method. /* GetRecordLockStats */

    /**
        Returns transaction throughput statistics from the _ActSummary VST.
        Field names follow the _Summary-* prefix convention confirmed by
        the ProMonitor reference implementation.

        @return JsonObject containing commits and rollbacks
      */
    method public JsonObject GetTransactionStats():
        var JsonObject oResult = new JsonObject().

        for first statsdb._ActSummary no-lock:
            oResult:Add("checkpoints":u,   statsdb._ActSummary._Summary-Chkpts).  // Checkpoints completed; each flushes all dirty buffers to disk
            oResult:Add("commits":u,       statsdb._ActSummary._Summary-Commits). // Transactions successfully committed since startup
            oResult:Add("rollbacks":u,     statsdb._ActSummary._Summary-Undos).   // Transactions rolled back (UNDO) since startup
            oResult:Add("uptimeSeconds":u, statsdb._ActSummary._Summary-UpTime).  // Seconds the database has been running since last startup
        end.

        return oResult.
    end method. /* GetTransactionStats */

    /**
        Returns per-latch lock and wait counts from the _Latch VST.
        Each latch is keyed by its unique numeric ID (_Latch-Id), with the
        name included as a field inside each entry. Keying by name is unsafe
        because _Latch-Name is not guaranteed unique across all latch records.

        @return JsonObject keyed by latch ID, each value containing name, locks and waits
      */
    method public JsonObject GetLatchStats():
        var JsonObject oResult = new JsonObject(), oEntry.

        for each statsdb._Latch no-lock by statsdb._Latch._Latch-Name:
            if statsdb._Latch._Latch-Lock eq 0 and statsdb._Latch._Latch-Wait eq 0 then next. // Skip idle latches; matches ProMonitor promon2.p pattern
            if trim(statsdb._Latch._Latch-Name) eq "" then next.
            assign oEntry = new JsonObject().
            oEntry:Add("name":u,  trim(statsdb._Latch._Latch-Name)).
            oEntry:Add("locks":u, statsdb._Latch._Latch-Lock). // Times this latch was successfully acquired in the current sample period
            oEntry:Add("waits":u, statsdb._Latch._Latch-Wait). // Times a thread had to spin or yield waiting for this latch; non-zero indicates contention
            oResult:Add(string(statsdb._Latch._Latch-Id), oEntry).
        end.

        return oResult.
    end method. /* GetLatchStats */

    /**
        Returns resource contention wait counts from the _Resrc VST.
        Resources represent internal engine-level objects such as database buffer
        pool slots, semaphores, and shared memory structures. Only entries where
        lock or wait is non-zero are included, matching the ProMonitor convention.
        Resource names are sanitized (spaces replaced with underscores) for use as JSON keys.

        @return JsonObject keyed by resource name, each value containing locks and waits
      */
    method public JsonObject GetResourceWaitStats():
        var JsonObject oResult = new JsonObject(), oEntry.

        for each statsdb._Resrc no-lock by statsdb._Resrc._Resrc-Name:
            if statsdb._Resrc._Resrc-Lock eq 0 and statsdb._Resrc._Resrc-Wait eq 0 then next. // Skip idle resources; matches ProMonitor promon2.p pattern
            if trim(statsdb._Resrc._Resrc-Name) eq "" then next.
            assign oEntry = new JsonObject().
            oEntry:Add("locks":u, statsdb._Resrc._Resrc-Lock). // Times this resource lock was acquired (e.g. DB buffer shared lock, record get)
            oEntry:Add("waits":u, statsdb._Resrc._Resrc-Wait). // Times acquisition was delayed; high waits on DB Buf I Lock or S Lock signal buffer contention
            oResult:Add(this-object:MakeJsonSafe(statsdb._Resrc._Resrc-Name), oEntry).
        end.

        return oResult.
    end method. /* GetResourceWaitStats */

    /**
        Returns TXE lock counts from the _TxeLock VST.
        The VST holds a single record with nine parallel extent arrays (_Txe-Type, _Txe-Locks, _Txe-Waits).
        Matches the ProMonitor promon2.p pattern: FOR FIRST _TxeLock, DO i = 1 TO 9.
        Each non-blank entry is keyed by its type name.

        @return JsonObject keyed by TXE type name, each value containing locks and waits
      */
    method public JsonObject GetTxeLockStats():
        var JsonObject oResult = new JsonObject(), oEntry.
        var integer ix.

        for first statsdb._TxeLock no-lock:
            do ix = 1 to 9:
                if trim(statsdb._TxeLock._Txe-Type[ix]) eq "" then next.
                assign oEntry = new JsonObject().
                oEntry:Add("locks":u, statsdb._TxeLock._Txe-Locks[ix]). // Cumulative TXE lock acquisitions for this lock type
                oEntry:Add("waits":u, statsdb._TxeLock._Txe-Waits[ix]). // Times acquisition was delayed for this TXE lock type
                oResult:Add(this-object:MakeJsonSafe(statsdb._TxeLock._Txe-Type[ix]), oEntry).
            end.
        end.

        return oResult.
    end method. /* GetTxeLockStats */

    /**
        Returns before-image log activity statistics from the _ActBILog VST.
        Buffer waits and empty waits are key indicators of BI pressure under load.

        @return JsonObject containing BI log throughput and wait counters
      */
    method public JsonObject GetBILogStats():
        var JsonObject oResult = new JsonObject().

        for first statsdb._ActBILog no-lock:
            oResult:Add("bufferWaits":u,   statsdb._ActBILog._BILog-BBuffWaits).  // Times a client waited for a BI buffer slot; key indicator of BI buffer pressure
            oResult:Add("bytesRead":u,     statsdb._ActBILog._BILog-BytesRead).   // Total bytes read from the BI log file
            oResult:Add("bytesWritten":u,  statsdb._ActBILog._BILog-BytesWrtn).   // Total bytes written to the BI log file
            oResult:Add("emptyWaits":u,    statsdb._ActBILog._BILog-EBuffWaits).  // Times a client stalled because all BI buffers were empty; indicates BIW falling behind
            oResult:Add("partialWrites":u, statsdb._ActBILog._BILog-PartialWrts). // BI writes smaller than a full block; may indicate bibufs tuning is needed
            oResult:Add("writerWrites":u,  statsdb._ActBILog._BILog-BIWWrites).   // Writes performed by the BI Writer background process (BIW)
            oResult:Add("totalWrites":u,   statsdb._ActBILog._BILog-TotalWrts).   // Total BI write operations including both BIW and direct client writes
            oResult:Add("totalReads":u,    statsdb._ActBILog._BILog-TotReads).    // Total BI reads; typically occurs during transaction backout or recovery
        end.

        return oResult.
    end method. /* GetBILogStats */

    /**
        Returns lock table utilization and database sizing data from the _DbStatus VST.
        currentLocks is a live snapshot of lock table slots in use; peakLocks is the
        high-watermark since last startup. These are lock table capacity metrics and
        are distinct from the cumulative request/wait counters in GetRecordLockStats().
        biSizeBytes and dbBlockSizeKB are included as they are only reliably sourced
        from this VST, matching the ProMonitor convention.

        @return JsonObject containing lock table utilization, BI file size, and block size
      */
    method public JsonObject GetLockTableStats():
        var JsonObject oResult = new JsonObject().

        for first statsdb._DbStatus no-lock:
            if statsdb._DbStatus._DbStatus-BiSize ne ? then do:
                oResult:Add("biBlockCount":u,     int64(statsdb._DbStatus._DbStatus-BiSize)). // Raw BI block count from _DbStatus-BiSize
                oResult:Add("biBlockSizeBytes":u, statsdb._DbStatus._DbStatus-BiBlkSize).     // BI block size in bytes from _DbStatus-BiBlkSize
                oResult:Add("biSizeMB":u,         int64(statsdb._DbStatus._DbStatus-BiSize) *
                                                  statsdb._DbStatus._DbStatus-BiBlkSize / 1024 / 1024). // BI file size in MB: biBlockCount × biBlockSizeBytes ÷ 1 MB
            end.
            else do:
                oResult:AddNull("biBlockCount":u).     // _DbStatus-BiSize unavailable
                oResult:AddNull("biBlockSizeBytes":u). // _DbStatus-BiBlkSize unavailable
                oResult:AddNull("biSizeMB":u).         // Cannot compute without block count
            end.
            oResult:Add("currentLocks":u,  statsdb._DbStatus._DbStatus-NumLocks).         // Record locks currently held across all sessions
            oResult:Add("dbBlockSizeKB":u, statsdb._DbStatus._DbStatus-DbBlkSize / 1024). // Database block size in KB; set at creation, typically 8
            oResult:Add("peakLocks":u,     statsdb._DbStatus._DbStatus-MostLocks).        // High-watermark lock count since last database startup
        end.

        return oResult.
    end method. /* GetLockTableStats */

    /**
        Returns a complete snapshot of all VST-sourced statistics for the aliased database.
        Callers must have created the "statsdb" alias before invoking this method.

        @param character pcDatabaseName [INPUT] Logical database name, included in the result for reference
        @return JsonObject containing timestamp, databaseName, and all stats categories
      */
    method public JsonObject GetAllStats ( input pcDatabaseName as character ):
        var JsonObject oResult = new JsonObject().

        oResult:Add("timestamp":u,     now).
        oResult:Add("databaseName":u,  pcDatabaseName).
        oResult:Add("config":u,        this-object:GetConfigStats()).
        oResult:Add("biLog":u,         this-object:GetBILogStats()).
        oResult:Add("bufferCache":u,   this-object:GetBufferCacheStats()).
        oResult:Add("connections":u,   this-object:GetConnectionStats()).
        oResult:Add("lockTable":u,     this-object:GetLockTableStats()).
        oResult:Add("latches":u,       this-object:GetLatchStats()).
        oResult:Add("recordLocks":u,   this-object:GetRecordLockStats()).
        oResult:Add("resourceWaits":u, this-object:GetResourceWaitStats()).
        oResult:Add("transactions":u,  this-object:GetTransactionStats()).
        oResult:Add("txeLocks":u,      this-object:GetTxeLockStats()).

        return oResult.
    end method. /* GetAllStats */

end class.