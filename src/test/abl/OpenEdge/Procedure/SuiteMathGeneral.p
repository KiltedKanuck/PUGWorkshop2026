 
 
 /*------------------------------------------------------------------------
    File        : OpenEdge / Procedure / SuiteMathGeneral.p 
    Author(s)   : Cameron David Wright
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
BLOCK-LEVEL ON ERROR UNDO, THROW.
@TestSuite(procedures="Procedure/TestMathFloatGeneral.p,
                       Procedure/TestMathIntegerGeneral.p,
                       Procedure/TestMathLongGeneral.p").
  