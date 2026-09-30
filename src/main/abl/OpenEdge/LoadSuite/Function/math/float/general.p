
/*------------------------------------------------------------------------
    File        : Function / math / float / general.p
    Purpose     : Execute and measure perfomance of OpenEdge float MATH functions
    Description : General math functions
    Author(s)   : Cameron David Wright
    Notes       :
  ----------------------------------------------------------------------*/

BLOCK-LEVEL ON ERROR UNDO, THROW.

/**
 * Performs addition of two decimal numbers.
 *
 * @param iNum1 First decimal number.
 * @param iNum2 Second decimal number.
 * @return The sum of the two numbers.
 */
FUNCTION addition RETURNS DECIMAL(
     INPUT iNum1 AS DECIMAL,
     INPUT iNum2 AS DECIMAL):

    DEFINE VARIABLE result AS DECIMAL NO-UNDO.
    ASSIGN result = (iNum1 + iNum2).
    RETURN result.
    
END FUNCTION.

/**
 * Performs subtraction of two decimal numbers.
 *
 * @param iNum1 First decimal number.
 * @param iNum2 Second decimal number.
 * @return The difference of the two numbers.
 */
FUNCTION subtraction RETURNS DECIMAL(
     INPUT iNum1 AS DECIMAL,
     INPUT iNum2 AS DECIMAL):

    DEFINE VARIABLE result AS DECIMAL NO-UNDO.
    ASSIGN result = (iNum1 - iNum2).
    RETURN result.
    
END FUNCTION.

/**
 * Performs multiplication of two decimal numbers.
 *
 * @param iNum1 First decimal number.
 * @param iNum2 Second decimal number.
 * @return The product of the two numbers.
 */
FUNCTION multiplication RETURNS DECIMAL(
     INPUT iNum1 AS DECIMAL,
     INPUT iNum2 AS DECIMAL):

    DEFINE VARIABLE result AS DECIMAL NO-UNDO.
    ASSIGN result = (iNum1 * iNum2).
    RETURN result.
    
END FUNCTION.

/**
 * Performs division of two decimal numbers.
 *
 * @param iNum1 First decimal number (dividend).
 * @param iNum2 Second decimal number (divisor).
 * @return The quotient of the two numbers.
 */
FUNCTION division RETURNS DECIMAL(
     INPUT iNum1 AS DECIMAL,
     INPUT iNum2 AS DECIMAL):

    DEFINE VARIABLE result AS DECIMAL NO-UNDO.
    ASSIGN result = (iNum1 / iNum2).
    RETURN result.
    
END FUNCTION.


