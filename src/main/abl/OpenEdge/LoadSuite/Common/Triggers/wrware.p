/***************************************************************************\
*****************************************************************************
**
**     Program: wrware.p
**
*****************************************************************************
\***************************************************************************/

trigger procedure for write of Warehouse new buffer newWarehouse old buffer oldWarehouse.

define variable hAuditManager as handle no-undo.
define variable i as int64 initial 0.
define variable iAuditKey as int64 no-undo initial 0.
define variable j as int64 initial 0.
define variable lAuditPerformed as logical no-undo initial false.
define variable lAuditSuccessful as logical no-undo initial false.

if OpenEdge.LoadSuite.Common.Util.AuditManager:RunTriggerLogic then do:
    /* Check to see if the user changed the Warehouse Number */
    if newWarehouse.WarehouseNum ne oldWarehouse.WarehouseNum and oldWarehouse.WarehouseNum > 0 then do:
        /* If user changed the Warehouse Number, find related bin and */
        /* change the Warehouse numbers.                              */
        for each Bin exclusive-lock where Bin.WarehouseNum = oldWarehouse.WarehouseNum:
            Bin.WarehouseNum = newWarehouse.WarehouseNum.
            i = i + 1.
        end.
        if i > 0 then
            message i "bin changed to reflect the new warehouse number!".

        /* If user changed the Warehouse Number, find related inventory trans and */
        /* change the Warehouse numbers.                                          */
        for each InventoryTrans exclusive-lock where InventoryTrans.WarehouseNum = oldWarehouse.WarehouseNum:
            InventoryTrans.WarehouseNum = newWarehouse.WarehouseNum.
            j = j + 1.
        end.
        if j > 0 then
            message j "inventory transactions changed to reflect the new warehouse number!".
    end.
end.

OpenEdge.LoadSuite.Common.Util.AuditManager:PerformWriteAudit(
    input "Warehouse":U,
    input buffer oldWarehouse:handle,
    input buffer newWarehouse:handle,
    input "WarehouseNum,WarehouseName,Country,Address,Address2,City,State,PostalCode,Phone":U,
    output lAuditPerformed,
    output iAuditKey).