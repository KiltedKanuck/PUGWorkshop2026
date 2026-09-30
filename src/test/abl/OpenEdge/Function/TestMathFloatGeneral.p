 
 /*------------------------------------------------------------------------
    File        : OpenEdge / Function / TestMathFloatGeneral.p 
    Author(s)   : Cameron David Wright
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using OpenEdge.Core.Assert.

block-level on error undo, throw.

{ OpenEdge/LoadSuite/Common/include/FunctionForwards.i "IN SUPER"}

define variable hProc as handle no-undo.

@Before.
procedure setUpBeforeProcedure:

    run "Function/math/float/general.p" persistent set hProc no-error.
    this-procedure:add-super-procedure(hProc).
    
end procedure. 

@After.
procedure tearDownAfterProcedure: 

    delete object hProc no-error.
    assert:IsNull(hProc).
    assign hProc = ?.

end procedure. 

@Test.  
procedure TestAddition: 
    
    define variable returned as decimal no-undo.

    returned = addition (5.1,3.3).
    Assert:equals(8.4,returned).    
    
end procedure.

@Test.  
procedure TestDivision: 

    define variable returned as decimal no-undo.

    returned = division(10.2,2.1).
    
    Assert:equals(4.8571428571,returned).    

end procedure.

@Test.  
procedure TestMultiplication: 

    define variable returned as decimal no-undo.

    returned = multiplication (5.1,3.3).
    Assert:equals(16.83,returned).    

end procedure.

@Test.  
procedure TestSubtraction: 
    define variable returned as decimal no-undo.

    returned = Subtraction (5.1,3.3).
    Assert:equals(1.8,returned).    

end procedure.
