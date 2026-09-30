/***************************************************************************\
*****************************************************************************
**
**     Program: crinvtx.p
**
*****************************************************************************
\***************************************************************************/

trigger procedure for create of InventoryTrans.

define variable iAuditKey as int64 no-undo initial 0.
define variable lAuditPerformed as logical no-undo initial false.
define variable lAuditSuccessful as logical no-undo initial false.

OpenEdge.LoadSuite.Common.Util.AuditManager:PerformWriteAudit(
    input "InventoryTrans":U,
    input buffer InventoryTrans:handle,
    input buffer InventoryTrans:handle,
    input "InvTransNum,ItemNum,Reference,TransType,WarehouseNum,Qty":U,
    output lAuditPerformed,
    output iAuditKey).