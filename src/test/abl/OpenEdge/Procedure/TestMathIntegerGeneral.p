 
 /*------------------------------------------------------------------------
    File        : OpenEdge / Procedure / TestMathFloatGeneral.p 
    Author(s)   : Cameron David Wright
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING OpenEdge.Core.Assert.

BLOCK-LEVEL ON ERROR UNDO, THROW.

DEFINE VARIABLE hProc AS HANDLE NO-UNDO.

@Before.
PROCEDURE setUpBeforeProcedure:

    RUN "Procedure\math\integer\general.p" PERSISTENT SET hProc NO-ERROR.
    THIS-PROCEDURE:ADD-SUPER-PROCEDURE(hProc).
    
END PROCEDURE. 

@After.
PROCEDURE tearDownAfterProcedure: 

    DELETE OBJECT hProc NO-ERROR.
    ASSIGN hProc = ?.

END PROCEDURE. 

@Test.  
PROCEDURE TestAddition: 
    
    DEFINE VARIABLE returned AS INTEGER NO-UNDO.

    RUN addition (15,9, OUTPUT returned).
    Assert:equals(24,returned).    
    
END PROCEDURE.

@Test.  
PROCEDURE TestDivision: 

    DEFINE VARIABLE returned AS INTEGER NO-UNDO.

    RUN division (25,5, OUTPUT returned).
    
    Assert:equals(5,returned).    

END PROCEDURE.

@Test.  
PROCEDURE TestMultiplication: 

    DEFINE VARIABLE returned AS INTEGER NO-UNDO.

    RUN multiplication (45,712, OUTPUT returned).
    Assert:equals(32040,returned).    

END PROCEDURE.

@Test.  
PROCEDURE TestSubtraction: 
    DEFINE VARIABLE returned AS INTEGER NO-UNDO.

    RUN Subtraction (912,18, OUTPUT returned).
    Assert:equals(894,returned).    

END PROCEDURE.
