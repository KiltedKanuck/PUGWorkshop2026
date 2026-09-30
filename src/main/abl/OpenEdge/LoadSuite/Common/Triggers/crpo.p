/***************************************************************************\
*****************************************************************************
**
**     Program: crpo.p
**
*****************************************************************************
\***************************************************************************/

trigger procedure for create of PurchaseOrder.

define variable iAuditKey as int64 no-undo initial 0.
define variable lAuditPerformed as logical no-undo initial false.
define variable lAuditSuccessful as logical no-undo initial false.

OpenEdge.LoadSuite.Common.Util.AuditManager:PerformWriteAudit(
    input "PurchaseOrder":U,
    input buffer PurchaseOrder:handle,
    input buffer PurchaseOrder:handle,
    input "PONum,SupplierIDNum,OrderDate":U,
    output lAuditPerformed,
    output iAuditKey).