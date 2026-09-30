 
 /*------------------------------------------------------------------------
    File        : OpenEdge.SuiteManager
    Author(s)   : Cameron David Wright
    N
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
block-level on error undo, throw.
@TestSuite(classes="OpenEdge.Class.SuiteMathGeneral").
@TestSuite(classes="OpenEdge.Class.SuiteStringGeneral").
@TestSuite(classes="OpenEdge.Class.TestTempTableGeneral").
@TestSuite(classes="OpenEdge.Class.StressGeneral").
@TestSuite(procedures="Function/SuiteMathGeneral.p").
@TestSuite(procedures="Procedure/SuiteMathGeneral.p").
@TestSuite(procedures="Procedure/SuiteStringGeneral.p").
class OpenEdge.SuiteManager: 

end class.