 
 /*------------------------------------------------------------------------
    File        : OpenEdge.Class.TestRecordReadGeneral
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Cameron David Wright [openedge]
    Created     : Tue Feb 23 08:51:52 EST 2021
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

block-level on error undo, throw.

class OpenEdge.Class.TestRecordReadGeneral:

    define private variable iMaxOrd as int64 no-undo.
    define private variable iMaxInv as int64 no-undo.
    define private variable iMaxCust as int64 no-undo.
    define private variable iMaxItem as int64 no-undo.

    define public property TestClass as OpenEdge.LoadSuite.Objects.record.read.general no-undo 
    get.
    set. 
    
    @Before.
    method public void setUpBeforeClass(  ):
        testClass = new OpenEdge.LoadSuite.Objects.record.read.general().
        
        iMaxCust = current-value(NextCustNum).
        iMaxInv = current-value(NextInvNum).
        iMaxOrd = current-value(NextOrdNum).
        iMaxItem = current-value(NextItemNum).
    end method.
   
    @After.
    method public void tearDownAfterClass(  ):
        if valid-object(testClass) then delete object testClass.
        return.

    end method.

// ORDERS[3951]
    @Test.
    method public void TestReadOrderForward(  ):  
        define variable count as int64 no-undo.
        
        do count = 10000 to iMaxOrd by 5:
            testClass:readOrder(count).
        end.
    end method.

    @Test.
    method public void TestReadOrderBackward(  ):  
        define variable count as int64 no-undo.
        do count = iMaxOrd to 10000 by -5:
            testClass:readOrder(count).
        end.
    end method.

    @Test.
    method public void TestReadOrderRandom(  ):  
        define variable counter as int64 no-undo.
        define variable recNum as int64 no-undo.
        define variable upperNum as int64 no-undo.
        
        upperNum = iMaxOrd / 5.
        do counter = 1 to upperNum:
            recNum = (2000 + ((counter - 1) MOD (upperNum - 2000))) * 5.
            testClass:readOrder(recNum).
        end.
    end method.

// INVOICE[147]
    @Test.
    method public void TestReadInvoiceForward(  ):  
        define variable count as int64 no-undo.
        do count = 1 to iMaxInv:
            testClass:readInvoice(count).
        end.
    end method.

    @Test.
    method public void TestReadInvoiceBackward(  ):  
        define variable count as int64 no-undo.
        do count = iMaxInv to 1 by -1:
            testClass:readInvoice(count).
        end.
    end method.

    @Test.
    method public void TestReadInvoiceRandom(  ):  
        define variable counter as int64 no-undo.
        define variable recNum as int64 no-undo.
        
        do counter = 1 to iMaxInv:
            recNum = ((counter - 1) MOD iMaxInv) + 1.
            testClass:readInvoice(recNum).
        end.
    end method.

// Customer[1117]
    @Test.
    method public void TestReadCustomerForward(  ):  
        define variable count as int64 no-undo.
        do count = 3000 to iMaxCust by 5:
            testClass:readCustomer(count).
        end.
    end method.

    @Test.
    method public void TestReadCustomerBackward(  ):  
        define variable count as int64 no-undo.
        do count = iMaxCust to 3000 by -5:
            testClass:readCustomer(count).
        end.
    end method.

    @Test.
    method public void TestReadCustomerRandom(  ):  
        define variable counter     as int64 no-undo.
        define variable recNum      as int64 no-undo.
        define variable upperNum    as int64 no-undo.
        
        upperNum = iMaxCust / 5.
        
        do counter = 1 to upperNum:
            recNum = (600 + ((counter - 1) MOD (upperNum - 600))) * 5.
            testClass:readCustomer(recNum).
        end.
    end method.  
    
// ITEM[55]
    @Test.
    method public void TestReadItemForward(  ):  
        define variable count as int64 no-undo.
        do count = 1 to iMaxItem:
            testClass:readItem(count).
        end.
    end method.

    @Test.
    method public void TestReadItemBackward(  ):  
        define variable count as int64 no-undo.
        do count = iMaxItem to 1 by -1:
            testClass:readItem(count).
        end.
    end method.

    @Test.
    method public void TestReadItemRandom(  ):  
        define variable counter as int64 no-undo.
        define variable recNum as int64 no-undo.
        
        do counter = 1 to iMaxItem:
            recNum = ((counter - 1) MOD iMaxItem) + 1.
            testClass:readItem(recNum).
        end.
    end method.
       
end class.