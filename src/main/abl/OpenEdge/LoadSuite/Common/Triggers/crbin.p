/***************************************************************************\
*****************************************************************************
**
**     Program: crbin.p
**
*****************************************************************************
\***************************************************************************/

trigger procedure for create of Bin.

define variable iAuditKey as int64 no-undo initial 0.
define variable lAuditPerformed as logical no-undo initial false.
define variable lAuditSuccessful as logical no-undo initial false.

OpenEdge.LoadSuite.Common.Util.AuditManager:PerformWriteAudit(
    input "Bin":U,
    input buffer Bin:handle,
    input buffer Bin:handle,
    input "BinNum,BinName":U,
    output lAuditPerformed,
    output iAuditKey).