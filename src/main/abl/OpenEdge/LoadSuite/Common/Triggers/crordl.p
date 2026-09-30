/***************************************************************************\
*****************************************************************************
**
**     Program: crordl.p
**
*****************************************************************************
\***************************************************************************/

trigger procedure for create of OrderLine.

define variable iAuditKey as int64 no-undo initial 0.
define variable lAuditPerformed as logical no-undo initial false.
define variable lAuditSuccessful as logical no-undo initial false.

/* No additional action required on OrderLine create. */

OpenEdge.LoadSuite.Common.Util.AuditManager:PerformWriteAudit(
    input "OrderLine":U,
    input buffer OrderLine:handle,
    input buffer OrderLine:handle,
    input "OrderNum,LineNum,ItemNum,Price,Qty,Discount,ExtendedPrice,OrderLineStatus":U,
    output lAuditPerformed,
    output iAuditKey).