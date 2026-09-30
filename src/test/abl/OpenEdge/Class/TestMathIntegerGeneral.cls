 
 /*------------------------------------------------------------------------
    File        : OpenEdge / Class / TestMathIntegerGeneral
    Author(s)   : Cameron David Wright
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING OpenEdge.Core.Assert.
USING OpenEdge.LoadSuite.Objects.math.integer.general.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS OpenEdge.Class.TestMathIntegerGeneral:
      
    DEFINE PUBLIC PROPERTY TestClass AS OpenEdge.LoadSuite.Objects.math.integer.general NO-UNDO 
    GET.
    SET. 

    @Before.
    METHOD PUBLIC VOID setUpBefore ():

        TestClass = NEW OpenEdge.LoadSuite.Objects.math.integer.general().
                
    END METHOD.
    
    @After.
    METHOD PUBLIC VOID tearDownAfter ():
        
        DELETE OBJECT TestClass.
        
    END METHOD.    
    
    @Test. 
    METHOD PUBLIC VOID TestAddition(  ):
        
        DEFINE VARIABLE returned AS INTEGER NO-UNDO.

        returned = TestClass:addition (5,3).
        Assert:equals(8,returned).  
        
        RETURN.

    END METHOD.
    
    
    @Test. 
    METHOD PUBLIC VOID TestSubtraction(  ):
        
        DEFINE VARIABLE returned AS INTEGER NO-UNDO.

        returned = TestClass:Subtraction (5,3).
        Assert:equals(2,returned).   
        
        RETURN.

    END METHOD.
    
    
    @Test. 
    METHOD PUBLIC VOID TestMultiplication(  ):
        
        DEFINE VARIABLE returned AS INTEGER NO-UNDO.

        returned = TestClass:multiplication (5,3).
        Assert:equals(15,returned).    
        
        RETURN.

    END METHOD.
    
    
    @Test. 
    METHOD PUBLIC VOID TestDivision(  ):
        
        DEFINE VARIABLE returned AS INTEGER NO-UNDO.

        returned = TestClass:division(10,2).
    
        Assert:equals(5,returned). 
        RETURN.

    END METHOD.
    
END CLASS.