 
 /*------------------------------------------------------------------------
    File        : TestStringShortGeneral
    Purpose     : 
    Description : 
    Author(s)   : Cameron David Wright
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING OpenEdge.Core.Assert.
USING OpenEdge.LoadSuite.Objects.string.short.general.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS OpenEdge.Class.TestStringShortGeneral:
    
    { OpenEdge/LoadSuite/Common/include/alphabet.i }
    
    DEFINE PRIVATE PROPERTY RandomNumber AS INTEGER NO-UNDO 
    GET.
    SET. 

    DEFINE PUBLIC PROPERTY TestClass AS OpenEdge.LoadSuite.Objects.string.short.general NO-UNDO 
    GET.
    SET. 

    @Before.
    METHOD PUBLIC VOID setUpBeforeClass(  ):
        
        TestClass = NEW OpenEdge.LoadSuite.Objects.string.short.general().
        RandomNumber = RANDOM(1,26).
        RETURN.

    END METHOD.
     
    @After.
    METHOD PUBLIC VOID tearDownAfterClass(  ):
        
        DELETE OBJECT TestClass.
        RETURN.

    END METHOD.

    @Test.
    METHOD PUBLIC VOID TestFill():
        
        Assert:NotZero(LENGTH(TestClass:FullString)).
      
        RETURN.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TestFindIn(  ):  

        DEFINE VARIABLE kLocal      AS CHARACTER NO-UNDO.
        DEFINE VARIABLE TestReturn  AS INTEGER NO-UNDO.
        kLocal = SUBSTRING(alphabet,RandomNumber).

        TestReturn = TestClass:FindIn(kLocal).
        Assert:equals(TestReturn,RandomNumber).

        RETURN.
 
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TestHelloJoin(  ):  

        DEFINE VARIABLE kLocal AS CHARACTER NO-UNDO.
        DEFINE VARIABLE TestReturn AS CHARACTER NO-UNDO.
        
        kLocal = "Test Harness".
        TestReturn = TestClass:HelloJoin(kLocal).
        
        Assert:Equals(TestReturn,"Hello " + kLocal).
        RETURN.
 
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TestWhatLetter(  ):  

        DEFINE VARIABLE kLocal AS CHARACTER NO-UNDO.
        DEFINE VARIABLE TestReturn AS CHARACTER NO-UNDO.

        TestReturn = TestClass:WhatLetter(RandomNumber).
        kLocal = SUBSTRING(alphabet,RandomNumber,1).
        Assert:Equals(TestReturn,kLocal).
        RETURN.
 
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TestWhatWord(  ):  
        DEFINE VARIABLE TestReturn  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iLoc        AS INTEGER NO-UNDO.
        DEFINE VARIABLE iLength     AS INTEGER NO-UNDO.
        
        ASSIGN
            iLength = RANDOM(1,8)
            iLoc = RANDOM(iLength, TestClass:StringSize)
            .

        TestReturn = TestClass:WhatWord(iLoc, iLength).
        Assert:Equals(TestReturn, SUBSTRING(TestClass:FullString,iLoc,iLength) ).

        RETURN.
 
    END METHOD.

END CLASS.