 
 /*------------------------------------------------------------------------
    File        : OpenEdge / Class / TestMathFloatGeneral
    Author(s)   : Cameron David Wright
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING OpenEdge.Core.Assert.
USING OpenEdge.LoadSuite.Objects.math.float.general.
USING OpenEdge.StressConfig.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS OpenEdge.Class.TestMathFloatGeneral INHERITS StressConfig:
      
    DEFINE PUBLIC PROPERTY TestClass AS OpenEdge.LoadSuite.Objects.math.float.general NO-UNDO 
    GET.
    SET. 

    @Before.
    METHOD PUBLIC VOID setUpBefore ():

        TestClass = NEW OpenEdge.LoadSuite.Objects.math.float.general().
                
    END METHOD.
    
    @After.
    METHOD PUBLIC VOID tearDownAfter ():
        
        DELETE OBJECT TestClass.
        
    END METHOD.    
    
    @Test. 
    METHOD PUBLIC VOID TestAddition(  ):
        
        DEFINE VARIABLE returned AS DECIMAL NO-UNDO.

        returned = TestClass:addition (5.1,3.3).
        Assert:equals(8.4,returned).  
        
        RETURN.

    END METHOD.
    
    
    @Test. 
    METHOD PUBLIC VOID TestSubtraction(  ):
        
        DEFINE VARIABLE returned AS DECIMAL NO-UNDO.

        returned = TestClass:Subtraction (5.1,3.3).
        Assert:equals(1.8,returned).   
        
        RETURN.

    END METHOD.
    
    
    @Test. 
    METHOD PUBLIC VOID TestMultiplication(  ):
        
        DEFINE VARIABLE returned AS DECIMAL NO-UNDO.

        returned = TestClass:multiplication (5.1,3.3).
        Assert:equals(16.83,returned).    
        
        
        RETURN.

    END METHOD.
    
    
    @Test. 
    METHOD PUBLIC VOID TestDivision(  ):
        
        DEFINE VARIABLE returned AS DECIMAL NO-UNDO.

        returned = TestClass:division(10.2,2.1).
    
        Assert:equals(4.8571428571,returned). 
        RETURN.

    END METHOD.
    
END CLASS.