
/*------------------------------------------------------------------------
    File        : Function / math / long / general.p
    Purpose     : Execute and measure perfomance of OpenEdge int64 MATH functions
    Description : General math functions
    Author(s)   : Cameron David Wright
    Notes       :
  ----------------------------------------------------------------------*/

BLOCK-LEVEL ON ERROR UNDO, THROW.

/**
 * Performs addition of two int64 numbers.
 *
 * @param iNum1 First int64 number.
 * @param iNum2 Second int64 number.
 * @return The sum of the two numbers.
 */
FUNCTION addition RETURNS INT64(
     INPUT iNum1 AS INT64,
     INPUT iNum2 AS INT64):

    DEFINE VARIABLE result AS INT64 NO-UNDO.
    ASSIGN result = (iNum1 + iNum2).
    RETURN result.
    
END FUNCTION.

/**
 * Performs subtraction of two int64 numbers.
 *
 * @param iNum1 First int64 number.
 * @param iNum2 Second int64 number.
 * @return The difference of the two numbers.
 */
FUNCTION subtraction RETURNS INT64(
     INPUT iNum1 AS INT64,
     INPUT iNum2 AS INT64):

    DEFINE VARIABLE result AS INT64 NO-UNDO.
    ASSIGN result = (iNum1 - iNum2).
    RETURN result.
    
END FUNCTION.

/**
 * Performs multiplication of two int64 numbers.
 *
 * @param iNum1 First int64 number.
 * @param iNum2 Second int64 number.
 * @return The product of the two numbers.
 */
FUNCTION multiplication RETURNS INT64(
     INPUT iNum1 AS INT64,
     INPUT iNum2 AS INT64):

    DEFINE VARIABLE result AS INT64 NO-UNDO.
    ASSIGN result = (iNum1 * iNum2).
    RETURN result.
    
END FUNCTION.

/**
 * Performs division of two int64 numbers.
 *
 * @param iNum1 First int64 number (dividend).
 * @param iNum2 Second int64 number (divisor).
 * @return The quotient of the two numbers.
 */
FUNCTION division RETURNS INT64(
     INPUT iNum1 AS INT64,
     INPUT iNum2 AS INT64):

    DEFINE VARIABLE result AS INT64 NO-UNDO.
    ASSIGN result = (iNum1 / iNum2).
    RETURN result.
    
END FUNCTION.
