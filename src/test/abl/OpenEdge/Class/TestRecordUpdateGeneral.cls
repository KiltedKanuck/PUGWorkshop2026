 
 /*------------------------------------------------------------------------
    File        : OpenEdge.Class.TestRecordUpdateGeneral
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Cameron David Wright [openedge]
    Created     : Tue Feb 23 08:51:52 EST 2021
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

block-level on error undo, throw.

class OpenEdge.Class.TestRecordUpdateGeneral:

    define private variable iMaxOrd as int64 no-undo.
    define private variable iMaxInv as int64 no-undo.
    define private variable iMaxCust as int64 no-undo.
    define private variable iMaxItem as int64 no-undo.
    define private variable someColors as character
                    initial "black,blue,green,red,yellow,white" no-undo.
    define private variable someFirstNames as character
                    initial "big,small,world,US" no-undo.
    define private variable someMiddleNames as character
                    initial "game,hunting,outdoor" no-undo.
    define private variable someLastNames as character
                    initial "academy,authority,sports,shop" no-undo.
    define private variable someWords as character
                    initial "customer,delivery,sports,shop,Welcome,hello,howdy,today,funny,tomorrow" no-undo.
    define private property RandomComments as character no-undo
    get:
        define variable cReturn as character no-undo.
        
        cReturn = entry(1,someWords)
                + " "         
                + entry(2,someWords)
                + " "
                + entry(3,someWords)
                + " "
                + entry(4,someWords)
                .
        return cReturn.        
    end.
    set.
    define private property RandomCustomerName as character no-undo 
    get:
        define variable cReturn as character no-undo.
        
        cReturn = entry(1,someFirstNames)
                + " "         
                + entry(1,someMiddleNames)
                + " "
                + entry(1,someLastNames)
                .
        return cReturn.        
    end.
    set.

    define private property RandomItemName as character no-undo 
    get:
        define variable cReturn as character no-undo.
        
        cReturn = entry(1,someFirstNames)
                + " "         
                + entry(1,someMiddleNames)
                + " "
                + entry(1,someColors)
                .
        return cReturn.        
    end.
    set.

    define public property TestClass as OpenEdge.LoadSuite.Objects.record.update.general no-undo 
    get.
    set. 
    
    @Before.
    method public void setUpBeforeClass(  ):
        testClass = new OpenEdge.LoadSuite.Objects.record.update.general().
        
        iMaxCust = current-value(NextCustNum).
        iMaxInv = current-value(NextInvNum).
        iMaxOrd = current-value(NextOrdNum).
        iMaxItem = current-value(NextItemNum).
        
        return.
    end method.
     
   
    @After.
    method public void tearDownAfterClass(  ):
        if valid-object(testClass) then delete object testClass.
        return.
    end method.

    @Test.
    method public void TestUpdateOrderForward(  ):  
        define variable count as int64 no-undo.
        
        do count = 10000 to iMaxOrd by 5:
            testClass:updateOrder(count, RandomComments, RandomComments, RandomComments, RandomComments).
        end.    
        return.
 

    end method.

    @Test.
    method public void TestUpdateOrderBackward(  ):  
        define variable count as int64 no-undo.
        
        do count = iMaxOrd to 10000 by -5:
            testClass:updateOrder(count, RandomComments, RandomComments, RandomComments, RandomComments).
        end.    
        return.
 
    end method.

    @Test.
    method public void TestUpdateOrderRandom(  ):  
        define variable counter as int64 no-undo.
        define variable recNum as int64 no-undo.
        define variable upperNum as int64 no-undo.
        
        upperNum = iMaxOrd / 5.
        do counter = 1 to upperNum:
            recNum = (2000 + ((counter - 1) MOD (upperNum - 2000))) * 5.
            testClass:updateOrder(recNum, RandomComments, RandomComments, RandomComments, RandomComments).
        end.    
        return.
 
    end method.

    @Test.
    method public void TestUpdateInvoiceForward(  ):  
        define variable count as int64 no-undo.
        do count = 1 to iMaxInv:
            testClass:updateInvoice(count, 10 + ((count - 1) MOD 100)).
        end.    
        return.
 
    end method.

    @Test.
    method public void TestUpdateInvoiceBackward(  ):  
        define variable count as int64 no-undo.
        do count = iMaxInv to 1 by -1:
            testClass:updateInvoice(count, 10 + ((iMaxInv - count) MOD 100)).
        end.    
        return.
 
    end method.

    @Test.
    method public void TestUpdateInvoiceRandom(  ):  
        define variable counter as int64 no-undo.
        define variable recNum as int64 no-undo.
        
        do counter = 1 to iMaxInv:
            recNum = ((counter - 1) MOD iMaxInv) + 1.
            testClass:updateInvoice(recNum, 10 + ((counter - 1) MOD 100)).
        end.    
        return.
 
    end method.

    @Test.
    method public void TestUpdateCustomerForward(  ):  
        define variable count as int64 no-undo.
        do count = 3000 to iMaxCust by 5:
            testClass:updateCustomer(count, RandomComments, RandomCustomerName, RandomComments, RandomComments, RandomComments, RandomComments).
        end.    
        return.
 
    end method.

    @Test.
    method public void TestUpdateCustomerBackward(  ):  
        define variable count as int64 no-undo.
        do count = iMaxCust to 3000 by -5:
            testClass:updateCustomer(count, RandomComments, RandomCustomerName, RandomComments, RandomComments, RandomComments, RandomComments).
        end.    
        return.
 
    end method.

    @Test.
    method public void TestUpdateCustomerRandom(  ):  
        define variable counter as int64 no-undo.
        define variable recNum as int64 no-undo.
        define variable upperNum as int64 no-undo.
        
        upperNum = iMaxCust / 5.
        do counter = 1 to upperNum:
            recNum = (600 + ((counter - 1) MOD (upperNum - 600))) * 5.
            testClass:updateCustomer(recNum, RandomComments, RandomCustomerName, RandomComments, RandomComments, RandomComments, RandomComments).
        end.    
        return.
 
    end method.  
    
    @Test.
    method public void TestUpdateItemForward(  ):  
        define variable count as int64 no-undo.
        do count = 1 to iMaxItem:
            testClass:updateItem(count, RandomComments, RandomItemName, RandomComments, RandomComments).
        end.    
        return.
 
    end method.

    @Test.
    method public void TestUpdateItemBackward(  ):  
        define variable count as int64 no-undo.
        do count = iMaxItem to 1 by -1:
            testClass:updateItem(count, RandomComments, RandomItemName, RandomComments, RandomComments).
        end.    
        return.
 
    end method.

    @Test.
    method public void TestUpdateItemRandom(  ):  
        define variable counter as int64 no-undo.
        define variable recNum as int64 no-undo.
        
        do counter = 1 to iMaxItem:
            recNum = ((counter - 1) MOD iMaxItem) + 1.
            testClass:updateItem(recNum, RandomComments, RandomItemName, RandomComments, RandomComments).
        end.    
        return.
 
    end method.
       
end class.