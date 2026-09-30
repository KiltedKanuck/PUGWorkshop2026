/***************************************************************************\
*****************************************************************************
**
**     Program: delcust.p
**
*****************************************************************************
\***************************************************************************/

trigger procedure for delete of Customer.

/* Variable Definitions */

define variable hAuditManager as handle no-undo.
define variable answer as logical.
define variable iAuditKey as int64 no-undo initial 0.
define variable lAuditPerformed as logical no-undo initial false.
define variable lAuditSuccessful as logical no-undo initial false.

if OpenEdge.LoadSuite.Common.Util.AuditManager:RunTriggerLogic then do:
     /* Customer record cannot be deleted if outstanding invoices are found */
     find first invoice of Customer no-lock no-error.
     if available invoice then do:
         if invoice.amount <= invoice.totalpaid + invoice.adjustment then do:
             find first order of Customer no-lock no-error.
             if available order then do:
                 message "Open orders exist for Customer " Customer.CustNum ", Cannot delete.".
                 return error.
             end.
         end.
         else do:
             message "Outstanding Unpaid Invoice Exists, Cannot Delete".
             return error.
         end.
     end.
     else do:
         find first order of Customer no-lock no-error.
         if available order then do:
             message "Open orders exist for Customer " Customer.CustNum ", Cannot delete.".
             return error.
         end.
     end.
end.

OpenEdge.LoadSuite.Common.Util.AuditManager:PerformDeleteAudit(
    input "Customer":U,
    input buffer Customer:handle,
    input "CustNum,Name,Address,Address2,City,State,Country,Phone,Contact,SalesRep,Comments,CreditLimit,Balance,Terms,Discount,PostalCode,Fax,EmailAddress":U,
    output lAuditPerformed,
    output iAuditKey).