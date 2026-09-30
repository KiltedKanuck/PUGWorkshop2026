/***************************************************************************\
*****************************************************************************
**
**     Program: delord.p
**
*****************************************************************************
\***************************************************************************/

trigger procedure for delete of Order.

/* When Orders are deleted, associated Order detail lines (OrderLine) are also deleted. */
for each OrderLine exclusive-lock
    where OrderLine.OrderNum = Order.OrderNum:
    delete OrderLine.
end.