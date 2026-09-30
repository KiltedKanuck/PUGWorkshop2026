 
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

    run "Function/math/integer/general.p" persistent set hProc no-error.
    this-procedure:add-super-procedure(hProc).
    
end procedure. 

@After.
procedure tearDownAfterProcedure: 

    delete object hProc no-error.
    assign hProc = ?.

end procedure. 

@Test.  
procedure TestAddition: 
    
    define variable returned as integer no-undo.

    returned = addition (15,9).
    Assert:equals(24,returned).    
    
end procedure.

@Test.  
procedure TestDivision: 

    define variable returned as integer no-undo.

    returned = division (25,5).
    
    Assert:equals(5,returned).    

end procedure.

@Test.  
procedure TestMultiplication: 

    define variable returned as integer no-undo.

    returned = multiplication (45,712).
    Assert:equals(32040,returned).    

end procedure.

@Test.  
procedure TestSubtraction: 
    define variable returned as integer no-undo.

    returned = Subtraction (912,18).
    Assert:equals(894,returned).    

end procedure.
