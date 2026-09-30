/***************************************************************************\
*****************************************************************************
**
**     Program: crord.p
**
*****************************************************************************
\***************************************************************************/

trigger procedure for create of Order.

define variable iAuditKey as int64 no-undo initial 0.
define variable lAuditPerformed as logical no-undo initial false.
define variable lAuditSuccessful as logical no-undo initial false.

if OpenEdge.LoadSuite.Common.Util.AuditManager:RunTriggerLogic then do:
    assign
        order.orderdate   = today
        order.promisedate = today + 14
        .
end.

OpenEdge.LoadSuite.Common.Util.AuditManager:PerformWriteAudit(
    input "Order":U,
    input buffer Order:handle,
    input buffer Order:handle,
    input "OrderNum,CustNum,OrderDate,ShipDate,PromiseDate,Carrier,Instructions,PO,Terms,SalesRep,BillToID,ShipToID,OrderStatus,WarehouseNum,CreditCard":U,
    output lAuditPerformed,
    output iAuditKey).