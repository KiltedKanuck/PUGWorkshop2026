 
 /*------------------------------------------------------------------------
    File        : TestTempTableGeneral
    Purpose     : 
    Description : 
    Author(s)   : Cameron David Wright
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING OpenEdge.Core.Assert.
USING OpenEdge.LoadSuite.Objects.temptable.general.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS OpenEdge.Class.TestTempTableGeneral:

    DEFINE PRIVATE PROPERTY RandomNumber AS INTEGER NO-UNDO 
    GET.
    SET. 

    DEFINE PUBLIC PROPERTY TestClass AS OpenEdge.LoadSuite.Objects.temptable.general NO-UNDO 
    GET.
    SET. 

    @Before.
    METHOD PUBLIC VOID setUpBeforeClass(  ):
        
        TestClass = NEW OpenEdge.LoadSuite.Objects.temptable.general().
        RETURN.

    END METHOD.
    
    @After.
    METHOD PUBLIC VOID tearDownAfterClass(  ):
        
        DELETE OBJECT TestClass.
        RETURN.

    END METHOD.
     
    @Test. 
    METHOD PUBLIC VOID testCreateSmallStatic(  ):
        DEFINE VARIABLE ReturnValue AS LOGICAL NO-UNDO.
        
        RandomNumber = RANDOM(100,1000).
        ReturnValue = TestClass:CreateStatic("SmallTable").
        Assert:equals(ReturnValue,TRUE).
        RETURN.

    END METHOD.

    @Test. 
    METHOD PUBLIC VOID testAddRecordsSmallStatic(  ):
        DEFINE VARIABLE ReturnValue AS INT64 NO-UNDO.
        
        ReturnValue = TestClass:AddRecords(RandomNumber).
        
        Assert:equals(ReturnValue,RandomNumber).
        RETURN.

    END METHOD.
    @Test. 
    METHOD PUBLIC VOID testDeleteSmallStatic(  ):
        DEFINE VARIABLE ReturnValue AS LOGICAL NO-UNDO.

        ReturnValue = TestClass:DeleteTable().        
        Assert:equals(ReturnValue,TRUE).
        
        RETURN.

    END METHOD.
    
    @Test. 
    METHOD PUBLIC VOID testCreateLargeStatic(  ):
        DEFINE VARIABLE ReturnValue AS LOGICAL NO-UNDO.
        
        RandomNumber = RANDOM(100,1000).
        ReturnValue = TestClass:CreateStatic("LargeTable").
        Assert:equals(ReturnValue,TRUE).
        RETURN.

    END METHOD.

    @Test. 
    METHOD PUBLIC VOID testAddRecordsLargeStatic(  ):
        DEFINE VARIABLE ReturnValue AS INT64 NO-UNDO.
        
        ReturnValue = TestClass:AddRecords(RandomNumber).
        
        Assert:equals(ReturnValue,RandomNumber).
        RETURN.

    END METHOD.
    
    @Test. 
    METHOD PUBLIC VOID testDeleteLargeStatic(  ):
        DEFINE VARIABLE ReturnValue AS LOGICAL NO-UNDO.

        ReturnValue = TestClass:DeleteTable().        
        Assert:equals(ReturnValue,TRUE).
        
        RETURN.

    END METHOD.

    @Test. 
    METHOD PUBLIC VOID testCreateSmallDynamic(  ):
        DEFINE VARIABLE ReturnValue AS LOGICAL NO-UNDO.
        /* random set the number of fields to create */
        RandomNumber = RANDOM(1,10).
        ReturnValue = TestClass:CreateDynamic(RandomNumber).
        Assert:equals(ReturnValue,TRUE).
        RETURN.

    END METHOD.

    @Test. 
    METHOD PUBLIC VOID testAddRecordsSmallDynamic(  ):
        DEFINE VARIABLE ReturnValue AS INT64 NO-UNDO.
        /* random set the number fo records to create */
        RandomNumber = RANDOM(100,1000).
        ReturnValue = TestClass:AddRecords(RandomNumber).
        
        Assert:equals(ReturnValue,RandomNumber).
        RETURN.

    END METHOD.
    @Test. 
    METHOD PUBLIC VOID testDeleteSmallDynamic(  ):
        DEFINE VARIABLE ReturnValue AS LOGICAL NO-UNDO.

        ReturnValue = TestClass:DeleteTable().        
        Assert:equals(ReturnValue,TRUE).
        
        RETURN.

    END METHOD.

    @Test.
    METHOD PUBLIC VOID testCreateLargeDynamic(  ):
        DEFINE VARIABLE ReturnValue AS LOGICAL NO-UNDO.
        
        RandomNumber = RANDOM(100,1000).
        ReturnValue = TestClass:CreateDynamic(RandomNumber).
        Assert:equals(ReturnValue,TRUE).
        RETURN.

    END METHOD.

    @Test. 
    METHOD PUBLIC VOID testAddRecordsLargeDynamic(  ):
        DEFINE VARIABLE ReturnValue AS INT64 NO-UNDO.
        
        RandomNumber = RANDOM(1000,10000).
        ReturnValue = TestClass:AddRecords(RandomNumber).
        
        Assert:equals(ReturnValue,RandomNumber).
        RETURN.

    END METHOD.
    
    @Test. 
    METHOD PUBLIC VOID testDeleteLargeDynamic(  ):
        DEFINE VARIABLE ReturnValue AS LOGICAL NO-UNDO.

        ReturnValue = TestClass:DeleteTable().        
        Assert:equals(ReturnValue,TRUE).
        
        RETURN.

    END METHOD.
    

END CLASS.