 /*------------------------------------------------------------------------
    File        : OpenEdge.LoadSuite.Objects.string.long.general
    Purpose     : Execute and measure performance of OpenEdge character 
                  string manipulation functions
    Description : General character functions
    Author(s)   : Cameron David Wright
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

block-level on error undo, throw.

/**
 * General LONGCHAR string manipulation utilities.
 *
 * Provides string operations for performance testing with large character strings.
 * Generates a random LONGCHAR string of configurable size and provides methods to
 * extract substrings by position and length.
 *
 * @author Cameron David Wright <openedge>
 * @since 1.0
 * @version 1.0
 */
class OpenEdge.LoadSuite.Objects.string.long.general: 

    /**
     * The full random character string used for testing.
     *
     * Contains a LONGCHAR string populated with random ASCII characters
     * between 33 and 122 during construction.
     */
    define public property FullString as longchar no-undo 
    get.
    set. 

    /**
     * The size of the generated string in characters.
     *
     * Defaults to 512000 characters. This value determines how many
     * random characters are generated during construction.
     */
    define public property StringSize as int64 no-undo 
    get.
    set. 
        
    /**
     * Initializes a new instance of `OpenEdge.LoadSuite.Objects.string.long.general`.
     *
     * Generates a random LONGCHAR string of 512000 characters using ASCII
     * characters between 33 and 122. This provides a large string for
     * performance testing of substring operations.
     */
    constructor public general (  ):
        super ().
        
        define variable iFill as int64 no-undo.
        StringSize = 512000.
        
        do iFill = 1 to StringSize:
            FullString = FullString + CHR(random(33,122)).    
        end.
    end constructor.

    /**
     * Extracts a single character at the specified position.
     *
     * @param iLoc The 1-based position of the character to extract.
     * @return The character at position `iLoc` in the FullString.
     * @throws Progress.Lang.Error If `iLoc` is out of bounds.
     */
    method public character WhatLetter (input iLoc as integer ):
        define variable result as character no-undo.
        
        RESULT = substring(FullString, iLoc, 1).
        
        return RESULT.
    end method.

    /**
     * Extracts a substring of specified length starting at the given position.
     *
     * @param iStart The 1-based starting position for extraction.
     * @param iLength The number of characters to extract.
     * @return A substring of `iLength` characters starting at `iStart`.
     * @throws Progress.Lang.Error If `iStart` or `iLength` result in out of bounds access.
     */
    method public character WhatWord( input iStart as integer, input iLength as integer ):
        define variable result as character no-undo.
        
        RESULT = substring(FullString, iStart, iLength).
            
        return result.
    end method.

    /**
     * Releases resources held by this instance.
     *
     * Clears the FullString and resets StringSize to free memory.
     */
    destructor public general ( ):
        assign
            FullString = ""
            StringSize = 0.
    end destructor.

end class.