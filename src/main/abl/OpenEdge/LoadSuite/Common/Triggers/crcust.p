/***************************************************************************\
*****************************************************************************
**
**     Program: crcust.p
**
*****************************************************************************
\***************************************************************************/

trigger procedure for create of Customer.

define variable iAuditKey as int64 no-undo initial 0.
define variable lAuditPerformed as logical no-undo initial false.
define variable lAuditSuccessful as logical no-undo initial false.

OpenEdge.LoadSuite.Common.Util.AuditManager:PerformWriteAudit(
    input "Customer":U,
    input buffer Customer:handle,
    input buffer Customer:handle,
    input "CustNum,Name,Address,Address2,City,State,Country,Phone,Contact,SalesRep,Comments,CreditLimit,Balance,Terms,Discount,PostalCode,Fax,EmailAddress":U,
    output lAuditPerformed,
    output iAuditKey).