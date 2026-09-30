/***************************************************************************\
*****************************************************************************
**
**     Program: cremp.p
**
*****************************************************************************
\***************************************************************************/

trigger procedure for create of Employee.

define variable iAuditKey as int64 no-undo initial 0.
define variable lAuditPerformed as logical no-undo initial false.
define variable lAuditSuccessful as logical no-undo initial false.

OpenEdge.LoadSuite.Common.Util.AuditManager:PerformWriteAudit(
    input "Employee":U,
    input buffer Employee:handle,
    input buffer Employee:handle,
    input "LastName,FirstName,Address,Address2,City,State,PostalCode,DeptCode,Position,HomePhone,WorkPhone,VacationDaysLeft,SickDaysLeft,EmpNum,StartDate,BirthDate":U,
    output lAuditPerformed,
    output iAuditKey).