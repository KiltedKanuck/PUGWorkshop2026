
/*------------------------------------------------------------------------
    File        : procedure/string/long/general.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : Cameron David Wright
    Created     : Thu Jan 30 12:33:11 EST 2020
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

/* ********************  Preprocessor Definitions  ******************** */

    define variable FullString  as longchar no-undo. 
    define variable StringSize  as int64 no-undo.
    define variable iFill       as int64 no-undo.
        
    StringSize = 512000.
        
    do iFill = 1 to StringSize:
        FullString = FullString + CHR(random(33,122)).    
    end.
    
/* ***************************  Main Block  *************************** */
    /**
     * Retrieves the generated string data and its size.
     *
     * @param iSize Output parameter containing the string size.
     * @param kString Output parameter containing the full string.
     */
    procedure getData:
        define output parameter iSize as int64 no-undo.
        define output parameter kString as longchar no-undo.
        
        assign
            iSize = StringSize
            kString = FullString.
    end procedure.
    
    /**
     * Retrieves a single character from the string at the specified location.
     *
     * @param iLoc The character location (1-based index).
     * @param result Output parameter containing the character.
     */
    procedure WhatLetter:
        define input  parameter iLoc as integer no-undo. 
        define output parameter result as character no-undo.    
        
        result = substring(FullString, iLoc, 1).
    end procedure.

    /**
     * Retrieves a substring from the string at the specified location and length.
     *
     * @param iStart The starting position (1-based index).
     * @param iLength The length of the substring.
     * @param result Output parameter containing the substring.
     */
    procedure WhatWord:
        define input  parameter iStart as integer no-undo.
        define input  parameter iLength as integer no-undo.
        define output parameter result as character no-undo.
        
        result = substring(FullString, iStart, iLength).
    end procedure.
