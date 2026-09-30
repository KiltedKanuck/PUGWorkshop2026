 
 /*------------------------------------------------------------------------
    File        : TestStringLongGeneral
    Purpose     : 
    Description : 
    Author(s)   : Cameron David Wright
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using OpenEdge.Core.Assert.
using OpenEdge.LoadSuite.Objects.string.long.general.

block-level on error undo, throw.

class OpenEdge.Class.TestStringLongGeneral:

    { OpenEdge/LoadSuite/Common/include/alphabet.i }
    
    define private property RandomNumber as integer no-undo 
    get.
    set. 

    define public property TestClass as OpenEdge.LoadSuite.Objects.string.long.general no-undo 
    get.
    set. 

    @Before.
    method public void setUpBeforeClass(  ):
        
        TestClass = new OpenEdge.LoadSuite.Objects.string.long.general().
        
        return.

    end method.

    @After.
    method public void tearDownAfterClass(  ):

        delete object TestClass.        
        return.

    end method.

    @Test.
    method public void TestFill():
        
        Assert:NotZero(length(TestClass:FullString)).
       
        return.
    end method.

    @Test.
    method public void TestWhatLetter(  ):  

        define variable kLocal      as character no-undo.
        define variable TestReturn  as character no-undo.
        define variable iRandLetter as integer no-undo.
        
        assign
            iRandLetter = random(1,TestClass:StringSize)
            kLocal = substring(TestClass:FullString,iRandLetter,1)
            .
        
        TestReturn = TestClass:WhatLetter(iRandLetter).
        Assert:Equals(TestReturn,kLocal).

        return.
 
    end method.     

    @Test.
    method public void TestWhat5Letter(  ):  

        define variable kLocal      as character no-undo.
        define variable TestReturn  as character no-undo.
        define variable iRandLetter as integer no-undo.
        define variable iLoop       as integer no-undo.
        define variable iMax        as integer initial 5 no-undo.
        
        do iLoop = 1 to iMax:
            assign
                iRandLetter = random(1,TestClass:StringSize)
                kLocal = substring(TestClass:FullString,iRandLetter,1)
                .
            
            TestReturn = TestClass:WhatLetter(iRandLetter).
            Assert:Equals(TestReturn,kLocal).
        end.
        return.
 
    end method.     

    @Test.
    method public void TestWhat25Letter(  ):  

        define variable kLocal      as character no-undo.
        define variable TestReturn  as character no-undo.
        define variable iRandLetter as integer no-undo.
        define variable iLoop       as integer no-undo.
        define variable iMax        as integer initial 25 no-undo.
        
        do iLoop = 1 to iMax:
            assign
                iRandLetter = random(1,TestClass:StringSize)
                kLocal = substring(TestClass:FullString,iRandLetter,1)
                .
            
            TestReturn = TestClass:WhatLetter(iRandLetter).
            Assert:Equals(TestReturn,kLocal).
        end.
        return.
 
    end method.     
    @Test.
    method public void TestWhat50Letter(  ):  

        define variable kLocal      as character no-undo.
        define variable TestReturn  as character no-undo.
        define variable iRandLetter as integer no-undo.
        define variable iLoop       as integer no-undo.
        define variable iMax        as integer initial 50 no-undo.
        
        do iLoop = 1 to iMax:
            assign
                iRandLetter = random(1,TestClass:StringSize)
                kLocal = substring(TestClass:FullString,iRandLetter,1)
                .
            
            TestReturn = TestClass:WhatLetter(iRandLetter).
            Assert:Equals(TestReturn,kLocal).
        end.
        return.
 
    end method.     
    @Test.
    method public void TestWhat500Letter(  ):  

        define variable kLocal      as character no-undo.
        define variable TestReturn  as character no-undo.
        define variable iRandLetter as integer no-undo.
        define variable iLoop       as integer no-undo.
        define variable iMax        as integer initial 500 no-undo.
        
        do iLoop = 1 to iMax:
            assign
                iRandLetter = random(1,TestClass:StringSize)
                kLocal = substring(TestClass:FullString,iRandLetter,1)
                .
            
            TestReturn = TestClass:WhatLetter(iRandLetter).
            Assert:Equals(TestReturn,kLocal).
        end.
        return.
 
    end method.     

    @Test.
    method public void TestWhatWord(  ):  
        define variable TestReturn  as character no-undo.
        define variable iLoc        as integer no-undo.
        define variable iLength     as integer no-undo.
        
        assign
            iLength = random(20,50)
            iLoc = random(iLength, TestClass:StringSize)
            .

        TestReturn = TestClass:WhatWord(iLoc, iLength).
        Assert:Equals(TestReturn, substring(TestClass:FullString,iLoc,iLength) ).

        return.
    end method.

    @Test.
    method public void TestWhat5Word(  ):  
        define variable TestReturn  as character no-undo.
        define variable iLoc        as integer no-undo.
        define variable iLength     as integer no-undo.
        define variable iLoop       as integer no-undo.
        define variable iMax        as integer initial 5 no-undo.
        
        do iLoop = 1 to iMax:
            assign
                iLength = random(20,50)
                iLoc = random(iLength, TestClass:StringSize)
                .
    
            TestReturn = TestClass:WhatWord(iLoc, iLength).
            Assert:Equals(TestReturn, substring(TestClass:FullString,iLoc,iLength) ).
        end.
        return.
    end method.

    @Test.
    method public void TestWhat25Word(  ):  
        define variable TestReturn  as character no-undo.
        define variable iLoc        as integer no-undo.
        define variable iLength     as integer no-undo.
        define variable iLoop       as integer no-undo.
        define variable iMax        as integer initial 25 no-undo.
        
        do iLoop = 1 to iMax:
            assign
                iLength = random(20,50)
                iLoc = random(iLength, TestClass:StringSize)
                .
    
            TestReturn = TestClass:WhatWord(iLoc, iLength).
            Assert:Equals(TestReturn, substring(TestClass:FullString,iLoc,iLength) ).
        end.
        return.
    end method.
    @Test.
    method public void TestWhat50Word(  ):  
        define variable TestReturn  as character no-undo.
        define variable iLoc        as integer no-undo.
        define variable iLength     as integer no-undo.
        define variable iLoop       as integer no-undo.
        define variable iMax        as integer initial 50 no-undo.
        
        do iLoop = 1 to iMax:
            assign
                iLength = random(20,50)
                iLoc = random(iLength, TestClass:StringSize)
                .
    
            TestReturn = TestClass:WhatWord(iLoc, iLength).
            Assert:Equals(TestReturn, substring(TestClass:FullString,iLoc,iLength) ).
        end.
        return.
    end method.
    @Test.
    method public void TestWhat500Word(  ):  
        define variable TestReturn  as character no-undo.
        define variable iLoc        as integer no-undo.
        define variable iLength     as integer no-undo.
        define variable iLoop       as integer no-undo.
        define variable iMax        as integer initial 500 no-undo.
        
        do iLoop = 1 to iMax:
            assign
                iLength = random(20,50)
                iLoc = random(iLength, TestClass:StringSize)
                .
    
            TestReturn = TestClass:WhatWord(iLoc, iLength).
            Assert:Equals(TestReturn, substring(TestClass:FullString,iLoc,iLength) ).
        end.
        return.
    end method.

end class.