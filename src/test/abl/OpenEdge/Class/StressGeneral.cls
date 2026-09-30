 
 /*------------------------------------------------------------------------
    File        : StressGeneral
    Purpose     : Stress some general class
    Author(s)   : Cameron David Wright
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING OpenEdge.Core.Assert.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS OpenEdge.Class.StressGeneral:

    { OpenEdge/LoadSuite/Common/include/alphabet.i }
    
    DEFINE PRIVATE PROPERTY RandomNumber AS INTEGER NO-UNDO 
    GET.
    SET. 
    DEFINE PUBLIC PROPERTY TestClassLong AS OpenEdge.LoadSuite.Objects.string.long.general NO-UNDO 
    GET.
    SET. 
    DEFINE PUBLIC PROPERTY TestClassShort AS OpenEdge.LoadSuite.Objects.string.short.general NO-UNDO 
    GET.
    SET. 
    DEFINE PUBLIC PROPERTY TestClassTT AS OpenEdge.LoadSuite.Objects.temptable.general NO-UNDO 
    GET.
    SET. 

    DEFINE VARIABLE iStress     AS INTEGER INIT 100 NO-UNDO.
    DEFINE VARIABLE iLoop       AS INTEGER NO-UNDO.

    @Before.
    METHOD PUBLIC VOID setUpBeforeClass(  ):
        
        TestClassLong = NEW OpenEdge.LoadSuite.Objects.string.long.general().
        TestClassShort = NEW OpenEdge.LoadSuite.Objects.string.short.general().
        TestClassTT = NEW OpenEdge.LoadSuite.Objects.temptable.general().
        RandomNumber = 5.
        RETURN.

    END METHOD.
     
    @After.
    METHOD PUBLIC VOID tearDownAfterClass(  ):
        
        DELETE OBJECT TestClassLong.
        DELETE OBJECT TestClassShort.
        DELETE OBJECT TestClassTT.
        RETURN.

    END METHOD.
      
    @Test.
    METHOD PUBLIC VOID StressWhatLetterLong(  ):  
        DEFINE VARIABLE kLocal      AS CHARACTER NO-UNDO.
        DEFINE VARIABLE TestReturn  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iRandLetter AS INTEGER NO-UNDO.
        
        DO iLoop = 1 TO iStress:
            ASSIGN
                iRandLetter = ((iLoop - 1) MOD (TestClassLong:StringSize - 1)) + 1
                kLocal = SUBSTRING(TestClassLong:FullString,iRandLetter,1)
                .
            
            TestReturn = TestClassLong:WhatLetter(iRandLetter).
            Assert:Equals(TestReturn,kLocal).
        END.
        
        RETURN.
 
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StressWhatWordLong(  ):  
        DEFINE VARIABLE TestReturn  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iLoc        AS INTEGER NO-UNDO.
        DEFINE VARIABLE iLength     AS INTEGER NO-UNDO.
    
        DO iLoop = 1 TO iStress:        
            ASSIGN
                iLength = 20 + ((iLoop - 1) MOD 10)
                iLoc = 30 + ((iLoop - 1) MOD 20)
                .
    
            TestReturn = TestClassLong:WhatWord(iLoc, iLength).
            Assert:Equals(TestReturn, SUBSTRING(TestClassLong:FullString,iLoc,iLength) ).
        END.
        
        RETURN.
 
    END METHOD.
           
    @Test.
    METHOD PUBLIC VOID StressWhatLetterShort(  ):  

        DEFINE VARIABLE kLocal AS CHARACTER NO-UNDO.
        DEFINE VARIABLE TestReturn AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iRandLetter AS INTEGER NO-UNDO.
        
        DO iLoop = 1 TO iStress:
            ASSIGN
                iRandLetter = ((iLoop - 1) MOD 25) + 1
                kLocal = SUBSTRING(alphabet,iRandLetter,1)
                .
            
            TestReturn = TestClassShort:WhatLetter(iRandLetter).
            Assert:Equals(TestReturn,kLocal).
        END.    
        RETURN.

    END METHOD.

    @Test.
    METHOD PUBLIC VOID StressWhatWordShort(  ):  

        DEFINE VARIABLE TestReturn  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iLoc        AS INTEGER NO-UNDO.
        DEFINE VARIABLE iLength     AS INTEGER NO-UNDO.
        
        DO iLoop = 1 TO iStress:
            ASSIGN
                iLength = 1 + ((iLoop - 1) MOD 4)
                iLoc = 5 + ((iLoop - 1) MOD 10)
                .
    
            TestReturn = TestClassShort:WhatWord(iLoc, iLength).
            Assert:Equals(TestReturn, SUBSTRING(TestClassShort:FullString,iLoc,iLength) ).
        END.  
        RETURN.
 
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StressFindInShort(  ):  

        DEFINE VARIABLE kLocal          AS CHARACTER NO-UNDO.
        DEFINE VARIABLE TestReturn      AS INTEGER NO-UNDO.
        DEFINE VARIABLE iRandLetter     AS INTEGER NO-UNDO.
        
        DO iLoop = 1 TO iStress:
            ASSIGN
                iRandLetter = ((iLoop - 1) MOD 25) + 1
                kLocal = SUBSTRING(alphabet,iRandLetter).
    
            TestReturn = TestClassShort:FindIn(kLocal).
            Assert:equals(TestReturn,iRandLetter).
        END.
        RETURN.
 
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StressSmallStatic():
        DEFINE VARIABLE ReturnValue AS LOGICAL NO-UNDO.

        DO iLoop = 1 TO iStress:        
            Assert:equals(TestClassTT:CreateStatic("SmallTable"),TRUE).
            RandomNumber = 500 + ((iLoop - 1) MOD 100).
            Assert:equals(TestClassTT:AddRecords(RandomNumber),RandomNumber).
            Assert:equals(TestClassTT:DeleteTable(),TRUE).
        END.
        RETURN.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StressLargeStatic():
        DEFINE VARIABLE ReturnValue AS LOGICAL NO-UNDO.

        DO iLoop = 1 TO iStress:        
            Assert:equals(TestClassTT:CreateStatic("LargeTable"),TRUE).
            RandomNumber = 1000 + ((iLoop - 1) MOD 1000).
            Assert:equals(TestClassTT:AddRecords(RandomNumber),RandomNumber).
            Assert:equals(TestClassTT:DeleteTable(),TRUE).
        END.
        RETURN.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StressSmallDynamic():
        DEFINE VARIABLE ReturnValue AS LOGICAL NO-UNDO.

        DO iLoop = 1 TO iStress:        
            RandomNumber = 1 + ((iLoop - 1) MOD 5).
            Assert:equals(TestClassTT:CreateDynamic(RandomNumber),TRUE).
            RandomNumber = 100 + ((iLoop - 1) MOD 50).
            Assert:equals(TestClassTT:AddRecords(RandomNumber),RandomNumber).
            Assert:equals(TestClassTT:DeleteTable(),TRUE).
        END.
        RETURN.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StressLargeDynamic():
        DEFINE VARIABLE ReturnValue AS LOGICAL NO-UNDO.

        DO iLoop = 1 TO iStress:        
            RandomNumber = 100 + ((iLoop - 1) MOD 50).
            Assert:equals(TestClassTT:CreateDynamic(RandomNumber),TRUE).
            RandomNumber = 1000 + ((iLoop - 1) MOD 500).
            Assert:equals(TestClassTT:AddRecords(RandomNumber),RandomNumber).
            Assert:equals(TestClassTT:DeleteTable(),TRUE).
        END.
        RETURN.
    END METHOD.    
                   
END CLASS.