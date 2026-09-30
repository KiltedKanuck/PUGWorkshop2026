 
 /*------------------------------------------------------------------------
    File        : OpenEdge.Class.TestTransaction
    Purpose     : Test large transaction (create, update and delete)
    Syntax      : Run in testSuite
    Author(s)   : Cameron David Wright
    Created     : Wed Feb 01 12:55:55 UTC 2023
    Notes       : adjust the private variables at the top for 'size' of transaction
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using OpenEdge.Core.Assert.

block-level on error undo, throw.

class OpenEdge.Class.TestTransaction:
      
    define private variable iSmall          as int64    init 1000      no-undo.
    define private variable iMedium         as int64    init 10000     no-undo.
    define private variable iLarge          as int64    init 100000    no-undo.
    define private variable iRecord         as int64                   no-undo.
    define private variable iStartBinNum    as int64                   no-undo.
    
    @Before.
    method public void TestBegin(  ):  

        assign
            iStartBinNum = current-value(NextBinNum).

        return.
 
    end method.

    @Test.
    method public void TestSmallCreate(  ):  

        do iRecord = 1 to iSmall transaction:
            create Bin.
            assign
                Bin.BinName = substitute("Test bin [&1]",iRecord)
                Bin.ItemNum = random(1,55)
                Bin.Qty     = random(1,10000)
                Bin.WarehouseNum = random(1,14)
                .
        end.
        return.
    end method.

    @Test.
    method public void TestMediumCreate(  ):  

        do iRecord = 1 to iMedium transaction:
            create Bin.
            assign
                Bin.BinName = substitute("Test bin [&1]",iRecord)
                Bin.ItemNum = random(1,55)
                Bin.Qty     = random(1,10000)
                Bin.WarehouseNum = random(1,14)
                .
        end.
        return.
    end method.

    @Test.
    method public void TestLargeCreate(  ):  

        do iRecord = 1 to iLarge transaction:
            create Bin.
            assign
                Bin.BinName = substitute("Test bin [&1]",iRecord)
                Bin.ItemNum = random(1,55)
                Bin.Qty     = random(1,10000)
                Bin.WarehouseNum = random(1,14)
                .
        end.
        return.
    end method.

    @Test.
    method public void TestSmallUpdate(  ):  
        define variable iCurr   as int64  no-undo.
        define variable iFind   as int64    no-undo.
        assign
            iCurr = current-value(NextBinNum).
       
        do iRecord = 1 to iSmall transaction:
            assign iFind = random(iStartBinNum, iCurr - 1 ).
            find first Bin where true
                             and Bin.BinNum = iFind 
                             exclusive-lock.
            assign
                Bin.ItemNum = random(1,55)
                Bin.Qty     = random(1,10000)
                Bin.WarehouseNum = random(1,14)
                .
        end.
        return.
        catch testError as Progress.Lang.Error :
                Assert:RaiseError(substitute("Could not find Bin.BinNum = [&1]",iFind)).
        end catch.
        
    end method.

    @Test.
    method public void TestMediumUpdate(  ):  
        define variable iCurr   as int64  no-undo.
        define variable iFind   as int64    no-undo.
        assign
            iCurr = current-value(NextBinNum).
            
        do iRecord = 1 to iMedium transaction:
            assign iFind = random(iStartBinNum, iCurr - 1 ).
            find first Bin where true
                             and Bin.BinNum = iFind
                             exclusive-lock.
            assign
                Bin.ItemNum = random(1,55)
                Bin.Qty     = random(1,10000)
                Bin.WarehouseNum = random(1,14)
                .
        end.
        return.
        catch testError as Progress.Lang.Error :
                Assert:RaiseError(substitute("Could not find Bin.BinNum = [&1]",iFind)).
        end catch.
    end method.

    @Test.
    method public void TestLargeUpdate(  ):  
        define variable iCurr   as int64  no-undo.
        define variable iFind   as int64    no-undo.
        
        assign
            iCurr = current-value(NextBinNum).
            
        do iRecord = 1 to iLarge transaction:
            assign iFind = random(iStartBinNum, iCurr - 1 ).
            find first Bin where true
                             and Bin.BinNum = iFind
                             exclusive-lock.
            assign
                Bin.ItemNum = random(1,55)
                Bin.Qty     = random(1,10000)
                Bin.WarehouseNum = random(1,14)
                .
        end.
        return.
        catch testError as Progress.Lang.Error :
                Assert:RaiseError(substitute("Could not find Bin.BinNum = [&1]",iFind)).
        end catch.
        
    end method.

    @Test.
    method public void TestSmallDelete(  ):  

        do iRecord = 1 to iSmall transaction:
            find first bin where true
                             and Bin.BinNum >= iStartBinNum
                             exclusive-lock no-error.
            if available bin then
                delete bin.
        end.
        return.
    end method.

    @Test.
    method public void TestMediumDelete(  ):  

        do iRecord = 1 to iMedium transaction:
            find first bin where true
                             and Bin.BinNum >= iStartBinNum
                             exclusive-lock no-error.
            if available bin then
                delete bin.
        end.
        return.
    end method.

    @Test.
    method public void TestLargeDelete(  ):  

        do iRecord = 1 to iLarge transaction:
            find first bin where true
                             and Bin.BinNum >= iStartBinNum
                             exclusive-lock no-error.
            if available bin then
                delete bin.
        end.
        return.
    end method.

    @After.
    method public void TestAfter(  ):  

        do transaction:
            for each bin where true
                           and Bin.BinNum >= iStartBinNum
                           exclusive-lock:
                delete bin.
            end.
        end.
        assign
            current-value(NextBinNum) = iStartBinNum.
        return.
 
    end method.

end class.