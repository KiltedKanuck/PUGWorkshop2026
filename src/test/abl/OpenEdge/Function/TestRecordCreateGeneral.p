/*------------------------------------------------------------------------
    File        : OpenEdge / Function / TestRecordCreateGeneral.p
    Author(s)   : Cameron David Wright
    Notes       : Tests for Function/record/create/general.p operations
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

    RUN "Function/record/create/general.p" PERSISTENT SET hProc NO-ERROR.
    THIS-PROCEDURE:ADD-SUPER-PROCEDURE(hProc).

    /* Generate static values for testing */
    ASSIGN
        RandomEmpNum = 55001
        RandomDeptCode = "DEPT0001"
        RandomCustNum = 77001.

END PROCEDURE.

@After.
PROCEDURE tearDownAfterProcedure:

    DELETE OBJECT hProc NO-ERROR.
    ASSIGN hProc = ?.

    /* Clean up test data */
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
PROCEDURE testCreateEmployee:
    DEFINE VARIABLE ReturnValue AS LOGICAL NO-UNDO.
    
    ReturnValue = createEmployee(RandomEmpNum, "TestFirst", "TestLast").
    
    Assert:Equals(ReturnValue, TRUE).
    
    FIND FIRST Employee EXCLUSIVE-LOCK
        WHERE Employee.EmpNum = RandomEmpNum
        NO-ERROR.
    Assert:IsTrue(AVAILABLE Employee).
    Assert:Equals(Employee.FirstName, "TestFirst").
    Assert:Equals(Employee.LastName, "TestLast").

END PROCEDURE.

@Test.
PROCEDURE testCreateDepartment:
    DEFINE VARIABLE ReturnValue AS LOGICAL NO-UNDO.
    
    ReturnValue = createDepartment(RandomDeptCode, "Test Department").
    
    Assert:Equals(ReturnValue, TRUE).
    
    FIND FIRST Department EXCLUSIVE-LOCK
        WHERE Department.DeptCode = RandomDeptCode
        NO-ERROR.
    Assert:IsTrue(AVAILABLE Department).
    Assert:Equals(Department.DeptName, "Test Department").

END PROCEDURE.

@Test.
PROCEDURE testCreateCustomer:
    DEFINE VARIABLE ReturnValue AS LOGICAL NO-UNDO.
    
    ReturnValue = createCustomer(RandomCustNum, "Test Customer", "CustomerName").
    
    Assert:Equals(ReturnValue, TRUE).
    
    FIND FIRST Customer EXCLUSIVE-LOCK
        WHERE Customer.CustNum = RandomCustNum
        NO-ERROR.
    Assert:IsTrue(AVAILABLE Customer).
    Assert:Equals(Customer.Name, "CustomerName").

END PROCEDURE.

@Test.
PROCEDURE testCreateBenefits:
    DEFINE VARIABLE ReturnValue AS LOGICAL NO-UNDO.
    DEFINE VARIABLE EmptyEmpNum AS INTEGER NO-UNDO.
    
    /* First create an employee to attach benefits to */
    ASSIGN EmptyEmpNum = 99001.
    ReturnValue = createEmployee(EmptyEmpNum, "BenefitsTest", "Employee").
    
    /* Now create benefits for that employee */
    ReturnValue = createBenefits(EmptyEmpNum).
    
    Assert:Equals(ReturnValue, TRUE).
    
    FIND FIRST Benefits EXCLUSIVE-LOCK
        WHERE Benefits.EmpNum = EmptyEmpNum
        NO-ERROR.
    Assert:IsTrue(AVAILABLE Benefits).
    
    /* Cleanup the employee we created */
    FIND FIRST Employee EXCLUSIVE-LOCK
        WHERE Employee.EmpNum = EmptyEmpNum
        NO-ERROR.
    IF AVAILABLE Employee THEN
        DELETE Employee.

END PROCEDURE.
