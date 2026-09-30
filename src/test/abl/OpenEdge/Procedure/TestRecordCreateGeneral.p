/*------------------------------------------------------------------------
    File        : OpenEdge / Procedure / TestRecordCreateGeneral.p
    Author(s)   : Cameron David Wright
    Notes       : Tests for Procedure/record/create/general.p operations
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING OpenEdge.Core.Assert.

BLOCK-LEVEL ON ERROR UNDO, THROW.

DEFINE VARIABLE hProc AS HANDLE NO-UNDO.
DEFINE VARIABLE RandomEmpNum AS INTEGER NO-UNDO.
DEFINE VARIABLE RandomDeptCode AS CHARACTER NO-UNDO.
DEFINE VARIABLE RandomCustNum AS INTEGER NO-UNDO.

@Before.
PROCEDURE setUpBeforeProcedure:

    RUN "Procedure/record/create/general.p" PERSISTENT SET hProc NO-ERROR.
    THIS-PROCEDURE:ADD-SUPER-PROCEDURE(hProc).

    /* Generate static values for testing */
    ASSIGN
        RandomEmpNum = 55011
        RandomDeptCode = "DEPT0011"
        RandomCustNum = 77011.

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
    RUN createEmployee(RandomEmpNum, "TestFirst", "TestLast").
    
    FIND FIRST Employee EXCLUSIVE-LOCK
        WHERE Employee.EmpNum = RandomEmpNum
        NO-ERROR.
    Assert:IsTrue(AVAILABLE Employee).
    Assert:Equals(Employee.FirstName, "TestFirst").
    Assert:Equals(Employee.LastName, "TestLast").

END PROCEDURE.

@Test.
PROCEDURE testCreateDepartment:
    RUN createDepartment(RandomDeptCode, "Test Department").
    
    FIND FIRST Department EXCLUSIVE-LOCK
        WHERE Department.DeptCode = RandomDeptCode
        NO-ERROR.
    Assert:IsTrue(AVAILABLE Department).
    Assert:Equals(Department.DeptName, "Test Department").

END PROCEDURE.

@Test.
PROCEDURE testCreateCustomer:
    RUN createCustomer(RandomCustNum, "Test Customer", "CustomerName").
    
    FIND FIRST Customer EXCLUSIVE-LOCK
        WHERE Customer.CustNum = RandomCustNum
        NO-ERROR.
    Assert:IsTrue(AVAILABLE Customer).
    Assert:Equals(Customer.Name, "CustomerName").

END PROCEDURE.

@Test.
PROCEDURE testCreateBenefits:
    DEFINE VARIABLE EmptyEmpNum AS INTEGER NO-UNDO.
    
    /* First create an employee to attach benefits to */
    ASSIGN EmptyEmpNum = 99011.
    RUN createEmployee(EmptyEmpNum, "BenefitsTest", "Employee").
    
    /* Now create benefits for that employee */
    RUN createBenefits(EmptyEmpNum).
    
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
