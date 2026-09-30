 /*------------------------------------------------------------------------
    File        : OpenEdge.LoadSuite.Objects.string.short.general
    Purpose     : Execute and measure performance of OpenEdge character 
                  string manipulation functions
    Description : General character functions
    Author(s)   : Cameron David Wright
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

/**
 * General CHARACTER string manipulation utilities.
 *
 * Provides string operations for performance testing with short character strings.
 * Generates a random CHARACTER string between 30000-32000 characters and provides
 * methods for substring extraction, character lookup, and string concatenation.
 *
 * @author Cameron David Wright <openedge>
 * @since 1.0
 * @version 1.0
 */
CLASS OpenEdge.LoadSuite.Objects.string.short.general: 
    
    { OpenEdge/LoadSuite/Common/include/alphabet.i }
    
    /**
     * The full random character string used for testing.
     *
     * Contains a CHARACTER string populated with random ASCII characters
     * between 33 and 122 during construction.
     */
    DEFINE PUBLIC PROPERTY FullString AS CHARACTER NO-UNDO 
    GET.
    SET. 

    /**
     * The size of the generated string in characters.
     *
     * Randomly set between 30000 and 32000 characters during construction.
     */
    DEFINE PUBLIC PROPERTY StringSize AS INTEGER NO-UNDO 
    GET.
    SET. 

    /**
     * Initializes a new instance of `OpenEdge.LoadSuite.Objects.string.short.general`.
     *
     * Generates a random CHARACTER string between 30000-32000 characters using
     * ASCII characters between 33 and 122 for performance testing.
     */
    CONSTRUCTOR PUBLIC general (  ):
        SUPER ().
        DEFINE VARIABLE iFill AS INTEGER NO-UNDO.
        StringSize = RANDOM(30000,31119). // Keep just below 32K
        DO iFill = 1 TO StringSize:
            FullString = FullString + CHR(RANDOM(33,122)).    
        END.
    END CONSTRUCTOR.

    /**
     * Finds the position of a letter in the alphabet.
     *
     * @param iLetter The character to find in the alphabet.
     * @return The 1-based position of the letter in the alphabet, or 0 if not found.
     */
    METHOD PUBLIC INTEGER FindIn( INPUT iLetter AS CHARACTER  ):
        DEFINE VARIABLE result AS INTEGER INIT 0 NO-UNDO.
        
        IF iLetter ne "" THEN 
            RESULT = INDEX(alphabet,iLetter).

        RETURN result.
    END METHOD.

    /**
     * Concatenates "Hello " with the provided word.
     *
     * @param iWord The word to append after "Hello ".
     * @return The concatenated string "Hello " + iWord.
     */
    METHOD PUBLIC CHARACTER HelloJoin( INPUT iWord AS CHARACTER ):
        DEFINE VARIABLE result AS CHARACTER NO-UNDO.

        RESULT = "Hello " + iWord.

        RETURN result.
    END METHOD.

    /**
     * Retrieves the letter at the specified position in the alphabet.
     *
     * @param iNum The 1-based position in the alphabet (1-26).
     * @return The letter at position `iNum`, or empty string if out of range.
     */
    METHOD PUBLIC CHARACTER WhatLetter( INPUT iNum AS INTEGER ):
        DEFINE VARIABLE result AS CHARACTER NO-UNDO.
        
        IF iNum > 0 AND iNum <= 26 THEN 
            RESULT = SUBSTRING(alphabet,iNum,1).
        
        RETURN result.
    END METHOD.

    /**
     * Extracts a substring from FullString starting at the given position.
     *
     * @param iStart The 1-based starting position for extraction.
     * @param iLength The number of characters to extract.
     * @return A substring of `iLength` characters starting at `iStart`, or remaining string if length exceeds bounds.
     */
    METHOD PUBLIC CHARACTER WhatWord( INPUT iStart AS INTEGER, INPUT iLength AS INTEGER ):
        DEFINE VARIABLE result AS CHARACTER NO-UNDO.

        IF (iStart + iLength) <= StringSize THEN
            // Only extract the requested length (from starting point) if it does not exceed the string bounds.
            RESULT = SUBSTRING(FullString, iStart, iLength).
        ELSE
            // Otherwise return from the starting point to the end of the string, ignoring the requested length.
            RESULT = SUBSTRING(FullString, iStart).
            
        RETURN result.
    END METHOD.

    /**
     * Releases resources held by this instance.
     *
     * Clears the FullString and resets StringSize to free memory.
     */
    DESTRUCTOR PUBLIC general ( ):
        ASSIGN
            FullString = ""
            StringSize = 0.
    END DESTRUCTOR.

END CLASS.