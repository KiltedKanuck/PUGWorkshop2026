/***************************************************************************\
*****************************************************************************
**
**     Program: crinv.p
**
*****************************************************************************
\***************************************************************************/

trigger procedure for create of Invoice.

define variable iAuditKey as int64 no-undo initial 0.
define variable lAuditPerformed as logical no-undo initial false.
define variable lAuditSuccessful as logical no-undo initial false.

OpenEdge.LoadSuite.Common.Util.AuditManager:PerformWriteAudit(
    input "Invoice":U,
    input buffer Invoice:handle,
    input buffer Invoice:handle,
    input "InvoiceNum,OrderNum,CustNum,Amount":U,
    output lAuditPerformed,
    output iAuditKey).