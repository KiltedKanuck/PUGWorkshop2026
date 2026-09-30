 
 /*------------------------------------------------------------------------
    File        : OpenEdge.Class.TestRecordDeleteGeneral
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Cameron David Wright [openedge]
    Created     : Tue Feb 23 08:51:52 EST 2021
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

block-level on error undo, throw.

class OpenEdge.Class.TestRecordDeleteGeneral:

    define private variable iMaxOrd as int64 no-undo.
    define private variable iMaxInv as int64 no-undo.
    define private variable iMaxCust as int64 no-undo.
    define private variable iMaxItem as int64 no-undo.

    define public property TestClass as OpenEdge.LoadSuite.Objects.record.delete.general no-undo 
    get.
    set. 
    
    @Before.
    method public void setUpBeforeClass(  ):
        testClass = new OpenEdge.LoadSuite.Objects.record.delete.general().
        
        iMaxCust = current-value(NextCustNum).
        iMaxInv = current-value(NextInvNum).
        iMaxOrd = current-value(NextOrdNum).
        iMaxItem = current-value(NextItemNum).
        
        return.
    end method.
   
    @After.
    method public void tearDownAfterClass(  ):
        
        if not can-find(first customer where custnum >= 9000) then current-value(NextCustNum) = 8580.
        if not can-find(first invoice where invoicenum >= 200) then current-value(NextInvNum) = 147.
        if not can-find(first order where ordernum >= 30000) then current-value(NextOrdNum) = 29750.
        
        if valid-object(testClass) then delete object testClass.
        return.

    end method.

    @Test.
    method public void TestDeleteOrderForward(  ):  
        define variable count as int64 no-undo.
        
        do count = 30000 to 40000 by 5:
            testClass:deleteOrder(count).
        end.    
        return.
 
    end method.

    @Test.
    method public void TestDeleteOrderBackward(  ):  
        define variable count as int64 no-undo.
        do count = iMaxOrd to (iMaxOrd - 12500) by -5:
            testClass:deleteOrder(count).
        end.    
        return.
 
    end method.

    @Test.
    method public void TestDeleteOrderRandom100(  ):  
        define variable recNum as int64 no-undo.
        define variable upperNum as int64 no-undo.
        define variable count as int64 no-undo.
        assign
            upperNum = iMaxOrd / 5
            count = 0.
        
        repeat:
            if not can-find(first order where ordernum >= 30000) then leave. 
            count = count + 1.
            if count >= 100 then leave.
            recNum = (6000 + ((count - 1) MOD (upperNum - 6000))) * 5.
            testClass:deleteOrder(recNum).   
        end.
        
        return.
 
    end method.

/*    @Test.                                        */
/*    method public void TestDeleteOrderRemain(  ): */
/*        for each order no-lock                    */
/*            where order.ordernum >= 30000:        */
/*            testClass:deleteOrder(order.ordernum).*/
/*        end.                                      */
/*                                                  */
/*        return.                                   */
/*                                                  */
/*    end method.                                   */

    @Test.
    method public void TestDeleteInvoiceForward(  ):  
        define variable count as int64 no-undo.
        do count = 200 to 2500:
            testClass:deleteInvoice(count).
           
        end.    
        return.
 
    end method.

    @Test.
    method public void TestDeleteInvoiceBackward(  ):  
        define variable count as int64 no-undo.
        do count = iMaxInv to (iMaxInv - 2500) by -1:
            testClass:deleteInvoice(count).
        end.    
        return.
 
    end method.

    @Test.
    method public void TestDeleteInvoiceRandom100(  ):  
        define variable recNum as int64 no-undo.
        define variable count as int64 init 0 no-undo.
        repeat:
            if not can-find(first invoice where invoicenum >= 200) then leave.
            count = count + 1.
            if count >= 100 then leave.
            recNum = 200 + ((count - 1) MOD (iMaxInv - 200)).
            testClass:deleteInvoice(recNum).
        end.

        return.
 
    end method.

/*    @Test.                                              */
/*    method public void TestDeleteInvoiceRemain(  ):     */
/*                                                        */
/*        for each invoice no-lock                        */
/*            where invoice.invoicenum >= 200:            */
/*            testClass:deleteInvoice(invoice.invoicenum).*/
/*        end.                                            */
/*                                                        */
/*        return.                                         */
/*                                                        */
/*    end method.                                         */

    @Test.
    method public void TestDeleteCustomerForward(  ):  
        define variable count as int64 no-undo.
        do count = 9000 to 21500 by 5:
            testClass:deleteCustomer(count).
        end.    
        return.
 
    end method.

    @Test.
    method public void TestDeleteCustomerBackward(  ):  
        define variable count as int64 no-undo.
        do count = iMaxCust to (iMaxCust - 12500)  by -5:
            testClass:deleteCustomer(count).
        end.    
        return.
 
    end method.

    @Test.
    method public void TestDeleteCustomerRandom100(  ):  
        define variable recNum as int64 no-undo.
        define variable upperNum as int64 no-undo.
        define variable count as int64 init 0 no-undo.
        assign
            upperNum = iMaxCust / 5.
            
        repeat:
            if not can-find(first customer where customer.custnum >= 9000) then leave.
            count = count + 1.
            if count >= 100 then leave. 
            recNum = (1800 + ((count - 1) MOD (upperNum - 1800))) * 5.
            testClass:deleteCustomer(recNum).   
        end.
        
        return.
 
    end method.  

/*    @Test.                                          */
/*    method public void TestDeleteCustomerRemain(  ):*/
/*                                                    */
/*        for each customer no-lock                   */
/*            where customer.custnum >= 9000:         */
/*            testClass:delCustomer(customer.custnum).*/
/*        end.                                        */
/*                                                    */
/*        return.                                     */
/*                                                    */
/*    end method.                                     */
      
end class.