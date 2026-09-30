/***************************************************************************\
*****************************************************************************
**
**     Program: writem.p
**
*****************************************************************************
\***************************************************************************/

trigger procedure for write of Item new buffer newItem old buffer oldItem.

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