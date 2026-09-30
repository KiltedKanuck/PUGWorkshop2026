/***************************************************************************\
*****************************************************************************
**
**     Program: delordl.p
**
*****************************************************************************
\***************************************************************************/

trigger procedure for delete of OrderLine.

define variable hAuditManager as handle no-undo.
define variable iAuditKey as int64 no-undo initial 0.
define variable lAuditPerformed as logical no-undo initial false.
define variable lAuditSuccessful as logical no-undo initial false.

OpenEdge.LoadSuite.Common.Util.AuditManager:PerformDeleteAudit(
    input "OrderLine":U,
    input buffer OrderLine:handle,
    input "OrderNum,LineNum,ItemNum,Price,Qty,Discount,ExtendedPrice,OrderLineStatus":U,
    output lAuditPerformed,
    output iAuditKey).