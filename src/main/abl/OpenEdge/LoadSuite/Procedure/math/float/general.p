
/*------------------------------------------------------------------------
    File        : Procedure / math / float / general.p
    Purpose     : Execute and measure perfomance of OpenEdge float MATH functions
    Description : General math functions
    Author(s)   : Cameron David Wright
    Notes       :
  ----------------------------------------------------------------------*/

BLOCK-LEVEL ON ERROR UNDO, THROW.

/* **********************  Internal Procedures  *********************** */

/**
 * Performs addition of two decimal numbers.
 *
 * @param iNum1 First decimal number.
 * @param iNum2 Second decimal number.
 * @param result Output parameter containing the sum.
 */
PROCEDURE addition:
    DEFINE INPUT  PARAMETER iNum1 AS DECIMAL NO-UNDO.
    DEFINE INPUT  PARAMETER iNum2 AS DECIMAL NO-UNDO.
    DEFINE OUTPUT PARAMETER result AS DECIMAL NO-UNDO.

    ASSIGN result = (iNum1 + iNum2).

END PROCEDURE.

/**
 * Performs subtraction of two decimal numbers.
 *
 * @param iNum1 First decimal number.
 * @param iNum2 Second decimal number.
 * @param result Output parameter containing the difference.
 */
PROCEDURE subtraction:
    DEFINE INPUT  PARAMETER iNum1 AS DECIMAL NO-UNDO.
    DEFINE INPUT  PARAMETER iNum2 AS DECIMAL NO-UNDO.
    DEFINE OUTPUT PARAMETER result AS DECIMAL NO-UNDO.

    ASSIGN result = (iNum1 - iNum2).

END PROCEDURE.

/**
 * Performs multiplication of two decimal numbers.
 *
 * @param iNum1 First decimal number.
 * @param iNum2 Second decimal number.
 * @param result Output parameter containing the product.
 */
PROCEDURE multiplication:
    DEFINE INPUT  PARAMETER iNum1 AS DECIMAL NO-UNDO.
    DEFINE INPUT  PARAMETER iNum2 AS DECIMAL NO-UNDO.
    DEFINE OUTPUT PARAMETER result AS DECIMAL NO-UNDO.

    ASSIGN result = (iNum1 * iNum2).

END PROCEDURE.

/**
 * Performs division of two decimal numbers.
 *
 * @param iNum1 First decimal number (dividend).
 * @param iNum2 Second decimal number (divisor).
 * @param result Output parameter containing the quotient.
 */
PROCEDURE division:
    DEFINE INPUT  PARAMETER iNum1 AS DECIMAL NO-UNDO.
    DEFINE INPUT  PARAMETER iNum2 AS DECIMAL NO-UNDO.
    DEFINE OUTPUT PARAMETER result AS DECIMAL NO-UNDO.

    ASSIGN result = (iNum1 / iNum2).

END PROCEDURE.

