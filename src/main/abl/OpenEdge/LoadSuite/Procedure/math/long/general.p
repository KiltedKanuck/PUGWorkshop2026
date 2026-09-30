
/*------------------------------------------------------------------------
    File        : Procedure / math / long / general.p
    Purpose     : Execute and measure perfomance of OpenEdge int64 MATH functions
    Description : General math functions
    Author(s)   : Cameron David Wright
    Notes       :
  ----------------------------------------------------------------------*/

BLOCK-LEVEL ON ERROR UNDO, THROW.

/* **********************  Internal Procedures  *********************** */

/**
 * Performs addition of two int64 numbers.
 *
 * @param iNum1 First int64 number.
 * @param iNum2 Second int64 number.
 * @param result Output parameter containing the sum.
 */
PROCEDURE addition:
    DEFINE INPUT  PARAMETER iNum1 AS INT64 NO-UNDO.
    DEFINE INPUT  PARAMETER iNum2 AS INT64 NO-UNDO.
    DEFINE OUTPUT PARAMETER result AS INT64 NO-UNDO.

    ASSIGN result = (iNum1 + iNum2).

END PROCEDURE.

/**
 * Performs subtraction of two int64 numbers.
 *
 * @param iNum1 First int64 number.
 * @param iNum2 Second int64 number.
 * @param result Output parameter containing the difference.
 */
PROCEDURE subtraction:
    DEFINE INPUT  PARAMETER iNum1 AS INT64 NO-UNDO.
    DEFINE INPUT  PARAMETER iNum2 AS INT64 NO-UNDO.
    DEFINE OUTPUT PARAMETER result AS INT64 NO-UNDO.

    ASSIGN result = (iNum1 - iNum2).

END PROCEDURE.

/**
 * Performs multiplication of two int64 numbers.
 *
 * @param iNum1 First int64 number.
 * @param iNum2 Second int64 number.
 * @param result Output parameter containing the product.
 */
PROCEDURE multiplication:
    DEFINE INPUT  PARAMETER iNum1 AS INT64 NO-UNDO.
    DEFINE INPUT  PARAMETER iNum2 AS INT64 NO-UNDO.
    DEFINE OUTPUT PARAMETER result AS INT64 NO-UNDO.

    ASSIGN result = (iNum1 * iNum2).

END PROCEDURE.

/**
 * Performs division of two int64 numbers.
 *
 * @param iNum1 First int64 number (dividend).
 * @param iNum2 Second int64 number (divisor).
 * @param result Output parameter containing the quotient.
 */
PROCEDURE division:
    DEFINE INPUT  PARAMETER iNum1 AS INT64 NO-UNDO.
    DEFINE INPUT  PARAMETER iNum2 AS INT64 NO-UNDO.
    DEFINE OUTPUT PARAMETER result AS INT64 NO-UNDO.

    ASSIGN result = (iNum1 / iNum2).

END PROCEDURE.

