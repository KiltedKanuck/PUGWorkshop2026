# Trigger Coverage Reference

This document lists every table defined in the schema and indicates whether a table-level `WRITE` or `DELETE` trigger is configured.

Source of truth:
- `src/main/resources/schema/thrasher.df` (`ADD TABLE` + `TABLE-TRIGGER` entries)
- Trigger procedures in `src/main/abl/OpenEdge/Workshop/Common/Triggers`

## When Triggers Fire

- `WRITE` trigger: fires when a record is written (new create or update).
- `DELETE` trigger: fires when a record is deleted.
- If no trigger is configured for an action on a table, no custom trigger procedure is run for that action.

## Table Matrix

| Table | Write Trigger | Delete Trigger | Write Procedure | Delete Procedure |
|---|---|---|---|---|
| AuditDetail | No | No |  |  |
| AuditHeader | No | No |  |  |
| Benefits | No | No |  |  |
| BillTo | No | No |  |  |
| Bin | No | No |  |  |
| ContextDetail | No | No |  |  |
| ContextHeader | No | No |  |  |
| Customer | Yes | Yes | OpenEdge/Workshop/Common/Triggers/wrcust.p | OpenEdge/Workshop/Common/Triggers/delcust.p |
| Department | No | No |  |  |
| Employee | Yes | No | OpenEdge/Workshop/Common/Triggers/wremp.p |  |
| Family | No | No |  |  |
| Feedback | No | No |  |  |
| InventoryTrans | No | No |  |  |
| Invoice | No | Yes |  | OpenEdge/Workshop/Common/Triggers/delinv.p |
| Item | Yes | Yes | OpenEdge/Workshop/Common/Triggers/writem.p | OpenEdge/Workshop/Common/Triggers/delitem.p |
| LocalDefault | No | No |  |  |
| Order | Yes | Yes | OpenEdge/Workshop/Common/Triggers/wrord.p | OpenEdge/Workshop/Common/Triggers/delord.p |
| OrderLine | Yes | Yes | OpenEdge/Workshop/Common/Triggers/wrordl.p | OpenEdge/Workshop/Common/Triggers/delordl.p |
| POLine | No | No |  |  |
| PurchaseOrder | No | No |  |  |
| RefCall | No | No |  |  |
| ReplQueue | No | No |  |  |
| SalesRep | No | No |  |  |
| ShipTo | No | No |  |  |
| State | No | No |  |  |
| Supplier | No | Yes |  | OpenEdge/Workshop/Common/Triggers/delsuppl.p |
| SupplierItemXref | No | No |  |  |
| SystemFile | No | No |  |  |
| TimeSheet | No | No |  |  |
| Vacation | No | No |  |  |
| Warehouse | Yes | No | OpenEdge/Workshop/Common/Triggers/wrware.p |  |

## Totals

- Total tables: 31
- Tables with `WRITE` trigger: 6
- Tables with `DELETE` trigger: 7
