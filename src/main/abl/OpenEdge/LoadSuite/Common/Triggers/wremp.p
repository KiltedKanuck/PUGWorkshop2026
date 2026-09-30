/***************************************************************************\
*****************************************************************************
**
**     Program: wremp.p
**
*****************************************************************************
\***************************************************************************/

trigger procedure for write of Employee new buffer newEmployee old buffer oldEmployee.

define variable hAuditManager as handle no-undo.
define variable h as int64 initial 0.
define variable i as int64 initial 0.
define variable iAuditKey as int64 no-undo initial 0.
define variable j as int64 initial 0.
define variable k as int64 initial 0.
define variable lAuditPerformed as logical no-undo initial false.
define variable lAuditSuccessful as logical no-undo initial false.

if OpenEdge.LoadSuite.Common.Util.AuditManager:RunTriggerLogic then do:
    /* Check to see if the user changed the Employee Number */
    if newEmployee.EmpNum ne oldEmployee.EmpNum and oldEmployee.EmpNum > 0 then do:
        /* If user changed the Employee Number, find related benefits and */
        /* change their employee numbers.                                 */
        for each Benefits exclusive-lock where Benefits.EmpNum = oldEmployee.EmpNum:
            Benefits.EmpNum = newEmployee.EmpNum.
            h = h + 1.
        end.
        if h > 0 then
            message h "benefits changed to reflect the new employee number!".

        /* If user changed the Employee Number, find related family members and */
        /* change their employee numbers.                                       */
        for each Family exclusive-lock where Family.EmpNum = oldEmployee.EmpNum:
            Family.EmpNum = newEmployee.EmpNum.
            i = i + 1.
        end.
        if i > 0 then
            message i "family members changed to reflect the new employee number!".

        /* If user changed the Employee Number, find related timesheet and */
        /* change their employee numbers.                                  */
        for each Timesheet exclusive-lock where Timesheet.EmpNum = oldEmployee.EmpNum:
            Timesheet.EmpNum = newEmployee.EmpNum.
            j = j + 1.
        end.
        if j > 0 then
            message j "timesheet changed to reflect the new employee number!".

        /* If user changed the Employee Number, find related timesheet and */
        /* change their employee numbers.                                  */
        for each Vacation exclusive-lock where Vacation.EmpNum = oldEmployee.EmpNum:
            Vacation.EmpNum = newEmployee.EmpNum.
            k = k + 1.
        end.
        if k > 0 then
            message k "vacation changed to reflect the new employee number!".

    end.
end.

OpenEdge.LoadSuite.Common.Util.AuditManager:PerformWriteAudit(
    input "Employee":U,
    input buffer oldEmployee:handle,
    input buffer newEmployee:handle,
    input "LastName,FirstName,Address,Address2,City,State,PostalCode,DeptCode,Position,HomePhone,WorkPhone,VacationDaysLeft,SickDaysLeft,EmpNum,StartDate,BirthDate":U,
    output lAuditPerformed,
    output iAuditKey).