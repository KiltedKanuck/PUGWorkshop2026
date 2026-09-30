/***************************************************************************\
*****************************************************************************
**
**     Program: delinv.p
**
*****************************************************************************
\***************************************************************************/

trigger procedure for delete of Invoice.

define variable hAuditManager as handle no-undo.
define variable iAuditKey as int64 no-undo initial 0.
define variable lAuditPerformed as logical no-undo initial false.
define variable lAuditSuccessful as logical no-undo initial false.

OpenEdge.LoadSuite.Common.Util.AuditManager:PerformDeleteAudit(
    input "Invoice":U,
    input buffer Invoice:handle,
    input "InvoiceNum,CustNum,InvoiceDate,Amount,TotalPaid,Adjustment,OrderNum,ShipCharge":U,
    output lAuditPerformed,
    output iAuditKey).