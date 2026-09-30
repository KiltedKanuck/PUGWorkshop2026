/***************************************************************************\
*****************************************************************************
**
**     Program: delsuppl.p
**
*****************************************************************************
\***************************************************************************/

trigger procedure for delete of Supplier.

find first purchaseorder of Supplier where postatus ne "Received" no-lock no-error.

if available purchaseorder then do:
    message "Supplier can not be deleted." "There is at least one PO that has not been received.".
    return error.
end.
else do:
    /* delete received po */
    for each purchaseorder of Supplier exclusive-lock:
        for each poline of purchaseorder exclusive-lock:
            delete poline.
        end.

        delete purchaseorder.
    end.
end.