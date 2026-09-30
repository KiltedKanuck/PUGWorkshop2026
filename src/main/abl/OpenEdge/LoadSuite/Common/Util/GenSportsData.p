/*------------------------------------------------------------------------------
  File    : GenSportsData.p
  Purpose : Generate dummy data for sports (app) tables in the database.
  Note    : Can be executed multiple times without creating duplicates.

    Excludes Special Tables: ContextHeader, ContextDetail, AuditHeader, 
    AuditDetail, SystemFile, ReplQueue, ReplProperties, ReplTableXRef.

    This populates each table with records:
    - Tables which use a sequence will continue to increment normally.
        - Note: All sequences begin at 100,000 and increment by 1.
    - Tables which use a natural key will have one generated consistently.
        - Format: "OELS-<FIELDNAME>-999999"
------------------------------------------------------------------------------*/

block-level on error undo, throw.

// Define the name of the class package for this application.
&GLOBAL-DEFINE CLASS_PACKAGE OpenEdge.LoadSuite

// General Supporting Classes
using OpenEdge.Logging.ILogWriter.
using OpenEdge.Logging.LoggerBuilder.
using Progress.Json.ObjectModel.JsonObject.
using Progress.Json.ObjectModel.JsonDataType.
using {&CLASS_PACKAGE}.Objects.record.create.general.

// Create a logger for consistent output.
var ILogWriter oLogger = LoggerBuilder:GetLogger("DataGenerator":u).

// Reuse the same logic for the record creation as would be used by the API endpoints.
var general oRecordCreate = new general().

var integer iMaxRecords   = 100000, // Constant: the total number of records to create per table (never changes).
            iCurrent      = 0,      // Variable: current sequence value (seq tables) or existing record count (non-seq tables).
            iCreateStart  = 0,      // Variable: loop start index - the first new record number to create for this table.
            iRemaining    = 0,      // Variable: number of records remaining to reach iMaxRecords.
            iTableCount   = 0,      // Variable: total number of tables in the cTables list.
            iTableLoop    = 0,      // Variable: current iteration index over the table list.
            iRecordLoop   = 0,      // Variable: current iteration index within the record creation loop.
            iTablesLoaded = 0,      // Variable: running count of tables processed (used in final log message).
            iLogStep      = 0,      // Variable: log output frequency (every N records = 10% of iMaxRecords).
            iOrderNum     = 0,      // Variable: order number returned from createOrder for use with createOrderLine.
            iOrderLineMax = 20,     // Constant: number of order lines to create per order.
            iOrderLine    = 0       // Variable: loop counter for order line creation.
            .

var JsonObject oCreateResult = ?.
var character cMaxRecords = "", cTableName = "", cTables = "", cFieldPrefix = "OELS".

// Fixed epoch for deterministic date-keyed record generation.
// Adding record ID (as minutes) to this epoch produces a unique, reproducible date per record.
// Must match DATE_EPOCH_MS in config.js.
var datetime-tz dtzDateEpoch = datetime-tz(date(1, 1, 2025), 0, 0).

var character[50]
    cStateAbbrev = ["AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA",
                    "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD",
                    "MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
                    "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
                    "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"],
    cStateName  = ["Alabama","Alaska","Arizona","Arkansas","California","Colorado","Connecticut","Delaware","Florida","Georgia",
                   "Hawaii","Idaho","Illinois","Indiana","Iowa","Kansas","Kentucky","Louisiana","Maine","Maryland","Massachusetts",
                   "Michigan","Minnesota","Mississippi","Missouri","Montana","Nebraska","Nevada","New Hampshire","New Jersey",
                   "New Mexico","New York","North Carolina","North Dakota","Ohio","Oklahoma","Oregon","Pennsylvania","Rhode Island",
                   "South Carolina","South Dakota","Tennessee","Texas","Utah","Vermont","Virginia","Washington","West Virginia",
                   "Wisconsin","Wyoming"]
    .

// Check for passed-in arguments/parameters.
if num-entries(session:parameter) ge 6 then
    assign cMaxRecords = entry(1, session:parameter).
else
    assign cMaxRecords = dynamic-function("getParameter" in source-procedure, "MaxRecords")
                         when (dynamic-function("getParameter" in source-procedure, "MaxRecords") gt "") eq true.

// Convert a passed value for MaxRecords into an integer.
if (cMaxRecords gt "") eq true then do:
    assign iMaxRecords = integer(cMaxRecords) no-error.
    if error-status:error then
        assign error-status:error = false.
end.
oLogger:Info(substitute("Sample data maximum record count: &1", trim(string(iMaxRecords, ">>>,>>>,>>9")))).

// Compute the log step so progress is output once per 10% of total records.
assign iLogStep = maximum(1, integer(iMaxRecords / 10)).

/**
 * Define all application tables (excluding system/context/audit/repl* tables),
 * ordered so that dependency tables are populated BEFORE their dependents.
 *
 * Sequenced Tables (PK assigned by DB sequence):
 * - Bin, Customer, Employee, InventoryTrans, Invoice, Item, LocalDefault,
 *   Order, PurchaseOrder, RefCall, Supplier, Warehouse
 *
 * Natural Key Tables (PK supplied by caller):
 * - Benefits, BillTo, Department, Family, Feedback, OrderLine, POLine,
 *   SalesRep, ShipTo, State, SupplierItemXref, TimeSheet, Vacation
 *
 * Dependency Tiers:
 * - Tier 1 (no deps):   State, SalesRep, Department, LocalDefault, Feedback, Supplier, Item, Warehouse
 * - Tier 2 (->Tier 1):  Customer (->SalesRep), Employee (->Department)
 * - Tier 3 (->Tier 2):  Benefits, BillTo, Bin, Family, InventoryTrans, Invoice,
 *                       Order, PurchaseOrder, RefCall, ShipTo, SupplierItemXref, TimeSheet, Vacation
 * - Tier 4 (->Tier 3):  OrderLine (created with Order), POLine (created with PurchaseOrder)
 */
assign cTables = "State,SalesRep,Department,LocalDefault,Feedback,Supplier,Item,Warehouse," +
                 "Customer,Employee," +
                 "Benefits,BillTo,Bin,Family,InventoryTrans,Invoice,Order,PurchaseOrder," +
                 "RefCall,ShipTo,SupplierItemXref,TimeSheet,Vacation".

if num-dbs eq 0 then do:
    oLogger:Error("No database connection available. Cannot generate sports data.").
    return.
end.

function genFieldData returns character (input pcFieldName as character, input piIndex as integer):
    // Creates a consistent field name based on a counter (up to 999,999,999) always padded to at least 6 digits.
    // Standard Format: "OELS-<FIELDNAME>-999999"
    return substitute("&1-&2-&3":u, cFieldPrefix, caps(pcFieldName), trim(string(piIndex, ">>>999999"))).
end function.

function genProgressBar returns character (input pcTableName as character, input piCurrent as integer, input piMax as integer):
    var character cBar = "".
    var integer iFilled = 0,
                iPercent = 0.

    // Output a progress bar as "<TABLE_NAME> |====>     | <PERCENTAGE>%" with each "=" representing 10% until complete.
    assign iFilled = integer(piCurrent * 10 / piMax).
    assign iPercent = integer(piCurrent * 100 / piMax).

    if iFilled ge 10 then
        assign cBar = fill("=", 10).
    else
        assign cBar = fill("=", iFilled) + ">" + fill(" ", 9 - iFilled).

    return substitute("&1 |&2| &3~%", pcTableName, cBar, iPercent).
end function.

// Disable audit and repl logic during data generation to avoid unnecessary overhead and potential conflicts.
OpenEdge.LoadSuite.Common.Util.AuditManager:RunAuditLogic = false.
OpenEdge.LoadSuite.Common.Util.AuditManager:RunReplUpdate = false.

assign iTableCount = num-entries(cTables).
oLogger:Info(substitute("Preparing to check &1 tables for sample data...", iTableCount)).

TABLEBLK:
do iTableLoop = 1 to iTableCount on error undo, throw:
    assign cTableName = entry(iTableLoop, cTables).

    case cTableName:
        when "Benefits" then do:
            // Reset to 0 for discovering/counting existing records.
            assign
                iCurrent     = 0
                iCreateStart = 0
                .

            for each Benefits no-lock:
                assign iCurrent += 1. // Count existing records to determine a starting point.
            end.

            assign iCreateStart = iCurrent + 1. // Determine the starting point for new records.
            assign iRemaining = iMaxRecords - iCreateStart + 1. // Calculate total new records to be created.

            if iCreateStart gt 0 and iCreateStart lt iMaxRecords then do:
                // Only create records if we haven't reached the max.
                oLogger:Info(substitute("Creating &1 records for table '&2'.", trim(string(iRemaining, ">>>,>>>,>>9")), cTableName)).
                oLogger:Debug(genProgressBar(cTableName, iCreateStart, iMaxRecords)).

                do iRecordLoop = iCreateStart to iMaxRecords:
                    oRecordCreate:createBenefits(iRecordLoop).
                    if (iRecordLoop mod iLogStep) eq 0 then
                        oLogger:Debug(genProgressBar(cTableName, iRecordLoop, iMaxRecords)).
                end.
                assign iTablesLoaded += 1.
            end.
        end. // Benefits

        when "BillTo" then do:
            // Reset to 0 for discovering/counting existing records.
            assign
                iCurrent     = 0
                iCreateStart = 0
                .

            for each BillTo no-lock:
                assign iCurrent += 1. // Count existing records to determine a starting point.
            end.

            assign iCreateStart = iCurrent + 1. // Determine the starting point for new records.
            assign iRemaining = iMaxRecords - iCreateStart + 1. // Calculate total new records to be created.

            if iCreateStart gt 0 and iCreateStart lt iMaxRecords then do:
                // Only create records if we haven't reached the max.
                oLogger:Info(substitute("Creating &1 records for table '&2'.", trim(string(iRemaining, ">>>,>>>,>>9")), cTableName)).
                oLogger:Debug(genProgressBar(cTableName, iCreateStart, iMaxRecords)).

                do iRecordLoop = iCreateStart to iMaxRecords:
                    oRecordCreate:createBillTo(iRecordLoop, 1, genFieldData("Name", iRecordLoop)).
                    if (iRecordLoop mod iLogStep) eq 0 then
                        oLogger:Debug(genProgressBar(cTableName, iRecordLoop, iMaxRecords)).
                end.
                assign iTablesLoaded += 1.
            end.
        end. // BillTo

        when "Bin" then do:
            assign iCurrent = current-value(NextBinNum). // Mark the current value of the table sequence.
            assign iCreateStart = iCurrent + 1. // Determine the starting point for new records.
            assign iRemaining = iMaxRecords - iCreateStart + 1. // Calculate total new records to be created.

            if iCreateStart gt 0 and iCreateStart lt iMaxRecords then do:
                // Only create records if we haven't reached the max.
                oLogger:Info(substitute("Creating &1 records for table '&2'.", trim(string(iRemaining, ">>>,>>>,>>9")), cTableName)).
                oLogger:Debug(genProgressBar(cTableName, iCreateStart, iMaxRecords)).

                do iRecordLoop = iCreateStart to iMaxRecords:
                    oRecordCreate:createBin(?, genFieldData("BinName", iRecordLoop)).
                    if (iRecordLoop mod iLogStep) eq 0 then
                        oLogger:Debug(genProgressBar(cTableName, iRecordLoop, iMaxRecords)).
                end.
                assign iTablesLoaded += 1.
            end.
        end. // Bin

        when "Customer" then do:
            assign iCurrent = current-value(NextCustNum). // Mark the current value of the table sequence.
            assign iCreateStart = iCurrent + 1. // Determine the starting point for new records.
            assign iRemaining = iMaxRecords - iCreateStart + 1. // Calculate total new records to be created.

            if iCreateStart gt 0 and iCreateStart lt iMaxRecords then do:
                // Only create records if we haven't reached the max.
                oLogger:Info(substitute("Creating &1 records for table '&2'.", trim(string(iRemaining, ">>>,>>>,>>9")), cTableName)).
                oLogger:Debug(genProgressBar(cTableName, iCreateStart, iMaxRecords)).

                do iRecordLoop = iCreateStart to iMaxRecords:
                    oRecordCreate:createCustomer(?, genFieldData("Name", iRecordLoop), genFieldData("Comments", iRecordLoop)).
                    if (iRecordLoop mod iLogStep) eq 0 then
                        oLogger:Debug(genProgressBar(cTableName, iRecordLoop, iMaxRecords)).
                end.
                assign iTablesLoaded += 1.
            end.
        end. // Customer

        when "Department" then do:
            // Reset to 0 for discovering/counting existing records.
            assign
                iCurrent     = 0
                iCreateStart = 0
                .

            for each Department no-lock:
                assign iCurrent += 1. // Count existing records to determine a starting point.
            end.

            assign iCreateStart = iCurrent + 1. // Determine the starting point for new records.
            assign iRemaining = iMaxRecords - iCreateStart + 1. // Calculate total new records to be created.

            if iCreateStart gt 0 and iCreateStart lt iMaxRecords then do:
                // Only create records if we haven't reached the max.
                oLogger:Info(substitute("Creating &1 records for table '&2'.", trim(string(iRemaining, ">>>,>>>,>>9")), cTableName)).
                oLogger:Debug(genProgressBar(cTableName, iCreateStart, iMaxRecords)).

                do iRecordLoop = iCreateStart to iMaxRecords:
                    oRecordCreate:createDepartment (genFieldData("DeptCode", iRecordLoop), genFieldData("DeptName", iRecordLoop)).
                    if (iRecordLoop mod iLogStep) eq 0 then
                        oLogger:Debug(genProgressBar(cTableName, iRecordLoop, iMaxRecords)).
                end.
                assign iTablesLoaded += 1.
            end.
        end. // Department

        when "Employee" then do:
            assign iCurrent = current-value(NextEmpNum). // Mark the current value of the table sequence.
            assign iCreateStart = iCurrent + 1. // Determine the starting point for new records.
            assign iRemaining = iMaxRecords - iCreateStart + 1. // Calculate total new records to be created.

            if iCreateStart gt 0 and iCreateStart lt iMaxRecords then do:
                // Only create records if we haven't reached the max.
                oLogger:Info(substitute("Creating &1 records for table '&2'.", trim(string(iRemaining, ">>>,>>>,>>9")), cTableName)).
                oLogger:Debug(genProgressBar(cTableName, iCreateStart, iMaxRecords)).

                do iRecordLoop = iCreateStart to iMaxRecords:
                    oRecordCreate:createEmployee(?, genFieldData("FirstName", iRecordLoop), genFieldData("LastName", iRecordLoop)).
                    if (iRecordLoop mod iLogStep) eq 0 then
                        oLogger:Debug(genProgressBar(cTableName, iRecordLoop, iMaxRecords)).
                end.
                assign iTablesLoaded += 1.
            end.
        end. // Employee

        when "Family" then do:
            // Reset to 0 for discovering/counting existing records.
            assign
                iCurrent     = 0
                iCreateStart = 0
                .

            for each Family no-lock:
                assign iCurrent += 1. // Count existing records to determine a starting point.
            end.

            assign iCreateStart = iCurrent + 1. // Determine the starting point for new records.
            assign iRemaining = iMaxRecords - iCreateStart + 1. // Calculate total new records to be created.

            if iCreateStart gt 0 and iCreateStart lt iMaxRecords then do:
                // Only create records if we haven't reached the max.
                oLogger:Info(substitute("Creating &1 records for table '&2'.", trim(string(iRemaining, ">>>,>>>,>>9")), cTableName)).
                oLogger:Debug(genProgressBar(cTableName, iCreateStart, iMaxRecords)).

                do iRecordLoop = iCreateStart to iMaxRecords:
                    oRecordCreate:createFamily(iRecordLoop, genFieldData("RelativeName", iRecordLoop)).
                    if (iRecordLoop mod iLogStep) eq 0 then
                        oLogger:Debug(genProgressBar(cTableName, iRecordLoop, iMaxRecords)).
                end.
                assign iTablesLoaded += 1.
            end.
        end. // Family

        when "Feedback" then do:
            // Reset to 0 for discovering/counting existing records.
            assign
                iCurrent     = 0
                iCreateStart = 0
                .

            for each Feedback no-lock:
                assign iCurrent += 1. // Count existing records to determine a starting point.
            end.

            assign iCreateStart = iCurrent + 1. // Determine the starting point for new records.
            assign iRemaining = iMaxRecords - iCreateStart + 1. // Calculate total new records to be created.

            if iCreateStart gt 0 and iCreateStart lt iMaxRecords then do:
                // Only create records if we haven't reached the max.
                oLogger:Info(substitute("Creating &1 records for table '&2'.", trim(string(iRemaining, ">>>,>>>,>>9")), cTableName)).
                oLogger:Debug(genProgressBar(cTableName, iCreateStart, iMaxRecords)).

                do iRecordLoop = iCreateStart to iMaxRecords:
                    oRecordCreate:createFeedback(genFieldData("Department", iRecordLoop), genFieldData("Comments", iRecordLoop)).
                    if (iRecordLoop mod iLogStep) eq 0 then
                        oLogger:Debug(genProgressBar(cTableName, iRecordLoop, iMaxRecords)).
                end.
                assign iTablesLoaded += 1.
            end.
        end. // Feedback

        when "InventoryTrans" then do:
            assign iCurrent = current-value(NextInvTransNum). // Mark the current value of the table sequence.
            assign iCreateStart = iCurrent + 1. // Determine the starting point for new records.
            assign iRemaining = iMaxRecords - iCreateStart + 1. // Calculate total new records to be created.

            if iCreateStart gt 0 and iCreateStart lt iMaxRecords then do:
                // Only create records if we haven't reached the max.
                oLogger:Info(substitute("Creating &1 records for table '&2'.", trim(string(iRemaining, ">>>,>>>,>>9")), cTableName)).
                oLogger:Debug(genProgressBar(cTableName, iCreateStart, iMaxRecords)).

                do iRecordLoop = iCreateStart to iMaxRecords:
                    oRecordCreate:createInventoryTrans(?).
                    if (iRecordLoop mod iLogStep) eq 0 then
                        oLogger:Debug(genProgressBar(cTableName, iRecordLoop, iMaxRecords)).
                end.
                assign iTablesLoaded += 1.
            end.
        end. // InventoryTrans

        when "Invoice" then do:
            assign iCurrent = current-value(NextInvNum). // Mark the current value of the table sequence.
            assign iCreateStart = iCurrent + 1. // Determine the starting point for new records.
            assign iRemaining = iMaxRecords - iCreateStart + 1. // Calculate total new records to be created.

            if iCreateStart gt 0 and iCreateStart lt iMaxRecords then do:
                // Only create records if we haven't reached the max.
                oLogger:Info(substitute("Creating &1 records for table '&2'.", trim(string(iRemaining, ">>>,>>>,>>9")), cTableName)).
                oLogger:Debug(genProgressBar(cTableName, iCreateStart, iMaxRecords)).

                do iRecordLoop = iCreateStart to iMaxRecords:
                    oRecordCreate:createInvoice(?, decimal(iRecordLoop)).
                    if (iRecordLoop mod iLogStep) eq 0 then
                        oLogger:Debug(genProgressBar(cTableName, iRecordLoop, iMaxRecords)).
                end.
                assign iTablesLoaded += 1.
            end.
        end. // Invoice

        when "Item" then do:
            assign iCurrent = current-value(NextItemNum). // Mark the current value of the table sequence.
            assign iCreateStart = iCurrent + 1. // Determine the starting point for new records.
            assign iRemaining = iMaxRecords - iCreateStart + 1. // Calculate total new records to be created.

            if iCreateStart gt 0 and iCreateStart lt iMaxRecords then do:
                // Only create records if we haven't reached the max.
                oLogger:Info(substitute("Creating &1 records for table '&2'.", trim(string(iRemaining, ">>>,>>>,>>9")), cTableName)).
                oLogger:Debug(genProgressBar(cTableName, iCreateStart, iMaxRecords)).

                do iRecordLoop = iCreateStart to iMaxRecords:
                    oRecordCreate:createItem(?, genFieldData("ItemName", iRecordLoop), genFieldData("CatDescription", iRecordLoop)).
                    if (iRecordLoop mod iLogStep) eq 0 then
                        oLogger:Debug(genProgressBar(cTableName, iRecordLoop, iMaxRecords)).
                end.
                assign iTablesLoaded += 1.
            end.
        end. // Item

        when "LocalDefault" then do:
            assign iCurrent = current-value(NextLocalDefNum). // Mark the current value of the table sequence.
            assign iCreateStart = iCurrent + 1. // Determine the starting point for new records.
            assign iRemaining = iMaxRecords - iCreateStart + 1. // Calculate total new records to be created.

            if iCreateStart gt 0 and iCreateStart lt iMaxRecords then do:
                // Only create records if we haven't reached the max.
                oLogger:Info(substitute("Creating &1 records for table '&2'.", trim(string(iRemaining, ">>>,>>>,>>9")), cTableName)).
                oLogger:Debug(genProgressBar(cTableName, iCreateStart, iMaxRecords)).

                do iRecordLoop = iCreateStart to iMaxRecords:
                    oRecordCreate:createLocalDefault(?).
                    if (iRecordLoop mod iLogStep) eq 0 then
                        oLogger:Debug(genProgressBar(cTableName, iRecordLoop, iMaxRecords)).
                end.
                assign iTablesLoaded += 1.
            end.
        end. // LocalDefault

        when "Order" then do:
            assign iCurrent = current-value(NextOrdNum). // Mark the current value of the table sequence.
            assign iCreateStart = iCurrent + 1. // Determine the starting point for new records.
            assign iRemaining = iMaxRecords - iCreateStart + 1. // Calculate total new records to be created.

            if iCreateStart gt 0 and iCreateStart lt iMaxRecords then do:
                // Only create records if we haven't reached the max.
                oLogger:Info(substitute("Creating &1 records for table '&2'.", trim(string(iRemaining, ">>>,>>>,>>9")), cTableName)).
                oLogger:Debug(genProgressBar(cTableName, iCreateStart, iMaxRecords)).

                do iRecordLoop = iCreateStart to iMaxRecords:
                    assign oCreateResult = cast(oRecordCreate:createOrder(?, iRecordLoop), JsonObject).

                    // Extract the order number from the returned JSON: { "data": { "OrderNum": <n> } }
                    if valid-object(oCreateResult) and oCreateResult:Has("data":u) and
                       oCreateResult:GetType("data":u) eq JsonDataType:object then do:
                        assign
                            iOrderNum  = oCreateResult:GetJsonObject("data":u):GetInteger("OrderNum":u)
                            iOrderLine = 0
                            .
                        do transaction:
                            do iOrderLine = 1 to iOrderLineMax:
                                oRecordCreate:createOrderLine(iOrderNum, iOrderLine).
                            end.
                        end.
                        oLogger:Trace(substitute("Order &1: Created &2 Order Lines.", iOrderNum, iOrderLineMax)).
                    end.
                    else
                        oLogger:Error(substitute("Order &1: createOrder did not return a valid data object; order lines skipped.", iRecordLoop)).

                    if (iRecordLoop mod iLogStep) eq 0 then
                        oLogger:Debug(genProgressBar(cTableName, iRecordLoop, iMaxRecords)).
                end.
                assign iTablesLoaded += 1.
            end.
        end. // Order

        when "PurchaseOrder" then do:
            assign iCurrent = current-value(NextPONum). // Mark the current value of the table sequence.
            assign iCreateStart = iCurrent + 1. // Determine the starting point for new records.
            assign iRemaining = iMaxRecords - iCreateStart + 1. // Calculate total new records to be created.

            if iCreateStart gt 0 and iCreateStart lt iMaxRecords then do:
                // Only create records if we haven't reached the max.
                oLogger:Info(substitute("Creating &1 records for table '&2'.", trim(string(iRemaining, ">>>,>>>,>>9")), cTableName)).
                oLogger:Debug(genProgressBar(cTableName, iCreateStart, iMaxRecords)).

                do iRecordLoop = iCreateStart to iMaxRecords:
                    assign oCreateResult = cast(oRecordCreate:createPurchaseOrder(?), JsonObject).

                    // Extract the PO number from the returned JSON: { "data": { "PONum": <n> } }
                    if valid-object(oCreateResult) and oCreateResult:Has("data":u) and
                       oCreateResult:GetType("data":u) eq JsonDataType:object then do:
                        assign
                            iOrderNum  = oCreateResult:GetJsonObject("data":u):GetInteger("PONum":u)
                            iOrderLine = 0
                            .
                        do transaction:
                            do iOrderLine = 1 to iOrderLineMax:
                                oRecordCreate:createPOLine(iOrderNum, iOrderLine).
                            end.
                        end.
                        oLogger:Trace(substitute("PurchaseOrder &1: Created &2 PO Lines.", iOrderNum, iOrderLineMax)).
                    end.
                    else
                        oLogger:Error(substitute("PurchaseOrder &1: createPurchaseOrder did not return a valid data object; PO lines skipped.", iRecordLoop)).

                    if (iRecordLoop mod iLogStep) eq 0 then
                        oLogger:Debug(genProgressBar(cTableName, iRecordLoop, iMaxRecords)).
                end.
                assign iTablesLoaded += 1.
            end.
        end. // PurchaseOrder

        when "RefCall" then do:
            assign iCurrent = current-value(NextRefNum). // Mark the current value of the table sequence.
            assign iCreateStart = iCurrent + 1. // Determine the starting point for new records.
            assign iRemaining = iMaxRecords - iCreateStart + 1. // Calculate total new records to be created.

            if iCreateStart gt 0 and iCreateStart lt iMaxRecords then do:
                // Only create records if we haven't reached the max.
                oLogger:Info(substitute("Creating &1 records for table '&2'.", trim(string(iRemaining, ">>>,>>>,>>9")), cTableName)).
                oLogger:Debug(genProgressBar(cTableName, iCreateStart, iMaxRecords)).

                do iRecordLoop = iCreateStart to iMaxRecords:
                    oRecordCreate:createRefCall(?, iRecordLoop, genFieldData("Parent", iRecordLoop)).
                    if (iRecordLoop mod iLogStep) eq 0 then
                        oLogger:Debug(genProgressBar(cTableName, iRecordLoop, iMaxRecords)).
                end.
                assign iTablesLoaded += 1.
            end.
        end. // RefCall

        when "SalesRep" then do:
            // Reset to 0 for discovering/counting existing records.
            assign
                iCurrent     = 0
                iCreateStart = 0
                .

            for each SalesRep no-lock:
                assign iCurrent += 1. // Count existing records to determine a starting point.
            end.

            assign iCreateStart = iCurrent + 1. // Determine the starting point for new records.
            assign iRemaining = iMaxRecords - iCreateStart + 1. // Calculate total new records to be created.

            if iCreateStart gt 0 and iCreateStart lt iMaxRecords then do:
                // Only create records if we haven't reached the max.
                oLogger:Info(substitute("Creating &1 records for table '&2'.", trim(string(iRemaining, ">>>,>>>,>>9")), cTableName)).
                oLogger:Debug(genProgressBar(cTableName, iCreateStart, iMaxRecords)).

                do iRecordLoop = iCreateStart to iMaxRecords:
                    oRecordCreate:createSalesRep(genFieldData("SalesRep", iRecordLoop), genFieldData("RepName", iRecordLoop)).
                    if (iRecordLoop mod iLogStep) eq 0 then
                        oLogger:Debug(genProgressBar(cTableName, iRecordLoop, iMaxRecords)).
                end.
                assign iTablesLoaded += 1.
            end.
        end. // SalesRep

        when "ShipTo" then do:
            // Reset to 0 for discovering/counting existing records.
            assign
                iCurrent     = 0
                iCreateStart = 0
                .

            for each ShipTo no-lock:
                assign iCurrent += 1. // Count existing records to determine a starting point.
            end.

            assign iCreateStart = iCurrent + 1. // Determine the starting point for new records.
            assign iRemaining = iMaxRecords - iCreateStart + 1. // Calculate total new records to be created.

            if iCreateStart gt 0 and iCreateStart lt iMaxRecords then do:
                // Only create records if we haven't reached the max.
                oLogger:Info(substitute("Creating &1 records for table '&2'.", trim(string(iRemaining, ">>>,>>>,>>9")), cTableName)).
                oLogger:Debug(genProgressBar(cTableName, iCreateStart, iMaxRecords)).

                do iRecordLoop = iCreateStart to iMaxRecords:
                    oRecordCreate:createShipTo(iRecordLoop, 1, genFieldData("Name", iRecordLoop), genFieldData("Comments", iRecordLoop)).
                    if (iRecordLoop mod iLogStep) eq 0 then
                        oLogger:Debug(genProgressBar(cTableName, iRecordLoop, iMaxRecords)).
                end.
                assign iTablesLoaded += 1.
            end.
        end. // ShipTo

        when "State" then do:
            // Reset to 0 for discovering/counting existing records.
            assign iCurrent = 0.

            for each State no-lock:
                assign iCurrent += 1. // Count existing records to determine a starting point.
            end.
            if iCurrent = 50 then next TABLEBLK. // All states already exist, no need to create.

            // Easy-peasy, just create all 50 states and be done with this table.
            do iRecordLoop = 1 to 50:
                oRecordCreate:createState(cStateAbbrev[iRecordLoop], cStateName[iRecordLoop]).
                if (iRecordLoop mod 5) eq 0 then
                    oLogger:Debug(genProgressBar(cTableName, iRecordLoop, 50)).
            end.
            assign iTablesLoaded += 1.
        end. // State

        when "Supplier" then do:
            assign iCurrent = current-value(NextSupplNum). // Mark the current value of the table sequence.
            assign iCreateStart = iCurrent + 1. // Determine the starting point for new records.
            assign iRemaining = iMaxRecords - iCreateStart + 1. // Calculate total new records to be created.

            if iCreateStart gt 0 and iCreateStart lt iMaxRecords then do:
                // Only create records if we haven't reached the max.
                oLogger:Info(substitute("Creating &1 records for table '&2'.", trim(string(iRemaining, ">>>,>>>,>>9")), cTableName)).
                oLogger:Debug(genProgressBar(cTableName, iCreateStart, iMaxRecords)).

                do iRecordLoop = iCreateStart to iMaxRecords:
                    oRecordCreate:createSupplier(?, genFieldData("Name", iRecordLoop), iRecordLoop, genFieldData("Comments", iRecordLoop)).
                    if (iRecordLoop mod iLogStep) eq 0 then
                        oLogger:Debug(genProgressBar(cTableName, iRecordLoop, iMaxRecords)).
                end.
                assign iTablesLoaded += 1.
            end.
        end. // Supplier

        when "SupplierItemXref" then do:
            // Reset to 0 for discovering/counting existing records.
            assign
                iCurrent     = 0
                iCreateStart = 0
                .

            for each SupplierItemXref no-lock:
                assign iCurrent += 1. // Count existing records to determine a starting point.
            end.

            assign iCreateStart = iCurrent + 1. // Determine the starting point for new records.
            assign iRemaining = iMaxRecords - iCreateStart + 1. // Calculate total new records to be created.

            if iCreateStart gt 0 and iCreateStart lt iMaxRecords then do:
                // Only create records if we haven't reached the max.
                oLogger:Info(substitute("Creating &1 records for table '&2'.", trim(string(iRemaining, ">>>,>>>,>>9")), cTableName)).
                oLogger:Debug(genProgressBar(cTableName, iCreateStart, iMaxRecords)).

                do iRecordLoop = iCreateStart to iMaxRecords:
                    oRecordCreate:createSupplierItemXref(iRecordLoop, 1).
                    if (iRecordLoop mod iLogStep) eq 0 then
                        oLogger:Debug(genProgressBar(cTableName, iRecordLoop, iMaxRecords)).
                end.
                assign iTablesLoaded += 1.
            end.
        end. // SupplierItemXref

        when "TimeSheet" then do:
            // Reset to 0 for discovering/counting existing records.
            assign
                iCurrent     = 0
                iCreateStart = 0
                .

            for each TimeSheet no-lock:
                assign iCurrent += 1. // Count existing records to determine a starting point.
            end.

            assign iCreateStart = iCurrent + 1. // Determine the starting point for new records.
            assign iRemaining = iMaxRecords - iCreateStart + 1. // Calculate total new records to be created.

            if iCreateStart gt 0 and iCreateStart lt iMaxRecords then do:
                // Only create records if we haven't reached the max.
                oLogger:Info(substitute("Creating &1 records for table '&2'.", trim(string(iRemaining, ">>>,>>>,>>9")), cTableName)).
                oLogger:Debug(genProgressBar(cTableName, iCreateStart, iMaxRecords)).

                do iRecordLoop = iCreateStart to iMaxRecords:
                    oRecordCreate:createTimeSheet(date(add-interval(dtzDateEpoch, iRecordLoop, "minutes")), iRecordLoop).
                    if (iRecordLoop mod iLogStep) eq 0 then
                        oLogger:Debug(genProgressBar(cTableName, iRecordLoop, iMaxRecords)).
                end.
                assign iTablesLoaded += 1.
            end.
        end. // TimeSheet

        when "Vacation" then do:
            // Reset to 0 for discovering/counting existing records.
            assign
                iCurrent     = 0
                iCreateStart = 0
                .

            for each Vacation no-lock:
                assign iCurrent += 1. // Count existing records to determine a starting point.
            end.

            assign iCreateStart = iCurrent + 1. // Determine the starting point for new records.
            assign iRemaining = iMaxRecords - iCreateStart + 1. // Calculate total new records to be created.

            if iCreateStart gt 0 and iCreateStart lt iMaxRecords then do:
                // Only create records if we haven't reached the max.
                oLogger:Info(substitute("Creating &1 records for table '&2'.", trim(string(iRemaining, ">>>,>>>,>>9")), cTableName)).
                oLogger:Debug(genProgressBar(cTableName, iCreateStart, iMaxRecords)).

                do iRecordLoop = iCreateStart to iMaxRecords:
                    oRecordCreate:createVacation(iRecordLoop, date(add-interval(dtzDateEpoch, iRecordLoop, "minutes"))).
                    if (iRecordLoop mod iLogStep) eq 0 then
                        oLogger:Debug(genProgressBar(cTableName, iRecordLoop, iMaxRecords)).
                end.
                assign iTablesLoaded += 1.
            end.
        end. // Vacation

        when "Warehouse" then do:
            assign iCurrent = current-value(NextWareNum). // Mark the current value of the table sequence.
            assign iCreateStart = iCurrent + 1. // Determine the starting point for new records.
            assign iRemaining = iMaxRecords - iCreateStart + 1. // Calculate total new records to be created.

            if iCreateStart gt 0 and iCreateStart lt iMaxRecords then do:
                // Only create records if we haven't reached the max.
                oLogger:Info(substitute("Creating &1 records for table '&2'.", trim(string(iRemaining, ">>>,>>>,>>9")), cTableName)).
                oLogger:Debug(genProgressBar(cTableName, iCreateStart, iMaxRecords)).

                do iRecordLoop = iCreateStart to iMaxRecords:
                    oRecordCreate:createWarehouse(?, genFieldData("WarehouseName", iRecordLoop)).
                    if (iRecordLoop mod iLogStep) eq 0 then
                        oLogger:Debug(genProgressBar(cTableName, iRecordLoop, iMaxRecords)).
                end.
                assign iTablesLoaded += 1.
            end.
        end. // Warehouse
    end case.

    oLogger:Info(substitute("Completed check for sample data within '&1'", cTableName)).

    catch err as Progress.Lang.Error:
        oLogger:Error("Table Load Error":u, err).
        if session:error-stack-trace then
            oLogger:Error(err:CallStack).

        next TABLEBLK. // Continue with the next table in the list.
    end catch.
end. // TABLEBLK

oLogger:Info(substitute("Done. Modified sample data for &1 tables", iTablesLoaded)).

catch err as Progress.Lang.Error:
    oLogger:Error("Data Generator Error":u, err).
    if session:error-stack-trace then
        oLogger:Error(err:CallStack).
end catch.
finally:
    /* Return value expected by PCT Ant task. */
    {&_proparse_ prolint-nowarn(returnfinally)}
    return string(0).
end finally.
