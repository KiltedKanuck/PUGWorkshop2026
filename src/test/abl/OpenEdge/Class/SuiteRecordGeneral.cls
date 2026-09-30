 
 /*------------------------------------------------------------------------
    File        : OpenEdge.Class.SuiteRecordGeneral
    Author(s)   : Cameron David Wright
    Created     : Tue Mar 02 11:27:38 EST 2021
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
block-level on error undo, throw.
@TestSuite(classes="OpenEdge.Class.TestRecordCreateGeneral,
                    OpenEdge.Class.TestRecordReadGeneral,
                    OpenEdge.Class.TestRecordUpdateGeneral,
                    OpenEdge.Class.TestRecordDeleteGeneral,
                    OpenEdge.Class.TestTransaction").
class OpenEdge.Class.SuiteRecordGeneral: 

end class.