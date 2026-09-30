/***************************************************************************\
*****************************************************************************
**
**     Program: crsuppl.p
**
*****************************************************************************
\***************************************************************************/

trigger procedure for create of Supplier.

define variable iAuditKey as int64 no-undo initial 0.
define variable lAuditPerformed as logical no-undo initial false.
define variable lAuditSuccessful as logical no-undo initial false.

OpenEdge.LoadSuite.Common.Util.AuditManager:PerformWriteAudit(
    input "Supplier":U,
    input buffer Supplier:handle,
    input buffer Supplier:handle,
    input "SupplierIDNum,Name,Address,Address2,City,State,PostalCode,Country,PhoneNumber,Contact,EmailAddress,ShipAmount,Terms,Comments":U,
    output lAuditPerformed,
    output iAuditKey).