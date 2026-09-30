/***************************************************************************\
*****************************************************************************
**
**     Program: delsuppl.p
**
*****************************************************************************
\***************************************************************************/

trigger procedure for delete of Supplier.

define variable hAuditManager as handle no-undo.
define variable iAuditKey as int64 no-undo initial 0.
define variable lAuditPerformed as logical no-undo initial false.
define variable lAuditSuccessful as logical no-undo initial false.

if OpenEdge.LoadSuite.Common.Util.AuditManager:RunTriggerLogic then do:
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
end.

OpenEdge.LoadSuite.Common.Util.AuditManager:PerformDeleteAudit(
    input "Supplier":U,
    input buffer Supplier:handle,
    input "SupplierIDNum,Name,Address,Address2,City,State,Country,Phone,Password,LoginDate,Comments,ShipAmount,PostalCode,Discount":U,
    output lAuditPerformed,
    output iAuditKey).