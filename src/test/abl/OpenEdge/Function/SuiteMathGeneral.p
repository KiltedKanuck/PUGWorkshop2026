 
 
 /*------------------------------------------------------------------------
    File        : OpenEdge / Function / SuiteMathGeneral.p 
    Author(s)   : Cameron David Wright
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
BLOCK-LEVEL ON ERROR UNDO, THROW.
@TestSuite(procedures="Function/TestMathFloatGeneral.p,
                       Function/TestMathIntegerGeneral.p,
                       Function/TestMathLongGeneral.p").
  