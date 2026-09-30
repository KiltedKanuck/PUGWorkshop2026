 
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

    RUN "Procedure\math\float\general.p" PERSISTENT SET hProc NO-ERROR.
    THIS-PROCEDURE:ADD-SUPER-PROCEDURE(hProc).
    
END PROCEDURE. 

@After.
PROCEDURE tearDownAfterProcedure: 

    DELETE OBJECT hProc NO-ERROR.
    ASSIGN hProc = ?.

END PROCEDURE. 

@Test.  
PROCEDURE TestAddition: 
    
    DEFINE VARIABLE returned AS DECIMAL NO-UNDO.

    RUN addition (5.1,3.3, OUTPUT returned).
    Assert:equals(8.4,returned).    
    
END PROCEDURE.

@Test.  
PROCEDURE TestDivision: 

    DEFINE VARIABLE returned AS DECIMAL NO-UNDO.

    RUN division (10.2,2.1, OUTPUT returned).
    
    Assert:equals(4.8571428571,returned).    

END PROCEDURE.

@Test.  
PROCEDURE TestMultiplication: 

    DEFINE VARIABLE returned AS DECIMAL NO-UNDO.

    RUN multiplication (5.1,3.3, OUTPUT returned).
    Assert:equals(16.83,returned).    

END PROCEDURE.

@Test.  
PROCEDURE TestSubtraction: 
    DEFINE VARIABLE returned AS DECIMAL NO-UNDO.

    RUN Subtraction (5.1,3.3, OUTPUT returned).
    Assert:equals(1.8,returned).    

END PROCEDURE.
