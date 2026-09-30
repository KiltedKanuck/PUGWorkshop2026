/*------------------------------------------------------------------------
    File        : OpenEdge / Procedure / TestRecordUpdateGeneral.p
    Author(s)   : Cameron David Wright
    Notes       : Tests for Procedure/record/update/general.p operations
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

    RUN "Procedure/record/update/general.p" PERSISTENT SET hProc NO-ERROR.
    THIS-PROCEDURE:ADD-SUPER-PROCEDURE(hProc).

    /* Generate static values for testing */
    ASSIGN
        RandomEmpNum = 55014
        RandomDeptCode = "DEPT0014"
        RandomCustNum = 77014.

    /* Pre-create test data that will be updated */

    CREATE Employee.
    ASSIGN
        Employee.EmpNum = RandomEmpNum
        Employee.FirstName = "OldFirst"
        Employee.LastName = "OldLast".


    CREATE Department.
    ASSIGN
        Department.DeptCode = RandomDeptCode
        Department.DeptName = "Old Department Name".


    CREATE Customer.
    ASSIGN
        Customer.CustNum = RandomCustNum
        Customer.Name = "OldCustomerName".

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
PROCEDURE testUpdateEmployee:
    /* Verify initial state */
    FIND FIRST Employee NO-LOCK
        WHERE Employee.EmpNum = RandomEmpNum
        NO-ERROR.
    Assert:IsTrue(AVAILABLE Employee).
    Assert:Equals(Employee.FirstName, "OldFirst").
    
    /* Update the employee */
    RUN updateEmployee(RandomEmpNum, "OldFirst", "OldLast").
    
    /* Verify update took effect */
    FIND FIRST Employee NO-LOCK
        WHERE Employee.EmpNum = RandomEmpNum
        NO-ERROR.
    Assert:IsTrue(AVAILABLE Employee).
    Assert:Equals(Employee.EmpNum, RandomEmpNum).

END PROCEDURE.

@Test.
PROCEDURE testUpdateDepartment:
    /* Verify initial state */
    FIND FIRST Department NO-LOCK
        WHERE Department.DeptCode = RandomDeptCode
        NO-ERROR.
    Assert:IsTrue(AVAILABLE Department).
    Assert:Equals(Department.DeptName, "Old Department Name").
    
    /* Update the department */
    RUN updateDepartment(RandomDeptCode, "Updated Department Name").
    
    /* Verify update took effect */
    FIND FIRST Department NO-LOCK
        WHERE Department.DeptCode = RandomDeptCode
        NO-ERROR.
    Assert:IsTrue(AVAILABLE Department).
    Assert:Equals(Department.DeptName, "Updated Department Name").

END PROCEDURE.

@Test.
PROCEDURE testUpdateCustomer:
    /* Verify initial state */
    FIND FIRST Customer NO-LOCK
        WHERE Customer.CustNum = RandomCustNum
        NO-ERROR.
    Assert:IsTrue(AVAILABLE Customer).
    Assert:Equals(Customer.Name, "OldCustomerName").
    
    /* Update the customer */
    RUN updateCustomer(RandomCustNum, "OldCustomerName", "UpdatedCustomerName").
    
    /* Verify update took effect */
    FIND FIRST Customer NO-LOCK
        WHERE Customer.CustNum = RandomCustNum
        NO-ERROR.
    Assert:IsTrue(AVAILABLE Customer).
    Assert:Equals(Customer.Name, "UpdatedCustomerName").

END PROCEDURE.

@Test.
PROCEDURE testUpdateBenefits:
    DEFINE VARIABLE BenefitEmpNum AS INTEGER NO-UNDO.
    
    ASSIGN BenefitEmpNum = 66014.
    
    /* Create employee and benefits to update */

    CREATE Employee.
    ASSIGN
        Employee.EmpNum = BenefitEmpNum
        Employee.FirstName = "BenefitTest"
        Employee.LastName = "Employee".
        

    CREATE Benefits.
    ASSIGN Benefits.EmpNum = BenefitEmpNum.
    
    /* Update the benefits */
    RUN updateBenefits(BenefitEmpNum).
    
    /* Cleanup */
    FOR EACH Benefits EXCLUSIVE-LOCK
        WHERE Benefits.EmpNum = BenefitEmpNum:
        DELETE Benefits.
    END.
    
    FOR EACH Employee EXCLUSIVE-LOCK
        WHERE Employee.EmpNum = BenefitEmpNum:
        DELETE Employee.
    END.

END PROCEDURE.
