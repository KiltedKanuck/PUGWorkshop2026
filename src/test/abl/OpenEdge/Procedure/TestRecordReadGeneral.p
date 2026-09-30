/*------------------------------------------------------------------------
    File        : OpenEdge / Procedure / TestRecordReadGeneral.p
    Author(s)   : Cameron David Wright
    Notes       : Tests for Procedure/record/read/general.p operations
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

    RUN "Procedure/record/read/general.p" PERSISTENT SET hProc NO-ERROR.
    THIS-PROCEDURE:ADD-SUPER-PROCEDURE(hProc).

    /* Generate static values for testing */
    ASSIGN
        RandomEmpNum = 55013
        RandomDeptCode = "DEPT0013"
        RandomCustNum = 77013.

    /* Pre-create test data that will be read */

    CREATE Employee.
    ASSIGN
        Employee.EmpNum = RandomEmpNum
        Employee.FirstName = "ReadTest"
        Employee.LastName = "Employee".


    CREATE Department.
    ASSIGN
        Department.DeptCode = RandomDeptCode
        Department.DeptName = "Read Test Department".


    CREATE Customer.
    ASSIGN
        Customer.CustNum = RandomCustNum
        Customer.Name = "ReadTestCustomer".

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
PROCEDURE testReadEmployee:
    /* Read the employee */
    RUN readEmployee(RandomEmpNum, "ReadTest", "Employee").

END PROCEDURE.

@Test.
PROCEDURE testReadDepartment:
    /* Read the department */
    RUN readDepartment(RandomDeptCode, "Read Test Department").

END PROCEDURE.

@Test.
PROCEDURE testReadCustomer:
    /* Read the customer */
    RUN readCustomer(RandomCustNum, "ReadTestCustomer", "ReadTestCustomer").

END PROCEDURE.

@Test.
PROCEDURE testReadBenefits:
    DEFINE VARIABLE BenefitEmpNum AS INTEGER NO-UNDO.
    
    ASSIGN BenefitEmpNum = 77013.
    
    /* Create employee and benefits to read */

    CREATE Employee.
    ASSIGN
        Employee.EmpNum = BenefitEmpNum
        Employee.FirstName = "BenefitTest"
        Employee.LastName = "Employee".
        

    CREATE Benefits.
    ASSIGN Benefits.EmpNum = BenefitEmpNum.
    
    /* Read the benefits */
    RUN readBenefits(BenefitEmpNum).
    
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
