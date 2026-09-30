/*------------------------------------------------------------------------
    File        : OpenEdge / Function / TestStringShortGeneral.p
    Author(s)   : Cameron David Wright
    Notes       :
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING OpenEdge.Core.Assert.

BLOCK-LEVEL ON ERROR UNDO, THROW.

{ OpenEdge/LoadSuite/Common/include/alphabet.i }
{ OpenEdge/LoadSuite/Common/include/FunctionForwards.i "IN SUPER" }

DEFINE VARIABLE hProc AS HANDLE NO-UNDO.
DEFINE VARIABLE testString AS CHARACTER NO-UNDO.
DEFINE VARIABLE testSize AS INTEGER NO-UNDO.
DEFINE VARIABLE randomNumber AS INTEGER NO-UNDO.

@Before.
PROCEDURE setUpBeforeProcedure:

    RUN "Function/string/short/general.p" PERSISTENT SET hProc NO-ERROR.
    THIS-PROCEDURE:ADD-SUPER-PROCEDURE(hProc).

    ASSIGN
        testSize = INTEGER(GetSize())
        testString = GetData()
        randomNumber = 5.

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
PROCEDURE TestFindIn:

    DEFINE VARIABLE kLocal AS CHARACTER NO-UNDO.
    DEFINE VARIABLE testReturn AS INTEGER NO-UNDO.

    ASSIGN kLocal = SUBSTRING(alphabet, randomNumber, 1).

    testReturn = FindIn(kLocal).

    Assert:Equals(testReturn, randomNumber).

END PROCEDURE.

@Test.
PROCEDURE TestHelloJoin:

    DEFINE VARIABLE kLocal AS CHARACTER NO-UNDO.
    DEFINE VARIABLE testReturn AS CHARACTER NO-UNDO.

    ASSIGN kLocal = "Test Harness".

    testReturn = HelloJoin(kLocal).

    Assert:Equals(testReturn, "Hello " + kLocal).

END PROCEDURE.

@Test.
PROCEDURE TestWhatLetter:

    DEFINE VARIABLE testReturn AS CHARACTER NO-UNDO.

    testReturn = WhatLetter(randomNumber).

    Assert:Equals(testReturn, SUBSTRING(alphabet, randomNumber, 1)).

END PROCEDURE.

@Test.
PROCEDURE TestWhatWord:

    DEFINE VARIABLE testReturn AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iLoc AS INTEGER NO-UNDO.
    DEFINE VARIABLE iLength AS INTEGER NO-UNDO.

    ASSIGN
        iLength = 8
        iLoc = 10.

    testReturn = WhatWord(iLoc, iLength).

    Assert:Equals(testReturn, SUBSTRING(testString, iLoc, iLength)).

END PROCEDURE.
