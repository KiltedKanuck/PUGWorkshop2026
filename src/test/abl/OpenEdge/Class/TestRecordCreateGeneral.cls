 /*------------------------------------------------------------------------
    File        : OpenEdge.Class.TestRecordCreateGeneral
    Purpose     :
    Syntax      :
    Description :
    Author(s)   : Cameron David Wright [openedge]
    Created     : Tue Feb 23 08:51:52 EST 2021
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

block-level on error undo, throw.

class OpenEdge.Class.TestRecordCreateGeneral:

    define private variable iSmall as int64 initial 5000    no-undo.
    define private variable ilarge as int64 initial 5000000   no-undo.
    define private variable someFirstNames as character
                    initial "big,small,world,US" no-undo.
    define private variable someMiddleNames as character
                    initial "game,hunting,outdoor" no-undo.
    define private variable someLastNames as character
                    initial "academy,authority,sports,shop" no-undo.
    define private variable someWords as character
                    initial "customer,delivery,sports,shop,Welcome,hello,howdy,today,funny,tomorrow" no-undo.


    define public property TestClass as OpenEdge.LoadSuite.Objects.record.create.general no-undo
    get.
    set.

    define private property RandomComments as character no-undo
    get:
        define variable cReturn as character no-undo.

        cReturn = entry(1,someWords)
                + " "
                + entry(2,someWords)
                + " "
                + entry(3,someWords)
                + " "
                + entry(4,someWords)
                .
        return cReturn.
    end.
    set.
    define private property RandomCustomerName as character no-undo
    get:
        define variable cReturn as character no-undo.

        cReturn = entry(1,someFirstNames)
                + " "
                + entry(1,someMiddleNames)
                + " "
                + entry(1,someLastNames)
                .
        return cReturn.
    end.
    set.

    @Before.
    method public void setUpBeforeClass(  ):
        testClass = new OpenEdge.LoadSuite.Objects.record.create.general().
        return.
    end method.


    @After.
    method public void tearDownAfterClass(  ):
        if valid-object(testClass) then delete object testClass.
        return.
    end method.

/* SMALL TESTS FIRST */

    @Test.
    method public void TestCreateCustomerSmall(  ):
        define variable count as int64 no-undo.
        do count = 1 to iSmall:
            testClass:createCustomer(next-value(NextCustNum), RandomCustomerName, RandomComments).
        end.
        return.

    end method.

    @Test.
    method public void TestCreateOrderSmall(  ):
        define variable count as int64 no-undo.
        do count = 1 to iSmall:
            testClass:createOrder(next-value(NextOrdNum), 1900 + ((count - 1) MOD 50)).
        end.
        return.
    end method.

    @Test.
    method public void TestCreateInvoiceSmall(  ):
        define variable count as int64 no-undo.
        do count = 1 to iSmall:
            testClass:createInvoice(next-value(NextInvNum), 1900 + ((count - 1) MOD 50)).
        end.
        return.

    end method.

    @Test.
    method public void TestCreateRandomSmall(  ):
        define variable counter as int64 no-undo.
        define variable custNum as int64 no-undo.
        define variable testNum as int64 initial 1 no-undo.

        do counter = 1 to iSmall:
            case testNum:
                when 1 then do:
                    custNum = next-value(NextCustNum).
                    testClass:createCustomer(CustNum, RandomCustomerName, RandomComments).
                end.
                when 2 then
                    testClass:createOrder(custNum, next-value(NextOrdNum)).
                otherwise
                    testClass:createInvoice(next-value(NextInvNum), custNum).
            end case.
            testNum = ((counter - 1) MOD 3) + 1.
        end.
        return.
    end method.

/* LARGE TESTS NEXT */
    @Test.
    method public void TestCreateCustomerLarge(  ):
        define variable count as int64 no-undo.
        do count = 1 to iLarge:
            testClass:createCustomer(next-value(NextCustNum), RandomCustomerName, RandomComments).
        end.
        return.

    end method.

    @Test.
    method public void TestCreateOrderLarge(  ):
        define variable count as int64 no-undo.
        do count = 1 to iLarge:
            testClass:createOrder(next-value(NextOrdNum), 2500 + ((count - 1) MOD 100)).
        end.
        return.

    end method.

    @Test.
    method public void TestCreateInvoiceLarge(  ):
        define variable count as int64 no-undo.
        do count = 1 to iLarge:
            testClass:createInvoice(next-value(NextInvNum), 2500 + ((count - 1) MOD 100)).
        end.
        return.

    end method.

/* NOW LETS CREATE SOME RANDOM for record thrashing */
    @Test.
    method public void TestCreateRandomLarge(  ):
        define variable counter as int64 no-undo.
        define variable custNum as int64 no-undo.
        define variable testNum as int64 initial 1 no-undo.

        do counter = 1 to iLarge:
            case testNum:
                when 1 then do:
                    custNum = next-value(NextCustNum).
                    testClass:createCustomer(CustNum, RandomCustomerName, RandomComments).
                end.
                when 2 then
                    testClass:createOrder(next-value(NextOrdNum), custNum).
                otherwise
                    testClass:createInvoice(next-value(NextInvNum), custNum).
            end case.
            testNum = ((counter - 1) MOD 3) + 1.
        end.
        return.

    end method.

end class.