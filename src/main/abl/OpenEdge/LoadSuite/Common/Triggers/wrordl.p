/***************************************************************************\
*****************************************************************************
**
**     Program: wrordl.p
**
*****************************************************************************
\***************************************************************************/

trigger procedure for write of OrderLine new buffer newOrderLine old buffer oldOrderLine.

define variable hAuditManager as handle no-undo.
define variable iAuditKey as int64 no-undo initial 0.
define variable lAuditPerformed as logical no-undo initial false.
define variable lAuditSuccessful as logical no-undo initial false.

/* Automatically calculate the Extended Price based on Price, Qty, Discount */

if OpenEdge.LoadSuite.Common.Util.AuditManager:RunTriggerLogic then do:
    newOrderLine.ExtendedPrice = newOrderLine.Price * newOrderLine.Qty * (1 - (newOrderLine.Discount / 100)).
end.

OpenEdge.LoadSuite.Common.Util.AuditManager:PerformWriteAudit(
    input "OrderLine":U,
    input buffer oldOrderLine:handle,
    input buffer newOrderLine:handle,
    input "OrderNum,LineNum,ItemNum,Price,Qty,Discount,ExtendedPrice,OrderLineStatus":U,
    output lAuditPerformed,
    output iAuditKey).