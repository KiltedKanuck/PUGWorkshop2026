/***************************************************************************\
*****************************************************************************
**
**     Program: wrcust.p
**
*****************************************************************************
\***************************************************************************/

trigger procedure for write of Customer new buffer newCustomer old buffer oldCustomer.

/* Variable Definitions */

define variable hAuditManager as handle no-undo.
define variable i as int64 initial 0.
define variable iAuditKey as int64 no-undo initial 0.
define variable lAuditPerformed as logical no-undo initial false.
define variable lAuditSuccessful as logical no-undo initial false.
define variable iOutstanding as int64 initial 0.

if OpenEdge.LoadSuite.Common.Util.AuditManager:RunTriggerLogic then do:
     /* Check to see if the user changed the Customer Number */
     if newCustomer.CustNum ne oldCustomer.CustNum and oldCustomer.CustNum ne 0 then do:
         /* If user changed the Customer Number, find related orders and change  */
         /* their customer numbers.                                              */
         for each Order of oldCustomer exclusive-lock:
             Order.CustNum = newCustomer.CustNum.
             i = i + 1.
         end.
         if i > 0 then
             message i "orders changed to reflect the new customer number!".
     end.

     /* Ensure that the Credit Limit value is always Greater than the sum of this
      * Customer's Outstanding Balance
      */
     for each Order of newCustomer no-lock:
         for each OrderLine of Order no-lock where order.shipdate = ?:
             iOutstanding = iOutstanding + OrderLine.ExtendedPrice.
         end.
     end.
     for each Invoice of newCustomer no-lock:
         iOutstanding = iOutstanding + (Amount - (TotalPaid + Adjustment)).
     end.

     if newCustomer.CreditLimit < iOutstanding then do:
         message "This Customer has an outstanding balance of: " iOutstanding ". Increasing the credit limit!".
         newCustomer.CreditLimit = iOutstanding + 1000.
     end.
end.

OpenEdge.LoadSuite.Common.Util.AuditManager:PerformWriteAudit(
    input "Customer":U,
    input buffer oldCustomer:handle,
    input buffer newCustomer:handle,
    input "CustNum,Name,Address,Address2,City,State,Country,Phone,Contact,SalesRep,Comments,CreditLimit,Balance,Terms,Discount,PostalCode,Fax,EmailAddress":U,
    output lAuditPerformed,
    output iAuditKey).