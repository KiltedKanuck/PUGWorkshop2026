/***************************************************************************\
*****************************************************************************
**
**     Program: crlocdef.p
**
*****************************************************************************
\***************************************************************************/

trigger procedure for create of LocalDefault.

define variable iAuditKey as int64 no-undo initial 0.
define variable lAuditPerformed as logical no-undo initial false.
define variable lAuditSuccessful as logical no-undo initial false.

OpenEdge.LoadSuite.Common.Util.AuditManager:PerformWriteAudit(
    input "LocalDefault":U,
    input buffer LocalDefault:handle,
    input buffer LocalDefault:handle,
    input "LocalDefNum":U,
    output lAuditPerformed,
    output iAuditKey).