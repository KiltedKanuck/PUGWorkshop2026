/***************************************************************************\
*****************************************************************************
**
**     Program: writem.p
**
*****************************************************************************
\***************************************************************************/

trigger procedure for write of Item new buffer newItem old buffer oldItem.

define variable hAuditManager as handle no-undo.
define variable iAuditKey as int64 no-undo initial 0.
define variable lAuditPerformed as logical no-undo initial false.
define variable lAuditSuccessful as logical no-undo initial false.

if OpenEdge.LoadSuite.Common.Util.AuditManager:RunTriggerLogic then do:
    /*
     * Generate PO if there is not enough QTY
     */
    if newItem.MinQty >
        ((newItem.OnHand - newItem.Allocated) + newItem.onorder) then do:

        find first supplieritemxref where supplieritemxref.itemnum =
            newItem.itemnum no-lock no-error.

        if available supplieritemxref then do:
            find supplier where supplier.supplieridnum =
                supplieritemxref.supplieridnum no-lock no-error.

            if available supplier then do:
                create purchaseorder.
                assign
                    purchaseorder.DateEntered = today
                    purchaseorder.POStatus = "Ordered"
                    purchaseorder.SupplierIDNum = supplieritemxref.supplieridnum.

                create poline.
                assign
                    poline.ponum = purchaseorder.ponum
                    poline.linenum = 1
                    poline.Discount = supplier.discount
                    poline.Itemnum = newItem.itemnum
                    poline.Price = newItem.price
                    poline.qty = newItem.reorder
                    poline.ExtendedPrice = (newItem.price * poline.qty) * (1 - supplier.discount)
                    newItem.onorder = newItem.onorder + newItem.reorder.

                /******
                message "Purchase Order: " purchaseorder.ponum " for " newItem.ItemName
                    ", Item Number: " newItem.ItemNum " has been generated."
                    view-as alert-box information buttons ok.
                *******/
            end.
        end.
    end.
end.

OpenEdge.LoadSuite.Common.Util.AuditManager:PerformWriteAudit(
    input "Item":U,
    input buffer oldItem:handle,
    input buffer newItem:handle,
    input "ItemNum,ItemName,CatPage,Price,CatDescription,OnHand,Allocated,ReOrder,OnOrder,Category1,Category2,Special,Weight,MinQty,ItemImage":U,
    output lAuditPerformed,
    output iAuditKey).