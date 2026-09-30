/***************************************************************************\
*****************************************************************************
**
**     Program: delcust.p
**
*****************************************************************************
\***************************************************************************/

trigger procedure for delete of Customer.

/* Variable Definitions */

define variable answer as logical.

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