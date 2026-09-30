/***************************************************************************\
*****************************************************************************
**
**     Program: wrord.p
**
*****************************************************************************
\***************************************************************************/

trigger procedure for write of Order new buffer newOrder old buffer oldOrder.

define variable hAuditManager as handle no-undo.
define variable iAuditKey as int64 no-undo initial 0.
define variable lAuditPerformed as logical no-undo initial false.
define variable lAuditSuccessful as logical no-undo initial false.

OpenEdge.LoadSuite.Common.Util.AuditManager:PerformWriteAudit(
    input "Order":U,
    input buffer oldOrder:handle,
    input buffer newOrder:handle,
    input "OrderNum,CustNum,OrderDate,ShipDate,PromiseDate,Carrier,Instructions,PO,Terms,SalesRep,BillToID,ShipToID,OrderStatus,WarehouseNum,CreditCard":U,
    output lAuditPerformed,
    output iAuditKey).