 
 /*------------------------------------------------------------------------
    File        : OpenEdge / Class / TestMathLongGeneral
    Author(s)   : Cameron David Wright
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING OpenEdge.Core.Assert.
USING OpenEdge.LoadSuite.Objects.math.long.general.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS OpenEdge.Class.TestMathLongGeneral:
      
    DEFINE PUBLIC PROPERTY TestClass AS OpenEdge.LoadSuite.Objects.math.long.general NO-UNDO 
    GET.
    SET. 

    @Before.
    METHOD PUBLIC VOID setUpBefore ():

        TestClass = NEW OpenEdge.LoadSuite.Objects.math.long.general().
                
    END METHOD.
    
    @After.
    METHOD PUBLIC VOID tearDownAfter ():
        
        DELETE OBJECT TestClass.
        
    END METHOD.    
    
    @Test. 
    METHOD PUBLIC VOID TestAddition(  ):
        
        DEFINE VARIABLE returned AS INT64 NO-UNDO.

        returned = TestClass:addition (111222333444,444555666777).
        Assert:equals(555778000221,returned).  
        
        RETURN.

    END METHOD.
    
    
    @Test. 
    METHOD PUBLIC VOID TestSubtraction(  ):
        
        DEFINE VARIABLE returned AS INT64 NO-UNDO.

        returned = TestClass:subtraction(999888777666,555444333222).
        Assert:equals(444444444444,returned).    
        
        RETURN.

    END METHOD.
    
    
    @Test. 
    METHOD PUBLIC VOID TestMultiplication(  ):
        
        DEFINE VARIABLE returned AS INT64 NO-UNDO.

        returned = TestClass:multiplication(123456789,987654321).
        Assert:equals(121932631112635269,returned).  
        
        RETURN.

    END METHOD.
    
    
    @Test. 
    METHOD PUBLIC VOID TestDivision(  ):
        
        DEFINE VARIABLE returned AS INT64 NO-UNDO.

        returned = TestClass:division(999888777666,1234567).
        Assert:equals(809911,returned).
         
        RETURN.

    END METHOD.
    
END CLASS.