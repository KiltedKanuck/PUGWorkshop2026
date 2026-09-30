/*------------------------------------------------------------------------
    File        : Function/string/long/general.p
    Purpose     : Execute and measure performance of OpenEdge long string functions
    Description : General long string functions
    Author(s)   : Cameron David Wright
    Notes       :
  ----------------------------------------------------------------------*/

BLOCK-LEVEL ON ERROR UNDO, THROW.

DEFINE VARIABLE FullString AS LONGCHAR NO-UNDO.
DEFINE VARIABLE StringSize AS INT64 NO-UNDO.
DEFINE VARIABLE iFill AS INT64 NO-UNDO.

ASSIGN StringSize = 512000.

DO iFill = 1 TO StringSize:
    FullString = FullString + CHR(RANDOM(33,122)).
END.

/**
 * Returns the generated long string size.
 *
 * @return Number of characters in the generated string.
 */
FUNCTION GetSize RETURNS INT64 ():

    RETURN StringSize.

END FUNCTION.

/**
 * Returns the generated long string.
 *
 * @return Generated long string data.
 */
FUNCTION GetData RETURNS LONGCHAR ():

    RETURN FullString.

END FUNCTION.

/**
 * Returns the character at the requested location.
 *
 * @param iLoc 1-based string position.
 * @return Single character at iLoc.
 */
FUNCTION WhatLetter RETURNS CHARACTER (
    INPUT iLoc AS INTEGER):

    DEFINE VARIABLE result AS CHARACTER NO-UNDO.
    ASSIGN result = SUBSTRING(FullString, iLoc, 1).
    RETURN result.

END FUNCTION.

/**
 * Returns a substring from the generated long string.
 *
 * @param iStart 1-based start position.
 * @param iLength Number of characters to return.
 * @return Substring from iStart for iLength characters.
 */
FUNCTION WhatWord RETURNS CHARACTER (
    INPUT iStart AS INTEGER,
    INPUT iLength AS INTEGER):

    DEFINE VARIABLE result AS CHARACTER NO-UNDO.
    ASSIGN result = SUBSTRING(FullString, iStart, iLength).
    RETURN result.

END FUNCTION.
