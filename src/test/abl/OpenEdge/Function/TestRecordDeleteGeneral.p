/*------------------------------------------------------------------------
    File        : OpenEdge / Function / TestRecordDeleteGeneral.p
    Author(s)   : Cameron David Wright
    Notes       : Tests for Function/record/delete/general.p operations
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING OpenEdge.Core.Assert.

BLOCK-LEVEL ON ERROR UNDO, THROW.

{ OpenEdge/LoadSuite/Common/include/RecordForward.i "IN SUPER" }

DEFINE VARIABLE hProc AS HANDLE NO-UNDO.
DEFINE VARIABLE RandomEmpNum AS INTEGER NO-UNDO.
DEFINE VARIABLE RandomDeptCode AS CHARACTER NO-UNDO.
DEFINE VARIABLE RandomCustNum AS INTEGER NO-UNDO.

@Before.
PROCEDURE setUpBeforeProcedure:

    RUN "Function/record/delete/general.p" PERSISTENT SET hProc NO-ERROR.
    THIS-PROCEDURE:ADD-SUPER-PROCEDURE(hProc).

    /* Generate static values for testing */
    ASSIGN
        RandomEmpNum = 55002
        RandomDeptCode = "DEPT0002"
        RandomCustNum = 77002.

    /* Pre-create test data that will be deleted */

    CREATE Employee.
    ASSIGN
        Employee.EmpNum = RandomEmpNum
        Employee.FirstName = "DeleteTest"
        Employee.LastName = "Employee".


    CREATE Department.
    ASSIGN
        Department.DeptCode = RandomDeptCode
        Department.DeptName = "Delete Test Department".


    CREATE Customer.
    ASSIGN
        Customer.CustNum = RandomCustNum
        Customer.Name = "DeleteTestCustomer".

END PROCEDURE.

@After.
PROCEDURE tearDownAfterProcedure:

    DELETE OBJECT hProc NO-ERROR.
    ASSIGN hProc = ?.

    /* Verify cleanup - records should be deleted */
    FOR EACH Employee EXCLUSIVE-LOCK
        WHERE Employee.EmpNum = RandomEmpNum:
        DELETE Employee.
    END.

    FOR EACH Department EXCLUSIVE-LOCK
        WHERE Department.DeptCode = RandomDeptCode:
        DELETE Department.
    END.

    FOR EACH Customer EXCLUSIVE-LOCK
        WHERE Customer.CustNum = RandomCustNum:
        DELETE Customer.
    END.

END PROCEDURE.

@Test.
PROCEDURE testDeleteEmployee:
    DEFINE VARIABLE ReturnValue AS LOGICAL NO-UNDO.
    
    /* Verify record exists before delete */
    FIND FIRST Employee NO-LOCK
        WHERE Employee.EmpNum = RandomEmpNum
        NO-ERROR.
    Assert:IsTrue(AVAILABLE Employee).
    
    /* Delete the employee */
    ReturnValue = deleteEmployee(RandomEmpNum, "DeleteTest", "Employee").
    
    Assert:Equals(ReturnValue, TRUE).
    
    /* Verify record is gone */
    FIND FIRST Employee NO-LOCK
        WHERE Employee.EmpNum = RandomEmpNum
        NO-ERROR.
    Assert:IsFalse(AVAILABLE Employee).

END PROCEDURE.

@Test.
PROCEDURE testDeleteDepartment:
    DEFINE VARIABLE ReturnValue AS LOGICAL NO-UNDO.
    
    /* Verify record exists before delete */
    FIND FIRST Department NO-LOCK
        WHERE Department.DeptCode = RandomDeptCode
        NO-ERROR.
    Assert:IsTrue(AVAILABLE Department).
    
    /* Delete the department */
    ReturnValue = deleteDepartment(RandomDeptCode, "Delete Test Department").
    
    Assert:Equals(ReturnValue, TRUE).
    
    /* Verify record is gone */
    FIND FIRST Department NO-LOCK
        WHERE Department.DeptCode = RandomDeptCode
        NO-ERROR.
    Assert:IsFalse(AVAILABLE Department).

END PROCEDURE.

@Test.
PROCEDURE testDeleteCustomer:
    DEFINE VARIABLE ReturnValue AS LOGICAL NO-UNDO.
    
    /* Verify record exists before delete */
    FIND FIRST Customer NO-LOCK
        WHERE Customer.CustNum = RandomCustNum
        NO-ERROR.
    Assert:IsTrue(AVAILABLE Customer).
    
    /* Delete the customer */
    ReturnValue = deleteCustomer(RandomCustNum, "DeleteTestCustomer", "DeleteTestCustomer").
    
    Assert:Equals(ReturnValue, TRUE).
    
    /* Verify record is gone */
    FIND FIRST Customer NO-LOCK
        WHERE Customer.CustNum = RandomCustNum
        NO-ERROR.
    Assert:IsFalse(AVAILABLE Customer).

END PROCEDURE.

@Test.
PROCEDURE testDeleteBenefits:
    DEFINE VARIABLE ReturnValue AS LOGICAL NO-UNDO.
    DEFINE VARIABLE BenefitEmpNum AS INTEGER NO-UNDO.
    
    ASSIGN BenefitEmpNum = 88002.
    
    /* Create employee and benefits to delete */

    CREATE Employee.
    ASSIGN
        Employee.EmpNum = BenefitEmpNum
        Employee.FirstName = "BenefitTest"
        Employee.LastName = "Employee".
        

    CREATE Benefits.
    ASSIGN Benefits.EmpNum = BenefitEmpNum.
    
    /* Delete the benefits */
    ReturnValue = deleteBenefits(BenefitEmpNum).
    
    Assert:Equals(ReturnValue, TRUE).
    
    /* Verify benefits record is gone */
    FIND FIRST Benefits NO-LOCK
        WHERE Benefits.EmpNum = BenefitEmpNum
        NO-ERROR.
    Assert:IsFalse(AVAILABLE Benefits).
    
    /* Cleanup employee */
    FIND FIRST Employee EXCLUSIVE-LOCK
        WHERE Employee.EmpNum = BenefitEmpNum
        NO-ERROR.
    IF AVAILABLE Employee THEN
        DELETE Employee.

END PROCEDURE.
