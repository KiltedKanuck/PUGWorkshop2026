/*------------------------------------------------------------------------
    File        : OpenEdge / Function / TestTempTableGeneral.p
    Author(s)   : Cameron David Wright
    Notes       :
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING OpenEdge.Core.Assert.

BLOCK-LEVEL ON ERROR UNDO, THROW.

{ OpenEdge/LoadSuite/Common/include/FunctionForwards.i "IN SUPER" }

DEFINE VARIABLE hProc AS HANDLE NO-UNDO.
DEFINE VARIABLE RandomNumber AS INTEGER NO-UNDO.

@Before.
PROCEDURE setUpBeforeProcedure:

    RUN "Function/temptable/general.p" PERSISTENT SET hProc NO-ERROR.
    THIS-PROCEDURE:ADD-SUPER-PROCEDURE(hProc).

END PROCEDURE.

@After.
PROCEDURE tearDownAfterProcedure:

    DELETE OBJECT hProc NO-ERROR.
    ASSIGN hProc = ?.

END PROCEDURE.

@Test.
PROCEDURE testCreateSmallStatic:

    DEFINE VARIABLE ReturnValue AS LOGICAL NO-UNDO.

    ASSIGN RandomNumber = 500.
    ReturnValue = CreateStatic("SmallTable").
    Assert:Equals(ReturnValue, TRUE).

END PROCEDURE.

@Test.
PROCEDURE testAddRecordsSmallStatic:

    DEFINE VARIABLE ReturnValue AS INT64 NO-UNDO.

    ReturnValue = AddRecords(RandomNumber).
    Assert:Equals(ReturnValue, RandomNumber).

END PROCEDURE.

@Test.
PROCEDURE testDeleteSmallStatic:

    DEFINE VARIABLE ReturnValue AS LOGICAL NO-UNDO.

    ReturnValue = DeleteTable().
    Assert:Equals(ReturnValue, TRUE).

END PROCEDURE.

@Test.
PROCEDURE testCreateLargeStatic:

    DEFINE VARIABLE ReturnValue AS LOGICAL NO-UNDO.

    ASSIGN RandomNumber = 800.
    ReturnValue = CreateStatic("LargeTable").
    Assert:Equals(ReturnValue, TRUE).

END PROCEDURE.

@Test.
PROCEDURE testAddRecordsLargeStatic:

    DEFINE VARIABLE ReturnValue AS INT64 NO-UNDO.

    ReturnValue = AddRecords(RandomNumber).
    Assert:Equals(ReturnValue, RandomNumber).

END PROCEDURE.

@Test.
PROCEDURE testDeleteLargeStatic:

    DEFINE VARIABLE ReturnValue AS LOGICAL NO-UNDO.

    ReturnValue = DeleteTable().
    Assert:Equals(ReturnValue, TRUE).

END PROCEDURE.

@Test.
PROCEDURE testCreateSmallDynamic:

    DEFINE VARIABLE ReturnValue AS LOGICAL NO-UNDO.

    ASSIGN RandomNumber = 7.
    ReturnValue = CreateDynamic(RandomNumber).
    Assert:Equals(ReturnValue, TRUE).

END PROCEDURE.

@Test.
PROCEDURE testAddRecordsSmallDynamic:

    DEFINE VARIABLE ReturnValue AS INT64 NO-UNDO.

    ASSIGN RandomNumber = 5.
    ReturnValue = AddRecords(RandomNumber).
    Assert:Equals(ReturnValue, RandomNumber).

END PROCEDURE.

@Test.
PROCEDURE testDeleteSmallDynamic:

    DEFINE VARIABLE ReturnValue AS LOGICAL NO-UNDO.

    ReturnValue = DeleteTable().
    Assert:Equals(ReturnValue, TRUE).

END PROCEDURE.

@Test.
PROCEDURE testCreateLargeDynamic:

    DEFINE VARIABLE ReturnValue AS LOGICAL NO-UNDO.

    ASSIGN RandomNumber = 750.
    ReturnValue = CreateDynamic(RandomNumber).
    Assert:Equals(ReturnValue, TRUE).

END PROCEDURE.

@Test.
PROCEDURE testAddRecordsLargeDynamic:

    DEFINE VARIABLE ReturnValue AS INT64 NO-UNDO.

    ASSIGN RandomNumber = 600.
    ReturnValue = AddRecords(RandomNumber).
    Assert:Equals(ReturnValue, RandomNumber).

END PROCEDURE.

@Test.
PROCEDURE testDeleteLargeDynamic:

    DEFINE VARIABLE ReturnValue AS LOGICAL NO-UNDO.

    ReturnValue = DeleteTable().
    Assert:Equals(ReturnValue, TRUE).

END PROCEDURE.
