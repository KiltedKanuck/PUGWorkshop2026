/***************************************************************************\
*****************************************************************************
**
**     Program: wrordl.p
**
*****************************************************************************
\***************************************************************************/

trigger procedure for write of OrderLine new buffer newOrderLine old buffer oldOrderLine.

/* Automatically calculate the Extended Price based on Price, Qty, Discount */

newOrderLine.ExtendedPrice = newOrderLine.Price * newOrderLine.Qty * (1 - (newOrderLine.Discount / 100)).