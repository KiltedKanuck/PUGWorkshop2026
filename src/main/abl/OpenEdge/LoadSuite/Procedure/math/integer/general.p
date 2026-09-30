
/*------------------------------------------------------------------------
    File        : Procedure / math / integer / general.p
    Purpose     : Execute and measure perfomance of OpenEdge integer MATH functions
    Description : General math functions
    Author(s)   : Cameron David Wright
    Notes       :
  ----------------------------------------------------------------------*/

BLOCK-LEVEL ON ERROR UNDO, THROW.

/* **********************  Internal Procedures  *********************** */

/**
 * Performs addition of two integer numbers.
 *
 * @param iNum1 First integer number.
 * @param iNum2 Second integer number.
 * @param result Output parameter containing the sum.
 */
PROCEDURE addition:
    DEFINE INPUT  PARAMETER iNum1 AS INTEGER NO-UNDO.
    DEFINE INPUT  PARAMETER iNum2 AS INTEGER NO-UNDO.
    DEFINE OUTPUT PARAMETER result AS INTEGER NO-UNDO.

    ASSIGN result = (iNum1 + iNum2).

END PROCEDURE.

/**
 * Performs subtraction of two integer numbers.
 *
 * @param iNum1 First integer number.
 * @param iNum2 Second integer number.
 * @param result Output parameter containing the difference.
 */
PROCEDURE subtraction:
    DEFINE INPUT  PARAMETER iNum1 AS INTEGER NO-UNDO.
    DEFINE INPUT  PARAMETER iNum2 AS INTEGER NO-UNDO.
    DEFINE OUTPUT PARAMETER result AS INTEGER NO-UNDO.

    ASSIGN result = (iNum1 - iNum2).

END PROCEDURE.

/**
 * Performs multiplication of two integer numbers.
 *
 * @param iNum1 First integer number.
 * @param iNum2 Second integer number.
 * @param result Output parameter containing the product.
 */
PROCEDURE multiplication:
    DEFINE INPUT  PARAMETER iNum1 AS INTEGER NO-UNDO.
    DEFINE INPUT  PARAMETER iNum2 AS INTEGER NO-UNDO.
    DEFINE OUTPUT PARAMETER result AS INTEGER NO-UNDO.

    ASSIGN result = (iNum1 * iNum2).

END PROCEDURE.

/**
 * Performs division of two integer numbers.
 *
 * @param iNum1 First integer number (dividend).
 * @param iNum2 Second integer number (divisor).
 * @param result Output parameter containing the quotient.
 */
PROCEDURE division:
    DEFINE INPUT  PARAMETER iNum1 AS INTEGER NO-UNDO.
    DEFINE INPUT  PARAMETER iNum2 AS INTEGER NO-UNDO.
    DEFINE OUTPUT PARAMETER result AS INTEGER NO-UNDO.

    ASSIGN result = (iNum1 / iNum2).

END PROCEDURE.

