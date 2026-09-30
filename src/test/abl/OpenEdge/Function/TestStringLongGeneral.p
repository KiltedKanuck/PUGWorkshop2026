/*------------------------------------------------------------------------
    File        : OpenEdge / Function / TestStringLongGeneral.p
    Author(s)   : Cameron David Wright
    Notes       :
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING OpenEdge.Core.Assert.

BLOCK-LEVEL ON ERROR UNDO, THROW.

{ OpenEdge/LoadSuite/Common/include/FunctionForwards.i "IN SUPER" }

DEFINE VARIABLE hProc AS HANDLE NO-UNDO.
DEFINE VARIABLE testSize AS INT64 NO-UNDO.
DEFINE VARIABLE testString AS LONGCHAR NO-UNDO.

@Before.
PROCEDURE setUpBeforeProcedure:

    RUN "Function/string/long/general.p" PERSISTENT SET hProc NO-ERROR.
    THIS-PROCEDURE:ADD-SUPER-PROCEDURE(hProc).

    ASSIGN
        testSize = GetSize()
        testString = GetData().

END PROCEDURE.

@After.
PROCEDURE tearDownAfterProcedure:

    DELETE OBJECT hProc NO-ERROR.
    ASSIGN hProc = ?.

END PROCEDURE.

@Test.
PROCEDURE TestGetData:

    Assert:NotZero(testSize).
    Assert:Equals(testSize, LENGTH(testString)).

END PROCEDURE.

@Test.
PROCEDURE TestWhatLetter:

    DEFINE VARIABLE testReturn AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iRandLetter AS INTEGER NO-UNDO.

    ASSIGN iRandLetter = 5.

    testReturn = WhatLetter(iRandLetter).

    Assert:Equals(testReturn, SUBSTRING(testString, iRandLetter, 1)).

END PROCEDURE.

@Test.
PROCEDURE TestWhatWord:

    DEFINE VARIABLE testReturn AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iLoc AS INTEGER NO-UNDO.
    DEFINE VARIABLE iLength AS INTEGER NO-UNDO.

    ASSIGN
        iLength = 10
        iLoc = 15.

    testReturn = WhatWord(iLoc, iLength).

    Assert:Equals(testReturn, SUBSTRING(testString, iLoc, iLength)).

END PROCEDURE.
