 
 /*------------------------------------------------------------------------
    File        : startup
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Cameron David Wright
    Created     : Thu Dec 12 13:35:56 EST 2019
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING Progress.Json.ObjectModel.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS OpenEdge.StressConfig ABSTRACT: 
    
    DEFINE PROTECTED VARIABLE oProfileConfig    AS Progress.Json.ObjectModel.JsonObject        NO-UNDO.
    
/*  TestMathFloatGeneral : {
 
 }*/
    
    
    METHOD PROTECTED VOID ReadConfig(  ):
        DEFINE VARIABLE oProfileParser AS Progress.Json.ObjectModel.ObjectModelParser.
        
        ASSIGN oProfileParser = NEW Progress.Json.ObjectModel.ObjectModelParser().
        
        ASSIGN oProfileConfig = CAST(oProfileParser:ParseFile(SEARCH("OpenEdge/StressConfig.json")), JsonObject) no-error.

        RETURN.

    END METHOD.

END CLASS.