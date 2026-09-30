/*------------------------------------------------------------------------------
  File    : GenSystemData.p
  Purpose : Generate required data for system tables in the database.
  Note    : Can be executed multiple times without creating duplicates.

    Excludes Special Tables: ContextHeader, ContextDetail, AuditHeader, 
    AuditDetail, SystemFile, ReplQueue.
    
    This populates ReplTableXRef records with:
    - GenQRec: true (enables queue record generation)
    - QThread: incrementing thread numbers
    - UseInDiff: true (enables replication updates)
------------------------------------------------------------------------------*/

block-level on error undo, throw.

// Expect a single parameter as a shared logger instance.
define input parameter oLogger as OpenEdge.Logging.ILogWriter no-undo.

var integer iThreadNum = 1, iSplitNum = 0, iTableCount = 0, iTableLoop = 0, iTablesLoaded = 0.
var character cTableName = "", cTables = "", cSplitTables = "Customer,Employee,Order".

// Define all application tables (excluding system/context/audit/repl* tables)
assign cTables = "Benefits,BillTo,Bin,Customer,Department,Employee,Family,Feedback," +
                 "InventoryTrans,Invoice,Item,LocalDefault,Order,OrderLine,POLine," +
                 "PurchaseOrder,RefCall,SalesRep,ShipTo,State,Supplier," +
                 "SupplierItemXref,TimeSheet,Vacation,Warehouse".

if num-dbs eq 0 then do:
    oLogger:Error("No database connection available. Cannot generate system data.").
    return.
end.

if lookup("READ-ONLY":u, dbrestrictions(1)) gt 0 then do:
    oLogger:Warn("Database is in read-only mode. Skipping system data generation.").
    return.
end.

// Check if ANY record for ReplTableXRef already exists for this database.
find first ReplTableXRef 
        where ReplTableXRef.SrcDB eq ldbname(1)
           no-lock no-error.
if available(ReplTableXRef) then do:
    oLogger:Debug("ReplTableXRef records already exist for this database, skipping generation.").
    return.
end.

// Transaction block for all inserts, must be idempotent.
do transaction:
    assign iTableCount = num-entries(cTables).

    TABLEBLK:
    do iTableLoop = 1 to iTableCount:
        assign cTableName = entry(iTableLoop, cTables).
        
        // Check if ReplTableXRef record already exists.
        find first ReplTableXRef 
             where ReplTableXRef.SrcDB    eq ldbname(1)
               and ReplTableXRef.SrcTable eq cTableName
                no-lock no-error.
        
        if not available(ReplTableXRef) then do:
            // Create ReplTableXRef record only if it doesn't exist.
            create ReplTableXRef.
            assign
                ReplTableXRef.SrcDB     = ldbname(1)
                ReplTableXRef.SrcTable  = cTableName
                ReplTableXRef.TgtTable  = cTableName
                ReplTableXRef.GenQRec   = true       // Enable queue record generation
                ReplTableXRef.ProcQRec  = false      // Don't process queue records
                ReplTableXRef.QThread   = iThreadNum // Assign incrementing thread
                ReplTableXRef.UseInDiff = true       // Use in replication
                ReplTableXRef.SchTable  = cTableName
                ReplTableXRef.TrigInst  = false
                ReplTableXRef.MrgdTrig  = false
                .

            assign iTablesLoaded += 1.
            oLogger:Debug(substitute("Created ReplTableXRef for &1 with QThread &2", cTableName, iThreadNum)).
        end.
        else
            oLogger:Debug(substitute("ReplTableXRef for &1 already exists, skipping", cTableName)).

        // Only selected tables should use split-thread replication.
        if can-do(cSplitTables, cTableName) then do:
            assign iSplitNum = if cTableName eq "Order":u then 3 else 2.

            // Check if ReplProperties record already exists.
            find first ReplProperties 
                 where ReplProperties.PropertyName eq "SPLIT_THREAD":u + string(ReplTableXRef.QThread)
                 no-lock no-error.
            
            if not available(ReplProperties) then do:
                create ReplProperties.
                assign
                    ReplProperties.PropertyName     = "SPLIT_THREAD":u + string(ReplTableXRef.QThread)
                    ReplProperties.PropertyValue    = string(iSplitNum)
                    ReplProperties.PropertyCategory = "REPLICATION":u
                    .
                
                oLogger:Debug(substitute("|-Created ReplProperties SPLIT_THREAD&1 = &2 for &3",
                                        ReplTableXRef.QThread, ReplProperties.PropertyValue, cTableName)).
            end.
            else do:
                oLogger:Debug(substitute("|-ReplProperties SPLIT_THREAD&1 already exists, skipping", ReplTableXRef.QThread)).
            end.
        end.

        // Increment thread for next table
        assign iThreadNum = iThreadNum + 1.
    end. // TABLEBLK

    oLogger:Info(substitute("Successfully created replication control records for &1 tables", iTablesLoaded)).
end. // transaction

catch err as Progress.Lang.Error:
    oLogger:Error("System Data Load Error":u, err).
end catch.
