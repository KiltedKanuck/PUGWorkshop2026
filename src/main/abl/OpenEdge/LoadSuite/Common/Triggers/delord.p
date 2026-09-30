/***************************************************************************\
*****************************************************************************
**
**     Program: delord.p
**
*****************************************************************************
\***************************************************************************/

trigger procedure for delete of Order.

define variable hAuditManager as handle no-undo.
define variable iAuditKey as int64 no-undo initial 0.
define variable lAuditPerformed as logical no-undo initial false.
define variable lAuditSuccessful as logical no-undo initial false.

/* When Orders are deleted, associated Order detail lines (OrderLine) are also deleted. */
if OpenEdge.LoadSuite.Common.Util.AuditManager:RunTriggerLogic then do:
    for each OrderLine exclusive-lock
        where OrderLine.OrderNum = Order.OrderNum:
        delete OrderLine.
    end.
end.

OpenEdge.LoadSuite.Common.Util.AuditManager:PerformDeleteAudit(
    input "Order":U,
    input buffer Order:handle,
    input "OrderNum,CustNum,OrderDate,ShipDate,PromiseDate,Carrier,Instructions,PO,Terms,SalesRep,BillToID,ShipToID,OrderStatus,WarehouseNum,CreditCard":U,
    output lAuditPerformed,
    output iAuditKey).