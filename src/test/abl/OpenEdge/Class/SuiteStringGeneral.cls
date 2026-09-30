 
 /*------------------------------------------------------------------------
    File        : OpenEdge.Class.SuiteStringGeneral
    Author(s)   : Cameron David Wright
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
BLOCK-LEVEL ON ERROR UNDO, THROW.
@TestSuite(classes="OpenEdge.Class.TestStringLongGeneral,
                    OpenEdge.Class.TestStringShortGeneral").
CLASS OpenEdge.Class.SuiteStringGeneral: 

END CLASS.