/*------------------------------------------------------------------------
    File        : Function/string/short/general.p
    Purpose     : Execute and measure performance of OpenEdge short string functions
    Description : General short string functions
    Author(s)   : Cameron David Wright
    Notes       :
  ----------------------------------------------------------------------*/

BLOCK-LEVEL ON ERROR UNDO, THROW.

{ OpenEdge/LoadSuite/Common/include/alphabet.i }

DEFINE VARIABLE FullString AS CHARACTER NO-UNDO.
DEFINE VARIABLE StringSize AS INTEGER NO-UNDO.
DEFINE VARIABLE iFill AS INTEGER NO-UNDO.

ASSIGN StringSize = RANDOM(30000,32000).

DO iFill = 1 TO StringSize:
    FullString = FullString + CHR(RANDOM(33,122)).
END.

/**
 * Returns the generated short string size.
 *
 * @return Number of characters in the generated string.
 */
FUNCTION GetSize RETURNS INTEGER ():

    RETURN StringSize.

END FUNCTION.

/**
 * Returns the generated short string.
 *
 * @return Generated short string data.
 */
FUNCTION GetData RETURNS CHARACTER ():

    RETURN FullString.

END FUNCTION.

/**
 * Finds the position of a letter in alphabet.
 *
 * @param iLetter Letter to locate.
 * @return 1-based index in alphabet or 0 when not found.
 */
FUNCTION FindIn RETURNS INTEGER (
    INPUT iLetter AS CHARACTER):

    DEFINE VARIABLE result AS INTEGER NO-UNDO.

    IF iLetter ne "" THEN
        ASSIGN result = INDEX(alphabet, iLetter).

    RETURN result.

END FUNCTION.

/**
 * Concatenates Hello with the provided word.
 *
 * @param iWord Word to append.
 * @return "Hello " plus iWord.
 */
FUNCTION HelloJoin RETURNS CHARACTER (
    INPUT iWord AS CHARACTER):

    DEFINE VARIABLE result AS CHARACTER NO-UNDO.
    ASSIGN result = "Hello " + iWord.
    RETURN result.

END FUNCTION.

/**
 * Returns the character at the requested alphabet index.
 *
 * @param iNum 1-based alphabet position.
 * @return Letter at iNum or empty when out of range.
 */
FUNCTION WhatLetter RETURNS CHARACTER (
    INPUT iNum AS INTEGER):

    DEFINE VARIABLE result AS CHARACTER NO-UNDO.

    IF iNum > 0 AND iNum <= 26 THEN
        ASSIGN result = SUBSTRING(alphabet, iNum, 1).

    RETURN result.

END FUNCTION.

/**
 * Returns a substring from the generated short string.
 *
 * @param iStart 1-based start position.
 * @param iLength Number of characters to return.
 * @return Requested substring when in range, else remaining string.
 */
FUNCTION WhatWord RETURNS CHARACTER (
    INPUT iStart AS INTEGER,
    INPUT iLength AS INTEGER):

    DEFINE VARIABLE result AS CHARACTER NO-UNDO.

    IF StringSize + iLength <= 32000 THEN
        ASSIGN result = SUBSTRING(FullString, iStart, iLength).
    ELSE
        ASSIGN result = SUBSTRING(FullString, iStart).

    RETURN result.

END FUNCTION.
