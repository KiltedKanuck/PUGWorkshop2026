 
 /*------------------------------------------------------------------------
    File        : OpenEdge / Function / TestMathFloatGeneral.p 
    Author(s)   : Cameron David Wright
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING OpenEdge.Core.Assert.

BLOCK-LEVEL ON ERROR UNDO, THROW.

{ OpenEdge/LoadSuite/Common/include/FunctionForwards.i "IN SUPER"}

DEFINE VARIABLE hProc AS HANDLE NO-UNDO.

@Before.
PROCEDURE setUpBeforeProcedure:

    RUN "Function\math\long\general.p" PERSISTENT SET hProc NO-ERROR.
    THIS-PROCEDURE:ADD-SUPER-PROCEDURE(hProc).
    
END PROCEDURE. 

@After.
PROCEDURE tearDownAfterProcedure: 

    DELETE OBJECT hProc NO-ERROR.
    ASSIGN hProc = ?.

END PROCEDURE. 

@Test.  
PROCEDURE TestAddition: 
    
    DEFINE VARIABLE returned AS INT64 NO-UNDO.

    returned = addition (111222333444,444555666777).
    Assert:equals(555778000221,returned).    
    
END PROCEDURE.

@Test.  
PROCEDURE TestDivision: 

    DEFINE VARIABLE returned AS INT64 NO-UNDO.

    returned = division (999888777666,1234567).
    
    Assert:equals(809911,returned).    

END PROCEDURE.

@Test.  
PROCEDURE TestMultiplication: 

    DEFINE VARIABLE returned AS INT64 NO-UNDO.

    returned = multiplication (123456789,987654321).
    Assert:equals(121932631112635269,returned).    

END PROCEDURE.

@Test.  
PROCEDURE TestSubtraction: 
    DEFINE VARIABLE returned AS INT64 NO-UNDO.

    returned = Subtraction (999888777666,555444333222).
    Assert:equals(444444444444,returned).    

END PROCEDURE.
