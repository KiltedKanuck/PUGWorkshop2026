 
 /*------------------------------------------------------------------------
    File        : OpenEdge.Class.SuiteMathGeneral
    Author(s)   : Cameron David Wright
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
BLOCK-LEVEL ON ERROR UNDO, THROW.
@TestSuite(classes="OpenEdge.Class.TestMathFloatGeneral,
                    OpenEdge.Class.TestMathIntegerGeneral,
                    OpenEdge.Class.TestMathLongGeneral").
CLASS OpenEdge.Class.SuiteMathGeneral: 

END CLASS.