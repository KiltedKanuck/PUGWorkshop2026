
/*------------------------------------------------------------------------
    File        : Function / math / integer / general.p
    Purpose     : Execute and measure perfomance of OpenEdge integer MATH functions
    Description : General math functions
    Author(s)   : Cameron David Wright
    Notes       :
  ----------------------------------------------------------------------*/

BLOCK-LEVEL ON ERROR UNDO, THROW.

/**
 * Performs addition of two integer numbers.
 *
 * @param iNum1 First integer number.
 * @param iNum2 Second integer number.
 * @return The sum of the two numbers.
 */
FUNCTION addition RETURNS INTEGER(
     INPUT iNum1 AS INTEGER,
     INPUT iNum2 AS INTEGER):

    DEFINE VARIABLE result AS INTEGER NO-UNDO.
    ASSIGN result = (iNum1 + iNum2).
    RETURN result.
    
END FUNCTION.

/**
 * Performs subtraction of two integer numbers.
 *
 * @param iNum1 First integer number.
 * @param iNum2 Second integer number.
 * @return The difference of the two numbers.
 */
FUNCTION subtraction RETURNS INTEGER(
     INPUT iNum1 AS INTEGER,
     INPUT iNum2 AS INTEGER):

    DEFINE VARIABLE result AS INTEGER NO-UNDO.
    ASSIGN result = (iNum1 - iNum2).
    RETURN result.
    
END FUNCTION.

/**
 * Performs multiplication of two integer numbers.
 *
 * @param iNum1 First integer number.
 * @param iNum2 Second integer number.
 * @return The product of the two numbers.
 */
FUNCTION multiplication RETURNS INTEGER(
     INPUT iNum1 AS INTEGER,
     INPUT iNum2 AS INTEGER):

    DEFINE VARIABLE result AS INTEGER NO-UNDO.
    ASSIGN result = (iNum1 * iNum2).
    RETURN result.
    
END FUNCTION.

/**
 * Performs division of two integer numbers.
 *
 * @param iNum1 First integer number (dividend).
 * @param iNum2 Second integer number (divisor).
 * @return The quotient of the two numbers.
 */
FUNCTION division RETURNS INTEGER(
     INPUT iNum1 AS INTEGER,
     INPUT iNum2 AS INTEGER):

    DEFINE VARIABLE result AS INTEGER NO-UNDO.
    ASSIGN result = (iNum1 / iNum2).
    RETURN result.
    
END FUNCTION.
