/***************************************************************************\
*****************************************************************************
**
**     Program: critem.p
**
*****************************************************************************
\***************************************************************************/

trigger procedure for create of Item.

define variable iAuditKey as int64 no-undo initial 0.
define variable lAuditPerformed as logical no-undo initial false.
define variable lAuditSuccessful as logical no-undo initial false.

OpenEdge.LoadSuite.Common.Util.AuditManager:PerformWriteAudit(
    input "Item":U,
    input buffer Item:handle,
    input buffer Item:handle,
    input "ItemNum,ItemName,CatPage,Price,CatDescription,OnHand,Allocated,ReOrder,OnOrder,Category1,Category2,Special,Weight,MinQty,ItemImage":U,
    output lAuditPerformed,
    output iAuditKey).