/***************************************************************************\
*****************************************************************************
**
**     Program: crware.p
**
*****************************************************************************
\***************************************************************************/

trigger procedure for create of Warehouse.

define variable iAuditKey as int64 no-undo initial 0.
define variable lAuditPerformed as logical no-undo initial false.
define variable lAuditSuccessful as logical no-undo initial false.

OpenEdge.LoadSuite.Common.Util.AuditManager:PerformWriteAudit(
    input "Warehouse":U,
    input buffer Warehouse:handle,
    input buffer Warehouse:handle,
    input "WarehouseNum,WarehouseName,Country,Address,Address2,City,State,PostalCode,Phone":U,
    output lAuditPerformed,
    output iAuditKey).