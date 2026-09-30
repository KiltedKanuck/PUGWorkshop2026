/***************************************************************************\
*****************************************************************************
**
**     Program: crref.p
**
*****************************************************************************
\***************************************************************************/

trigger procedure for create of RefCall.

define variable iAuditKey as int64 no-undo initial 0.
define variable lAuditPerformed as logical no-undo initial false.
define variable lAuditSuccessful as logical no-undo initial false.

OpenEdge.LoadSuite.Common.Util.AuditManager:PerformWriteAudit(
    input "RefCall":U,
    input buffer RefCall:handle,
    input buffer RefCall:handle,
    input "CallNum,CustNum,Parent":U,
    output lAuditPerformed,
    output iAuditKey).