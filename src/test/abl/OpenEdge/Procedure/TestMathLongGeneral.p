 
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

    RUN "Procedure\math\long\general.p" PERSISTENT SET hProc NO-ERROR.
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

    RUN addition (111222333444,444555666777, OUTPUT returned).
    Assert:equals(555778000221,returned).    
    
END PROCEDURE.

@Test.  
PROCEDURE TestDivision: 

    DEFINE VARIABLE returned AS INT64 NO-UNDO.

    RUN division (999888777666,1234567, OUTPUT returned).
    
    Assert:equals(809911,returned).    

END PROCEDURE.

@Test.  
PROCEDURE TestMultiplication: 

    DEFINE VARIABLE returned AS INT64 NO-UNDO.

    RUN multiplication (123456789,987654321, OUTPUT returned).
    Assert:equals(121932631112635269,returned).    

END PROCEDURE.

@Test.  
PROCEDURE TestSubtraction: 
    DEFINE VARIABLE returned AS INT64 NO-UNDO.

    RUN Subtraction (999888777666,555444333222, OUTPUT returned).
    Assert:equals(444444444444,returned).    

END PROCEDURE.
