/***************************************************************************\
*****************************************************************************
**
**     Program: delitem.p
**
*****************************************************************************
\***************************************************************************/

trigger procedure for delete of Item.

define variable hAuditManager as handle no-undo.
define variable iAuditKey as int64 no-undo initial 0.
define variable lAuditPerformed as logical no-undo initial false.
define variable lAuditSuccessful as logical no-undo initial false.

if OpenEdge.LoadSuite.Common.Util.AuditManager:RunTriggerLogic then do:
    for each bin of Item exclusive-lock:
        delete bin.
    end.
end.

OpenEdge.LoadSuite.Common.Util.AuditManager:PerformDeleteAudit(
    input "Item":U,
    input buffer Item:handle,
    input "ItemNum,ItemName,CatPage,Price,CatDescription,OnHand,Allocated,ReOrder,OnOrder,Category1,Category2,Special,Weight,MinQty,ItemImage":U,
    output lAuditPerformed,
    output iAuditKey).